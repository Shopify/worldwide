//! Configuration for YAML to CLDR JSON conversion.

use std::path::PathBuf;

/// Configuration paths for the conversion process.
#[derive(Debug, Clone)]
pub struct Config {
    /// Root directory containing CLDR YAML data (e.g., `data/cldr/`)
    pub cldr_root: PathBuf,
    /// Output directory for CLDR JSON (e.g., `vendor/cldr-json/`)
    pub output_dir: PathBuf,
}

impl Config {
    /// Creates a new Config with the given paths.
    pub fn new(cldr_root: PathBuf, output_dir: PathBuf) -> Self {
        Self {
            cldr_root,
            output_dir,
        }
    }

    /// Path to the locales directory within CLDR root.
    pub fn locales_dir(&self) -> PathBuf {
        self.cldr_root.join("locales")
    }

    /// Path to cldr-numbers-full/main output directory.
    pub fn numbers_output_dir(&self) -> PathBuf {
        self.output_dir.join("cldr-numbers-full").join("main")
    }

    /// Path to cldr-dates-full/main output directory.
    pub fn dates_output_dir(&self) -> PathBuf {
        self.output_dir.join("cldr-dates-full").join("main")
    }

    /// Path to cldr-localenames-full/main output directory.
    pub fn localenames_main_dir(&self) -> PathBuf {
        self.output_dir
            .join("cldr-localenames-full")
            .join("main")
    }

    /// Path to cldr-localenames-full/subdivisions output directory.
    pub fn localenames_subdivisions_dir(&self) -> PathBuf {
        self.output_dir
            .join("cldr-localenames-full")
            .join("subdivisions")
    }

    /// Path to cldr-core/supplemental output directory.
    pub fn supplemental_dir(&self) -> PathBuf {
        self.output_dir.join("cldr-core").join("supplemental")
    }
}
