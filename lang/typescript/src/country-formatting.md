# Country Address Formatting API

This module provides a TypeScript API for fetching country-specific address formatting details, including:

- Address display templates (edit and show formats)
- Required address fields per country
- Political subdivisions (states, provinces, zones)
- Localized field labels
- Postal code validation patterns

## Installation

```bash
npm install @shopify/worldwide
# or
yarn add @shopify/worldwide
# or
pnpm add @shopify/worldwide
```

## Usage

### Basic Usage

```typescript
import {getCountryFormatting} from '@shopify/worldwide';

// Get Canadian address formatting in English
const canadaFormatting = await getCountryFormatting('CA', 'en');

console.log(canadaFormatting.format.edit);
// Output: "{country}_{firstName}{lastName}_{company}_{address1}_{address2}_{city}{province}{zip}_{phone}"

console.log(canadaFormatting.labels.province);
// Output: "Province"

console.log(canadaFormatting.zones.find(z => z.code === 'ON'));
// Output: { code: "ON", name: "Ontario", zip_prefixes: ["K", "L", "M", "N", "P"], ... }
```

### Get Localized Formatting

```typescript
import {getCountryFormatting} from '@shopify/worldwide';

// Get Brazilian formatting in Portuguese
const brazilPT = await getCountryFormatting('BR', 'pt-BR');

console.log(brazilPT.labels.zip);
// Output: "CEP"

console.log(brazilPT.labels.neighborhood);
// Output: "Bairro"

// Brazil uses split street fields
console.log(brazilPT.additional_address_fields.street_name);
// Output: true
console.log(brazilPT.additional_address_fields.street_number);
// Output: true
```

### Check Available Locales

```typescript
import {getAvailableLocales, hasCountryFormatting} from '@shopify/worldwide';

// Get available locales for a country
const locales = await getAvailableLocales('CA');
console.log(locales);
// Output: ["en", "fr"]

// Check if formatting exists for a country/locale combination
const exists = await hasCountryFormatting('CA', 'fr');
console.log(exists);
// Output: true
```

### Working with Zones (States/Provinces)

```typescript
import {getCountryFormatting} from '@shopify/worldwide';

const formatting = await getCountryFormatting('CA', 'en');

// Find a zone by code
const ontario = formatting.zones?.find(z => z.code === 'ON');
console.log(ontario?.name);
// Output: "Ontario"

// Check postal code prefixes
console.log(ontario?.zip_prefixes);
// Output: ["K", "L", "M", "N", "P"]

// Find neighboring zones
console.log(ontario?.neighboring_zones);
// Output: ["QC", "MB"]
```

### Validate Required Fields

```typescript
import {getCountryFormatting} from '@shopify/worldwide';

const formatting = await getCountryFormatting('US', 'en');

// Check which fields are required
if (formatting.additional_address_fields.province) {
  console.log('State is required for US addresses');
}

if (formatting.additional_address_fields.zip) {
  console.log('ZIP code is required for US addresses');
}

// Get the postal code example
console.log(`Example ZIP code: ${formatting.zip_example}`);
```

## API Reference

### `getCountryFormatting(countryCode, locale?)`

Fetch country address formatting details for a specific country and locale.

**Parameters:**
- `countryCode` (string): ISO 3166-1 alpha-2 country code (e.g., "CA", "BR", "US")
- `locale` (string, optional): Locale code (e.g., "en", "fr", "pt-BR"). Defaults to "en"

**Returns:** `Promise<CountryFormatting>`

**Throws:** Error if the country/locale combination is not found

### `hasCountryFormatting(countryCode, locale?)`

Check if formatting data exists for a country/locale combination.

**Parameters:**
- `countryCode` (string): ISO 3166-1 alpha-2 country code
- `locale` (string, optional): Locale code. Defaults to "en"

**Returns:** `Promise<boolean>`

### `getAvailableLocales(countryCode)`

Get available locales for a specific country.

**Parameters:**
- `countryCode` (string): ISO 3166-1 alpha-2 country code

**Returns:** `Promise<string[]>`

## Type Definitions

### `CountryFormatting`

```typescript
interface CountryFormatting {
  countryCode: string;
  locale: string;
  name: string;
  format: AddressFormat;
  format_extended?: AddressFormatExtended;
  additional_address_fields: AdditionalAddressFields;
  zones?: Zone[];
  labels: AddressLabels;
  zip_example?: string;
  zip_regex?: string;
  use_zone_code_as_short_name?: boolean;
}
```

### `AddressFormat`

```typescript
interface AddressFormat {
  edit: string;
  show: string;
  address1?: string;
  address1_with_unit?: string;
}
```

### `Zone`

```typescript
interface Zone {
  code: string;
  name: string;
  name_alternates?: string[];
  code_alternates?: string[];
  zip_prefixes?: string[];
  neighboring_zones?: string[];
}
```

See [types/country-formatting.ts](./types/country-formatting.ts) for complete type definitions.

## Data Organization

Country formatting data is organized in JSON files:

```
src/data/
  ├── CA/
  │   ├── en.json
  │   └── fr.json
  ├── BR/
  │   ├── en.json
  │   └── pt-br.json
  └── ...
```

Each JSON file contains the complete `CountryFormatting` object for that country/locale combination.

## Dynamic Imports

The module uses dynamic imports to load only the required country/locale data on demand:

```typescript
const data = await import(`./data/${countryCode}/${locale}.json`);
```

This ensures minimal bundle size and optimal performance by loading data chunks as needed.

## Notes

- Country codes are case-insensitive (normalized to uppercase)
- Locale codes are case-insensitive (normalized to lowercase)
- Template placeholders use the format `{fieldName}`, e.g., `{firstName}`, `{city}`, `{province}`
- Line separators in templates are represented by `_` (underscore)
- Some countries use split street fields (e.g., Brazil: `street_name` + `street_number`)
- Some countries use additional fields like `neighborhood`, `district`, or `line2`

## Future Enhancements

- Add validation utilities using the `zip_regex` patterns
- Add address formatting utilities that apply the templates
- Add zone lookup utilities (e.g., find zone by postal code prefix)
- Generate TypeScript types from YAML source data automatically
- Add build step to convert YAML data to optimized JSON chunks
