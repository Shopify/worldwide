import {Address} from '../types/address';
import {splitAddressField} from '../utils/address-fields';
import {getRegionConfig} from '../utils/regions';

/**
 * Parse a concatenated address1 string based on the region specified by
 * country code
 * @param countryCode 2-letter country code string
 * @param concatenatedAddress Combined address1 string
 * @returns Partial Address object containing parsed address fields or null if
 * the region does not define an extended address format
 */
export function splitAddress1(
  countryCode: string,
  concatenatedAddress: string,
): Partial<Address> | null {
  const config = getRegionConfig(countryCode);
  const address1CombinedFormat = config?.combined_address_format?.address1;

  if (address1CombinedFormat) {
    return splitAddressField(address1CombinedFormat, concatenatedAddress);
  }

  return null;
}
