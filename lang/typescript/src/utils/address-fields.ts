import {Address} from '../types/address';

import {FieldConcatenationRule} from './regions';

export const RESERVED_DELIMITER = '\xA0';

/**
 * Utility function that concatenates address fields based on a provided field
 * definition and set of values for those fields
 *
 * @param fieldDefinition Array of definitions of address sub-fields
 * @param values Object with mapping fieldName to their values
 * @returns Concatenated address string
 */
export function concatAddressField(
  fieldDefinition: FieldConcatenationRule[],
  address: Partial<Address>,
): string {
  return fieldDefinition.reduce((concatenatedAddress, field, index) => {
    if (address[field.key]) {
      // Don't include decorator at the start of the string
      const decorator =
        field.decorator && concatenatedAddress.length > 0
          ? field.decorator
          : '';

      // Don't include delimiter if only first field is present
      const delimiter = index === 0 ? '' : RESERVED_DELIMITER;

      return `${concatenatedAddress}${decorator}${delimiter}${address[field.key]}`;
    }

    return concatenatedAddress;
  }, '');
}
