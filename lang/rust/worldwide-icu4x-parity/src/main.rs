//! ICU4X Parity CLI
//!
//! A small CLI that takes JSON input and returns JSON output for parity testing
//! between ICU4X (Rust) and Ruby worldwide gem implementations.
//!
//! Usage:
//!   echo '{"op": "plural_cardinal", "locale": "en", "number": 5}' | worldwide-icu4x-parity
//!   => {"result": "other"}

use fixed_decimal::FixedDecimal;
use icu_decimal::FixedDecimalFormatter;
use icu_locid::Locale;
use icu_plurals::{PluralCategory, PluralRules};
use serde::{Deserialize, Serialize};
use std::io::{self, BufRead, Write};
use worldwide_icu4x_data::provider;
use writeable::Writeable;

/// Request from Ruby
#[derive(Debug, Deserialize)]
struct Request {
    op: String,
    locale: String,
    #[serde(default)]
    number: Option<i64>,
}

/// Response to Ruby
#[derive(Debug, Serialize)]
struct Response {
    #[serde(skip_serializing_if = "Option::is_none")]
    result: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

impl Response {
    fn ok(result: String) -> Self {
        Self {
            result: Some(result),
            error: None,
        }
    }

    fn err(error: String) -> Self {
        Self {
            result: None,
            error: Some(error),
        }
    }
}

fn plural_category_to_string(category: PluralCategory) -> &'static str {
    match category {
        PluralCategory::Zero => "zero",
        PluralCategory::One => "one",
        PluralCategory::Two => "two",
        PluralCategory::Few => "few",
        PluralCategory::Many => "many",
        PluralCategory::Other => "other",
    }
}

fn handle_plural_cardinal(locale: &str, number: i64) -> Response {
    let loc: Locale = match locale.parse() {
        Ok(l) => l,
        Err(e) => return Response::err(format!("Invalid locale '{}': {}", locale, e)),
    };

    let prov = provider();

    let rules = match PluralRules::try_new_cardinal_with_buffer_provider(&prov, &loc.into()) {
        Ok(r) => r,
        Err(e) => return Response::err(format!("Failed to create plural rules: {}", e)),
    };

    // Use unsigned for non-negative, signed for negative
    let category = if number >= 0 {
        rules.category_for(number as u64)
    } else {
        // ICU4X doesn't support negative numbers directly for plurals
        // Fall back to absolute value (this matches typical plural behavior)
        rules.category_for(number.unsigned_abs())
    };

    Response::ok(plural_category_to_string(category).to_string())
}

fn handle_plural_ordinal(locale: &str, number: i64) -> Response {
    let loc: Locale = match locale.parse() {
        Ok(l) => l,
        Err(e) => return Response::err(format!("Invalid locale '{}': {}", locale, e)),
    };

    let prov = provider();

    let rules = match PluralRules::try_new_ordinal_with_buffer_provider(&prov, &loc.into()) {
        Ok(r) => r,
        Err(e) => return Response::err(format!("Failed to create ordinal rules: {}", e)),
    };

    let category = if number >= 0 {
        rules.category_for(number as u64)
    } else {
        rules.category_for(number.unsigned_abs())
    };

    Response::ok(plural_category_to_string(category).to_string())
}

fn handle_format_decimal(locale: &str, number: i64) -> Response {
    let loc: Locale = match locale.parse() {
        Ok(l) => l,
        Err(e) => return Response::err(format!("Invalid locale '{}': {}", locale, e)),
    };

    let prov = provider();

    let formatter = match FixedDecimalFormatter::try_new_with_buffer_provider(
        &prov,
        &loc.into(),
        Default::default(),
    ) {
        Ok(f) => f,
        Err(e) => return Response::err(format!("Failed to create decimal formatter: {}", e)),
    };

    let fixed = FixedDecimal::from(number);
    let formatted = formatter.format(&fixed);

    Response::ok(formatted.write_to_string().into_owned())
}

fn process_request(req: Request) -> Response {
    match req.op.as_str() {
        "plural_cardinal" => {
            let number = req.number.unwrap_or(0);
            handle_plural_cardinal(&req.locale, number)
        }
        "plural_ordinal" => {
            let number = req.number.unwrap_or(0);
            handle_plural_ordinal(&req.locale, number)
        }
        "format_decimal" => {
            let number = req.number.unwrap_or(0);
            handle_format_decimal(&req.locale, number)
        }
        other => Response::err(format!("Unknown operation: {}", other)),
    }
}

fn main() {
    let stdin = io::stdin();
    let stdout = io::stdout();
    let mut stdout_lock = stdout.lock();

    for line in stdin.lock().lines() {
        let line = match line {
            Ok(l) => l,
            Err(e) => {
                let resp = Response::err(format!("Failed to read input: {}", e));
                let _ = serde_json::to_writer(&mut stdout_lock, &resp);
                let _ = writeln!(stdout_lock);
                continue;
            }
        };

        if line.trim().is_empty() {
            continue;
        }

        let req: Request = match serde_json::from_str(&line) {
            Ok(r) => r,
            Err(e) => {
                let resp = Response::err(format!("Invalid JSON: {}", e));
                let _ = serde_json::to_writer(&mut stdout_lock, &resp);
                let _ = writeln!(stdout_lock);
                continue;
            }
        };

        let resp = process_request(req);
        let _ = serde_json::to_writer(&mut stdout_lock, &resp);
        let _ = writeln!(stdout_lock);
    }
}
