import {regions, configs} from 'custom:regions';

import type {Script} from '../types/script';
import type {Address} from '../types/address';
import type {
  ExtendableFieldType,
  FieldConcatenationRule,
  RegionScript,
  RegionYamlConfig,
} from '../types/region-yaml-config';

import {identifyScripts, stringExclusivelyUsesScript} from './script';

/**
 * Get the region config for a specified country code
 * @param countryCode 2-letter country code string
 * @returns RegionYamlConfig config object, or null if config for region not
 * found
 */
export function getRegionConfig(countryCode: string): RegionYamlConfig | null {
  const regionConfig = configs[countryCode];
  if (regionConfig) {
    return regionConfig;
  } else if (regions.includes(countryCode)) {
    return {};
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
  extendedField: ExtendableFieldType,
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

/**
 * The regex patterns to use for splitting address1 strings that do not
 * contain a reserved delimiter
 */
export function getAddress1Regex(config: RegionYamlConfig): RegExp[] {
  if (config.address1_regex === undefined) {
    return [];
  }

  return config.address1_regex.map((pattern) => new RegExp(pattern, 'i'));
}
