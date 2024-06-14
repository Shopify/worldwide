# Worldwide - Typescript

Utilities for parsing and formatting address fields

## Usage

### Generating a concatenated address string

To generate a concatenated string for a specific address field, pass an address
object with the country code and extended fields as defined in the region yaml.

For example, the Brazil yaml defines the format as follows:

```yaml
# db/data/region/BR.yml
combined_address_format:
  address1:
    - key: streetName
    - key: streetNumber
      decorator: ","
  address2:
    - key: line2
    - key: neighborhood
      decorator: ","
```

To generate a correctly formatted `address1` string for Brazil, include
`streetName` and `streetNumber` in the address object.

```ts
concatenateAddress1({
  countryCode: 'BR',
  streetName: 'Av. Paulista',
  streetNumber: '1578',
}); // returns 'Av. Paulista, \u20601578'
```

You can generate Address1 or Address2 fields for any supported country, even if
there is not a `combined_address_format` for that region. In those cases we
return an unmodified `address1`.

```ts
import {concatenateAddress1, concatenateAddress2} from '@shopify/worldwide';

// Generate Address1
concatenateAddress1({
  countryCode: 'BR',
  streetName: 'Av. Paulista',
  streetNumber: '1578',
}); // returns 'Av. Paulista, \u20601578'
concatenateAddress1({
  countryCode: 'US',
  address1: '123 Main',
}); // returns '123 Main'

// Generate Address2
concatenateAddress2({
  countryCode: 'BR',
  line2: 'dpto 4',
  neighborhood: 'Centro',
}); // returns 'dpto 4, \u2060Centro'
concatenateAddress2({
  countryCode: 'US',
  address2: 'Apt 2',
}); // returns 'Apt 2'
```

### Parsing a concatentated address string

To parse a concatenated address string use the split functions which return a
partial Address object including any address fields we are able to match given
the region specified.

Using our Brazil example, we can pass the concatenated string into our split
function for address1:

```ts
splitAddress1('BR', 'Av. Paulista, \u20601578'); // returns { streetName: 'Av. Paulista', streetNumber: '1578' }
```

Trying to parse an address string for a region that doesn't have a defined
`combined_address_format` will return `null`.

```ts
import {splitAddress1, splitAddress2} from '@shopify/worldwide';

// Parse Address1
splitAddress1('BR', 'Av. Paulista, \u20601578'); // returns { streetName: 'Av. Paulista', streetNumber: '1578' }
splitAddress1('US', '123 Main'); // returns null

// Parse Address2
splitAddress2('BR', 'dpto 4, \u2060Centro'); // returns { line2: 'dpto 4', neighborhood: 'Centro', }
splitAddress2('US', 'Apt 2'); // returns null
```

## Contributing & Development

### Setup

You'll need [node](https://nodejs.org/en) and [pnpm](https://pnpm.io/installation) installed. We use pnpm for dependency management. First make sure both are installed.

```sh
node -v # ex: v20.13.1, Should be version 20 (or highter LTS)
pnpm -v # ex: 9.1.3, Should be version 9
```

Change directories to `lang/typescript`, you'll need to run all `pnpm` commands from that directory.

```sh
cd lang/typescript
```

To install dependencies run:

```sh
pnpm install
```

### Build

To run a build run:

```sh
pnpm build
```

This will use Rollup to generate `dist/`, which is our bundled JS package.

Verify the npm package is bundled correctly with [publint](https://publint.dev/). This should only need to be done when changing `rollup.config.ts` to modify the bundle output:

```sh
npx publint
```

### Other commands

```sh
# Run code linter (w/ eslint)
pnpm lint
# Run code formatting (w/ prettier)
pnpm format
# Run typechecker (w/ typescript/tsc)
pnpm typecheck
# Run test suite (w/ vitest)
pnpm test
# Run test watcher (w/ vitest)
pnpm test:watch
```

### Adding a changelog

To add a changelog entry use:

```sh
pnpm changeset
```

Changesets will create a new version after merging the [corresponding PR](https://github.com/Shopify/worldwide/pulls?q=is%3Apr+is%3Aopen+%22Version+Packages%22) that merges unreleased changesets and handles the version bump.
