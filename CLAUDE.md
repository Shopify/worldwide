# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

The `worldwide` gem provides internationalization and localization APIs for Ruby, including address validation/formatting, currency handling, date/time formatting, region/country data, phone validation, and more. It also includes a TypeScript/JavaScript package at `lang/typescript`.

## Build and Development Commands

### Ruby Gem
- Install dependencies: `bundle install`
- Run tests: `bundle exec rake test`
- Run single test file: `bundle exec ruby -Itest test/path/to/test_file.rb`
- Run single test method: `bundle exec ruby -Itest test/path/to/test_file.rb -n test_method_name`
- Lint: `bundle exec rubocop`
- Auto-fix lint issues: `bundle exec rubocop -a`
- Run tests and linting: `bundle exec rake` (default task)
- Console: `bin/console` or `bundle exec rake console`

### TypeScript Package
- Navigate to TypeScript directory: `cd lang/typescript`
- Install dependencies: `pnpm install`
- Build: `pnpm build`
- Run tests: `pnpm test`
- Watch tests: `pnpm test:watch`
- Lint: `pnpm lint`
- Type check: `pnpm typecheck`
- Format: `pnpm format`

### Rake Tasks
- Update CLDR data: See `rake/tasks/cldr.rake` and "Updating CLDR Data" section below

## Updating CLDR Data

The gem uses Unicode CLDR (Common Locale Data Repository) for internationalization data. To update CLDR data, run these rake tasks **in order**:

1. **Clean old data**: `bundle exec rake cldr:data:clean`
   - Removes pre-existing CLDR files to prepare for fresh import

2. **Import from Unicode**: `bundle exec rake cldr:data:import`
   - Downloads CLDR data from unicode.org (version specified in `data/cldr.yml`)
   - Converts XML to YAML format
   - Stores raw data in `vendor/cldr/` and processed data in `vendor/ruby-cldr/`
   - Takes several minutes; downloads ~50MB of data
   - Optional: `VERSION=42` to download a specific CLDR version
   - Optional: `COMPONENTS=Units,Calendars` to import specific components only

3. **Apply patches**: `bundle exec rake cldr:data:patch`
   - Applies fixes to upstream CLDR data defined in `rake/cldr/patch.rb`
   - Corrects inconsistencies in CLDR (e.g., `²` duplicate markers, inconsistent naming conventions)
   - Updates `data/cldr/` files with patched data

4. **Generate additional data**: `bundle exec rake cldr:data:generate`
   - Generates locale-specific data (date/time formats, missing plurals)
   - Takes several minutes

5. **Generate file indices**: `bundle exec rake cldr:data:generate_paths`
   - Creates lookup indices for fast file loading

### Adding Custom CLDR Patches

To fix CLDR data inconsistencies:

1. Edit `rake/cldr/patch.rb` and add your patch using `patch_subdivisions` or `patch_file`
2. Run the patch task: `bundle exec rake cldr:data:patch`
3. Verify changes in the appropriate `data/cldr/locales/*/` file
4. Commit both the patch code and the resulting data file changes
5. Consider reporting the issue upstream at https://unicode-org.atlassian.net

Example patch:
```ruby
# Remove ² markers from Spanish subdivisions in Portuguese
patch_subdivisions(:pt, [
  [:esna, "Navarra²", "Navarra"],
  [:esri, "La Rioja²", "La Rioja"],
])
```

**Important**: The `vendor/` directory is gitignored - it contains temporary build artifacts that should not be committed.

## Architecture

### Data-Driven Design
The gem is heavily data-driven, with locale/region data stored in YAML files under `data/`:
- `data/regions/` - Contains country/territory-specific data (one file per ISO country code)
- `data/cldr/` - Unicode CLDR data for localization
- `data/world.yml` - Global region hierarchy and metadata
- `data/country_codes.yml` - Country code mappings
- `data/extant_outcodes.yml` - Postal code prefix data for validation

### Core Module Structure
The `Worldwide` module provides a facade with factory methods:
- `Worldwide.region(code:)` - Access region/country data
- `Worldwide.address(...)` - Create and manipulate addresses
- `Worldwide.currency(code:)` - Currency information and formatting
- `Worldwide.locale(code:)` - Locale information
- `Worldwide.numbers`, `Worldwide.names`, `Worldwide.lists` - Formatting utilities

### Key Components

**Regions & Addresses**
- `Worldwide::Region` - Represents countries, territories, provinces, states, etc.
- `Worldwide::Address` - Address objects with validation, normalization, and formatting
- `Worldwide::AddressValidator` - Validates address completeness and correctness
- `Worldwide::Zip` - Postal code validation and normalization

**Localization**
- `Worldwide::Locale` - Locale metadata and translations
- `Worldwide::Locales` - Locale collections and lookups
- `Worldwide::RubyI18nConfig` - Configures Ruby's I18n library
- `Worldwide::Config` - Global configuration

**Formatting**
- `Worldwide::Numbers` - Number formatting per locale
- `Worldwide::Currency` - Currency symbols, names, and money formatting
- `Worldwide::TimeFormatter` - Time/date formatting helpers
- `Worldwide::Names` - Person name formatting respecting cultural conventions
- `Worldwide::Lists` - List formatting with locale-appropriate conjunctions
- `Worldwide::Punctuation` - Punctuation rules per locale

**Validation**
- `Worldwide::Phone` - Phone number validation using phonelib
- Region-specific postal code validation
- Address field completeness checking

### Testing
Uses Minitest with:
- `minitest/autorun` for test running
- `minitest/reporters` for better output
- `minitest/focus` for focusing on specific tests (dev only)
- `mocha/minitest` for mocking/stubbing

Test files are organized under `test/worldwide/` mirroring the `lib/worldwide/` structure.

### Dependencies
- `activesupport` (>= 7.0) - Rails utilities
- `i18n` - Ruby internationalization library
- `phonelib` (~> 0.8) - Phone number validation
- `ruby-cldr` (git ref) - CLDR data parser (dev/build only)

### Ruby Version
Requires Ruby >= 3.1.0

## Code Conventions
- Frozen string literals: All Ruby files should start with `# frozen_string_literal: true`
- Style: Follow Shopify Ruby style guide via `rubocop-shopify`
- Module caching: Use instance variables for caching (e.g., `@currencies_cache`)
- Data loading: Lazy-load YAML data to minimize memory footprint
- Locale awareness: Most classes accept `locale:` parameter, defaulting to `I18n.locale`

## Important Notes
- **This is a public gem**: Avoid adding internal-only references or artifacts
- When modifying region data, update the corresponding YAML file in `data/regions/`
- CLDR data is periodically updated; don't manually edit `data/cldr/` files directly - use patches
- The gem supports both country-level and province/state-level validation
- Address formatting varies significantly by country; check `data/regions/XX.yml` for country-specific rules
- The TypeScript package provides equivalent address concatenation/splitting utilities
