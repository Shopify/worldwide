//! Error types for YAML to CLDR JSON conversion.

use std::path::PathBuf;
use thiserror::Error;

/// Errors that can occur during YAML to JSON conversion.
#[derive(Debug, Error)]
pub enum ConvertError {
    #[error("Failed to read YAML file {path}: {source}")]
    YamlRead {
        path: PathBuf,
        #[source]
        source: serde_yaml::Error,
    },

    #[error("Failed to open file {path}: {source}")]
    FileOpen {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("Failed to write JSON file {path}: {source}")]
    JsonWrite {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("Failed to serialize JSON for {path}: {source}")]
    JsonSerialize {
        path: PathBuf,
        #[source]
        source: serde_json::Error,
    },

    #[error("Failed to clean directory {path}: {source}")]
    CleanDir {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("Failed to create directory {path}: {source}")]
    CreateDir {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("Missing locale data for '{locale}' in {file}")]
    MissingLocale { locale: String, file: String },
}
