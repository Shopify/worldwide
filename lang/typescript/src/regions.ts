import regions from 'custom:regions';

import {ValidYamlType} from './types/yaml';

// TODO: Strictly type this to only available country codes
export type CountryCode = string;
export interface AdditionalAddressField {
  key: string;
  decorator?: string;
}
export type CombinedAddressFormat = Record<string, AdditionalAddressField[]>;
export type RegionYamlConfig = Record<string, any> & {
  /** Two-letter country code */
  code: string;
  /** Full region name */
  name: string;
  // eslint-disable-next-line @typescript-eslint/naming-convention
  combined_address_format?: CombinedAddressFormat;
};

/**
 * Type-guard to ensure we're operating on the right yaml data.
 *
 * combined_address_format is optional, so check against `code` and
 * `name` which should be on all region configs.
 */
function isRegionYamlConfig(
  yamlConfig: ValidYamlType,
): yamlConfig is RegionYamlConfig {
  return (
    yamlConfig !== null &&
    typeof yamlConfig === 'object' &&
    'code' in yamlConfig &&
    typeof yamlConfig.code === 'string' &&
    'name' in yamlConfig &&
    typeof yamlConfig.name === 'string'
  );
}

export function getRegionConfig(
  countryCode: CountryCode,
): RegionYamlConfig | null {
  const regionConfig = regions[countryCode];
  if (regionConfig && isRegionYamlConfig(regionConfig)) {
    return regionConfig;
  }

  return null;
}
