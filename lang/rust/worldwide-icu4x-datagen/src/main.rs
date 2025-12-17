//! ICU4X Data Generator for Worldwide
//!
//! This binary generates ICU4X data blobs from worldwide's patched CLDR JSON.
//! The generated blob can be loaded at runtime using BlobDataProvider.
//!
//! TODO: Implement support for loading from custom CLDR JSON path (../../vendor/cldr-json)
//! For now, uses ICU4X's tested CLDR data. Custom CLDR support will be added in a future PR.

use icu_datagen::prelude::*;
use icu_provider_blob::export::BlobExporter;
use std::fs::File;
use std::path::PathBuf;
use log::info;

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

    let output_path = PathBuf::from("../worldwide-icu4x-data/data/icu4x.postcard");

    info!("🦀 Starting ICU4X data generation");
    info!("Output blob: {}", output_path.display());

    // Create the output directory
    if let Some(parent) = output_path.parent() {
        std::fs::create_dir_all(parent)?;
    }

    // Create datagen provider with latest tested CLDR data
    // TODO: Switch to custom CLDR JSON from ../../vendor/cldr-json
    info!("📦 Using ICU4X latest tested CLDR data");
    let provider = DatagenProvider::new_latest_tested();

    // Create output file
    let output_file = File::create(&output_path)?;
    let exporter = BlobExporter::new_v2_with_sink(Box::new(output_file));

    // Configure driver for full locale support
    info!("🌍 Configuring driver for all locales and keys");
    let driver = DatagenDriver::new()
        .with_keys(icu_datagen::all_keys())
        .with_locales_and_fallback(
            [LocaleFamily::FULL],
            Default::default(),
        );

    // Generate the data
    info!("⚡ Generating ICU4X data blob...");
    driver.export(&provider, exporter)?;

    // Report results
    let metadata = std::fs::metadata(&output_path)?;
    let size_mb = metadata.len() as f64 / 1_000_000.0;

    info!("✅ Generation complete!");
    info!("📊 Blob size: {:.2} MB", size_mb);
    info!("📁 Output path: {}", output_path.display());
    info!("🎉 Ready for use in worldwide-icu4x-data crate");

    Ok(())
}
