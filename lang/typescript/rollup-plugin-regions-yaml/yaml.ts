/**
 * Typescript type to match possible yaml structure from js-yaml
 *
 * @see https://github.com/rollup/plugins/blob/master/packages/yaml/types/index.d.ts
 */
export type ValidYamlType =
  | number
  | string
  | boolean
  | null
  | {[key: string]: ValidYamlType}
  | ValidYamlType[];
