import {concatAddressField} from '../utils/address-fields';
import {getRegionConfig} from '../utils/regions';
import {Address} from '../types/address';

/**
 * Generate a concatenated address2 string based on the region of the given address
 * @param address Address containing `countryCode` and any number of other
 * optional address fields
 * @returns concatenated address string or null if invalid input was sent
 */
export function concatenateAddress2(address: Address): string | null {
  const config = getRegionConfig(address.countryCode);
  const address2CombinedFormat = config?.combined_address_format?.address2;
  const containsAddress2ExtendedFields = address2CombinedFormat?.some(
    (rule) => rule.key in address && address[rule.key] !== undefined,
  );

  if (address2CombinedFormat && containsAddress2ExtendedFields) {
    return concatAddressField(address2CombinedFormat, address);
  } else if (address.address2 !== undefined) {
    return address.address2;
  }

  return null;
}
