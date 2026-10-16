//! Plural rules conversion.
//!
//! Exports cardinal rules to plurals.json and ordinal rules to ordinals.json.

use std::collections::HashMap;
use std::fs::File;
use std::io::BufReader;

use serde::{Deserialize, Serialize};
use walkdir::WalkDir;

use crate::convert::config::Config;
use crate::convert::error::ConvertError;
use crate::convert::json_types::SupplementalWrapper;
use crate::convert::writer::write_json;

// ============================================================================
// YAML input types
// ============================================================================

/// Structure of plural_rules.yml: `{locale: {cardinal: {...}, ordinal: {...}}}`
#[derive(Debug, Deserialize)]
struct PluralRulesYaml {
    #[serde(flatten)]
    locales: HashMap<String, PluralRulesData>,
}

#[derive(Debug, Clone, Deserialize)]
struct PluralRulesData {
    #[serde(default)]
    cardinal: Option<HashMap<String, String>>,
    #[serde(default)]
    ordinal: Option<HashMap<String, String>>,
}

// ============================================================================
// JSON output types
// ============================================================================

/// Plurals data for ICU4X: `{"plurals-type-cardinal": {...}}`
#[derive(Debug, Serialize)]
struct PluralsCardinalData {
    #[serde(rename = "plurals-type-cardinal")]
    plurals_type_cardinal: HashMap<String, HashMap<String, String>>,
}

/// Ordinals data for ICU4X: `{"plurals-type-ordinal": {...}}`
#[derive(Debug, Serialize)]
struct PluralsOrdinalData {
    #[serde(rename = "plurals-type-ordinal")]
    plurals_type_ordinal: HashMap<String, HashMap<String, String>>,
}

/// Plural ranges data (empty placeholder)
#[derive(Debug, Serialize)]
struct PluralRangesData {
    #[serde(rename = "plurals")]
    plurals: serde_json::Value,
}

// ============================================================================
// Helper functions
// ============================================================================

/// Converts plural category keys to ICU4X format: "one" -> "pluralRule-count-one"
fn convert_to_icu4x_format(rules: &HashMap<String, String>) -> HashMap<String, String> {
    rules
        .iter()
        .map(|(category, rule)| {
            let key = format!("pluralRule-count-{}", category);
            (key, rule.clone())
        })
        .collect()
}

/// Collects all plural rules from locale directories
fn collect_plural_rules(config: &Config) -> Result<HashMap<String, PluralRulesData>, ConvertError> {
    let locales_dir = config.locales_dir();
    let mut all_plurals: HashMap<String, PluralRulesData> = HashMap::new();

    for entry in WalkDir::new(&locales_dir)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name() == "plural_rules.yml")
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

        let file = File::open(path).map_err(|e| ConvertError::FileOpen {
            path: path.to_path_buf(),
            source: e,
        })?;
        let reader = BufReader::new(file);

        let yaml: PluralRulesYaml =
            serde_yaml::from_reader(reader).map_err(|e| ConvertError::YamlRead {
                path: path.to_path_buf(),
                source: e,
            })?;

        if let Some(data) = yaml.locales.get(locale) {
            all_plurals.insert(locale.to_string(), data.clone());
        }
    }

    Ok(all_plurals)
}

// ============================================================================
// Export functions
// ============================================================================

/// Checks if a locale code is valid for ICU4X (excludes "root" and other invalid codes)
fn is_valid_locale(locale: &str) -> bool {
    // ICU4X doesn't accept "root" as a language subtag
    locale != "root"
}

/// Exports cardinal plural rules to cldr-core/supplemental/plurals.json
pub fn export_plurals(config: &Config) -> Result<(), ConvertError> {
    let all_plurals = collect_plural_rules(config)?;

    // Extract only cardinal rules and convert to ICU4X format
    // Filter out invalid locales like "root"
    let cardinal_rules: HashMap<String, HashMap<String, String>> = all_plurals
        .iter()
        .filter(|(locale, _)| is_valid_locale(locale))
        .filter_map(|(locale, data)| {
            data.cardinal
                .as_ref()
                .map(|rules| (locale.clone(), convert_to_icu4x_format(rules)))
        })
        .collect();

    let output = SupplementalWrapper::new(PluralsCardinalData {
        plurals_type_cardinal: cardinal_rules,
    });

    let output_path = config.supplemental_dir().join("plurals.json");
    write_json(&output_path, &output)?;

    log::debug!("  Written: {}", output_path.display());
    Ok(())
}

/// Exports ordinal plural rules to cldr-core/supplemental/ordinals.json
pub fn export_ordinals(config: &Config) -> Result<(), ConvertError> {
    let all_plurals = collect_plural_rules(config)?;

    // Extract only ordinal rules and convert to ICU4X format
    // Filter out invalid locales like "root"
    let ordinal_rules: HashMap<String, HashMap<String, String>> = all_plurals
        .iter()
        .filter(|(locale, _)| is_valid_locale(locale))
        .filter_map(|(locale, data)| {
            data.ordinal
                .as_ref()
                .map(|rules| (locale.clone(), convert_to_icu4x_format(rules)))
        })
        .collect();

    let output = SupplementalWrapper::new(PluralsOrdinalData {
        plurals_type_ordinal: ordinal_rules,
    });

    let output_path = config.supplemental_dir().join("ordinals.json");
    write_json(&output_path, &output)?;

    log::debug!("  Written: {}", output_path.display());
    Ok(())
}

/// Exports empty plural ranges to cldr-core/supplemental/pluralRanges.json
///
/// Note: worldwide's CLDR data doesn't include plural ranges, but ICU4X expects
/// this file. We export an empty structure to satisfy the requirement.
pub fn export_plural_ranges(config: &Config) -> Result<(), ConvertError> {
    let output = SupplementalWrapper::new(PluralRangesData {
        plurals: serde_json::json!({}),
    });

    let output_path = config.supplemental_dir().join("pluralRanges.json");
    write_json(&output_path, &output)?;

    log::debug!(
        "  Written: {} (empty - not available in source data)",
        output_path.display()
    );
    Ok(())
}
