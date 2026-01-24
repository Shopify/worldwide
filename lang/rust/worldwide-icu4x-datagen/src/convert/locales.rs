//! Locale names conversion (territories and subdivisions).

use std::collections::HashMap;
use std::fs::File;
use std::io::BufReader;

use rayon::prelude::*;
use serde::Serialize;
use walkdir::WalkDir;

use crate::convert::config::Config;
use crate::convert::error::ConvertError;
use crate::convert::json_types::Identity;
use crate::convert::writer::write_json;

// ============================================================================
// JSON output types
// ============================================================================

#[derive(Debug, Serialize)]
struct TerritoriesLocaleOutput {
    identity: Identity,
    #[serde(rename = "localeDisplayNames")]
    locale_display_names: TerritoriesDisplayNames,
}

#[derive(Debug, Serialize)]
struct TerritoriesDisplayNames {
    territories: serde_json::Value,
}

#[derive(Debug, Serialize)]
struct MainWrapperTerritories {
    main: HashMap<String, TerritoriesLocaleOutput>,
}

// Subdivisions have a different structure - no main wrapper
#[derive(Debug, Serialize)]
struct SubdivisionsWrapper {
    subdivisions: HashMap<String, serde_json::Value>,
}

// ============================================================================
// Export functions
// ============================================================================

/// Exports territories.yml files to cldr-localenames-full/main/{locale}/territories.json
pub fn export_territories(config: &Config) -> Result<(), ConvertError> {
    let locales_dir = config.locales_dir();
    let output_dir = config.localenames_main_dir();

    // Collect all territories.yml files
    let entries: Vec<_> = WalkDir::new(&locales_dir)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name() == "territories.yml")
        .collect();

    // Process in parallel
    entries.par_iter().try_for_each(|entry| {
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
            return Ok(());
        }

        let file = File::open(path).map_err(|e| ConvertError::FileOpen {
            path: path.to_path_buf(),
            source: e,
        })?;
        let reader = BufReader::new(file);

        // Parse as generic YAML value
        let yaml: serde_yaml::Value =
            serde_yaml::from_reader(reader).map_err(|e| ConvertError::YamlRead {
                path: path.to_path_buf(),
                source: e,
            })?;

        // Extract locale data: {locale: {territories: {...}}}
        let locale_data = yaml
            .get(locale)
            .ok_or_else(|| ConvertError::MissingLocale {
                locale: locale.to_string(),
                file: path.display().to_string(),
            })?;

        // Build output with localeDisplayNames wrapper
        let mut main = HashMap::new();
        main.insert(
            locale.to_string(),
            TerritoriesLocaleOutput {
                identity: Identity::from_locale(locale),
                locale_display_names: TerritoriesDisplayNames {
                    territories: serde_json::to_value(locale_data).unwrap(),
                },
            },
        );

        let output = MainWrapperTerritories { main };

        let output_path = output_dir.join(locale).join("territories.json");
        write_json(&output_path, &output)?;

        Ok(())
    })?;

    log::debug!("  Written territories for {} locales", entries.len());
    Ok(())
}

/// Exports subdivisions.yml files to cldr-localenames-full/subdivisions/{locale}/territories.json
///
/// Note: Subdivisions use a different JSON structure - no "main" wrapper.
pub fn export_subdivisions(config: &Config) -> Result<(), ConvertError> {
    let locales_dir = config.locales_dir();
    let output_dir = config.localenames_subdivisions_dir();

    // Collect all subdivisions.yml files
    let entries: Vec<_> = WalkDir::new(&locales_dir)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name() == "subdivisions.yml")
        .collect();

    // Process in parallel
    entries.par_iter().try_for_each(|entry| {
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
            return Ok(());
        }

        let file = File::open(path).map_err(|e| ConvertError::FileOpen {
            path: path.to_path_buf(),
            source: e,
        })?;
        let reader = BufReader::new(file);

        // Parse as generic YAML value
        let yaml: serde_yaml::Value =
            serde_yaml::from_reader(reader).map_err(|e| ConvertError::YamlRead {
                path: path.to_path_buf(),
                source: e,
            })?;

        // Extract locale data: {locale: {subdivisions: {...}}}
        let locale_data = yaml
            .get(locale)
            .ok_or_else(|| ConvertError::MissingLocale {
                locale: locale.to_string(),
                file: path.display().to_string(),
            })?;

        // Build output: {"subdivisions": {"locale": data}}
        // Note: Different structure from other locale files!
        let mut subdivisions = HashMap::new();
        subdivisions.insert(
            locale.to_string(),
            serde_json::to_value(locale_data).unwrap(),
        );

        let output = SubdivisionsWrapper { subdivisions };

        let output_path = output_dir.join(locale).join("territories.json");
        write_json(&output_path, &output)?;

        Ok(())
    })?;

    log::debug!("  Written subdivisions for {} locales", entries.len());
    Ok(())
}
