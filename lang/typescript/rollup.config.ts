import path from 'path';
import glob from 'fast-glob';
import {promises as fs} from 'fs';
import yaml from 'js-yaml';

import typescript from '@rollup/plugin-typescript';
import alias from '@rollup/plugin-alias';

import type {ValidYamlType} from '@/types/yaml';

const projectRootDir = path.resolve(__dirname);

const REGIONS_IMPORT_ID = 'custom:regions';

/**
 * Strip any data we don't need from the yaml before its bundled in
 * the JS, which drastically reduces the bundle size
 */
function transformRegionYaml(data: ValidYamlType) {
  if (
    typeof data === 'object' &&
    data !== null &&
    'code' in data &&
    typeof data.code === 'string'
  ) {
    const {code, name, combined_address_format, zips_crossing_provinces} = data;
    return {code, name, combined_address_format, zips_crossing_provinces};
  }
}

export default {
  input: 'src/index.ts',
  output: {
    dir: 'dist',
    format: 'cjs',
    sourcemap: true,
  },
  plugins: [
    {
      // Custom yaml parsing plugin to load all region yamls as one object
      // with the country code as the keys for each config
      name: 'region-yaml',
      resolveId: (id: string) => {
        if (id === REGIONS_IMPORT_ID) {
          return id;
        }
      },
      load: async (id: string) => {
        if (id === REGIONS_IMPORT_ID) {
          const regions: Record<string, any> = {};
          const yamlFilesGlobPath = path.resolve(
            projectRootDir,
            '../../db/data/regions/*.yml',
          );
          for (const ymlPath of await glob(yamlFilesGlobPath)) {
            const [fileName] = ymlPath.split('/').slice(-1);
            const data = yaml.load(
              (await fs.readFile(ymlPath)).toString(),
            ) as ValidYamlType;
            const countryCode = fileName.replace(/\.yml$/, '');
            regions[countryCode] = transformRegionYaml(data);
          }
          return `export default ${JSON.stringify(regions, undefined, '  ')}`;
        }
      },
    },
    alias({
      entries: [{find: '@', replacement: path.resolve(projectRootDir, 'src')}],
    }),
    typescript(),
  ],
};
