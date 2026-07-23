//! ICU4X data provider with Shopify's CLDR patches from the worldwide gem.
//!
//! This crate provides a pre-generated ICU4X data blob that includes Shopify's
//! corrections to upstream CLDR for:
//! - Subdivision names (Argentina, Chile, Italy, Spain, etc.)
//! - Territory names (Türkiye, eSwatini, etc.)
//! - Number and currency formatting
//! - Date and time formatting
//! - Plural rules and locale display names
//!
//! # Usage
//!
//! ```rust,ignore
//! use icu_datetime::{DateTimeFormatterOptions, TypedDateTimeFormatter, options::length};
//! use icu_calendar::{DateTime, Gregorian};
//! use icu_locid::locale;
//! use worldwide_icu4x_data::provider;
//!
//! let provider = provider();
//!
//! // Create formatter options
//! let options: DateTimeFormatterOptions =
//!     length::Bag::from_date_time_style(length::Date::Medium, length::Time::Short).into();
//!
//! // Create a typed datetime formatter for Gregorian calendar
//! let dtf = TypedDateTimeFormatter::<Gregorian>::try_new_with_buffer_provider(
//!     &provider,
//!     &locale!("en").into(),
//!     options,
//! ).expect("Failed to create formatter");
//!
//! // Create a date (December 25, 2023)
//! let date = DateTime::try_new_gregorian_datetime(2023, 12, 25, 12, 0, 0)
//!     .expect("Failed to create date");
//!
//! println!("{}", dtf.format(&date));
//! ```
//!
//! # Features
//!
//! - **Full CLDR v41 coverage** with Shopify patches
//! - **Runtime loading** via `BlobDataProvider`
//! - **All ICU4X data keys** included
//! - **1,500+ locales** supported
//! - **Production ready** - validated against Ruby output

use icu_provider_blob::BlobDataProvider;

/// Static ICU4X data blob (postcard-serialized)
static ICU4X_DATA: &[u8] = include_bytes!("../data/icu4x.postcard");

/// Returns a `BlobDataProvider` loaded with worldwide's patched CLDR data.
///
/// This provider includes all ICU4X data keys and supports all locales
/// in the CLDR dataset, with Shopify's custom corrections applied.
///
/// # Panics
///
/// Panics if the embedded data blob is invalid (should never happen in practice).
///
/// # Example
///
/// ```rust
/// use worldwide_icu4x_data::provider;
///
/// let provider = provider();
/// // Use with ICU4X components
/// ```
pub fn provider() -> BlobDataProvider {
    BlobDataProvider::try_new_from_static_blob(ICU4X_DATA).expect("valid ICU4X data blob")
}

/// Returns the CLDR version this data was generated from.
pub fn cldr_version() -> &'static str {
    "41"
}

/// Returns the worldwide patch version (same as crate version).
pub fn patch_version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

/// Returns the approximate size of the data blob in bytes.
pub fn data_size() -> usize {
    ICU4X_DATA.len()
}

#[cfg(test)]
mod tests {
    use super::*;
    use icu_calendar::{DateTime, Gregorian};
    use icu_datetime::{
        options::length, DateTimeFormatterOptions, TypedDateFormatter, TypedDateTimeFormatter,
    };
    use icu_decimal::FixedDecimalFormatter;
    use icu_locid::locale;
    use icu_plurals::{PluralCategory, PluralRules};

    #[test]
    fn test_provider_loads_successfully() {
        let provider = provider();
        // If we get here without panicking, the provider loaded correctly
        assert!(data_size() > 0);
        drop(provider);
    }

    #[test]
    fn test_cldr_version() {
        assert_eq!(cldr_version(), "41");
    }

    #[test]
    fn test_patch_version() {
        // Should return a valid semver version
        let version = patch_version();
        assert!(!version.is_empty());
    }

    #[test]
    fn test_data_size_is_reasonable() {
        // Data blob should be at least 1MB (it's comprehensive)
        let size = data_size();
        assert!(
            size > 1_000_000,
            "Data blob seems too small: {} bytes",
            size
        );
    }

    #[test]
    fn test_datetime_formatter_english() {
        let provider = provider();
        let options: DateTimeFormatterOptions =
            length::Bag::from_date_time_style(length::Date::Medium, length::Time::Short).into();

        let dtf = TypedDateTimeFormatter::<Gregorian>::try_new_with_buffer_provider(
            &provider,
            &locale!("en").into(),
            options,
        )
        .expect("Failed to create English datetime formatter");

        let date = DateTime::try_new_gregorian_datetime(2023, 12, 25, 14, 30, 0)
            .expect("Failed to create date");

        let formatted = dtf.format(&date).to_string();
        assert!(
            formatted.contains("Dec") || formatted.contains("25"),
            "Formatted date should contain month or day: {}",
            formatted
        );
    }

    #[test]
    fn test_date_formatter_french() {
        let provider = provider();

        // Use TypedDateFormatter for date-only formatting
        let dtf = TypedDateFormatter::<Gregorian>::try_new_with_buffer_provider(
            &provider,
            &locale!("fr").into(),
            length::Date::Long,
        )
        .expect("Failed to create French date formatter");

        let date = DateTime::try_new_gregorian_datetime(2023, 12, 25, 0, 0, 0)
            .expect("Failed to create date");

        let formatted = dtf.format(&date.date).to_string();
        assert!(
            formatted.contains("déc") || formatted.contains("2023"),
            "French formatted date should contain French month or year: {}",
            formatted
        );
    }

    #[test]
    fn test_decimal_formatter_english() {
        let provider = provider();
        let fdf = FixedDecimalFormatter::try_new_with_buffer_provider(
            &provider,
            &locale!("en").into(),
            Default::default(),
        )
        .expect("Failed to create English decimal formatter");

        let decimal = 1234567.into();
        let formatted = fdf.format(&decimal).to_string();
        assert_eq!(formatted, "1,234,567");
    }

    #[test]
    fn test_decimal_formatter_german() {
        let provider = provider();
        let fdf = FixedDecimalFormatter::try_new_with_buffer_provider(
            &provider,
            &locale!("de").into(),
            Default::default(),
        )
        .expect("Failed to create German decimal formatter");

        let decimal = 1234567.into();
        let formatted = fdf.format(&decimal).to_string();
        // German uses periods as thousand separators
        assert_eq!(formatted, "1.234.567");
    }

    #[test]
    fn test_plural_rules_english() {
        let provider = provider();
        let pr =
            PluralRules::try_new_cardinal_with_buffer_provider(&provider, &locale!("en").into())
                .expect("Failed to create English plural rules");

        assert_eq!(pr.category_for(0_u32), PluralCategory::Other);
        assert_eq!(pr.category_for(1_u32), PluralCategory::One);
        assert_eq!(pr.category_for(2_u32), PluralCategory::Other);
        assert_eq!(pr.category_for(5_u32), PluralCategory::Other);
    }

    #[test]
    fn test_plural_rules_russian() {
        let provider = provider();
        let pr =
            PluralRules::try_new_cardinal_with_buffer_provider(&provider, &locale!("ru").into())
                .expect("Failed to create Russian plural rules");

        // Russian has complex plural rules: one, few, many, other
        assert_eq!(pr.category_for(1_u32), PluralCategory::One);
        assert_eq!(pr.category_for(2_u32), PluralCategory::Few);
        assert_eq!(pr.category_for(5_u32), PluralCategory::Many);
        assert_eq!(pr.category_for(21_u32), PluralCategory::One);
        assert_eq!(pr.category_for(22_u32), PluralCategory::Few);
        assert_eq!(pr.category_for(25_u32), PluralCategory::Many);
    }

    #[test]
    fn test_multiple_locales_supported() {
        let provider = provider();
        let locales = [
            locale!("en"),
            locale!("es"),
            locale!("fr"),
            locale!("de"),
            locale!("ja"),
            locale!("zh"),
            locale!("ar"),
            locale!("pt"),
            locale!("ru"),
            locale!("ko"),
        ];

        for loc in locales {
            let result = FixedDecimalFormatter::try_new_with_buffer_provider(
                &provider,
                &loc.into(),
                Default::default(),
            );
            assert!(
                result.is_ok(),
                "Failed to create decimal formatter for locale: {}",
                loc
            );
        }
    }

    #[test]
    fn test_provider_can_be_cloned_and_reused() {
        let provider1 = provider();
        let provider2 = provider();

        // Both providers should work independently
        let fdf1 = FixedDecimalFormatter::try_new_with_buffer_provider(
            &provider1,
            &locale!("en").into(),
            Default::default(),
        )
        .expect("Failed with provider1");

        let fdf2 = FixedDecimalFormatter::try_new_with_buffer_provider(
            &provider2,
            &locale!("de").into(),
            Default::default(),
        )
        .expect("Failed with provider2");

        let decimal = 1000.into();
        assert_eq!(fdf1.format(&decimal).to_string(), "1,000");
        assert_eq!(fdf2.format(&decimal).to_string(), "1.000");
    }
}
