import BR from '@data/regions/BR.yml';
import CL from '@data/regions/CL.yml';
// import US from '@data/regions/US.yml';

// TODO: Include all available country codes
export type CountryCode = 'BR' | 'CL' | 'US';
export interface AdditionalAddressField {
  key: string;
  required: boolean;
  decorator?: string;
}
export type AdditionalAddressFields = Record<string, AdditionalAddressField[]>;
export type RegionYamlConfig = Record<string, any> & {
  code: string;
  // eslint-disable-next-line @typescript-eslint/naming-convention
  additional_address_fields?: AdditionalAddressFields;
};

function isRegionYamlConfig(
  yamlConfig: Record<string, any>,
): yamlConfig is RegionYamlConfig {
  return 'code' in yamlConfig && typeof yamlConfig.code === 'string';
}

// TODO: Use https://github.com/rollup/plugins/tree/master/packages/dynamic-import-vars
export function getRegionConfig(
  countryCode: CountryCode,
): RegionYamlConfig | null {
  switch (countryCode) {
    case 'BR':
      return isRegionYamlConfig(BR) ? BR : null;
    case 'CL':
      return isRegionYamlConfig(CL) ? CL : null;
    // TODO: Resolve yaml parsing issue with US data
    case 'US':
      return {code: 'US'};
    default:
      return null;
  }
}
