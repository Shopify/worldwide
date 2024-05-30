import {concatAddressField} from '@/utils';
import {CountryCode, getRegionConfig} from '@/regions';

// TODO: Decide on how flexible we want the inputs
interface Address1 {
  address1?: string;
  streetName?: string;
  streetNumber?: string;
}

/**
 * Generate a concatenated address1 string based on the region specified by country code
 * @param countryCode 2-letter country code
 * @param address1 object containing full `address1` field or a combination of `streetName` and `streetNumber` sub-fields
 * @returns concatenated address string or null if invalid input was sent
 */
export function generateAddress1(
  countryCode: CountryCode,
  address1: Address1,
): string | null {
  const config = getRegionConfig(countryCode);
  const address1AdditionalFields = config?.combined_address_format?.address1;

  if (address1.address1 !== undefined) {
    // Always default to returning address1 if it's provided
    return address1.address1;
  } else if (address1AdditionalFields) {
    // concatAddressField utility works on arbitrary keys, just expects `Record<string, string>`
    const addressValues = {...address1};
    return concatAddressField(address1AdditionalFields, addressValues);
  }

  return null;
}
