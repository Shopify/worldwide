import {concatAddressField} from '@/utils';
import {CountryCode, getRegionConfig} from '@/regions';

// TODO: Decide on how flexible we want the inputs
interface Address2 {
  address2?: string;
  line2?: string;
  neighborhood?: string;
}

/**
 * Generate a concatenated address2 string based on the region specified by country code
 * @param countryCode 2-letter country code
 * @param address2 object containing full `address2` field or a combination of `line2` and `neighborhood` sub-fields
 * @returns concatenated address string or null if invalid input was sent
 */
export function generateAddress2(
  countryCode: CountryCode,
  address2: Address2,
): string | null {
  const config = getRegionConfig(countryCode);
  const address2AdditionalFields = config?.additional_address_fields?.address2;

  if (address2.address2 !== undefined) {
    // Always default to returning address2 if it's provided
    return address2.address2;
  } else if (address2AdditionalFields) {
    // concatAddressField utility works on arbitrary keys, just expects `Record<string, string>`
    const addressValues = {...address2};
    return concatAddressField(address2AdditionalFields, addressValues);
  }

  return null;
}
