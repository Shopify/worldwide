declare module 'custom:regions' {
  // Defining the types within the source code of the package itself and not
  // using the zod infered types to avoid introducing zod as a dependency
  import type {RegionYamlConfig} from './region-yaml-config';

  const regions: string[];
  export const regions;

  const configs: Record<string, RegionYamlConfig | undefined>;
  export const configs;
}
