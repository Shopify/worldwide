import {concatAddressField} from '../utils/address-fields';
import {getRegionConfig} from '../utils/regions';
import {Address} from '../types/address';

/**
 * Generate a concatenated address1 string based on the region of the given address
 * @param address Address containing `countryCode` and any number of other
 * optional address fields
 * @returns concatenated address string or null if invalid input was sent
 */
export function concatenateAddress1(address: Address): string | null {
  const config = getRegionConfig(address.countryCode);
  const address1CombinedFormat = config?.combined_address_format?.address1;
  const containsAddress1ExtendedFields = address1CombinedFormat?.some(
    (rule) => rule.key in address && address[rule.key] !== undefined,
  );

  if (address1CombinedFormat && containsAddress1ExtendedFields) {
    return concatAddressField(address1CombinedFormat, address);
  } else if (address.address1 !== undefined) {
    return address.address1;
  }

  return null;
}
