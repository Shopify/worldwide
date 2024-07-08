import {concatAddressField} from '../utils/address-fields';
import {getConcatenationRules, getRegionConfig} from '../utils/regions';
import type {Address} from '../types/address';

/**
 * Generate a concatenated address2 string based on the region of the given address
 * @param address Address containing `countryCode` and any number of other
 * optional address fields
 * @returns concatenated address string or null if invalid input was sent
 */
export function concatenateAddress2(address: Address): string | null {
  const config = getRegionConfig(address.countryCode);
  const fieldConcatenationRules = config
    ? getConcatenationRules(config, address, 'address2')
    : undefined;
  const containsAddress2ExtendedFields = fieldConcatenationRules?.some(
    (rule) => rule.key in address && address[rule.key] !== undefined,
  );

  if (fieldConcatenationRules && containsAddress2ExtendedFields) {
    return concatAddressField(fieldConcatenationRules, address);
  } else if (address.address2 !== undefined) {
    return address.address2;
  }

  return null;
}
