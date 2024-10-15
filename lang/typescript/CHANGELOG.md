# @shopify/worldwide

## 0.7.2

### Patch Changes

- 4064982: Update BR address1_regex to remove lookbehinds

## 0.7.1

### Patch Changes

- 2c2b6f1: Handle input having multiple word joiners in address-splitting functions

## 0.7.0

### Minor Changes

- bbacde1: Add address1 regex for BE, BR, CL, ES, IL, MX
- b6e1c7f: Add address1 regex for DE
- ee7b7a9: Add optional tryRegexFallback param to splitAddress1 function to attempt splitting address lines that do not contain the reserved delimiter

## 0.7.0-next.2

### Minor Changes

- 3bfb56a: Add address1 regex for DE

## 0.7.0-next.1

### Minor Changes

- Add address1 regex for BE, BR, CL, ES, IL, MX

## 0.7.0-next.0

### Minor Changes

- 1f5d405: Add optional tryRegexFallback param to splitAddress1 function to attempt splitting address lines that do not contain the reserved delimiter

## 0.6.0

### Minor Changes

- 67dfcd9: Introduce additional field support for DE, defining the required additional fields `streetName`, `streetNumber`, and supporting the ability to concatenate and split address1. Update additional field neighborhood requirement in BR.

## 0.5.0

### Minor Changes

- bf28729: Rework yaml loading, add build-time validation, reduce bundle size

## 0.4.1

### Patch Changes

- fba5872: Update npm package homepage to npm package readme, fix release workflow (no functional changes)

## 0.4.0

### Minor Changes

- fbe5457: Add script detection and support for English in Taiwan

## 0.3.0

### Minor Changes

- 6102f2b: Change reserved delimiter to word joiner

## 0.2.2

### Patch Changes

- 5219bcb: Remove names from bundled region map

## 0.2.1

### Patch Changes

- 40adfed: Include ESM module

## 0.2.0

### Minor Changes

- 681a584: Add parsing functions `splitAddress1` and `splitAddress2`
- 7bbd1b6: Add concatenation functions `concatenateAddress1` and `concatenateAddress2`

## 0.1.0

### Patch Changes

- Initial package setup
