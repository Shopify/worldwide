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

export function isYamlObject(
  yamlData: ValidYamlType,
): yamlData is Record<string, ValidYamlType> {
  return (
    yamlData !== null &&
    typeof yamlData === 'object' &&
    !Array.isArray(yamlData)
  );
}

export function isYamlArray(
  yamlData: ValidYamlType,
): yamlData is ValidYamlType[] {
  return (
    yamlData !== null && typeof yamlData === 'object' && Array.isArray(yamlData)
  );
}
