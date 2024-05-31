declare module 'custom:regions' {
  import {ValidYamlType} from './yaml';

  const data: Record<string, ValidYamlType>;
  export default data;
}
