import regions from 'custom:regions';

import {ValidYamlType} from '../types/yaml';
import {Address} from '../types/address';

export interface FieldConcatenationRule {
  key: keyof Address;
  decorator?: string;
}
export type CombinedAddressFormat = Record<string, FieldConcatenationRule[]>;
export type RegionYamlConfig = Record<string, any> & {
  /** Two-letter country code */
  code: string;
  /** Format definition for an extended address */
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
    typeof yamlConfig.code === 'string'
  );
}

/**
 * Get the region config for a specified country code
 * @param countryCode 2-letter country code string
 * @returns RegionYamlConfig config object, or null if config for region not
 * found
 */
export function getRegionConfig(countryCode: string): RegionYamlConfig | null {
  const regionConfig = regions[countryCode];
  if (regionConfig && isRegionYamlConfig(regionConfig)) {
    return regionConfig;
  }

  return null;
}
