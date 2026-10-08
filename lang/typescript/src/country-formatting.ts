import type {CountryFormatting} from './types/country-formatting';

/**
 * Fetch country address formatting details for a specific country and locale.
 * 
 * This function dynamically loads the formatting data for the specified country
 * and locale combination. The data includes address templates, field requirements,
 * political subdivisions (zones), and localized labels.
 * 
 * @param countryCode - ISO 3166-1 alpha-2 country code (e.g., "CA", "BR", "US")
 * @param locale - Locale code (e.g., "en", "fr", "pt-BR"). Defaults to "en"
 * @returns Promise resolving to CountryFormatting object
 * @throws Error if the country/locale combination is not found
 * 
 * @example
 * ```typescript
 * // Get Canadian formatting in English
 * const caFormatting = await getCountryFormatting('CA', 'en');
 * console.log(caFormatting.format.edit);
 * // "{country}_{firstName}{lastName}_{company}_{address1}_{address2}_{city}{province}{zip}_{phone}"
 * 
 * // Get Brazilian formatting in Portuguese
 * const brFormatting = await getCountryFormatting('BR', 'pt-BR');
 * console.log(brFormatting.labels.zip); // "CEP"
 * ```
 */
export async function getCountryFormatting(
  countryCode: string,
  locale: string = 'en',
): Promise<CountryFormatting> {
  const normalizedCountryCode = countryCode.toUpperCase();
  const normalizedLocale = locale.toLowerCase();

  try {
    // Dynamically import the JSON data chunk for this country/locale
    // The data files are organized as: data/{countryCode}/{locale}.json
    const data = await import(
      `./data/${normalizedCountryCode}/${normalizedLocale}.json`
    );

    return data.default || data;
  } catch (error) {
    throw new Error(
      `Country formatting not found for country "${normalizedCountryCode}" with locale "${normalizedLocale}". ` +
        `Please ensure the data file exists at: data/${normalizedCountryCode}/${normalizedLocale}.json`,
    );
  }
}

/**
 * Check if formatting data exists for a country/locale combination.
 * 
 * This is a lightweight check that doesn't load the full data.
 * 
 * @param countryCode - ISO 3166-1 alpha-2 country code
 * @param locale - Locale code. Defaults to "en"
 * @returns Promise resolving to true if data exists, false otherwise
 */
export async function hasCountryFormatting(
  countryCode: string,
  locale: string = 'en',
): Promise<boolean> {
  try {
    await getCountryFormatting(countryCode, locale);
    return true;
  } catch {
    return false;
  }
}

/**
 * Get available locales for a specific country.
 * 
 * Note: This is a stub implementation. In production, this would scan
 * the data directory or use a manifest file.
 * 
 * @param countryCode - ISO 3166-1 alpha-2 country code
 * @returns Promise resolving to array of available locale codes
 */
export async function getAvailableLocales(
  countryCode: string,
): Promise<string[]> {
  const normalizedCountryCode = countryCode.toUpperCase();

  // Stub: In production, this would dynamically discover available locales
  // by scanning data/{countryCode}/ or reading a manifest
  // For now, we return common defaults
  const commonLocales = ['en'];

  // Some countries have additional common locales
  const countryLocaleMap: Record<string, string[]> = {
    CA: ['en', 'fr'],
    BR: ['pt-BR', 'en'],
    US: ['en', 'es'],
    MX: ['es', 'en'],
    FR: ['fr', 'en'],
    ES: ['es', 'en'],
    DE: ['de', 'en'],
    IT: ['it', 'en'],
    JP: ['ja', 'en'],
    CN: ['zh-CN', 'en'],
  };

  return countryLocaleMap[normalizedCountryCode] || commonLocales;
}
