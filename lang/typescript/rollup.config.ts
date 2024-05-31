import path from 'path';

import typescript from '@rollup/plugin-typescript';
import yaml from '@rollup/plugin-yaml';
import alias from '@rollup/plugin-alias';
import dynamicImportVars from '@rollup/plugin-dynamic-import-vars';

const projectRootDir = path.resolve(__dirname);
const regionConfigFileRegex = /db\/data\/regions\/[a-zA-Z]{2}\.yml/;

export default {
  input: 'src/index.ts',
  output: {
    dir: 'dist',
    format: 'cjs',
    sourcemap: true,
  },
  plugins: [
    yaml({
      transform(data, filePath) {
        // console.log(
        //   filePath,
        //   regionConfigFileRegex.test(filePath) &&
        //     typeof data === 'object' &&
        //     data !== null &&
        //     'code' in data &&
        //     typeof data.code === 'string',
        // );
        // if (
        //   filePath ===
        //   '/home/spin/src/github.com/Shopify/worldwide/db/data/regions/AU.yml'
        // ) {
        //   console.log(data);
        // }
        // On the region config yamls, we only need combined_address_format
        // 1. Strip any data we don't need from the yaml before its bundled in
        //    the JS, which drastically reduces the bundle size
        // 2. Removes `zips_crossing_provinces` which is not being converted to
        //    JS properly by `@rollup/plugin-yaml`'s dependency `tosource`, it
        //    is converting all zip code strings used as keys to numbers
        if (
          regionConfigFileRegex.test(filePath) &&
          typeof data === 'object' &&
          data !== null &&
          'code' in data &&
          typeof data.code === 'string'
        ) {
          const {code, name, combined_address_format} = data;
          return {code, name, combined_address_format};
        }
      },
    }),
    alias({
      entries: [
        {find: '@', replacement: path.resolve(projectRootDir, 'src')},
        {
          find: '@data',
          replacement: path.resolve(projectRootDir, '../../db/data'),
        },
      ],
    }),
    dynamicImportVars({errorWhenNoFilesFound: true}),
    typescript(),
  ],
};
