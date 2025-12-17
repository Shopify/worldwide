//! YAML to CLDR JSON conversion module.
//!
//! This module converts worldwide's patched CLDR YAML data to the CLDR JSON
//! format expected by ICU4X datagen.

pub mod config;
pub mod error;
pub mod json_types;
pub mod writer;

pub mod dates;
pub mod likely_subtags;
pub mod lists;
pub mod locales;
pub mod numbers;
pub mod plurals;
pub mod supplemental;

use config::Config;
use error::ConvertError;

/// Converts all CLDR YAML data to JSON format.
pub fn convert_all(config: &Config) -> Result<(), ConvertError> {
    log::info!("Starting YAML->JSON conversion");
    log::info!("  CLDR root: {}", config.cldr_root.display());
    log::info!("  Output dir: {}", config.output_dir.display());

    // Clean output directory
    writer::clean_output_dir(&config.output_dir)?;

    // Export supplemental data first (simplest, no locale iteration)
    log::info!("Exporting supplemental data...");
    supplemental::export_likely_subtags(config)?;
    supplemental::export_parent_locales(config)?;
    supplemental::export_aliases(config)?;
    supplemental::export_coverage_levels(config)?;

    // Export plurals (aggregates from all locales)
    log::info!("Exporting plurals data...");
    plurals::export_plurals(config)?;
    plurals::export_ordinals(config)?;
    plurals::export_plural_ranges(config)?;

    // Export per-locale data (can be parallelized)
    log::info!("Exporting numbers data...");
    numbers::export_numbers(config)?;
    numbers::export_currencies(config)?;

    log::info!("Exporting dates data...");
    dates::export_dates(config)?;

    log::info!("Exporting locale names data...");
    locales::export_territories(config)?;
    locales::export_subdivisions(config)?;

    log::info!("Exporting list patterns data...");
    lists::export_lists(config)?;

    log::info!("YAML->JSON conversion complete");
    Ok(())
}
