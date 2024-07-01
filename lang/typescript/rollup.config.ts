import path from 'path';
import {promises as fs} from 'fs';

import glob from 'fast-glob';
import yaml from 'js-yaml';
import typescript from '@rollup/plugin-typescript';
import {dts} from 'rollup-plugin-dts';

import {type ValidYamlType} from './src/types/yaml';
import {transformRegionYaml, validateRegionYaml} from './validate-region-yaml';

const projectRootDir = path.resolve(__dirname);

const REGIONS_IMPORT_ID = 'custom:regions';

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
          const configs: Record<string, any> = {};
          const yamlFilesGlobPath = path.resolve(
            projectRootDir,
            '../../db/data/regions/*.yml',
          );
          const regions: string[] = [];
          for (const ymlPath of await glob(yamlFilesGlobPath)) {
            const [fileName] = ymlPath.split('/').slice(-1);
            const data = yaml.load(
              (await fs.readFile(ymlPath)).toString(),
            ) as ValidYamlType;
            const countryCode = fileName.replace(/\.yml$/, '');

            const regionYaml = validateRegionYaml(fileName, data);

            regions.push(countryCode);
            if (regionYaml.combined_address_format) {
              configs[countryCode] = transformRegionYaml(regionYaml);
            }
          }
          return [
            `export const regions = [${regions.map((code) => `"${code}"`).join(',')}]`,
            `export const configs = ${JSON.stringify(configs, undefined, ' ')}`,
          ].join('; ');
        }

        return undefined;
      },
    },
    typescript({
      exclude: ['**/*.config.ts', '**/*.test.ts'],
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
