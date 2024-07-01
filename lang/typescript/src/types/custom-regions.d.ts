declare module 'custom:regions' {
  import {RegionYamlConfig} from 'src/utils/regions';

  const regions: string[];
  export const regions;

  const configs: Record<string, RegionYamlConfig | undefined>;
  export const configs;
}
