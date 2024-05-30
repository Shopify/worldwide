import path from 'path';

import {defineConfig} from 'vitest/config';
import yaml from '@rollup/plugin-yaml';
import alias from '@rollup/plugin-alias';

const projectRootDir = path.resolve(__dirname);
const regionConfigFileRegex = /db\/data\/regions\/[a-zA-Z]{2}\.yml/;

export default defineConfig({
  test: {
    globals: true,
  },
  // TODO: Merge config with rollup.config.mjs
  plugins: [
    yaml({
      transform(data, filePath) {
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
          // eslint-disable-next-line @typescript-eslint/naming-convention
          const {code, name, combined_address_format} = data;
          // eslint-disable-next-line @typescript-eslint/naming-convention
          return {code, name, combined_address_format};
        }

        return undefined;
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
  ],
});
