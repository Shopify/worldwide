import path from 'path';

import {defineConfig} from 'vitest/config';
import yaml from '@rollup/plugin-yaml';
import alias from '@rollup/plugin-alias';

const projectRootDir = path.resolve(__dirname);

export default defineConfig({
  test: {
    globals: true,
  },
  plugins: [
    yaml(),
    alias({
      entries: [
        {find: '@', replacement: path.resolve(projectRootDir, 'src')},
        {
          find: '@data',
          replacement: path.resolve(projectRootDir, '../../db/data'),
        },
      ],
    }),
  ],
});
