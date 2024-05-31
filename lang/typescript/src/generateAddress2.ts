import {concatAddressField} from '@/utils';
import {CountryCode, getRegionConfig} from '@/regions';

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
export async function generateAddress2(
  countryCode: CountryCode,
  address2: Address2,
): Promise<string | null> {
  const config = await getRegionConfig(countryCode);
  const address2CombinedFormat = config?.combined_address_format?.address2;
  const address2NotEmpty =
    Object.values(address2).filter((value) => value !== undefined).length > 0;

  if (address2.address2 !== undefined) {
    // Always default to returning address2 if it's provided
    return address2.address2;
  } else if (address2CombinedFormat && address2NotEmpty) {
    // concatAddressField utility works on arbitrary keys, just expects `Record<string, string>`
    const addressValues = {...address2};
    return concatAddressField(address2CombinedFormat, addressValues);
  }

  return null;
}
