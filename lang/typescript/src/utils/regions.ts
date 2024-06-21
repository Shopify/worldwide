import regions from 'custom:regions';

import {ValidYamlType, isYamlObject} from '../types/yaml';
import {Address} from '../types/address';

import {Script, identifyScripts, stringExclusivelyUsesScript} from './script';

export interface FieldConcatenationRule {
  key: keyof Address;
  decorator?: string;
}

type RegionScript = 'default' | Script;
export type CombinedAddressFormat = Record<RegionScript, FieldDefinitions>;
export type FieldDefinitions = Record<keyof Address, FieldConcatenationRule[]>;
export type RegionYamlConfig = Record<string, any> & {
  /** Two-letter country code */
  code: string;
  /** Format definition for an extended address */
  combined_address_format?: CombinedAddressFormat;
};

/**
 * Type-guard to ensure we're operating on the right yaml data.
 *
 * combined_address_format is optional, so check against `code` which should be
 * on all region configs.
 */
function isRegionYamlConfig(
  yamlConfig: ValidYamlType,
): yamlConfig is RegionYamlConfig {
  return (
    isYamlObject(yamlConfig) &&
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

/**
 * Checks if one or more address field contains the character set of a given
 * script type and only that type.
 *
 * @param fieldDefinition Array of definitions of address sub-fields
 * @param address Partial address object
 * @param script Script to detect within the value string
 * @returns true if any characters of the specified script is found in the
 * address and no other scripts match
 */
export function addressExclusivelyUsesScript(
  fieldDefinition: FieldConcatenationRule[],
  address: Partial<Address>,
  script: Script,
): boolean {
  const scriptsFound = new Set(
    fieldDefinition
      .flatMap((field) => {
        const value = address[field.key];
        return value ? identifyScripts(value) : [];
      })
      .flat(),
  );
  return scriptsFound.size === 1 && scriptsFound.has(script);
}

/**
 * Determine the extended address rules to use for a given field based on the
 * region's config as well as analyzing the address object itself for matching
 * character sets for language-specific overrides.
 */
export function getConcatenationRules(
  config: RegionYamlConfig,
  address: Address | string,
  extendedField: keyof Address,
): FieldConcatenationRule[] | undefined {
  if (config.combined_address_format === undefined) {
    return undefined;
  }

  const combinedAddressFormat = config.combined_address_format;
  const script: RegionScript = 'default';
  const configScripts = Object.keys(combinedAddressFormat).filter(
    (key) => key !== 'default',
  );
  const concatenationRules = combinedAddressFormat[script][extendedField];
  const matchingScripts = configScripts.filter((configScript) => {
    const fieldDefinition =
      config.combined_address_format?.[configScript as RegionScript]?.[
        extendedField
      ];
    if (fieldDefinition) {
      if (typeof address === 'string') {
        return stringExclusivelyUsesScript(address, configScript as Script);
      } else {
        return addressExclusivelyUsesScript(
          fieldDefinition,
          address,
          configScript as Script,
        );
      }
    }
    return false;
  });

  if (matchingScripts.length === 1) {
    return combinedAddressFormat[matchingScripts[0] as RegionScript][
      extendedField
    ];
  }
  return concatenationRules;
}
