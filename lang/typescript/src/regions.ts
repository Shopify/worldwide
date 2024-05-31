import regions from 'custom:regions';

// TODO: Strictly type this to only available country codes
export type CountryCode = string;
export interface AdditionalAddressField {
  key: string;
  decorator?: string;
}
export type CombinedAddressFormat = Record<string, AdditionalAddressField[]>;
export type RegionYamlConfig = Record<string, any> & {
  code: string;
  name: string;
  // eslint-disable-next-line @typescript-eslint/naming-convention
  combined_address_format?: CombinedAddressFormat;
};

// TODO: Use ValidYamlConfig or similar type instead of Record<string, any>
function isRegionYamlConfig(
  yamlConfig: Record<string, any>,
): yamlConfig is RegionYamlConfig {
  return 'code' in yamlConfig && typeof yamlConfig.code === 'string';
}

export function getRegionConfig(
  countryCode: CountryCode,
): RegionYamlConfig | null {
  const regionConfig = regions[countryCode];
  if (isRegionYamlConfig(regionConfig)) {
    return regionConfig;
  }

  return null;
}
