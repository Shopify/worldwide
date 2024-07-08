import path from 'path';
import {promises as fs} from 'fs';

import glob from 'fast-glob';
import yaml from 'js-yaml';

import type {ValidYamlType} from './yaml';
import {
  type MinimalRegionYaml,
  transformRegionYaml,
  validateRegionYaml,
} from './utils';

const REGIONS_IMPORT_ID = 'custom:regions';

interface RegionsYamlOptions {
  directory: string;
}
export function regionsYaml({directory}: RegionsYamlOptions) {
  return {
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
        const configs: Record<string, MinimalRegionYaml> = {};
        const regions: string[] = [];

        const yamlFilesGlobPath = path.resolve(directory, '*.yml');
        for (const ymlPath of await glob(yamlFilesGlobPath)) {
          const [fileName] = ymlPath.split('/').slice(-1);
          const data = yaml.load(
            (await fs.readFile(ymlPath)).toString(),
          ) as ValidYamlType;
          const countryCode = fileName.replace(/\.yml$/, '');
          const regionYaml = validateRegionYaml(fileName, data);

          // Aggregate the data we need to produce the virtual rollup module
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
  };
}
