// TODO: Include all available country codes
export type CountryCode = 'BR' | 'CL' | 'PH' | 'US' | 'VN' | 'TH';
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

function isRegionYamlConfig(
  yamlConfig: Record<string, any>,
): yamlConfig is RegionYamlConfig {
  return 'code' in yamlConfig && typeof yamlConfig.code === 'string';
}

function importRegionYaml(countryCode: string) {
  // import TH from '@data/regions/TH.yml';
  return import(`../../../db/data/regions/${countryCode}.yml`);
}

export async function getRegionConfig(
  countryCode: CountryCode,
): Promise<RegionYamlConfig | null> {
  const regionYaml = await importRegionYaml(countryCode);
  return isRegionYamlConfig(regionYaml) ? regionYaml : null;
}
