import type {SplitAddress} from 'src/types/address';

import {splitAddressField} from '../utils/address-fields';
import {getRegionConfig, getConcatenationRules} from '../utils/regions';

/**
 * Parse a concatenated address2 string based on the region specified by
 * country code
 * @param countryCode 2-letter country code string
 * @param concatenatedAddress Combined address2 string
 * @returns Partial Address object containing parsed address fields or null if
 * the region does not define an extended address format
 */
export function splitAddress2(
  countryCode: string,
  concatenatedAddress: string,
): SplitAddress | null {
  const config = getRegionConfig(countryCode);
  const fieldConcatenationRules = config
    ? getConcatenationRules(config, concatenatedAddress, 'address2')
    : undefined;
  if (fieldConcatenationRules) {
    return splitAddressField(fieldConcatenationRules, concatenatedAddress);
  }

  return null;
}
