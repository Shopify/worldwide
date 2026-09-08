# Draft: Country Address Formatting API

## Summary

This PR introduces a new TypeScript module in the `lang/typescript` package that provides a public API for fetching country-specific address formatting details.

## What's New

### API Functions

- `getCountryFormatting(countryCode, locale)` - Fetch complete formatting details for a country/locale
- `hasCountryFormatting(countryCode, locale)` - Check if formatting data exists
- `getAvailableLocales(countryCode)` - Get available locales for a country

### Type Definitions

- `CountryFormatting` - Complete country formatting object
- `AddressFormat` - Edit and show templates
- `AddressFormatExtended` - Extended formatting with separators
- `AdditionalAddressFields` - Required field flags per country
- `Zone` - Political subdivisions (states/provinces)
- `AddressLabels` - Localized field labels

### Features

1. **Dynamic Imports**: Loads country/locale data on-demand via dynamic imports for optimal bundle size
2. **Type Safety**: Full TypeScript type definitions for all data structures
3. **Localization**: Supports multiple locales per country (e.g., CA has en/fr, BR has pt-br/en)
4. **Comprehensive Data**: Includes formatting templates, zones, labels, postal code patterns
5. **Pure Static**: No internal Shopify systems mentioned - ready for open-source

## Data Organization

```
lang/typescript/src/
├── country-formatting.ts         (105 lines - main API)
├── country-formatting.md         (240 lines - documentation)
├── country-formatting.example.ts (94 lines - usage examples)
├── types/
│   └── country-formatting.ts     (268 lines - type definitions)
└── data/
    ├── CA/
    │   ├── en.json               (Canadian English formatting)
    │   └── fr.json               (Canadian French formatting)
    └── BR/
        ├── en.json               (Brazilian English formatting)
        └── pt-br.json            (Brazilian Portuguese formatting)
```

## Example Usage

```typescript
import {getCountryFormatting} from '@shopify/worldwide';

// Get Canadian address formatting in English
const ca = await getCountryFormatting('CA', 'en');

console.log(ca.format.edit);
// "{country}_{firstName}{lastName}_{company}_{address1}_{address2}_{city}{province}{zip}_{phone}"

console.log(ca.labels.province); // "Province"
console.log(ca.zones.find(z => z.code === 'ON').name); // "Ontario"
```

## Country Differences Demonstrated

The stub data shows key differences between countries:

**Canada (CA)**:
- Uses `address1` and `address2` fields
- Requires province, city, and postal code
- Standard North American format

**Brazil (BR)**:
- Uses split street fields: `streetName` + `streetNumber`
- Requires `neighborhood` field
- Uses `line2` for complement
- Different display format with dashes and state abbreviation

## Files Changed

- `lang/typescript/src/index.ts` - Exports new API
- `lang/typescript/src/country-formatting.ts` - Main API module
- `lang/typescript/src/country-formatting.md` - Documentation
- `lang/typescript/src/country-formatting.example.ts` - Usage examples
- `lang/typescript/src/types/country-formatting.ts` - Type definitions
- `lang/typescript/src/data/CA/en.json` - Canadian English data
- `lang/typescript/src/data/CA/fr.json` - Canadian French data
- `lang/typescript/src/data/BR/en.json` - Brazilian English data
- `lang/typescript/src/data/BR/pt-br.json` - Brazilian Portuguese data

## Next Steps

1. Generate full data set from YAML sources (currently only CA and BR as stubs)
2. Add build step to convert YAML → JSON chunks
3. Add validation utilities using `zip_regex` patterns
4. Add formatting utilities that apply the templates
5. Add zone lookup utilities (e.g., find zone by postal code)
6. Write unit tests
7. Update main package README

## Notes

- No internal Shopify details leaked
- Pure static data API
- Designed for code splitting via dynamic imports
- Ready for npm package publication
