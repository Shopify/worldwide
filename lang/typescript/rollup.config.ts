import path from 'path';

import typescript from '@rollup/plugin-typescript';
import {dts} from 'rollup-plugin-dts';

import {regionsYaml} from './rollup-plugin-regions-yaml';

const projectRootDir = path.resolve(__dirname);

export const mainConfig = {
  input: 'src/index.ts',
  output: [
    {
      file: 'dist/index.mjs',
      format: 'esm',
      sourcemap: true,
    },
    {
      file: 'dist/index.cjs',
      format: 'cjs',
      sourcemap: true,
    },
  ],
  plugins: [
    regionsYaml({
      directory: path.resolve(projectRootDir, '../../db/data/regions'),
    }),
    typescript({
      exclude: [
        '**/*.config.ts',
        '**/*.test.ts',
        'rollup-plugin-regions-yaml/**/*.ts',
      ],
    }),
  ],
};

const dtsConfig = {
  // path to your declaration files root
  input: './dist/dts/src/index.d.ts',
  output: [
    {file: 'dist/index.d.ts', format: 'esm'},
    {file: 'dist/index.d.cts', format: 'cjs'},
  ],
  plugins: [dts()],
};

const config = [mainConfig, dtsConfig];
export default config;
