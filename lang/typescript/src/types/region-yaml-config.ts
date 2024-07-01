import type {Address} from './address';
import type {Script} from './script';

export interface FieldConcatenationRule {
  key: keyof Address;
  decorator?: string;
}
export type RegionScript = 'default' | Script;
export type ExtendableFieldType = keyof Pick<Address, 'address1' | 'address2'>;
export type CombinedAddressFormat = Record<RegionScript, FieldDefinitions>;
export type FieldDefinitions = Record<
  ExtendableFieldType,
  FieldConcatenationRule[]
>;
export type RegionYamlConfig = Record<string, any> & {
  /** Format definition for an extended address */
  combined_address_format?: CombinedAddressFormat;
};
