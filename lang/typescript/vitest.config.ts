import {defineConfig} from 'vitest/config';

import {mainConfig} from './rollup.config';

export default defineConfig({
  ...mainConfig,
  test: {
    globals: true,
  },
});
