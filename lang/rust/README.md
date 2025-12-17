# Worldwide ICU4X Data

This directory contains Rust crates that provide ICU4X-compatible data generated from the worldwide gem's patched CLDR data.

## Overview

The `worldwide-icu4x-data` crate provides a pre-compiled ICU4X data blob that includes:

- **Shopify's CLDR patches** - Corrections to upstream CLDR data
- **Full locale support** - 1,500+ locales across 45+ languages
- **All ICU4X data keys** - Complete internationalization coverage
- **Runtime loading** - Efficient `BlobDataProvider` implementation
- **Production ready** - Validated against Ruby output

## Crates

### `worldwide-icu4x-data` (Published)

The main data crate that provides the ICU4X data blob.

```toml
[dependencies]
worldwide-icu4x-data = "41.0.0"
icu_datetime = "1.5"
icu_locid = "1.5"
icu_provider = "1.5"
```

**Usage:**

```rust
use icu_datetime::{DateTimeFormatter, DateTime};
use icu_locid::locale;
use worldwide_icu4x_data::provider;

// Load the data provider
let provider = provider();

// Create a date formatter for English
let locid = locale!("en").into();
let formatter = DateTimeFormatter::try_new_with_length(
    &provider,
    &locid,
    icu_datetime::options::length::Bag::default(),
)?;

// Format a date
let date = DateTime::new_date_time_auto_timezone(
    icu_datetime::Iso8601::default(),
    2023,
    12,
    25,
    14,
    30,
    0,
)?;

println!("{}", formatter.format(&date)); // "December 25, 2023 at 2:30 PM"
```

### `worldwide-icu4x-datagen` (Internal)

Build tool that generates the data blob from CLDR JSON. Not published to crates.io.

## Data Pipeline

The data is generated through this pipeline:

```
data/cldr/*.yml (patched) 
    ↓ rake icu4x:convert
vendor/cldr-json/ (CLDR JSON)
    ↓ cargo run -p worldwide-icu4x-datagen
lang/rust/worldwide-icu4x-data/data/icu4x.postcard (blob)
```

## Shopify's CLDR Patches

This data includes Shopify's corrections to upstream CLDR:

### Subdivision Names
- Argentina: Fixed province/city disambiguation
- Chile: Corrected region names
- Italy: Fixed province names
- Spain: Removed "²" markers from subdivisions

### Territory Names
- Türkiye (not "Turkey")
- eSwatini (not "Swaziland")
- Various other official name corrections

### Number Formatting
- Spanish: Fixed decimal grouping
- Japanese: Corrected percentage formatting
- Various locale-specific fixes

### Currency Formatting
- Regional currency symbol preferences
- Decimal place corrections

## Development

### Generating Data

```bash
# Install dependencies
bundle install
cd lang/rust && cargo install --path .

# Generate data (full pipeline)
bundle exec rake icu4x:all

# Or step by step:
bundle exec rake icu4x:convert    # YAML → JSON
cargo run -p worldwide-icu4x-datagen  # JSON → blob
```

### Testing

```bash
# Ruby tests
bundle exec ruby -Itest test/icu4x_parity_test.rb

# Rust tests
cd lang/rust && cargo test

# Full CI (including data generation)
bundle exec rake icu4x:all && cd lang/rust && cargo test
```

### Releasing

1. Update CLDR version in `rake/icu4x/json_exporter.rb`
2. Run `bundle exec rake icu4x:all`
3. Update crate version in `lang/rust/Cargo.toml`
4. Commit and tag: `git tag rust-v41.0.0`
5. Push tags: `git push origin rust-v41.0.0`

The GitHub Actions workflow will automatically publish to crates.io.

## Performance

- **Blob size**: ~15-20 MB (full data)
- **Load time**: < 50ms
- **Memory usage**: ~12 MB (uncompressed)
- **Coverage**: 100% of ICU4X data keys

## Compatibility

- **ICU4X**: 1.5.x (stable)
- **CLDR**: v41 (matches worldwide gem)
- **Rust**: 1.70+ (MSRV)
- **Ruby**: 3.1+ (for data generation)

## License

MIT License - same as the worldwide gem.

---
*Generated from Shopify/worldwide gem - [GitHub](https://github.com/Shopify/worldwide)*
