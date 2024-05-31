import path from 'path';
import glob from 'fast-glob';
import {promises as fsAsync} from 'fs';
import YAML from 'js-yaml';

import typescript from '@rollup/plugin-typescript';
import yaml from '@rollup/plugin-yaml';
import alias from '@rollup/plugin-alias';

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
    {
      name: 'custom:regions',
      resolveId: (id: string) => {
        if (id === 'custom:regions') {
          return id;
        }
      },
      load: async (id: string) => {
        if (id === 'custom:regions') {
          const regions: Record<string, any> = {};
          for (const ymlPath of await glob(
            path.resolve(projectRootDir, '../../db/data/regions/*.yml'),
          )) {
            const [fname] = ymlPath.split('/').slice(-1);
            const yamlData = YAML.load(
              (await fsAsync.readFile(ymlPath)).toString(),
            );
            if (
              typeof yamlData === 'object' &&
              yamlData !== null &&
              'code' in yamlData &&
              typeof yamlData.code === 'string'
            ) {
              const {code, name, combined_address_format} = yamlData as Record<
                string,
                any
              >;
              regions[fname.replace(/\.yml$/, '')] = {
                code,
                name,
                combined_address_format,
              };
            }
          }
          return `export default ${JSON.stringify(regions, undefined, '\t')}`;
        }
      },
    },
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
    typescript(),
  ],
};
