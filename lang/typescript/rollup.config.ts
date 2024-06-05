import path from 'path';
import {promises as fs} from 'fs';

import glob from 'fast-glob';
import yaml from 'js-yaml';
import typescript from '@rollup/plugin-typescript';
import {dts} from 'rollup-plugin-dts';

import type {ValidYamlType} from './src/types/yaml';

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
    const {code, name, combined_address_format} = data;
    return {code, name, combined_address_format};
  }

  return undefined;
}

export const mainConfig = {
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

        return undefined;
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

        return undefined;
      },
    },
    typescript(),
  ],
};

const dtsConfig = {
  // path to your declaration files root
  input: './dist/dts/src/index.d.ts',
  output: [{file: 'dist/index.d.ts', format: 'cjs'}],
  plugins: [dts()],
};

const config = [mainConfig, dtsConfig];
export default config;
