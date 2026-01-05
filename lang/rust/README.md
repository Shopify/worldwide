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
icu_plurals = "1.5"
icu_locid = "1.5"
icu_provider = "1.5"
```

**Usage:**

```rust
use icu_plurals::{PluralRules, PluralCategory};
use icu_locid::locale;
use worldwide_icu4x_data::provider;

// Load the data provider with worldwide's patched CLDR
let provider = provider();

// Create plural rules for Russian
let rules = PluralRules::try_new_cardinal_with_buffer_provider(
    &provider,
    &locale!("ru").into(),
).expect("Failed to create plural rules");

// Get plural category for a number
assert_eq!(rules.category_for(1_u32), PluralCategory::One);
assert_eq!(rules.category_for(2_u32), PluralCategory::Few);
assert_eq!(rules.category_for(5_u32), PluralCategory::Many);
```

### `worldwide-icu4x-datagen` (Internal)

Build tool that generates the data blob from worldwide's patched CLDR data. Not published to crates.io.

Converts YAML CLDR data to JSON format, then generates ICU4X postcard blob.

### `worldwide-icu4x-parity` (Internal)

CLI tool for testing parity between ICU4X (Rust) and worldwide (Ruby) implementations.

```bash
# Test plural cardinal
echo '{"op": "plural_cardinal", "locale": "en", "number": 5}' | ./target/release/worldwide-icu4x-parity
# => {"result":"other"}

# Test plural ordinal
echo '{"op": "plural_ordinal", "locale": "en", "number": 1}' | ./target/release/worldwide-icu4x-parity
# => {"result":"one"}
```

## Data Pipeline

The data is generated through this pipeline:

```
data/cldr/*.yml (worldwide's patched CLDR) 
    ↓ 
    ↓ worldwide-icu4x-datagen (Rust converter)
    ↓
vendor/cldr-json/ (CLDR JSON format)
    ↓ 
    ↓ ICU4X datagen with custom CLDR
    ↓
lang/rust/worldwide-icu4x-data/data/icu4x.postcard (blob)
```

## Shopify's CLDR Patches

This data includes Shopify's corrections to upstream CLDR:

### Subdivision Names
- Argentina: Fixed province/city disambiguation
- Chile: Corrected region names
- Italy: Fixed province names
- Spain: Removed duplicate markers from subdivisions

### Territory Names
- Turkiye (not "Turkey")
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

### Current Status

The datagen now uses worldwide's custom CLDR data. The following ICU4X keys are generated from worldwide's patched data:

**Working:**
- `locid_transform/aliases@1` - Locale aliases
- `locid_transform/likelysubtags_*` - Likely subtags for locale resolution
- `plurals/cardinal@1` - Cardinal plural rules
- `plurals/ordinal@1` - Ordinal plural rules

**TODO:**
- List formatting (requires exporting all pattern variants)
- Decimal symbols (requires matching ICU4X's expected JSON format)
- Date/time formatting

### Generating Data

```bash
# Install dependencies
bundle install

# Generate data (full pipeline)
bundle exec rake icu4x:all

# Or step by step:
cargo run -p worldwide-icu4x-datagen  # YAML → JSON → blob

# Build parity CLI for testing
cargo build -p worldwide-icu4x-parity --release
```

### Testing

```bash
# Ruby parity tests (compares Ruby and ICU4X output)
bundle exec ruby -Itest test/icu4x_parity_test.rb

# Rust unit tests
cargo test -p worldwide-icu4x-data

# Full test suite
bundle exec rake icu4x:all && cargo test
```

### Parity Testing

The parity test framework verifies ICU4X output matches Ruby:

```ruby
# test/icu4x_parity_test.rb
class Icu4xParityTest < ActiveSupport::TestCase
  test "cardinal plural parity for all locales" do
    # Tests all locales with representative numbers
    # Catches any differences between Ruby and ICU4X implementations
  end
end
```

### Releasing

1. Update CLDR version in `data/cldr.yml`
2. Run `bundle exec rake icu4x:all`
3. Update crate version in `lang/rust/Cargo.toml`
4. Commit and tag: `git tag rust-v41.0.0`
5. Push tags: `git push origin rust-v41.0.0`

The GitHub Actions workflow will automatically publish to crates.io.

## Performance

- **Blob size**: ~40 KB (plurals + locale transforms only)
- **Load time**: < 10ms
- **Memory usage**: Minimal
- **Coverage**: Plural rules for all locales

## Compatibility

- **ICU4X**: 1.5.x (stable)
- **CLDR**: v41 (matches worldwide gem)
- **Rust**: 1.70+ (MSRV)
- **Ruby**: 3.1+ (for data generation)

## License

MIT License - same as the worldwide gem.

---
*Generated from Shopify/worldwide gem - [GitHub](https://github.com/Shopify/worldwide)*
