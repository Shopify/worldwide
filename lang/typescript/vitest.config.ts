import {defineConfig} from 'vitest/config';

import rollupConfig from './rollup.config';

export default defineConfig({
  ...rollupConfig,
  test: {
    globals: true,
  },
});
