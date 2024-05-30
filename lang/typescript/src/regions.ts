import BR from '@data/regions/BR.yml';
import CL from '@data/regions/CL.yml';
import PH from '@data/regions/PH.yml';
import US from '@data/regions/US.yml';
import VN from '@data/regions/VN.yml';
import TH from '@data/regions/TH.yml';

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

// TODO: Use https://github.com/rollup/plugins/tree/master/packages/dynamic-import-vars
export function getRegionConfig(
  countryCode: CountryCode,
): RegionYamlConfig | null {
  switch (countryCode) {
    case 'BR':
      return isRegionYamlConfig(BR) ? BR : null;
    case 'CL':
      return isRegionYamlConfig(CL) ? CL : null;
    case 'PH':
      return isRegionYamlConfig(PH) ? PH : null;
    case 'TH':
      return isRegionYamlConfig(TH) ? TH : null;
    case 'US':
      return isRegionYamlConfig(US) ? US : null;
    case 'VN':
      return isRegionYamlConfig(VN) ? VN : null;
    default:
      return null;
  }
}
