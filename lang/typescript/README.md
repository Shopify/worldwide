# Worldwide - Typescript

🚧 Still in development -- not ready for use yet 🚧

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
