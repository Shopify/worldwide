import type {FieldConcatenationRule} from '../types/region-yaml-config';
import type {Address} from '../types/address';

export const RESERVED_DELIMITER = '\u2060';

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

/**
 * Utility function that parses an address string based on a provided field
 * definition and set of values for those fields
 *
 * @param fieldDefinition Array of definitions of address sub-fields
 * @param concatenatedAddress Concatenated string of address field
 * @returns Partial Address object of fields parsed from string
 */
export function splitAddressField(
  fieldDefinition: FieldConcatenationRule[],
  concatenatedAddress: string,
): Partial<Address> {
  const values = concatenatedAddress.split(RESERVED_DELIMITER);

  const parsedAddressObject = values.reduce((obj, value, index) => {
    if (value !== '') {
      // Decorator is included as a suffix in the previous sub-field value,
      // so we need to strip it from the current field by looking ahead at the
      // next field's definition
      // Ex: streetNumber decorator is ","; ["Main,", "123"] => ["Main", "123"]
      const nextFieldDecorator = fieldDefinition[index + 1]?.decorator;
      const fieldValue =
        nextFieldDecorator &&
        nextFieldDecorator.length > 0 &&
        value.endsWith(nextFieldDecorator)
          ? value.substring(0, value.length - nextFieldDecorator.length)
          : value;
      return {
        ...obj,
        [fieldDefinition[index].key]: fieldValue,
      };
    }

    return obj;
  }, {});

  return parsedAddressObject;
}
