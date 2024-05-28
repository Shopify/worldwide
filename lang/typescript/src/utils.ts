import {AdditionalAddressField} from './regions';

export const RESERVED_DELIMETER = '\xA0';

export type AddressValues = Record<string, string | undefined>;

/**
 * Utility function that concatenates address fields based on a provided field
 * definition and set of values for those fields
 *
 * @param fieldDefinition Array of definitions of address sub-fields
 * @param values Object with mapping fieldName to their values
 * @returns Concatenated address string
 */
export function concatAddressField(
  fieldDefinition: AdditionalAddressField[],
  values: AddressValues,
): string {
  return fieldDefinition.reduce((concatenatedAddress, field, index) => {
    if (values[field.key]) {
      // Don't include decorator at the start of the string
      const decorator =
        field.decorator && concatenatedAddress.length > 0
          ? field.decorator
          : '';
      // Don't include delimeter if only first field is present
      const delimeter = index === 0 ? '' : RESERVED_DELIMETER;
      return `${concatenatedAddress}${decorator}${delimeter}${values[field.key]}`;
    }

    return concatenatedAddress;
  }, '');
}
