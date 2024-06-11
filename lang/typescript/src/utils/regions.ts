import regions from 'custom:regions';

import {ValidYamlType, isYamlArray, isYamlObject} from '../types/yaml';
import {Address} from '../types/address';

import {Script, stringUsesScript} from './script';

export const langScripts: Record<string, Script> = {
  // eslint-disable-next-line @typescript-eslint/naming-convention
  'zh-TW': 'Han',
};

export interface FieldConcatenationRule {
  key: keyof Address;
  decorator?: string;
  delimiter?: string;
}

// TODO: Find a more elegant way to type 1 level of circular references
export type LanguageSpecificAddressFormat = Record<
  string,
  FieldConcatenationRule[]
>;
export type CombinedAddressFormat = Record<
  string,
  FieldConcatenationRule[] | LanguageSpecificAddressFormat
>;
export type RegionYamlConfig = Record<string, any> & {
  /** Two-letter country code */
  code: string;
  /** Format definition for an extended address */
  combined_address_format?: CombinedAddressFormat;
};

function isLanguageSpecificAddressFormat(
  format: FieldConcatenationRule[] | LanguageSpecificAddressFormat,
): format is LanguageSpecificAddressFormat {
  return !Array.isArray(format);
}

function isFieldConcatenationRuleArray(
  rules: FieldConcatenationRule[] | LanguageSpecificAddressFormat,
): rules is FieldConcatenationRule[] {
  return Array.isArray(rules);
}

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
    isYamlObject(yamlConfig) &&
    'code' in yamlConfig &&
    typeof yamlConfig.code === 'string' &&
    (!('combined_address_format' in yamlConfig) ||
      isCombinedAddressFormat(yamlConfig.combined_address_format as any))
  );
}

// TODO: Figure out a cleaner way to do this or ditch it
function isCombinedAddressFormat(
  yamlProperty: Record<string, any>,
): yamlProperty is CombinedAddressFormat {
  return (
    isYamlObject(yamlProperty) &&
    Object.entries(yamlProperty).every(
      ([key, value]) =>
        (key === 'address1' &&
          isYamlArray(value) &&
          isYamlObject(value[0]) &&
          'key' in value[0] &&
          typeof value[0].key === 'string') ||
        (key === 'address2' &&
          isYamlArray(value) &&
          isYamlObject(value[0]) &&
          'key' in value[0] &&
          typeof value[0].key === 'string') ||
        key === 'zh-TW',
    )
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

export function addressUsesScript(
  fieldDefinition: FieldConcatenationRule[],
  address: Partial<Address>,
  script: Script,
): boolean {
  const charsetFound = fieldDefinition.reduce((matchesCharset, field) => {
    if (address[field.key]) {
      const value = address[field.key];
      if (value) {
        return matchesCharset || stringUsesScript(value, script);
      }
    }

    return matchesCharset;
  }, false);

  return charsetFound;
}

export function getConcatenationRules(
  config: RegionYamlConfig,
  address: Address,
  extendedField: keyof Address,
): FieldConcatenationRule[] | undefined {
  if (config.combined_address_format === undefined) {
    return undefined;
  }

  const combinedAddressFormat = config.combined_address_format;
  let concatenationRules = combinedAddressFormat[extendedField];

  if (!isFieldConcatenationRuleArray(concatenationRules)) {
    throw Error(
      `combined_address_format.${extendedField} must be an array. It is: ${JSON.stringify(concatenationRules, null, 2)}`,
    );
  }

  // Check for a valid language override and use the first one found
  const langOverrides = Object.keys(langScripts).filter(
    (lang) => lang in combinedAddressFormat,
  );
  for (const lang of langOverrides) {
    const overrideConfig = config.combined_address_format[lang];
    if (
      isLanguageSpecificAddressFormat(overrideConfig) &&
      isFieldConcatenationRuleArray(overrideConfig[extendedField]) &&
      addressUsesScript(
        overrideConfig[extendedField],
        address,
        langScripts[lang],
      )
    ) {
      concatenationRules = overrideConfig[extendedField];
      break;
    }
  }

  return concatenationRules;
}

export function getSplitRules(
  config: RegionYamlConfig,
  concatenatedAddress: string,
  extendedField: keyof Address,
): FieldConcatenationRule[] | undefined {
  if (config.combined_address_format === undefined) {
    return undefined;
  }

  const combinedAddressFormat = config.combined_address_format;
  let concatenationRules = combinedAddressFormat[extendedField];

  if (!isFieldConcatenationRuleArray(concatenationRules)) {
    throw Error(
      `combined_address_format.${extendedField} must be an array. It is: ${JSON.stringify(concatenationRules, null, 2)}`,
    );
  }

  // Check for a valid language override and use the first one found
  const langOverrides = Object.keys(langScripts).filter(
    (lang) => lang in combinedAddressFormat,
  );
  for (const lang of langOverrides) {
    const overrideConfig = config.combined_address_format[lang];
    if (
      isLanguageSpecificAddressFormat(overrideConfig) &&
      isFieldConcatenationRuleArray(overrideConfig[extendedField]) &&
      stringUsesScript(concatenatedAddress, langScripts[lang])
    ) {
      concatenationRules = overrideConfig[extendedField];
      break;
    }
  }

  return concatenationRules;
}
