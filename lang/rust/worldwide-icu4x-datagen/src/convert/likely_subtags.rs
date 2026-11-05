//! Likely subtags expansion for ICU4X locale compatibility.
//!
//! ICU4X internally expands locales using likelysubtags (e.g., `en-GY` -> `en-Latn-GY`).
//! This module provides utilities to expand locales so we can generate data files
//! for all variants ICU4X might request.

use std::collections::HashMap;
use std::fs::File;
use std::io::BufReader;
use std::path::Path;

use serde::Deserialize;

use crate::convert::error::ConvertError;

#[derive(Debug, Deserialize)]
struct LikelySubtagsYaml {
    subtags: HashMap<String, String>,
}

/// Loads likely_subtags.yml and returns a map of locale -> expanded locale.
/// Keys and values use hyphens (e.g., "en" -> "en-Latn-US").
pub fn load_likely_subtags(cldr_root: &Path) -> Result<HashMap<String, String>, ConvertError> {
    let path = cldr_root.join("likely_subtags.yml");
    let file = File::open(&path).map_err(|e| ConvertError::FileOpen {
        path: path.clone(),
        source: e,
    })?;
    let reader = BufReader::new(file);

    let yaml: LikelySubtagsYaml =
        serde_yaml::from_reader(reader).map_err(|e| ConvertError::YamlRead { path, source: e })?;

    // Convert underscores to hyphens in values
    let subtags: HashMap<String, String> = yaml
        .subtags
        .into_iter()
        .map(|(k, v)| (k, v.replace('_', "-")))
        .collect();

    Ok(subtags)
}

/// Expands a locale to its likelysubtags variant if applicable.
///
/// For example:
/// - `en-GY` with subtags `en` -> `en-Latn-US` would expand to `en-Latn-GY`
/// - `fr-RW` with subtags `fr` -> `fr-Latn-FR` would expand to `fr-Latn-RW`
///
/// Returns None if no expansion is needed (locale already has script).
pub fn expand_locale(locale: &str, subtags: &HashMap<String, String>) -> Option<String> {
    let parts: Vec<&str> = locale.split('-').collect();

    // If locale already has 3+ parts, it likely already has a script
    // e.g., "zh-Hans-HK" or "sr-Latn-BA"
    if parts.len() >= 3 {
        // Check if second part is a script (4 letters, title case)
        if parts[1].len() == 4
            && parts[1]
                .chars()
                .next()
                .map(|c| c.is_uppercase())
                .unwrap_or(false)
        {
            return None; // Already has script
        }
    }

    // Get the language code
    let lang = parts[0];

    // Look up the likely subtag for this language
    let expanded = subtags.get(lang)?;
    let expanded_parts: Vec<&str> = expanded.split('-').collect();

    // expanded should be like "en-Latn-US" (lang-script-region)
    if expanded_parts.len() < 2 {
        return None;
    }

    let script = expanded_parts[1];

    // Build the expanded locale
    match parts.len() {
        1 => {
            // Just language (e.g., "en") -> "en-Latn" (add script only)
            Some(format!("{}-{}", lang, script))
        }
        2 => {
            // Language + region (e.g., "en-GY") -> "en-Latn-GY"
            let region = parts[1];
            // Check if second part is already a script
            if region.len() == 4
                && region
                    .chars()
                    .next()
                    .map(|c| c.is_uppercase())
                    .unwrap_or(false)
            {
                None // Already has script, no region
            } else {
                Some(format!("{}-{}-{}", lang, script, region))
            }
        }
        _ => None, // Complex locale, don't expand
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_expand_locale() {
        let mut subtags = HashMap::new();
        subtags.insert("en".to_string(), "en-Latn-US".to_string());
        subtags.insert("fr".to_string(), "fr-Latn-FR".to_string());
        subtags.insert("zh".to_string(), "zh-Hans-CN".to_string());

        assert_eq!(
            expand_locale("en-GY", &subtags),
            Some("en-Latn-GY".to_string())
        );
        assert_eq!(
            expand_locale("fr-RW", &subtags),
            Some("fr-Latn-RW".to_string())
        );
        assert_eq!(expand_locale("en", &subtags), Some("en-Latn".to_string()));

        // Already has script
        assert_eq!(expand_locale("zh-Hans-HK", &subtags), None);
        assert_eq!(expand_locale("sr-Latn-BA", &subtags), None);
    }
}
