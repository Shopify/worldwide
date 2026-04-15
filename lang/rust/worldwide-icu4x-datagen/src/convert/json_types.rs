//! CLDR JSON output type definitions.
//!
//! These types match the CLDR JSON schema expected by ICU4X datagen.
//! See: https://cldr.unicode.org/index/cldr-spec/cldr-json-bindings

use serde::Serialize;

/// Identity block required in all locale files.
#[derive(Debug, Clone, Serialize)]
pub struct Identity {
    pub language: String,
}

impl Identity {
    /// Creates an identity from a locale code, extracting the language part.
    pub fn from_locale(locale: &str) -> Self {
        let language = locale.split('-').next().unwrap_or(locale).to_string();
        Self { language }
    }
}

/// Wrapper for supplemental data files.
/// Structure: `{"supplemental": {...data}}`
#[derive(Debug, Serialize)]
pub struct SupplementalWrapper<T: Serialize> {
    pub supplemental: T,
}

impl<T: Serialize> SupplementalWrapper<T> {
    pub fn new(data: T) -> Self {
        Self { supplemental: data }
    }
}

// ============================================================================
// Supplemental JSON output types
// ============================================================================

/// Likely subtags supplemental data.
#[derive(Debug, Serialize)]
pub struct LikelySubtagsData {
    #[serde(rename = "likelySubtags")]
    pub likely_subtags: serde_json::Value,
}

/// Parent locales supplemental data.
#[derive(Debug, Serialize)]
pub struct ParentLocalesData {
    #[serde(rename = "parentLocales")]
    pub parent_locales: ParentLocalesInner,
}

#[derive(Debug, Serialize)]
pub struct ParentLocalesInner {
    #[serde(rename = "parentLocale")]
    pub parent_locale: serde_json::Value,
    // ICU4X requires these additional fields to be present (can be empty)
    pub collations: serde_json::Value,
    pub segmentations: serde_json::Value,
    #[serde(rename = "grammaticalFeatures")]
    pub grammatical_features: serde_json::Value,
    pub plurals: serde_json::Value,
}
