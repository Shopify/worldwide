import type {Address} from '../types/address';
import {
  RESERVED_DELIMITER,
  splitAddressField,
  regexSplitAddressField,
} from '../utils/address-fields';
import {
  getRegionConfig,
  getConcatenationRules,
  getAddress1Regex,
} from '../utils/regions';

/**
 * Splits an address string into sub-fields using a reserved delimiter.
 * Optionally provides a fallback mechanism to parse the address using
 * a regex when the delimiter is absent, which should be used with caution
 * as it may not provide accurate results.
 *
 * @param countryCode 2-letter country code string
 * @param address Combined address1 string
 * @param tryRegexFallback Flag to attempt regex parsing as a fallback mechanism
 * @returns Partial Address object containing parsed address fields or null if
 * the region does not define an extended address format
 */
export function splitAddress1(
  countryCode: string,
  address: string,
  tryRegexFallback = false,
): Partial<Address> | null {
  const config = getRegionConfig(countryCode);
  const fieldConcatenationRules = config
    ? getConcatenationRules(config, address, 'address1')
    : undefined;
  const address1Regex = config ? getAddress1Regex(config) : undefined;
  if (!fieldConcatenationRules) {
    return null;
  }

  if (address === '') {
    return {};
  }

  if (address.includes(RESERVED_DELIMITER)) {
    return splitAddressField(fieldConcatenationRules, address);
  }
  if (tryRegexFallback && address1Regex) {
    return regexSplitAddressField(
      fieldConcatenationRules,
      address1Regex,
      address,
    );
  }
  return {[fieldConcatenationRules[0].key]: address};
}
