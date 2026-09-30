//! List patterns conversion.
//!
//! Exports lists.yml from each locale to cldr-misc-full/main/{locale}/listPatterns.json
//!
//! ICU4X requires all 9 list pattern types to be present:
//! - standard, standard-short, standard-narrow
//! - or, or-short, or-narrow
//! - unit, unit-short, unit-narrow
//!
//! This module provides fallback logic when patterns are missing.

use std::collections::HashMap;
use std::fs::File;
use std::io::BufReader;

use serde::{Deserialize, Serialize};
use walkdir::WalkDir;

use crate::convert::config::Config;
use crate::convert::error::ConvertError;
use crate::convert::json_types::Identity;
use crate::convert::writer::write_json;

// ============================================================================
// YAML input types
// ============================================================================

/// Structure of lists.yml: `{locale: {lists: {...}}}`
#[derive(Debug, Deserialize)]
struct ListsYaml {
    #[serde(flatten)]
    locales: HashMap<String, ListsLocaleData>,
}

#[derive(Debug, Deserialize)]
struct ListsLocaleData {
    lists: HashMap<String, ListPatternYaml>,
}

/// A single list pattern with start/middle/end/2 variants, or a reference to another pattern
#[derive(Debug, Deserialize)]
#[serde(untagged)]
enum ListPatternYaml {
    /// A reference to another list pattern (e.g., ":lists.or_short")
    Reference(String),
    /// Actual pattern data
    Data {
        #[serde(rename = "2")]
        two: Option<String>,
        start: Option<String>,
        middle: Option<String>,
        end: Option<String>,
    },
}

// ============================================================================
// JSON output types
// ============================================================================

/// Wrapper for main locale data files
#[derive(Debug, Serialize)]
struct MainWrapper<T: Serialize> {
    main: HashMap<String, T>,
}

/// List patterns locale data
#[derive(Debug, Serialize)]
struct ListPatternsLocaleData {
    identity: Identity,
    #[serde(rename = "listPatterns")]
    list_patterns: HashMap<String, ListPatternJson>,
}

/// A single list pattern in JSON format - all fields required by ICU4X
#[derive(Debug, Clone, Serialize)]
struct ListPatternJson {
    #[serde(rename = "2")]
    two: String,
    start: String,
    middle: String,
    end: String,
}

impl Default for ListPatternJson {
    fn default() -> Self {
        // Default pattern that just concatenates with commas
        Self {
            two: "{0}, {1}".to_string(),
            start: "{0}, {1}".to_string(),
            middle: "{0}, {1}".to_string(),
            end: "{0}, {1}".to_string(),
        }
    }
}

// ============================================================================
// Pattern type definitions
// ============================================================================

/// All the pattern types ICU4X requires
const REQUIRED_PATTERN_TYPES: &[&str] = &[
    "listPattern-type-standard",
    "listPattern-type-standard-short",
    "listPattern-type-standard-narrow",
    "listPattern-type-or",
    "listPattern-type-or-short",
    "listPattern-type-or-narrow",
    "listPattern-type-unit",
    "listPattern-type-unit-short",
    "listPattern-type-unit-narrow",
];

/// Maps worldwide list type names to CLDR JSON list pattern type names
fn map_list_type(yaml_type: &str) -> String {
    match yaml_type {
        "default" => "listPattern-type-standard".to_string(),
        "or" => "listPattern-type-or".to_string(),
        "unit" => "listPattern-type-unit".to_string(),
        "unit_narrow" => "listPattern-type-unit-narrow".to_string(),
        "unit_short" => "listPattern-type-unit-short".to_string(),
        "standard_narrow" => "listPattern-type-standard-narrow".to_string(),
        "standard_short" => "listPattern-type-standard-short".to_string(),
        "or_narrow" => "listPattern-type-or-narrow".to_string(),
        "or_short" => "listPattern-type-or-short".to_string(),
        other => format!("listPattern-type-{}", other.replace('_', "-")),
    }
}

/// Returns the fallback pattern type for a given type
/// e.g., standard-short falls back to standard, or-narrow falls back to or-short then or
fn get_fallback_chain(pattern_type: &str) -> Vec<&str> {
    match pattern_type {
        "listPattern-type-standard-short" => vec!["listPattern-type-standard"],
        "listPattern-type-standard-narrow" => {
            vec![
                "listPattern-type-standard-short",
                "listPattern-type-standard",
            ]
        }
        "listPattern-type-or-short" => vec!["listPattern-type-or"],
        "listPattern-type-or-narrow" => {
            vec!["listPattern-type-or-short", "listPattern-type-or"]
        }
        "listPattern-type-unit-short" => vec!["listPattern-type-unit"],
        "listPattern-type-unit-narrow" => {
            vec!["listPattern-type-unit-short", "listPattern-type-unit"]
        }
        // Base types fall back to standard
        "listPattern-type-or" => vec!["listPattern-type-standard"],
        "listPattern-type-unit" => vec!["listPattern-type-standard"],
        _ => vec![],
    }
}

// ============================================================================
// Export functions
// ============================================================================

/// Exports lists.yml from each locale to cldr-misc-full/main/{locale}/listPatterns.json
pub fn export_lists(config: &Config) -> Result<(), ConvertError> {
    let locales_dir = config.locales_dir();
    let misc_full_dir = config.output_dir.join("cldr-misc-full").join("main");

    // Ensure output directory exists
    std::fs::create_dir_all(&misc_full_dir).map_err(|e| ConvertError::FileOpen {
        path: misc_full_dir.clone(),
        source: e,
    })?;

    let mut count = 0;

    for entry in WalkDir::new(&locales_dir)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name() == "lists.yml")
    {
        let path = entry.path();
        let locale = path
            .parent()
            .and_then(|p| p.file_name())
            .and_then(|n| n.to_str())
            .ok_or_else(|| ConvertError::MissingLocale {
                locale: "unknown".to_string(),
                file: path.display().to_string(),
            })?;

        // Skip "root" as it's not a valid ICU4X locale
        if locale == "root" {
            continue;
        }

        let file = File::open(path).map_err(|e| ConvertError::FileOpen {
            path: path.to_path_buf(),
            source: e,
        })?;
        let reader = BufReader::new(file);

        let yaml: ListsYaml =
            serde_yaml::from_reader(reader).map_err(|e| ConvertError::YamlRead {
                path: path.to_path_buf(),
                source: e,
            })?;

        // Get the locale data
        if let Some(locale_data) = yaml.locales.get(locale) {
            // First, collect all available patterns from YAML
            let mut available_patterns: HashMap<String, ListPatternJson> = HashMap::new();

            for (yaml_type, pattern) in &locale_data.lists {
                let json_type = map_list_type(yaml_type);

                let json_pattern = match pattern {
                    ListPatternYaml::Reference(ref_str) => {
                        // Parse reference like ":lists.or_short" -> "or_short"
                        let ref_type = ref_str.strip_prefix(":lists.").unwrap_or(ref_str.as_str());
                        let ref_json_type = map_list_type(ref_type);
                        // We'll resolve references after collecting all patterns
                        available_patterns
                            .get(&ref_json_type)
                            .cloned()
                            .unwrap_or_default()
                    }
                    ListPatternYaml::Data {
                        two,
                        start,
                        middle,
                        end,
                    } => ListPatternJson {
                        two: two.clone().unwrap_or_else(|| "{0}, {1}".to_string()),
                        start: start.clone().unwrap_or_else(|| "{0}, {1}".to_string()),
                        middle: middle.clone().unwrap_or_else(|| "{0}, {1}".to_string()),
                        end: end.clone().unwrap_or_else(|| "{0}, {1}".to_string()),
                    },
                };

                available_patterns.insert(json_type, json_pattern);
            }

            // Now ensure all required patterns exist with fallbacks
            let mut list_patterns: HashMap<String, ListPatternJson> = HashMap::new();

            for &pattern_type in REQUIRED_PATTERN_TYPES {
                let pattern = if let Some(p) = available_patterns.get(pattern_type) {
                    p.clone()
                } else {
                    // Try fallback chain
                    let mut found = None;
                    for fallback in get_fallback_chain(pattern_type) {
                        if let Some(p) = available_patterns.get(fallback) {
                            found = Some(p.clone());
                            break;
                        }
                    }
                    found.unwrap_or_default()
                };

                list_patterns.insert(pattern_type.to_string(), pattern);
            }

            let locale_output = ListPatternsLocaleData {
                identity: Identity::from_locale(locale),
                list_patterns,
            };

            let mut main_data = HashMap::new();
            main_data.insert(locale.to_string(), locale_output);

            let output = MainWrapper { main: main_data };

            // Create locale directory
            let locale_dir = misc_full_dir.join(locale);
            std::fs::create_dir_all(&locale_dir).map_err(|e| ConvertError::FileOpen {
                path: locale_dir.clone(),
                source: e,
            })?;

            let output_path = locale_dir.join("listPatterns.json");
            write_json(&output_path, &output)?;

            count += 1;
        }
    }

    log::debug!("  Written {} listPatterns.json files", count);
    Ok(())
}
