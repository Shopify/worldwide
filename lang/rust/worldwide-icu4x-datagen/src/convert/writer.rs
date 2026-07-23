//! JSON file writing utilities.

use serde::Serialize;
use std::fs::{self, File};
use std::io::BufWriter;
use std::path::Path;

use crate::convert::error::ConvertError;

/// Writes a serializable value to a JSON file with pretty formatting.
pub fn write_json<T: Serialize>(path: &Path, data: &T) -> Result<(), ConvertError> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|e| ConvertError::CreateDir {
            path: parent.to_path_buf(),
            source: e,
        })?;
    }

    let file = File::create(path).map_err(|e| ConvertError::JsonWrite {
        path: path.to_path_buf(),
        source: e,
    })?;
    let writer = BufWriter::new(file);
    serde_json::to_writer_pretty(writer, data).map_err(|e| ConvertError::JsonSerialize {
        path: path.to_path_buf(),
        source: e,
    })?;

    Ok(())
}

/// Cleans and recreates the output directory.
pub fn clean_output_dir(dir: &Path) -> Result<(), ConvertError> {
    if dir.exists() {
        fs::remove_dir_all(dir).map_err(|e| ConvertError::CleanDir {
            path: dir.to_path_buf(),
            source: e,
        })?;
    }
    fs::create_dir_all(dir).map_err(|e| ConvertError::CreateDir {
        path: dir.to_path_buf(),
        source: e,
    })?;
    Ok(())
}
