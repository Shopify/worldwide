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
  const [firstField, ...rest] = concatenatedAddress.split(RESERVED_DELIMITER);
  const secondField = rest.join(RESERVED_DELIMITER);
  const values = [firstField, secondField];

  const parsedAddressObject = fieldDefinition.reduce((obj, field, index) => {
    if (values[index]) {
      // Decorator is included as a suffix in the previous sub-field value,
      // so we need to strip it from the current field by looking ahead at the
      // next field's definition
      // Ex: streetNumber decorator is ","; ["Main,", "123"] => ["Main", "123"]
      const nextFieldDecorator = fieldDefinition[index + 1]?.decorator;
      const fieldValue =
        nextFieldDecorator &&
        nextFieldDecorator.length > 0 &&
        values[index].endsWith(nextFieldDecorator)
          ? values[index].substring(
              0,
              values[index].length - nextFieldDecorator.length,
            )
          : values[index];
      return {
        ...obj,
        [field.key]: fieldValue,
      };
    }

    return obj;
  }, {});

  return parsedAddressObject;
}

/**
 * Utility function that attempts to parse an address string based on a regex
 *
 * @param fieldDefinition Array of definitions of address sub-fields
 * @param regexPatterns Regex patterns for parsing sub-fields from an address string
 * @param address Address string to parse
 * @returns Partial Address object of fields parsed from string
 */
export function regexSplitAddressField(
  fieldDefinition: FieldConcatenationRule[],
  regexPatterns: RegExp[],
  address: string,
): Partial<Address> {
  for (const regex of regexPatterns) {
    const match = address.match(regex);
    if (match?.groups) {
      // Return the first group that matches
      return match.groups;
    }
  }
  return {[fieldDefinition[0].key]: address};
}
