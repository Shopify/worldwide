# frozen_string_literal: true

module Worldwide
  module Zip
    extend self

    # We want to show numeric keypad on mobile view for countries with only numeric postal codes
    # Spaces or dashes are allowed.
    # @return [Boolean] true or false depending on whether postal code can contain only digits or not.
    def numeric_only_zip?(country_code:)
      NUMERIC_ONLY_ZIP_COUNTRIES.include?(country_code.to_s.upcase)
    end

    # We want to show numeric keypad on mobile view for countries with only numeric postal codes
    # Spaces or dashes aren't allowed.
    # @return [Boolean] true or false depending on whether postal code can contain only digits or not.
    def pure_numeric_only_zip?(country_code:)
      return false if SPACES_AND_HYPHENS.key?(country_code.to_s.upcase.to_sym)

      numeric_only_zip?(country_code: country_code)
    end

    # The United Kingdom has an unusual style of postcode.
    # It consists of two halves (outcode and incode), separated by a space.
    # The incode is always 3 characters, with 1 digit followed by 2 letters.
    # The outcode varies from 2 to 4 characters, following certain patterns.
    # A handful of other countries also allocate their codes within the UK "namespace".
    def gb_style?(country_code:)
      GB_STYLE_ZIP_COUNTRIES.include?(country_code.to_s.upcase)
    end

    # Suggest a country for a given postal code.
    #
    # Some countries have an ambiguous dual state.  For example, some consider Jersey to be a
    # top-level country in its own right, while others consider it to be part of the United Kingdom.
    # This leads to frustrated buyers receiving a validation error when they enter their address
    # and the postal code isn't valid for the selected "country".
    #
    # Also, in some cases, users are simply confused, and use a postal code that is obviously
    # inappropriate for the selected country.  Some examples:
    #   - entering a postal code for Georgia, United States, but selecting the country Georgia
    #   - using a USA FPO address, but selecting the non-US physical location of the US base as the country
    #
    # This method attempts to heuristically suggest a country in some common cases where we see
    # a lot of confusion.  There's no way to solve this problem for all cases, and we will often
    # not have a suggestion (in which case this method will return `nil`).
    #
    # @param country_code [String] The country code that the user thought this postal code was for (optional)
    # @param zip [String] The postal code that the user entered (required)
    # @param min_confidence [Integer] The minimum confidence level (between 0-100) that is accepted from a suggestion (optional)
    # @return [Region] which is a "country" if we have a suggestion, or `nil` if we do not.
    def find_country(country_code: nil, zip:, min_confidence: 0)
      return nil unless Util.present?(zip)

      country = Worldwide.region(code: country_code) unless country_code.nil?
      return country if country&.valid_zip?(zip)

      adjusted_zip = zip.strip.upcase

      # Try to match based on the alleged country
      suggestion, confidence = find_country_using_alleged_country(country_code, adjusted_zip)
      return suggestion unless suggestion.nil? || confidence.nil? || confidence < min_confidence

      # If our postal code is wholly numeric, we can't make an intelligent suggestion without an alleged country.
      return nil unless adjusted_zip.match?(/[A-Z]/)

      # Try a broader-ranging match without considering the alleged country
      # We'll see if we have only a single suggestion and, if so, return it.
      # In cases where there's more than one possible match, we'll return nil.
      suggestions = find_country_using_zip_alone(adjusted_zip)
      suggestion = suggestions.first[0] unless Util.blank?(suggestions)
      confidence = suggestions.first[1] unless Util.blank?(suggestions)

      return suggestion if suggestions.length == 1 && confidence && confidence >= min_confidence

      nil
    end

    # Normalizes the postal code into the format expected by the national postal authority.
    # @param country_code [String] The country in which this postal code is located.
    # @param zip [String] The postal code as the user has entered it.
    # @param allow_autofill [String] Normalize the postal code for the candidate country prior to seeing whether the regular expression matches that (normalized) code.
    # @param strip_extraneous_characters [String] Allow additional stripping of characters to either fully numeric or alphanumeric depending on the country.
    # @return [String] The postal code with spaces inserted/removed and other formatting fixes applied.
    def normalize(country_code:, zip:, allow_autofill: true, strip_extraneous_characters: false)
      input = zip # preserve the original zip, in case we need to fall back to it

      country = Worldwide.region(code: country_code)
      return zip if country.nil? || NORMALIZATION_DISABLED_COUNTRIES.include?(country.iso_code)

      if allow_autofill
        autofill = country.autofill_zip
        return autofill if Util.present?(autofill)
      end

      return nil if zip.nil?

      # Convert to uppercase
      # Convert numeric and romaji full-width to half-width
      # Strip hyphens, dashes and the Japanese postcode marker
      zip = zip.upcase.tr("０-９ａ-ｚＡ-Ｚ", "0-9a-zA-Z")
        .delete("〒\u058a\u05be\u1806\u1b60\u200b\u2010\u2011\u2012\u2013\u2014\u2015\u2053\u2e17\u2e3a\u2e3b\u2212\u30fb\u30fc\ufe58\ufe63\uff0d\uff65(),./_~-")
      zip = add_prefix_if_required(country_code: country_code, zip: zip)
      if strip_extraneous_characters
        zip = strip_extraneous_characters(zip: zip, country_code: country_code)
      end

      result = if gb_style?(country_code: country.iso_code)
        normalize_for_gb(zip: zip)
      else
        # Remove both normal-width and double-width spaces
        zip.delete!(" 　")
        zip = replace_letters_and_numbers(country_code: country.iso_code, zip: zip)

        if "BD" == country.iso_code
          normalize_for_bd(zip: zip)
        elsif "FO" == country.iso_code
          normalize_for_fo(zip: zip)
        elsif "GH" == country.iso_code
          normalize_for_gh(zip: zip)
        elsif "HT" == country.iso_code
          normalize_for_ht(zip: zip)
        elsif "LK" == country.iso_code
          normalize_for_lk(zip: zip)
        elsif "MD" == country.iso_code
          normalize_for_md(zip: zip)
        elsif "MG" == country.iso_code
          normalize_for_mg(zip: zip)
        elsif "NG" == country.iso_code
          normalize_for_ng(zip: zip)
        elsif "SG" == country.iso_code
          normalize_for_sg(zip: zip)
        elsif "MA" == country.iso_code
          normalize_for_ma(zip: zip)
        elsif "XK" == country.iso_code
          normalize_for_xk(zip: zip)
        elsif "BR" == country.iso_code || "JP" == country.iso_code
          insert_spaces_and_hyphens_for_partial_code(country_code: country.iso_code, zip: zip)
        else
          insert_spaces_and_hyphens(country_code: country.iso_code, zip: zip)
        end
      end

      if country.send(:valid_normalized_zip?, result)
        result
      elsif country.send(:valid_normalized_zip?, result, partial_match: true)
        result
      else
        input # fall back to the original input, because we don't seem to have generated anything sensible
      end
    end

    # Returns the "outcode" (first portion) of a postcode for a country that uses the UK style.
    # Returns the "forward sortation area" (first portion) of a postal code for Canada.
    # Returns the "routing key" (first portion) of a postal code for Ireland.
    # Otherwise, returns the full zip.
    def outcode(country_code:, zip:)
      @split_code_countries ||= Set.new(GB_STYLE_ZIP_COUNTRIES).add("CA").add("IE")

      return zip unless @split_code_countries.include?(country_code.to_s.upcase)

      normalize(country_code: country_code, zip: zip)&.split(" ")&.first
    end

    def strip_optional_country_prefix(country_code:, zip:)
      return zip if Util.blank?(zip)

      unless OPTIONAL_PREFIX_COUNTRIES.include?(country_code&.to_sym)
        return zip
      end

      vehicle_code = OPTIONAL_PREFIX_COUNTRIES[country_code&.to_sym]

      stripped = zip.strip
      upcased = stripped.upcase

      if upcased.start_with?(country_code&.to_s)
        stripped = stripped[country_code&.to_s&.length..-1]
      elsif upcased.start_with?(vehicle_code)
        stripped = stripped[vehicle_code.length..-1]
      end

      if stripped.start_with?("-")
        stripped = stripped[1..-1]
      end

      m = stripped.match(/^\d/)

      if m.nil?
        zip
      else
        stripped
      end
    end

    private

    # Countries that use GB-style postal code spacing, and should normalize the same way as GB
    GB_STYLE_ZIP_COUNTRIES = ["GB", "GG", "GI", "IM", "JE"]
    private_constant :GB_STYLE_ZIP_COUNTRIES

    # TODO(on: date('2022-07-01'), to: '#address-service')
    # A plus customer in Costa Rica has customized their address form to put the city value in the zip field.
    # To avoid impacting their holiday-season sales, we are temporarily disabling normaliziton for zip for CR.
    # The intention is to remove this special case (start normalizing again) in 2022.
    NORMALIZATION_DISABLED_COUNTRIES = [
      "CR",
    ]

    # Countries with alphanumeric postal codes
    # This mapping is in the format (country_code) => [possible_zip_format]
    # The possible postal code format does not include any spaces of hyphens
    # A represents where we expect to see a letter
    # 1 represents where we expect to see a number
    # E represents where we expect either a number or an Eircode-permitted letter
    # ? represents where we expect to see a letter or a number
    ALPHNUMERIC_POSTAL_CODE_FORMATS = {
      AR: ["A1111AAA"],
      BB: ["AA11111"],
      BN: ["AA1111"],
      CA: ["A1A1A1"],
      IE: ["A1EEEEE"],
      LC: ["AA11111"],
      MS: ["AAA1111"],
      MT: ["AA11", "AAA1111"],
      NL: ["1111AA"],
      SZ: ["A111"],
      VC: ["AA1111"],
      VG: ["AA1111"],
      WS: ["AA1111"],
    }
    private_constant :ALPHNUMERIC_POSTAL_CODE_FORMATS

    EIRCODE_CHAR_MAPPING = {
      B: "8",
      G: "6",
      I: "1",
      J: "1",
      L: "1",
      M: "W",
      O: "0",
      Q: "0",
      S: "5",
    }
    private_constant :EIRCODE_CHAR_MAPPING

    # Most European countries have an optional prefix that denotes to which country the postal code applies.
    # This may use the ISO country code, or the car number plate code.
    # For example, the Reichstag in Berlin's postal code may be written "11011", "DE-11011" or "D-11011".
    # We must strip that prefix before trying to look up the zone based on the remaining prefix.
    OPTIONAL_PREFIX_COUNTRIES = {
      AD: "AND",
      AX: "AX",
      BA: "BIH",
      BE: "B",
      BG: "BG",
      BY: "BY",
      CH: "CH",
      CY: "CY",
      CZ: "CZ",
      DE: "D",
      DK: "DK",
      EE: "EST",
      ES: "E",
      FI: "FIN",
      FO: "FO",
      FR: "F",
      GR: "GR",
      HR: "HR",
      HU: "H",
      IT: "I",
      LI: "FL",
      LT: "LT",
      LV: "LV",
      LU: "L",
      MC: "MC",
      MK: "NMK",
      NL: "NL",
      NO: "N",
      PL: "PL",
      PT: "P",
      RO: "RO",
      RS: "SRB",
      SI: "SLO",
      SK: "SK",
      VA: "V",
    }
    private_constant :OPTIONAL_PREFIX_COUNTRIES

    REQUIRED_PREFIX_COUNTRIES = {
      VG: "VG",
    }
    private_constant :REQUIRED_PREFIX_COUNTRIES

    # Some countries have spaces and/or hyphens in their postal codes.
    # We strip all spaces and hyphens before normalizing, and then put them back only in the spots where they are expected.
    # This mapping is in the format (country_code) => [number_of_characters, character_to_insert, position]
    SPACES_AND_HYPHENS = {
      AC: [[7, " ", 4]],
      AI: [[6, "-", 2]],
      AT: [[6, "-", 2], [5, "-", 1]],
      BM: [[4, " ", 2]],
      BR: [[8, "-", 5]],
      CA: [[6, " ", 3]],
      CH: [[6, "-", 2]],
      CR: [[9, "-", 5]],
      CZ: [[5, " ", 3]],
      FK: [[7, " ", 4]],
      GG: [[7, " ", 4], [6, " ", 3]],
      GI: [[7, " ", 4]],
      GR: [[5, " ", 3]],
      IE: [[7, " ", 3]],
      IM: [[7, " ", 4], [6, " ", 3]],
      IT: [[7, "-", 2], [6, "-", 1]],
      JE: [[6, " ", 3]],
      JP: [[7, "-", 3]],

      # Old-style (pre-2015) South Korea postal codes are 6 digits, in two groups of three, with a hyphen.
      # Thees are still found "in the wild".
      # New-style codes are 5 digits with no hyphen.
      KR: [[6, "-", 3]],

      LC: [[7, "  ", 4]], # Note, *two* spaces, not just one.
      LV: [[6, "-", 2]],

      # Old-style (pre-2007) Malta postal codes are 3 chars, a space, and then 2 digits
      # New-style Malta postal codes are 3 chars, a space, and then 4 digits
      MT: [[7, " ", 3], [5, " ", 3]],

      NL: [[6, " ", 4]],
      PL: [[5, "-", 2]],
      PN: [[7, " ", 4]],
      PT: [[7, "-", 4]],
      SA: [[9, "-", 5]],
      SE: [[5, " ", 3]],
      SH: [[7, " ", 4]],
      SK: [[5, " ", 3]],
      TA: [[7, " ", 4]],
      TC: [[7, " ", 4]],
      TH: [[9, "-", 5]], # Source: https://en.wikipedia.org/wiki/Thai_addressing_system#Postal_code
      US: [[9, "-", 5]],
      VE: [[5, "-", 4]],
    }
    private_constant :SPACES_AND_HYPHENS

    # CO, PO, SO, YO
    # SO and postal town S (Sheffield) both don't have a district 0 so it can be checked correctly
    GB_POSTAL_TOWN_WITH_SECOND_CHAR_OH = ["C", "S", "P", "Y"]
    private_constant :GB_POSTAL_TOWN_WITH_SECOND_CHAR_OH

    # Based on postal code formats here: https://en.wikipedia.org/wiki/List_of_postal_codes
    NUMERIC_ONLY_ZIP_COUNTRIES = Set.new([
      "AF",
      "AL",
      "AM",
      "AT",
      "AU",
      "AX",
      "BA",
      "BD",
      "BE",
      "BG",
      "BH",
      "BL",
      "BR",
      "BY",
      "CC",
      "CH",
      "CL",
      "CN",
      "CO",
      "CR",
      "CU",
      "CV",
      "CX",
      "CY",
      "CZ",
      "DE",
      "DK",
      "DO",
      "DZ",
      "EC",
      "EE",
      "EG",
      "ES",
      "ET",
      "FI",
      "FM",
      "FO",
      "FR",
      "GE",
      "GF",
      "GL",
      "GN",
      "GP",
      "GR",
      "GT",
      "GW",
      "HR",
      "HT",
      "HU",
      "ID",
      "IL",
      "IN",
      "IQ",
      "IR",
      "IS",
      "IT",
      "JM",
      "JO",
      "JP",
      "KE",
      "KG",
      "KR",
      "KW",
      "KZ",
      "LA",
      "LB",
      "LI",
      "LK",
      "LR",
      "LS",
      "LT",
      "LU",
      "LV",
      "MA",
      "MC",
      "ME",
      "MF",
      "MG",
      "MK",
      "MM",
      "MN",
      "MQ",
      "MV",
      "MW",
      "MX",
      "MY",
      "MZ",
      "NA",
      "NC",
      "NE",
      "NF",
      "NG",
      "NI",
      "NO",
      "NP",
      "NZ",
      "OM",
      "PA",
      "PF",
      "PG",
      "PH",
      "PK",
      "PL",
      "PM",
      "PS",
      "PT",
      "PY",
      "RE",
      "RO",
      "RS",
      "RU",
      "SA",
      "SD",
      "SE",
      "SG",
      "SI",
      "SJ",
      "SK",
      "SM",
      "SN",
      "SV",
      "TH",
      "TJ",
      "TM",
      "TN",
      "TR",
      "TT",
      "TW",
      "TZ",
      "UA",
      "UM",
      "US",
      "UY",
      "UZ",
      "VA",
      "VN",
      "WF",
      "XK",
      "YT",
      "ZA",
      "ZM",
    ])

    private_constant :NUMERIC_ONLY_ZIP_COUNTRIES

    def add_prefix_if_required(country_code:, zip:)
      required_prefix = REQUIRED_PREFIX_COUNTRIES[country_code&.to_sym]

      return zip unless required_prefix
      return zip if zip.start_with?(required_prefix)

      "#{required_prefix}#{zip}"
    end

    def find_country_using_alleged_country(country_code, zip)
      zips_for_country[country_code&.to_sym]&.each do |candidate_code, candidate_regex|
        regex = candidate_regex[0]
        confidence = candidate_regex[1]

        normalized = normalize(country_code: candidate_code, zip: zip, allow_autofill: false)
        if normalized.match(regex)
          candidate = Worldwide.region(code: candidate_code)
          return candidate, confidence if candidate.valid_zip?(normalized)
        end
      end
      nil
    end

    def find_country_using_zip_alone(zip)
      suggestions = []
      zips_for_country.each do |_, mappings|
        mappings.each do |candidate_code, candidate_regex|
          regex = candidate_regex[0]
          confidence = candidate_regex[1]

          normalized = normalize(country_code: candidate_code, zip: zip, allow_autofill: false)
          if normalized.match(regex)
            candidate = Worldwide.region(code: candidate_code)
            suggestions.append([candidate, confidence]) if candidate.valid_zip?(normalized)
          end
        end
      end
      suggestions
    end

    def insert_spaces_and_hyphens(country_code:, zip:)
      instructions = SPACES_AND_HYPHENS[country_code.to_s.upcase.to_sym]

      return zip unless instructions

      instructions.each do |length, char, pos|
        return "#{zip[0..(pos - 1)]}#{char}#{zip[pos..-1]}" if length == zip.length
      end

      zip
    end

    def insert_spaces_and_hyphens_for_partial_code(country_code:, zip:)
      instructions = SPACES_AND_HYPHENS[country_code.to_s.upcase.to_sym]

      return zip unless instructions

      instructions.each do |length, char, pos|
        return zip.delete(char).gsub(/(\d{#{pos}})(\d{1,#{length - pos}})/, "\\1#{char}\\2")
      end

      zip
    end

    def replace_where_eircode_char_is_expected(country_code: nil, zip:)
      EIRCODE_CHAR_MAPPING[zip.to_sym] || zip
    end

    def replace_where_number_is_expected(country_code: nil, zip:)
      zip = zip.tr("OILZSB", "011258")

      if country_code&.to_s == "CA"
        zip = zip.tr("DQ", "0")
      end
      zip
    end

    def replace_where_letter_is_expected(country_code: nil, zip:)
      zip = zip.tr("0258", "OZSB")

      if country_code&.to_s == "CA"
        zip = zip.tr("1FU", "LEV")
      end
      zip
    end

    def replace_letters_and_numbers(country_code:, zip:)
      stripped = strip_optional_country_prefix(country_code: country_code, zip: zip)
      prefix = zip.gsub(stripped, "")
      if NUMERIC_ONLY_ZIP_COUNTRIES.include?(country_code)
        autocorrected = replace_where_number_is_expected(zip: stripped)
        if autocorrected.scan(/^\d+$/).any?
          return prefix + autocorrected
        end
      elsif ALPHNUMERIC_POSTAL_CODE_FORMATS.include?(country_code.to_sym)
        return prefix + replace_letters_and_numbers_for_alphanumeric(country_code: country_code, zip: stripped)
      elsif country_code == "GB"
        return replace_ohs_and_zeros_for_gb(zip: zip)
      elsif country_code == "BM"
        return replace_ohs_and_zeros_for_bm(zip: zip)
      end
      zip
    end

    def replace_letters_and_numbers_for_alphanumeric(country_code:, zip:)
      unless ALPHNUMERIC_POSTAL_CODE_FORMATS.include?(country_code.to_sym)
        return zip
      end

      return zip if Util.blank?(zip)

      autocorrected_zips = []
      input = zip
      modified_input = input.dup

      ALPHNUMERIC_POSTAL_CODE_FORMATS[country_code&.to_sym].each do |mapping|
        autocorrected_zip = ""
        input_iterator = 0

        mapping.each_char do |type|
          if input_iterator >= modified_input.length
            input_iterator += 1
            break
          end

          if modified_input[input_iterator] == " " || modified_input[input_iterator] == "-"
            autocorrected_zip += modified_input[input_iterator]
            input_iterator += 1
          end

          if type == "A"
            modified_input[input_iterator] = replace_where_letter_is_expected(
              zip: modified_input[input_iterator],
              country_code: country_code,
            )
            # Verify that character is a non-digit as expected by country's postal code mapping
            break if modified_input[input_iterator].scan(/^\D+$/).none?
          elsif type == "1"
            modified_input[input_iterator] = replace_where_number_is_expected(
              zip: modified_input[input_iterator],
              country_code: country_code,
            )
            # Verify that character is a digit as expected by country's postal code mapping
            break if modified_input[input_iterator].scan(/^\d+$/).none?
          elsif type == "E"
            # This is a position in an Eircode where a letter or number is permitted.
            # But Eircodes never use the letters B, G, I, J, L, M, O, Q or S.
            # So, we can autocorrect certain mistakes, e.g. S => 5
            # The official Eircode finder (https://finder.eircode.ie/#/) is smart enough to do this, too.
            modified_input[input_iterator] = replace_where_eircode_char_is_expected(
              zip: modified_input[input_iterator],
              country_code: country_code,
            )
          end

          autocorrected_zip += modified_input[input_iterator]
          input_iterator += 1
        end
        autocorrected_zips.append(autocorrected_zip) if input_iterator == modified_input.length
      end

      return autocorrected_zips.first if autocorrected_zips.length == 1

      input
    end

    def replace_ohs_and_zeros_for_bm(zip:)
      # Postcodes in Bermuda have two letters, followed by either two digits (for a street address) or by
      # two letters (for a P.O. box).  It seems safe to assume that the letter O (oh) will never show up
      # P.O. Box code, and it is relatively common to see users confusing oh with zero entering something
      # like HM O1.  In addition, it seems that all P.O. Box codes end in X.

      return zip unless zip.length == 4

      po_box = zip.match?(/^...[A-Z]$/)

      [
        replace_where_letter_is_expected(country_code: "BM", zip: zip[0]),
        replace_where_letter_is_expected(country_code: "BM", zip: zip[1]),
        po_box ? zip[2] : replace_where_number_is_expected(country_code: "BM", zip: zip[2]),
        po_box ? zip[3] : replace_where_number_is_expected(country_code: "BM", zip: zip[3]),
      ].join("")
    end

    def replace_ohs_and_zeros_for_gb(zip:)
      # If an inputted postcode has 4 or less characters, then the zip is only the outcode
      if zip.length >= 5
        outcode = zip[0..-4]
        incode = zip[-3..-1]
      else
        outcode = zip
        incode = nil
      end

      # Possible outcode formats, where A is a letter and 9 is a digit
      # There are some rules when ohs and zeros can and cannot appear mentioned below
      # A9
      # A99
      # AA9
      # A9A
      # AA99
      # AA9A

      # First character of an outcode is always a letter - can never be Zero
      # Last chacter of an outcode can never be a Oh - if Oh should be Zero
      outcode[0] = "O" if outcode[0] == "0"
      outcode[-1] = "0" if outcode[-1] == "O"

      # When outcode is 4 characters long
      # The second character cannot be a Zero and the third character cannot be an Oh
      if outcode.length == 4
        outcode[1] = "O" if outcode[1] == "0"
        outcode[2] = "0" if outcode[2] == "O"
      # When outcode is 4 characters long
      # Post towns CO, PO, SO, and YO are the only codes with an Oh in the second character
      elsif outcode.length == 3
        if GB_POSTAL_TOWN_WITH_SECOND_CHAR_OH.include?(outcode[0])
          outcode[1] = "O" if outcode[1] == "0"
        end
      end

      # Incode only has 1 format: 9AA
      # Last 2 characters of the incode can never be an Oh so no need to check those
      # First character of the incode must be a digit
      if incode && incode[0] == "O"
        incode[0] = "0"
      end

      outcode + (incode || "")
    end

    def normalize_for_bd(zip:)
      return zip if Util.blank?(zip)

      m = zip.match(/^(GPO:?|DHAKA)(\d{4})$/)
      if m.nil?
        zip
      else
        m[2]
      end
    end

    # Users have a habit of entering the 3-digit postal code for Faroe Islands with an extraneous 0 prefix
    # This is not permitted by the FO postal service, but is predictable enough that we can auto-correct it.
    def normalize_for_fo(zip:)
      stripped = strip_optional_country_prefix(country_code: :FO, zip: zip)
      prefix = if zip == stripped
        ""
      else
        "FO-"
      end

      return zip unless /0\d{3}/.match?(stripped)

      "#{prefix}#{stripped[1..3]}"
    end

    # zip should be stripped of spaces, converted full-width to half-width, and upcased before we call this function
    def normalize_for_gb(zip:)
      return zip if zip.nil?

      upcased = zip.upcase
      stripped = replace_letters_and_numbers(country_code: "GB", zip: upcased.delete(" 　"))

      # In case we have an incomplete postcode with only the outcode provided,
      # we'll add a space on the end of it.  This is necessary so that our prefix-based
      # lookup will correctly match against prefixes, and assign an appropriate zone.
      # For example, "CH6" is in Wales, but "CH64" is in England, and we differentiate
      # between the two in our prefix table by setting the expected prefix for Wales to
      # "CH6 ".

      # Check for complete postcode (outcode and incode)
      m = stripped.match(/^([A-Z]{1,2})(\d{1,2})([A-Z])*\s*(\d)([A-Z][A-Z])$/)

      if m&.size == 6
        # outcode
        postal_town = m[1]
        division = m[2]
        division_suffix = m[3] || ""

        # incode
        digit = m[4]
        alpha = m[5]

        return "#{postal_town}#{division}#{division_suffix} #{digit}#{alpha}"
      end

      # Check for outcode-only postcode
      m = upcased.match(/^([A-Z]{1,2}\d{1,2}[A-Z]{0,1})\s*$/)
      if !m.nil? && m[1].length <= 4
        # Note that we're intentionally appending a space, so that this outcode will work for prefix matching
        "#{m[1]} "
      end
    end

    # GhanaPostGPS codes may be any of
    #   AX
    #   AX-111
    #   AX-1111
    #   AX-111-1111
    #   AX-1111-1111
    # where
    #   A is a letter
    #   X is a letter or a digit
    #   1 is a digit
    def normalize_for_gh(zip:)
      return zip if zip.nil?

      if zip.length <= 2
        zip
      elsif zip.length <= 6
        "#{zip[0..1]}-#{zip[2..]}"
      elsif zip.length <= 9
        "#{zip[0..1]}-#{zip[2..4]}-#{zip[5..]}"
      else
        "#{zip[0..1]}-#{zip[2..5]}-#{zip[6..]}"
      end
    end

    # A non-trivial number of buyers in HT seem to write their postcode as
    # xxxxHT, when the official format is HTxxxx.
    def normalize_for_ht(zip:)
      return zip if zip.nil?

      m = zip.match(/^(\d{4}) ?HT$/)
      if m.nil?
        zip
      else
        "HT#{m[1]}"
      end
    end

    # Certain "mistakes" are common in Sri Lanka
    #   - codes in Colombo are often given in old "sorting code" style, "02" or "002" instead of "00200"
    #   - codes ending in four zeroes often drop one of them, "4000" instead of "40000"
    def normalize_for_lk(zip:)
      return zip if zip.nil?

      m = zip.match(/^0?0?0?0?([1-9])0?0?$/)
      return "00#{m[1]}00" if Util.present?(m)

      m = zip.match(/^0?0?1([1-9])0?0?$/)
      return "01#{m[1]}00" if Util.present?(m)

      if zip.match?(/^[1-9][0-9]00$/)
        "#{zip}0"
      else
        zip
      end
    end

    # Moldova post prefers codes to be written "MD-nnnn", but some folks seem to be writing them
    # nnnnMD.  Let's rewrite those so that they'll be accepted.
    def normalize_for_md(zip:)
      return zip if zip.nil?

      m = zip.match(/^(\d{4})MD$/)
      if m.nil?
        zip
      else
        "MD-#{m[1]}"
      end
    end

    # MG postcodes are only 3 digits, but some users zip them with two leading zeroes.
    def normalize_for_mg(zip:)
      return zip if zip.nil?

      m = zip.match(/^00(\d{3})$/)
      if m.nil?
        zip
      else
        m[1]
      end
    end

    # In Nigeria, several commonly-used postcodes are of the form "n00001".
    # (This is the main post office of a major centre.)
    # We often see users mistype those as either "n0001" or "n000001".
    # Looking at the rest of the address records when that happens, we are reasonably confident that we can
    # auto-correct those particular codes.
    def normalize_for_ng(zip:)
      return zip if zip.nil?

      m = zip.match(/^([1-9])000(00)?1$/)
      if m.nil?
        zip
      else
        "#{m[1]}00001"
      end
    end

    # Users in SG do a couple of odd things:
    #  - add `S` or `5` in front of the code; we should remove this if it's present
    #  - add `SINGAPORE` either before or after the code; we should remove this if it's present
    def normalize_for_sg(zip:)
      return zip if zip.nil?

      upcased = zip.upcase

      return upcased[1..6] if upcased.length == 7 && ["5", "S"].include?(upcased[0])

      m = upcased.match(/^(S[1IL]NGAP[0O]RE)?(\d{6})(S[1IL]NGAP[0O]RE)?$/)
      if m.nil?
        zip
      else
        m[2]
      end
    end

    # For a given country, a list of alternative countries that we might suggest, and the
    # regular expression that should match in order to make that suggestion.
    def zips_for_country
      @zips_for_country ||= {
        # We see a non-trivial number of checkouts for "Andorra" with addresses in La Seu d'Urgell,
        # Spain, which is the closest major town across the border.
        AD: {
          ES: [/^(ES?-?)?257\d{2}$/, 80],
        },

        # Liechtenstein has a range of codes carved out of the Swiss namespace.
        CH: {
          LI: [regex_for(:LI), 90],
        },

        # Country code CY refers to the government (and postal service) of "South" Cyprus, which uses
        # 4-digit postal codes.  4-digit codes starting with 9 have been allocated, but refer to parts of
        # "North" Cyprus, whose mail delivery is handled "via Mersin 10 Turkey" using Turkish postal codes
        # (5 digits) starting with 99 (and possibly also with 98).
        CY: {
          TR: [/^9[89]\d{3}$/, 90],
        },

        # When Czechoslovakia split into the Czech Republic and Slovakia, they kept their existing postcodes.
        # This means that CZ and SK share a postcode namespace, and we can autocorrect from one country
        # to the other based on postcode.
        CZ: {
          SK: [regex_for(:SK), 90],
        },

        DE: {
          # Canadian military mail-forwarding addresses.  These are similar to US APO/FPO/DPO and UK BFPO.
          # These are really relevant to any country world-wide where CFPO has a presence; they should end
          # up matching globally, because Canadian codes are sufficiently unique to be distinctive.
          # But, we'll enter them under DE here because we know of at least one example of a Canadian base
          # that is actually in Germany.
          CA: [/^((B3K\s5X5)|(K8N 5W6)|(V9A 7N2))$/, 70], # Canadian FMO mail
        },

        # French overseas territories, overseas departments, and collectivities
        FR: {
          BL: [regex_for(:BL), 90],
          GF: [regex_for(:GF), 90],
          GP: [regex_for(:GP), 90],
          MC: [regex_for(:MC), 90],
          MF: [regex_for(:MF), 90],
          MQ: [regex_for(:MQ), 90],
          NC: [regex_for(:NC), 90],
          PF: [regex_for(:PF), 90],
          PM: [regex_for(:PM), 90],
          RE: [regex_for(:RE), 90],
          WF: [regex_for(:WF), 90],
          TF: [regex_for(:TF), 90],
          YT: [regex_for(:YT), 90],
        },

        # Countries ruled by HM Queen Elizabeth that are not technically part of the United Kingdom
        GB: {
          AC: [regex_for(:AC), 100],
          AI: [regex_for(:AI), 90],
          FK: [regex_for(:FK), 100],
          GG: [regex_for(:GG), 90],
          GI: [regex_for(:GI), 100],
          GS: [regex_for(:GS), 100],
          IM: [regex_for(:IM), 90],
          JE: [regex_for(:JE), 90],
          MS: [regex_for(:MS), 90],
          PN: [regex_for(:PN), 100],
          SH: [regex_for(:SH), 100],
          TA: [regex_for(:TA), 100],
          TC: [regex_for(:TC), 100],
          VG: [regex_for(:VG), 90],
        },

        GE: {
          US: [/^3[01]\d{3}(-\d{4})?$/, 70], # US state of Georgia
        },

        JP: {
          # There is a signficant US FPO presence in Okinawa, Japan.  But when using the
          # US FPO address for these personnel, the address must use country "United States",
          # not "Japan", because the US address is being used to ship to the addressee in Japan.
          US: [/^96[23456]\d{2}(-\d{4})?$/, 50], # US AP FPO zip codes
        },

        KN: {
          # We see a non-trivial number of checkouts shipping to KN via a freight forwarder based
          # near MIA airport in FL USA.  In such cases, the shipping label needs to read "United States".
          US: [/^33[12]\d{2}(-\d{4})?$/, 50],
        },

        KR: {
          # We see a non-trivial number of checkouts in "South Korea" that are destined for US FPO addresses.
          # These need to be specified with country "United States" because the US government is
          # handling the delivery.
          # Records that have cropped up historically in "South Korea" have been limited to 962xx.
          US: [/^962\d{2}(-\d{4})?$/, 50],
        },

        LC: {
          # Many buyers seem to use freight forwarding services based near MIA airport.
          # This means that the merchant is shipping to Miami, FL, USA, despite the fact that
          # the buyer (and ultimate destination) is in LC.  For that reason, the shipping address
          # country needs to be US, not LC.
          US: [/^33[12]\d{2}(-\d{4})?$/, 50],
        },

        LI: {
          # Vorarlberg is the bit of Austria next to Liechtenstein
          # It is isolated from the rest of Austria by some significant mountains, with
          # the result that it is culturally and economically close to CH and LI.
          # Vorarlberg codes are in the ranges 67xx, 68xx, and 69xx.
          AT: [/^(AT?-?)?6[789]\d{2}$/, 80],

          # Parts of Switzerland that are geographically close to Liechtenstein:
          #  - 7xxx Graubünden (GR)
          #  - 9xxx Ostscheiz (Appenzell and St. Gallen, AI AR SG)
          # Note that 948x and 949x are Liechtenstein itself.
          CH: [/^(CH-?)?(7\d{3}|9[0-35-9]\d{2}|94[0-7]\d)$/, 80],
        },

        MC: {
          # We see a non-trivial number of checkouts for country "Monaco" that give addresses
          # in parts of France that are close to Monaco.
          FR: [/^(FR?-?)?06\d{3}$/, 80],
        },

        NO: {
          SJ: [regex_for(:SJ), 90],
        },

        # When Czechoslovakia split into the Czech Republic and Slovakia, they kept their existing postcodes.
        # This means that CZ and SK share a postcode namespace, and we can autocorrect from one country
        # to the other based on postcode.
        SK: {
          CZ: [regex_for(:CZ), 90],
        },

        VC: {
          # We see a non-trivial number of checkouts shipping via a freight forwarder based near MIA
          # airport in FL, USA.  This means that the merchant is shipping to Miami FL USA despite the
          # fact that the buyer and ultimate destination is in Saint Vincent and the Grenadines.
          # To calculate shipping correctly (and have the package arrive at the freight forwarder
          # successfully) the shipping label must read "United States".
          US: [/^33[12]\d{2}(-\d{4})?$/, 50],
        },
      }
    end

    def regex_for(country_code)
      # /^(?=x)y/ requires the string to start with both 'x' and 'y' at the same time.
      # This contradiction will never match any string.
      Regexp.new(Worldwide.region(code: country_code).zip_regex || "^(?=x)y")
    end

    # In Morocco, many of the most-frequently-used postcodes end in a long string of zeroes.
    # Users frequently get confused about how many zeroes there should be, and either leave one out
    # or insert an extra one.
    # So, for example, we see addresses in Casablanca, whose postcode is 20000, with postcode 2000.
    # To reduce friction during checkout, we auto-correct these.
    def normalize_for_ma(zip:)
      return zip if zip.nil?

      if zip.match?(/^[1-9][0-9]00$/)
        "#{zip}0"
      elsif zip.match?(/^[1-9][0-9]0000$/)
        zip[0..4]
      else
        zip
      end
    end

    # Several common Kosovo codes have long strings of zeroes.
    # Users frequently have either one extra zero, or one zero missing.
    # We can help them out by autocorrecting those.
    def normalize_for_xk(zip:)
      return zip if zip.nil?

      m = zip.match(/^([1-7])000(00)?$/)
      if m.nil?
        zip
      else
        "#{m[1]}0000"
      end
    end

    def strip_extraneous_characters(zip:, country_code:)
      if NUMERIC_ONLY_ZIP_COUNTRIES.include?(country_code.to_s.upcase)
        return zip.gsub(/[^0-9]/i, "")
      elsif ALPHNUMERIC_POSTAL_CODE_FORMATS.include?(country_code.to_sym)
        return zip.gsub(/[^0-9A-Za-z]/i, "")
      end

      zip
    end
  end
end
