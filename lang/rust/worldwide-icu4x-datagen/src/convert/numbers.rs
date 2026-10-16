//! Numbers and currencies conversion.
//!
//! Converts worldwide's numbers.yml format to CLDR JSON format expected by ICU4X.
//!
//! Worldwide format (YAML):
//! ```yaml
//! en:
//!   numbers:
//!     latn:
//!       symbols:
//!         decimal: "."
//!         minus_sign: "-"
//!         ...
//! ```
//!
//! ICU4X expected format (JSON):
//! ```json
//! {
//!   "main": {
//!     "en": {
//!       "numbers": {
//!         "defaultNumberingSystem": "latn",
//!         "symbols-numberSystem-latn": {
//!           "decimal": ".",
//!           "minusSign": "-",
//!           ...
//!         }
//!       }
//!     }
//!   }
//! }
//! ```

use std::collections::HashMap;
use std::fs::File;
use std::io::BufReader;

use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use walkdir::WalkDir;

use crate::convert::config::Config;
use crate::convert::error::ConvertError;
use crate::convert::json_types::Identity;
use crate::convert::likely_subtags::{expand_locale, load_likely_subtags};
use crate::convert::writer::write_json;

// ============================================================================
// YAML input types
// ============================================================================

#[derive(Debug, Deserialize)]
struct NumbersYaml {
    #[serde(flatten)]
    locales: HashMap<String, NumbersLocaleYaml>,
}

#[derive(Debug, Deserialize)]
struct NumbersLocaleYaml {
    numbers: NumbersDataYaml,
}

#[derive(Debug, Deserialize)]
struct NumbersDataYaml {
    latn: Option<NumberSystemYaml>,
}

#[derive(Debug, Deserialize)]
struct NumberSystemYaml {
    symbols: Option<SymbolsYaml>,
}

#[derive(Debug, Deserialize)]
struct SymbolsYaml {
    decimal: Option<String>,
    group: Option<String>,
    list: Option<String>,
    #[serde(rename = "percent_sign")]
    percent_sign: Option<String>,
    #[serde(rename = "plus_sign")]
    plus_sign: Option<String>,
    #[serde(rename = "minus_sign")]
    minus_sign: Option<String>,
    exponential: Option<String>,
    #[serde(rename = "superscripting_exponent")]
    superscripting_exponent: Option<String>,
    #[serde(rename = "per_mille")]
    per_mille: Option<String>,
    infinity: Option<String>,
    nan: Option<String>,
}

// ============================================================================
// JSON output types
// ============================================================================

#[derive(Debug, Serialize)]
struct MainWrapper {
    main: HashMap<String, NumbersLocaleOutput>,
}

#[derive(Debug, Serialize)]
struct NumbersLocaleOutput {
    identity: Identity,
    numbers: NumbersOutput,
}

#[derive(Debug, Serialize)]
struct NumbersOutput {
    #[serde(rename = "defaultNumberingSystem")]
    default_numbering_system: String,
    #[serde(rename = "minimumGroupingDigits")]
    minimum_grouping_digits: String,
    #[serde(rename = "symbols-numberSystem-latn")]
    symbols_latn: SymbolsOutput,
}

#[derive(Debug, Clone, Serialize)]
struct SymbolsOutput {
    decimal: String,
    group: String,
    list: String,
    #[serde(rename = "percentSign")]
    percent_sign: String,
    #[serde(rename = "plusSign")]
    plus_sign: String,
    #[serde(rename = "minusSign")]
    minus_sign: String,
    exponential: String,
    #[serde(rename = "superscriptingExponent")]
    superscripting_exponent: String,
    #[serde(rename = "perMille")]
    per_mille: String,
    infinity: String,
    nan: String,
    #[serde(rename = "timeSeparator")]
    time_separator: String,
}

impl Default for SymbolsOutput {
    fn default() -> Self {
        Self {
            decimal: ".".to_string(),
            group: ",".to_string(),
            list: ";".to_string(),
            percent_sign: "%".to_string(),
            plus_sign: "+".to_string(),
            minus_sign: "-".to_string(),
            exponential: "E".to_string(),
            superscripting_exponent: "×".to_string(),
            per_mille: "‰".to_string(),
            infinity: "∞".to_string(),
            nan: "NaN".to_string(),
            time_separator: ":".to_string(),
        }
    }
}

impl From<&SymbolsYaml> for SymbolsOutput {
    fn from(yaml: &SymbolsYaml) -> Self {
        let defaults = SymbolsOutput::default();
        Self {
            decimal: yaml.decimal.clone().unwrap_or(defaults.decimal),
            group: yaml.group.clone().unwrap_or(defaults.group),
            list: yaml.list.clone().unwrap_or(defaults.list),
            percent_sign: yaml.percent_sign.clone().unwrap_or(defaults.percent_sign),
            plus_sign: yaml.plus_sign.clone().unwrap_or(defaults.plus_sign),
            minus_sign: yaml.minus_sign.clone().unwrap_or(defaults.minus_sign),
            exponential: yaml.exponential.clone().unwrap_or(defaults.exponential),
            superscripting_exponent: yaml
                .superscripting_exponent
                .clone()
                .unwrap_or(defaults.superscripting_exponent),
            per_mille: yaml.per_mille.clone().unwrap_or(defaults.per_mille),
            infinity: yaml.infinity.clone().unwrap_or(defaults.infinity),
            nan: yaml.nan.clone().unwrap_or(defaults.nan),
            time_separator: defaults.time_separator, // Not in worldwide YAML
        }
    }
}

// ============================================================================
// Export functions
// ============================================================================

/// Exports numbers data to cldr-numbers-full/main/{locale}/numbers.json
/// for ALL locales in the data directory, using inheritance for locales
/// without explicit numbers.yml files.
///
/// Also generates expanded locale variants using likelysubtags (e.g., en-GY -> en-Latn-GY)
/// because ICU4X internally expands locales and expects data files for all variants.
pub fn export_numbers(config: &Config) -> Result<(), ConvertError> {
    let locales_dir = config.locales_dir();
    let output_dir = config.numbers_output_dir();

    // Load likely subtags for locale expansion
    let subtags = load_likely_subtags(&config.cldr_root)?;

    // Build a map of locale -> symbols by reading all numbers.yml files
    // Locales without numbers.yml will inherit from their parent or use defaults
    let mut locale_symbols: HashMap<String, SymbolsOutput> = HashMap::new();

    // First pass: read all explicit numbers.yml files
    for entry in WalkDir::new(&locales_dir)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name() == "numbers.yml")
    {
        let path = entry.path();
        let locale = match path
            .parent()
            .and_then(|p| p.file_name())
            .and_then(|n| n.to_str())
        {
            Some(l) if l != "root" => l,
            _ => continue,
        };

        let file = File::open(path).map_err(|e| ConvertError::FileOpen {
            path: path.to_path_buf(),
            source: e,
        })?;
        let reader = BufReader::new(file);

        let yaml: NumbersYaml =
            serde_yaml::from_reader(reader).map_err(|e| ConvertError::YamlRead {
                path: path.to_path_buf(),
                source: e,
            })?;

        if let Some(locale_data) = yaml.locales.get(locale) {
            let symbols = locale_data
                .numbers
                .latn
                .as_ref()
                .and_then(|l| l.symbols.as_ref())
                .map(SymbolsOutput::from)
                .unwrap_or_default();
            locale_symbols.insert(locale.to_string(), symbols);
        }
    }

    // Collect ALL locale directories (not just those with numbers.yml)
    let all_locales: Vec<String> = std::fs::read_dir(&locales_dir)
        .map_err(|e| ConvertError::FileOpen {
            path: locales_dir.clone(),
            source: e,
        })?
        .filter_map(|e| e.ok())
        .filter(|e| e.path().is_dir())
        .filter_map(|e| e.file_name().to_str().map(|s| s.to_string()))
        .filter(|name| name != "root")
        .collect();

    // Helper to get symbols for a locale, falling back to parent or defaults
    let get_symbols = |locale: &str| -> SymbolsOutput {
        // Try exact match first
        if let Some(symbols) = locale_symbols.get(locale) {
            return symbols.clone();
        }

        // Try parent locale (e.g., "en-KE" -> "en")
        if let Some(parent) = locale.split('-').next() {
            if parent != locale {
                if let Some(symbols) = locale_symbols.get(parent) {
                    return symbols.clone();
                }
            }
        }

        // Fall back to defaults
        SymbolsOutput::default()
    };

    // Process all locales in parallel
    all_locales.par_iter().try_for_each(|locale| {
        let symbols = get_symbols(locale);

        // Helper to write numbers.json for a given locale tag
        let write_numbers_for_locale =
            |locale_tag: &str, symbols: &SymbolsOutput| -> Result<(), ConvertError> {
                let mut main = HashMap::new();
                main.insert(
                    locale_tag.to_string(),
                    NumbersLocaleOutput {
                        identity: Identity::from_locale(locale_tag),
                        numbers: NumbersOutput {
                            default_numbering_system: "latn".to_string(),
                            minimum_grouping_digits: "1".to_string(),
                            symbols_latn: symbols.clone(),
                        },
                    },
                );

                let output = MainWrapper { main };
                let output_path = output_dir.join(locale_tag).join("numbers.json");
                write_json(&output_path, &output)?;
                Ok(())
            };

        // Write for the base locale
        write_numbers_for_locale(locale, &symbols)?;

        // Also write for the likelysubtags-expanded variant if different
        // ICU4X internally expands locales (e.g., en-GY -> en-Latn-GY) and expects data
        if let Some(expanded) = expand_locale(locale, &subtags) {
            write_numbers_for_locale(&expanded, &symbols)?;
        }

        Ok(())
    })?;

    log::debug!("  Written numbers for {} locales", all_locales.len());
    Ok(())
}

/// Exports currencies.yml files to cldr-numbers-full/main/{locale}/currencies.json
pub fn export_currencies(config: &Config) -> Result<(), ConvertError> {
    let locales_dir = config.locales_dir();
    let output_dir = config.numbers_output_dir();

    // Collect all currencies.yml files
    let entries: Vec<_> = WalkDir::new(&locales_dir)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name() == "currencies.yml")
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

        // Extract locale data: {locale: {currencies: {...}}}
        let locale_data = yaml
            .get(locale)
            .ok_or_else(|| ConvertError::MissingLocale {
                locale: locale.to_string(),
                file: path.display().to_string(),
            })?;

        // Build output
        let mut main = HashMap::new();
        main.insert(
            locale.to_string(),
            CurrenciesLocaleOutput {
                identity: Identity::from_locale(locale),
                numbers: CurrenciesWrapper {
                    currencies: serde_json::to_value(locale_data).unwrap(),
                },
            },
        );

        let output = MainWrapperCurrencies { main };

        let output_path = output_dir.join(locale).join("currencies.json");
        write_json(&output_path, &output)?;

        Ok(())
    })?;

    log::debug!("  Written currencies for {} locales", entries.len());
    Ok(())
}

#[derive(Debug, Serialize)]
struct CurrenciesLocaleOutput {
    identity: Identity,
    numbers: CurrenciesWrapper,
}

#[derive(Debug, Serialize)]
struct CurrenciesWrapper {
    currencies: serde_json::Value,
}

#[derive(Debug, Serialize)]
struct MainWrapperCurrencies {
    main: HashMap<String, CurrenciesLocaleOutput>,
}
