//! Calendar/dates conversion.

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
struct DatesLocaleOutput {
    identity: Identity,
    dates: serde_json::Value,
}

#[derive(Debug, Serialize)]
struct MainWrapperDates {
    main: HashMap<String, DatesLocaleOutput>,
}

// ============================================================================
// Export functions
// ============================================================================

/// Exports calendars.yml files to cldr-dates-full/main/{locale}/ca-gregorian.json
pub fn export_dates(config: &Config) -> Result<(), ConvertError> {
    let locales_dir = config.locales_dir();
    let output_dir = config.dates_output_dir();

    // Collect all calendars.yml files
    let entries: Vec<_> = WalkDir::new(&locales_dir)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name() == "calendars.yml")
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

        // Extract locale data: {locale: {calendars: {...}}}
        let locale_data = yaml
            .get(locale)
            .ok_or_else(|| ConvertError::MissingLocale {
                locale: locale.to_string(),
                file: path.display().to_string(),
            })?;

        // Build output: {"main": {"locale": {"identity": {...}, "dates": {...}}}}
        // Note: YAML has {calendars: {...}}, output uses "dates" as the key
        let mut main = HashMap::new();
        main.insert(
            locale.to_string(),
            DatesLocaleOutput {
                identity: Identity::from_locale(locale),
                dates: serde_json::to_value(locale_data).unwrap(),
            },
        );

        let output = MainWrapperDates { main };

        let output_path = output_dir.join(locale).join("ca-gregorian.json");
        write_json(&output_path, &output)?;

        Ok(())
    })?;

    log::debug!("  Written dates for {} locales", entries.len());
    Ok(())
}
