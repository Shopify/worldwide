# Worldwide - Typescript

🚧 Still in development -- not ready for use yet 🚧

## Usage

```ts
import {generateAddress1, generateAddress2} from '@shopify/worldwide';

// Generate Address1
generateAddress1('BR', {
  streetName: 'Main',
  streetNumber: '123',
}); // returns '123,\u00A0Main'
generateAddress1('US', {
  address1: '123 Main',
}); // returns '123 Main'

// Generate Address2
generateAddress1('BR', {
  line2: '#2',
  neighborhood: 'Centro',
}); // returns '#2,\u00A0Centro'
generateAddress1('US', {
  address1: 'Apt 2',
}); // returns 'Apt 2'
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
