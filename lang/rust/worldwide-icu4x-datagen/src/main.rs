//! ICU4X Data Generator for Worldwide
//!
//! This binary generates ICU4X data blobs from worldwide's patched CLDR data.
//! The generated blob can be loaded at runtime using BlobDataProvider.
//!
//! The process has two stages:
//! 1. Convert CLDR YAML data to CLDR JSON format (type-safe Rust conversion)
//! 2. Generate ICU4X postcard blob from the CLDR JSON
//!
//! This ensures the ICU4X blob includes Shopify's custom CLDR patches with
//! full type safety during the conversion process.

mod convert;

use icu_datagen::prelude::*;
use icu_provider::KeyedDataMarker;
use icu_provider_blob::export::BlobExporter;
use log::info;
use std::fs::{self, File};
use std::path::PathBuf;

use convert::config::Config;

/// Returns the subset of ICU4X keys that worldwide needs.
fn worldwide_keys() -> Vec<DataKey> {
    use icu::list::provider::*;
    use icu::plurals::provider::*;

    vec![
        // Note: Locale transform keys (AliasesV1Marker, LikelySubtags*) are excluded because:
        // 1. They require icuexport data that we don't have
        // 2. LikelySubtags causes ICU4X to derive locale variants we don't have data for
        // Locale resolution is handled on the Ruby side instead.

        // Plurals (cardinal and ordinal)
        CardinalV1Marker::KEY,
        OrdinalV1Marker::KEY,
        // List formatting
        AndListV1Marker::KEY,
        OrListV1Marker::KEY,
        UnitListV1Marker::KEY,
        // TODO: Decimal symbols - disabled because ICU4X requires decimalFormats-numberSystem-latn
        // with format patterns (e.g., "#,##0.###") in addition to symbols. Worldwide's YAML only
        // contains symbols, not format patterns. Would need to add pattern export to numbers.rs.
        // use icu::decimal::provider::*;
        // DecimalSymbolsV1Marker::KEY,
    ]
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::init();

    // In debug mode, configure Rayon to abort on panic instead of recovering
    #[cfg(debug_assertions)]
    {
        std::panic::set_hook(Box::new(|panic_info| {
            eprintln!("🛑 PANIC in datagen (aborting immediately):");
            eprintln!("{}", panic_info);
            std::process::abort();
        }));
    }

    // Configure paths (relative to repo root, where cargo runs from)
    let cldr_yaml_root = PathBuf::from("data/cldr");
    let cldr_json_output = PathBuf::from("vendor/cldr-json");
    let blob_output = PathBuf::from("lang/rust/worldwide-icu4x-data/data/icu4x.postcard");

    // =========================================================================
    // Step 1: Convert YAML to CLDR JSON
    // =========================================================================
    info!("🚀 Step 1: Converting YAML to CLDR JSON...");

    let config = Config::new(cldr_yaml_root.clone(), cldr_json_output.clone());

    if !config.cldr_root.exists() {
        eprintln!(
            "❌ CLDR YAML directory not found: {}",
            config.cldr_root.display()
        );
        std::process::exit(1);
    }

    convert::convert_all(&config)?;

    // =========================================================================
    // Step 2: Generate ICU4X blob from CLDR JSON
    // =========================================================================
    info!("🦀 Step 2: Generating ICU4X data blob...");
    info!(
        "📁 CLDR JSON path: {}",
        cldr_json_output.canonicalize()?.display()
    );
    info!("📁 Output blob: {}", blob_output.display());

    // Create the output directory
    if let Some(parent) = blob_output.parent() {
        std::fs::create_dir_all(parent)?;
    }

    // Create datagen provider using worldwide's custom CLDR JSON
    info!("🔧 Creating datagen provider from custom CLDR...");
    info!(
        "   - Using worldwide's patched CLDR data from: {}",
        cldr_json_output.display()
    );

    // Use worldwide's custom CLDR data but fetch standard ICU export data.
    // ICU export data is needed for certain keys like plurals which require
    // additional data beyond what's in CLDR JSON.
    let provider = DatagenProvider::new_custom()
        .with_cldr(cldr_json_output.canonicalize()?)?
        .with_icuexport_for_tag("release-75-1");

    // Create output file
    let output_file = File::create(&blob_output)?;
    let exporter = BlobExporter::new_v2_with_sink(Box::new(output_file));

    // Collect the locales we actually have data for by scanning the numbers directory.
    // We use numbers as the source of truth since it has the most complete coverage.
    // This avoids ICU4X trying to generate data for likelysubtags-expanded locales
    // (e.g., fr-Latn-RW) that we don't have in our converted CLDR data.
    let numbers_dir = cldr_json_output.join("cldr-numbers-full/main");
    let available_locales: Vec<LanguageIdentifier> = fs::read_dir(&numbers_dir)?
        .filter_map(|entry| entry.ok())
        .filter(|entry| entry.path().is_dir())
        .filter_map(|entry| {
            entry
                .file_name()
                .to_str()
                .and_then(|s| s.parse::<LanguageIdentifier>().ok())
        })
        .collect();

    info!(
        "📊 Found {} locales with numbers data",
        available_locales.len()
    );

    // Configure driver with only the locales we have data for
    // Note: Using worldwide_keys() instead of all_keys() to avoid datetime
    // patterns which have a known bug in ICU4X 1.5 (hour cycle assertion)
    let keys = worldwide_keys();
    info!(
        "🌍 Configuring driver for {} keys and {} locales",
        keys.len(),
        available_locales.len()
    );

    // Convert to LocaleFamily entries for explicit locale specification
    let locale_families: Vec<LocaleFamily> = available_locales
        .iter()
        .map(|lid| LocaleFamily::with_descendants(lid.clone()))
        .collect();

    let driver = DatagenDriver::new()
        .with_keys(keys)
        .with_locales_and_fallback(locale_families, Default::default());

    // Generate the data
    info!("⚡ Exporting ICU4X data...");
    driver.export(&provider, exporter)?;

    // Report results
    let metadata = std::fs::metadata(&blob_output)?;
    let size_mb = metadata.len() as f64 / 1_000_000.0;

    info!("✅ Generation complete!");
    info!("📊 Blob size: {:.2} MB", size_mb);
    info!("📁 Output path: {}", blob_output.display());
    info!("🎉 Ready for use in worldwide-icu4x-data crate");

    Ok(())
}
