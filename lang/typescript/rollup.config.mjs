import path from 'path';

import typescript from '@rollup/plugin-typescript';
import yaml from '@rollup/plugin-yaml';
import alias from '@rollup/plugin-alias';

const projectRootDir = path.resolve(import.meta.dirname);

export default {
  input: 'src/index.ts',
  output: {
    dir: 'dist',
    format: 'cjs',
    sourcemap: true,
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
    typescript(),
  ],
};
