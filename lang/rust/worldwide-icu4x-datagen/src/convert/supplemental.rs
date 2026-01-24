//! Supplemental CLDR data conversion (likely_subtags, parent_locales, aliases).

use std::collections::HashMap;
use std::fs::File;
use std::io::BufReader;

use serde::{Deserialize, Serialize};

use crate::convert::config::Config;
use crate::convert::error::ConvertError;
use crate::convert::json_types::{
    LikelySubtagsData, ParentLocalesData, ParentLocalesInner, SupplementalWrapper,
};
use crate::convert::writer::write_json;

// ============================================================================
// YAML input types
// ============================================================================

#[derive(Debug, Deserialize)]
struct LikelySubtagsYaml {
    subtags: HashMap<String, String>,
}

// parent_locales.yml is a flat map, no wrapper key
type ParentLocalesYaml = HashMap<String, String>;

/// YAML structure for aliases.yml
#[derive(Debug, Deserialize)]
struct AliasesYaml {
    aliases: AliasesInnerYaml,
}

#[derive(Debug, Deserialize)]
struct AliasesInnerYaml {
    language: HashMap<String, String>,
    territory: HashMap<String, TerritoryAliasValue>,
}

/// Territory alias values can be a single string or a list of strings
#[derive(Debug, Deserialize)]
#[serde(untagged)]
enum TerritoryAliasValue {
    Single(String),
    Multiple(Vec<String>),
}

/// JSON output types for aliases
#[derive(Debug, Serialize)]
struct AliasEntry {
    #[serde(rename = "_replacement")]
    replacement: String,
}

#[derive(Debug, Serialize)]
struct AliasesMetadata {
    alias: AliasCategories,
}

#[derive(Debug, Serialize)]
struct AliasCategories {
    #[serde(rename = "languageAlias")]
    language_alias: HashMap<String, AliasEntry>,
    #[serde(rename = "scriptAlias")]
    script_alias: HashMap<String, AliasEntry>,
    #[serde(rename = "territoryAlias")]
    territory_alias: HashMap<String, AliasEntry>,
    #[serde(rename = "subdivisionAlias")]
    subdivision_alias: HashMap<String, AliasEntry>,
    #[serde(rename = "variantAlias")]
    variant_alias: HashMap<String, AliasEntry>,
}

#[derive(Debug, Serialize)]
struct AliasesData {
    metadata: AliasesMetadata,
}

// ============================================================================
// Export functions
// ============================================================================

/// Exports likely_subtags.yml to cldr-core/supplemental/likelySubtags.json
pub fn export_likely_subtags(config: &Config) -> Result<(), ConvertError> {
    let input_path = config.cldr_root.join("likely_subtags.yml");

    let file = File::open(&input_path).map_err(|e| ConvertError::FileOpen {
        path: input_path.clone(),
        source: e,
    })?;
    let reader = BufReader::new(file);

    let yaml: LikelySubtagsYaml =
        serde_yaml::from_reader(reader).map_err(|e| ConvertError::YamlRead {
            path: input_path,
            source: e,
        })?;

    // Transform subtags format: aa_Latn_ET -> aa-Latn-ET (underscores to hyphens)
    let transformed: HashMap<String, String> = yaml
        .subtags
        .into_iter()
        .map(|(k, v)| (k, v.replace('_', "-")))
        .collect();

    let output = SupplementalWrapper::new(LikelySubtagsData {
        likely_subtags: serde_json::to_value(transformed).unwrap(),
    });

    let output_path = config.supplemental_dir().join("likelySubtags.json");
    write_json(&output_path, &output)?;

    log::debug!("  Written: {}", output_path.display());
    Ok(())
}

/// Exports parent_locales.yml to cldr-core/supplemental/parentLocales.json
pub fn export_parent_locales(config: &Config) -> Result<(), ConvertError> {
    let input_path = config.cldr_root.join("parent_locales.yml");

    let file = File::open(&input_path).map_err(|e| ConvertError::FileOpen {
        path: input_path.clone(),
        source: e,
    })?;
    let reader = BufReader::new(file);

    let yaml: ParentLocalesYaml =
        serde_yaml::from_reader(reader).map_err(|e| ConvertError::YamlRead {
            path: input_path,
            source: e,
        })?;

    // Filter out entries where parent is "root" - ICU4X doesn't accept "root" as a valid
    // language subtag. These locales will fall back to "und" (undetermined) automatically.
    let filtered: ParentLocalesYaml = yaml
        .into_iter()
        .filter(|(_, parent)| parent != "root")
        .collect();

    let output = SupplementalWrapper::new(ParentLocalesData {
        parent_locales: ParentLocalesInner {
            parent_locale: serde_json::to_value(filtered).unwrap(),
            // ICU4X requires these fields to be present, but we don't use collations,
            // segmentations, grammaticalFeatures, or plurals parent mappings in worldwide.
            // Empty objects are sufficient.
            collations: serde_json::json!({}),
            segmentations: serde_json::json!({}),
            grammatical_features: serde_json::json!({}),
            plurals: serde_json::json!({}),
        },
    });

    let output_path = config.supplemental_dir().join("parentLocales.json");
    write_json(&output_path, &output)?;

    log::debug!("  Written: {}", output_path.display());
    Ok(())
}

/// Exports aliases.yml to cldr-core/supplemental/aliases.json
pub fn export_aliases(config: &Config) -> Result<(), ConvertError> {
    let input_path = config.cldr_root.join("aliases.yml");

    let file = File::open(&input_path).map_err(|e| ConvertError::FileOpen {
        path: input_path.clone(),
        source: e,
    })?;
    let reader = BufReader::new(file);

    let yaml: AliasesYaml =
        serde_yaml::from_reader(reader).map_err(|e| ConvertError::YamlRead {
            path: input_path,
            source: e,
        })?;

    // Convert language aliases: underscores to hyphens in keys
    let language_alias: HashMap<String, AliasEntry> = yaml
        .aliases
        .language
        .into_iter()
        .map(|(k, v)| {
            let key = k.replace('_', "-");
            let replacement = v.replace('_', "-");
            (key, AliasEntry { replacement })
        })
        .collect();

    // Convert territory aliases: join multiple values with space
    let territory_alias: HashMap<String, AliasEntry> = yaml
        .aliases
        .territory
        .into_iter()
        .map(|(k, v)| {
            let replacement = match v {
                TerritoryAliasValue::Single(s) => s,
                TerritoryAliasValue::Multiple(vec) => vec.join(" "),
            };
            (k, AliasEntry { replacement })
        })
        .collect();

    let output = SupplementalWrapper::new(AliasesData {
        metadata: AliasesMetadata {
            alias: AliasCategories {
                language_alias,
                script_alias: HashMap::new(), // worldwide doesn't have script aliases
                territory_alias,
                subdivision_alias: HashMap::new(), // worldwide doesn't have subdivision aliases
                variant_alias: HashMap::new(),     // worldwide doesn't have variant aliases
            },
        },
    });

    let output_path = config.supplemental_dir().join("aliases.json");
    write_json(&output_path, &output)?;

    log::debug!("  Written: {}", output_path.display());
    Ok(())
}

/// Exports a minimal coverageLevels.json stub
///
/// ICU4X uses this file to determine which locales to include at various coverage levels.
/// We export all worldwide locales at "modern" coverage level.
pub fn export_coverage_levels(config: &Config) -> Result<(), ConvertError> {
    // Get list of all locales from the locales directory
    let locales_dir = config.locales_dir();
    let mut coverage: HashMap<String, String> = HashMap::new();

    if let Ok(entries) = std::fs::read_dir(&locales_dir) {
        for entry in entries.flatten() {
            if entry.file_type().map(|t| t.is_dir()).unwrap_or(false) {
                if let Some(locale) = entry.file_name().to_str() {
                    // Skip "root" as it's not a valid ICU4X locale
                    if locale != "root" {
                        coverage.insert(locale.to_string(), "modern".to_string());
                    }
                }
            }
        }
    }

    let output = serde_json::json!({
        "coverageLevels": coverage
    });

    let output_path = config
        .output_dir
        .join("cldr-core")
        .join("coverageLevels.json");
    write_json(&output_path, &output)?;

    log::debug!(
        "  Written: {} ({} locales)",
        output_path.display(),
        coverage.len()
    );
    Ok(())
}
