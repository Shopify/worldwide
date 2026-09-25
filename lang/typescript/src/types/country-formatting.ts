/**
 * Address formatting templates for displaying addresses
 */
export interface AddressFormat {
  /**
   * Template for editing addresses (form input display)
   * Uses placeholders like {firstName}, {lastName}, {address1}, {city}, etc.
   */
  edit: string;

  /**
   * Template for displaying addresses (read-only display)
   * Uses placeholders like {firstName}, {lastName}, {address1}, {city}, etc.
   */
  show: string;

  /**
   * Optional templates for specific address field compositions
   */
  address1?: string;
  address1_with_unit?: string;
}

/**
 * Extended address formatting with additional metadata
 */
export interface AddressFormatExtended extends AddressFormat {
  /**
   * Address line separators and delimiters
   */
  line2_separator?: string;
  
  /**
   * Display options
   */
  show_compact?: string;
}

/**
 * Additional address fields that may be required for certain countries
 */
export interface AdditionalAddressFields {
  /**
   * Whether the country requires a province/state field
   */
  province?: boolean;

  /**
   * Whether the country requires a postal/ZIP code
   */
  zip?: boolean;

  /**
   * Whether the country requires a city field
   */
  city?: boolean;

  /**
   * Whether the country uses a neighborhood field
   */
  neighborhood?: boolean;

  /**
   * Whether the country uses split street fields (street name + number)
   */
  street_name?: boolean;
  street_number?: boolean;

  /**
   * Whether the country uses a dedicated line2 field
   */
  line2?: boolean;

  /**
   * Whether the country uses a district field
   */
  district?: boolean;

  /**
   * Whether the country uses a subdistrict field
   */
  subdistrict?: boolean;

  /**
   * Whether building number is required
   */
  building_number_required?: boolean;
}

/**
 * Political subdivision (state, province, region, etc.)
 */
export interface Zone {
  /**
   * Zone code (e.g., "ON" for Ontario, "CA" for California)
   */
  code: string;

  /**
   * Full name of the zone
   */
  name: string;

  /**
   * Alternative names for the zone
   */
  name_alternates?: string[];

  /**
   * Alternative codes for the zone
   */
  code_alternates?: string[];

  /**
   * Postal code prefixes for this zone (if applicable)
   */
  zip_prefixes?: string[];

  /**
   * Neighboring zones (for validation or suggestions)
   */
  neighboring_zones?: string[];
}

/**
 * Localized labels for address fields
 */
export interface AddressLabels {
  /**
   * Label for the first name field
   */
  firstName?: string;

  /**
   * Label for the last name field
   */
  lastName?: string;

  /**
   * Label for the company field
   */
  company?: string;

  /**
   * Label for the first address line
   */
  address1?: string;

  /**
   * Label for the second address line
   */
  address2?: string;

  /**
   * Label for the postal/ZIP code field
   */
  zip?: string;

  /**
   * Label for the city field
   */
  city?: string;

  /**
   * Label for the province/state field
   */
  province?: string;

  /**
   * Label for the country field
   */
  country?: string;

  /**
   * Label for the phone field
   */
  phone?: string;

  /**
   * Label for the street name field (if used)
   */
  streetName?: string;

  /**
   * Label for the street number field (if used)
   */
  streetNumber?: string;

  /**
   * Label for the line2 field (if used)
   */
  line2?: string;

  /**
   * Label for the neighborhood field (if used)
   */
  neighborhood?: string;

  /**
   * Label for the district field (if used)
   */
  district?: string;

  /**
   * Label for the subdistrict field (if used)
   */
  subdistrict?: string;
}

/**
 * Complete country formatting information
 */
export interface CountryFormatting {
  /**
   * ISO 3166-1 alpha-2 country code
   */
  countryCode: string;

  /**
   * Locale code for the formatting (e.g., "en", "fr", "pt-BR")
   */
  locale: string;

  /**
   * Country name in the specified locale
   */
  name: string;

  /**
   * Address formatting templates
   */
  format: AddressFormat;

  /**
   * Extended formatting options (optional)
   */
  format_extended?: AddressFormatExtended;

  /**
   * Additional address field requirements
   */
  additional_address_fields: AdditionalAddressFields;

  /**
   * Political subdivisions (states, provinces, etc.)
   */
  zones?: Zone[];

  /**
   * Localized field labels
   */
  labels: AddressLabels;

  /**
   * Postal code example
   */
  zip_example?: string;

  /**
   * Postal code regex pattern
   */
  zip_regex?: string;

  /**
   * Whether to use zone code as short name
   */
  use_zone_code_as_short_name?: boolean;
}
