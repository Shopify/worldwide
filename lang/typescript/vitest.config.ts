import path from 'path';

import {defineConfig} from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
  },
  resolve: {
    alias: {
      /* eslint-disable @typescript-eslint/naming-convention */
      '@': path.resolve(__dirname, './src'),
      '@data': path.resolve(__dirname, '../../db/data'),
      /* eslint-enable @typescript-eslint/naming-convention */
    },
  },
});
