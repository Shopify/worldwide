# frozen_string_literal: true

module Worldwide
  class Address
    RESERVED_DELIMITER = "\u2060"

    attr_reader :first_name,
      :last_name,
      :company,
      :address1,
      :address2,
      :zip,
      :city,
      :province_code,
      :country_code,
      :phone,
      :street_name,
      :street_number,
      :line2,
      :neighborhood

    def initialize(
      first_name: nil,
      last_name: nil,
      company: nil,
      address1: nil,
      address2: nil,
      zip: nil,
      city: nil,
      province_code: nil,
      country_code: "ZZ", # Unknown region
      phone: nil,
      street_name: nil,
      street_number: nil,
      line2: nil,
      neighborhood: nil
    )
      @first_name = first_name
      @last_name = last_name
      @company = company
      @address1 = address1
      @address2 = address2
      @zip = zip
      @city = city
      @province_code = province_code&.to_s&.upcase
      @country_code = country_code.to_s.upcase
      @phone = phone
      @street_name = street_name
      @street_number = street_number
      @line2 = line2
      @neighborhood = neighborhood
    end

    def errors
      AddressValidator.errors(self)
    end

    def format(additional_lines: [], excluded_fields: [])
      normalized_excluded_fields = normalize_field_names(excluded_fields)

      lines = build_filled_address_data(
        additional_lines: additional_lines,
        excluded_fields: normalized_excluded_fields,
      )

      strip_extra_chars(lines: lines, excluded_fields: normalized_excluded_fields).map do |line|
        line.join(" ")
      end
    end

    def normalize(autocorrect_level: 1)
      dup.normalize!(autocorrect_level: autocorrect_level)
    end

    def normalize!(autocorrect_level: 1)
      @country_code = normalize_country_code(autocorrect_level: autocorrect_level)
      @city = normalize_city
      @zip = normalize_zip
      @province_code = normalize_province_code || @province_code
      @phone = normalize_phone

      self
    end

    COUNTRIES_USING_REVERSE_ADDRESS_ORDER = ["JP"]
    def single_line(additional_lines: [], excluded_fields: [])
      normalized_excluded_fields = normalize_field_names(excluded_fields)

      lines = build_address_format_array(
        additional_lines: additional_lines,
        excluded_fields: normalized_excluded_fields,
      )

      if "BR" == country_code
        lines = adjust_single_line_format_for_brazil(lines: lines, excluded_fields: normalized_excluded_fields)
      end

      filled = fill_in_lines(lines: lines, address_data: build_formatted_address_data)

      stripped = strip_extra_chars(lines: filled, excluded_fields: normalized_excluded_fields)

      # Fallback to showing the country name by itself, in case no other information ended up being displayed
      if stripped.empty?
        stripped = [[Worldwide.region(code: country_code).full_name]]
      end

      fields = stripped.flatten.filter_map do |field|
        field unless blank?(field)
      end

      locale_str = I18n.locale.to_s.downcase
      # A handful of countries show their address in reverse order.
      # When formatting a mailing address for that country, we display in the country's order.
      # But, when constructing a single-line address like "Tokyo, Japan", we'd rather have things
      # in the "natural order" for the active locale.
      # So, in those cases where format_address returns the fields in reverse order, let's
      # unflip them before we get to producing our output.  That way, we'll show "Tokyo, Japan"
      # for :en, instead of showing "Japan, Tokyo".
      if COUNTRIES_USING_REVERSE_ADDRESS_ORDER.include?(country_code) &&
          locale_str.start_with?("ja", "zh")
        fields.reverse!
      end

      line =
        if locale_str.downcase.start_with?("ja")
          result = if fields.size < 2 || !lines.any? { |line| line.include?("{country}") }
            fields.reverse.join("")
          else
            fields.reverse.insert(1, "：").join("")
          end

          if Worldwide::Scripts.identify(text: result).include?(:Latin)
            result
          else
            result.delete(" \u{3000}")
          end
        elsif locale_str.start_with?("zh")
          fields.reverse.join("")
        else
          Worldwide::Lists.format(fields, join: :narrow)
        end

      line.strip
    end

    def valid?
      Util.blank?(errors)
    end

    def concatenate_address1
      additional_fields = region.combined_address_format.dig(script_from_field("address1"), "address1") || []
      additional_field_keys = additional_fields.map { |field| field["key"] }

      return address1 if field_values(additional_field_keys).empty?

      concatenate_fields(additional_fields)
    end

    def concatenate_address2
      additional_fields = region.combined_address_format.dig(script_from_field("address2"), "address2") || []
      additional_field_keys = additional_fields.map { |field| field["key"] }

      return address2 if field_values(additional_field_keys).empty?

      concatenate_fields(additional_fields)
    end

    def split_address1
      additional_fields = region.combined_address_format.dig(script_from_string(address1), "address1") || []
      number_of_fields = additional_fields.size
      split_fields_arr = address1&.split(RESERVED_DELIMITER, number_of_fields) || []
      split_fields(additional_fields, split_fields_arr)
    end

    def split_address2
      additional_fields = region.combined_address_format.dig(script_from_string(address2), "address2") || []
      number_of_fields = additional_fields.size
      split_fields_arr = address2&.split(RESERVED_DELIMITER, number_of_fields) || []
      split_fields(additional_fields, split_fields_arr)
    end

    private

    def region
      return @region if defined?(@region)

      @region = Worldwide.region(code: country_code)
    end

    LINE_SEP = "_"
    private_constant :LINE_SEP
    WORD_SEP = " "
    private_constant :WORD_SEP
    def address_format_array
      address_format_string.split(LINE_SEP).map { |line| line.split(WORD_SEP) }
    end

    def address_format_string
      if japan_with_non_japanese_script?
        # In Japan, the order of fields on an address label varies depending on the script used to write the address.
        # If the label is written in kanji (Japanese script), then it should be ordered from largest area
        # to smallest, i.e. prefecture ("province"), city, address1, address2, lastName, firstName.  This is the
        # order returned by Worldwide.region(code: "JP").format["show"].
        # But, if the address is written in romaji (Latin characters), then the fielsd should be ordered from
        # lest to most signficant.
        # As we understand it, Japan is unique in this, so we implement the re-ordering as a one-off special case here.
        # See also:  https://www.japan-guide.com/e/e2224.html

        "{firstName} {lastName}_{company}_{address1}_{address2}_{city} {province}_{country} 〒{zip}_{phone}"
      else
        Worldwide.region(code: country_code).format["show"] ||
          Worldwide.region(code: "BM").format["show"] # fallback of last resort
      end
    end

    # For Brazil, there's a convention that, when printing on a single line, there should be
    # commas between the fields except:
    #  - between address1 and address2, and between city and province, there should be a hyphen-minus
    #  - between zip and city, there should be a space with no comma
    def adjust_single_line_format_for_brazil(lines:, excluded_fields:)
      adjusted = lines

      # Merge address1 and address2 if necessary...

      a = adjusted.find_index(["{address1}"])
      b = adjusted.find_index(["{address2}"])
      if a && b && a < b && !blank?(address1) && !blank?(address2)
        adjusted = adjusted[0..a - 1] + adjusted[a + 1..b - 1] + [["{address1} - {address2}"]] + adjusted[b + 1..-1]
      end

      # Merge zip, city and province if necessary...

      # The "effective" version of a field's value takes into account whether it's been excluded
      # Using short names here for "effective_zip", "effective_city" and "effective_province"
      # so that the massive "if" below can fit each clause on a single line
      e_zip = zip unless excluded_fields.include?("zip")
      e_city = city unless excluded_fields.include?("city")
      e_province = province_name unless excluded_fields.include?("province")

      a = adjusted.find_index(["{zip}", "{city}", "{province}"]) ||
        adjusted.find_index(["{zip}", "{city}", ""]) ||
        adjusted.find_index(["{zip}", "", "{province}"]) ||
        adjusted.find_index(["{zip}", "", ""]) ||
        adjusted.find_index(["", "{city}", "{province}"]) ||
        adjusted.find_index(["", "{city}", ""]) ||
        adjusted.find_index(["", "{city}", "{province}"])

      if a
        reformatted = if blank?(e_zip) && blank?(e_city) && blank?(e_province)
          []
        elsif blank?(e_zip) && blank?(e_city) && !blank?(e_province)
          ["{province}"]
        elsif blank?(e_zip) && !blank?(e_city) && blank?(e_province)
          ["{city}"]
        elsif blank?(e_zip) && !blank?(e_city) && !blank?(e_province)
          ["{city} - {province}"]
        elsif !blank?(e_zip) && blank?(e_city) && blank?(e_province)
          ["{zip}"]
        elsif !blank?(e_zip) && blank?(e_city) && !blank?(e_province)
          ["{zip} - {province}"]
        elsif !blank?(e_zip) && !blank?(e_city) && blank?(e_province)
          ["{zip} {city}"]
        else # !blank?(e_zip) && !blank?(e_city) && !blank?(e_province)
          ["{zip} {city} - {province}"]
        end

        adjusted = adjusted[0..a - 1] + [reformatted] + adjusted[a + 1..-1]
      end

      adjusted
    end

    def blank?(text)
      text.nil? || text.strip.delete("\u200e").empty?
    end

    # Returns an array of lines containing the positions into which each field should be substituted,
    # e.g. ["{firstName} {lastName}", "{address1}", "{address2}", "{city} {province} {zip}", "{country}"]
    def build_address_format_array(additional_lines:, excluded_fields:)
      result = []

      address_format_array.each do |line|
        line.map do |component|
          stripped = component
          excluded_fields.each do |excluded|
            stripped.sub!("{#{excluded}}", "")
          end
          stripped
        end
        result << line unless blank?(line.join)
      end

      result + additional_lines.map { |x| [x] }
    end

    # Returns a hash containing the values for each address field
    def build_formatted_address_data
      {
        address1: address1,
        address2: address2,
        city: city,
        company: company,
        country: Worldwide.region(code: country_code).full_name,
        first_name: first_name,
        last_name: last_name,
        phone: phone,
        province: province_name,
        zip: zip,
      }
    end

    # Post-processes the output of build_address_format_array(), adding a LTR mark for the {phone} field
    # and enforcing snake_case for field names.
    # Fill in fields (e.g. "{city}") with their values (e.g. "London")
    def build_filled_address_data(additional_lines:, excluded_fields:)
      fill_in_lines(
        lines: build_address_format_array(
          additional_lines: additional_lines,
          excluded_fields: excluded_fields,
        ),
        address_data: build_formatted_address_data,
      )
    end

    def fill_in_lines(lines:, address_data:)
      lines.map do |line|
        fill_in_fields(fields: line, address_data: address_data)
      end
    end

    def fill_in_fields(fields:, address_data:)
      fields.map do |field|
        mapped = field
        address_data.each do |key, value|
          # Forcibly prefix the Unicode left-to-right mark to the phone number
          replacement = key == :phone ? "\u200e#{value}" : value

          replacement ||= ""

          mapped = mapped.gsub("{#{snake_to_camel_case(key)}}", replacement)
        end
        mapped
      end
    end

    JAPANESE_SCRIPTS = [:Han, :Katakana, :Hiragana]
    private_constant :JAPANESE_SCRIPTS
    def japan_with_non_japanese_script?
      text = build_formatted_address_data.values.join

      country_code == "JP" && Worldwide::Scripts.identify(text: text).intersection(JAPANESE_SCRIPTS).empty?
    end

    def normalize_city
      Worldwide.region(code: @country_code)&.autofill_city || @city
    end

    def normalize_country_code(autocorrect_level:)
      return @country_code if Util.blank?(@zip)

      level = autocorrect_level.to_i

      raise "Invalide autocorrect level (must be between 0 and 10)" if level < 0 || level > 10

      Zip.find_country(
        country_code: @country_code,
        zip: @zip,
        min_confidence: (100 - (10 * level)),
      )&.legacy_code || @country_code
    end

    def normalize_field_names(fields)
      result = fields.map do |field|
        snake_to_camel_case(field)
      end

      if result.include?("name")
        result << "firstName"
        result << "lastName"
      end

      result
    end

    def normalize_phone
      parsed_phone = Phone.new(number: @phone, country_code: @country_code)

      return @phone unless parsed_phone.valid?

      if parsed_phone.country_code&.to_s&.upcase == @country_code
        parsed_phone.domestic
      else
        parsed_phone.international
      end
    end

    def normalize_province_code
      country = Worldwide.region(code: @country_code)
      return @province_code if country.nil?

      inferred_province = country.zone(code: @province_code) unless Util.blank?(@province_code)

      if inferred_province.nil? || inferred_province == Worldwide.unknown_region
        inferred_province = country.zone(zip: @zip) unless Util.blank?(@zip)
      end

      if inferred_province == Worldwide.unknown_region
        nil
      else
        inferred_province&.legacy_code
      end
    end

    def normalize_zip
      Zip.normalize(country_code: @country_code, zip: @zip)
    end

    def province_name
      return "" if blank?(province_code)

      country_region = Worldwide.region(code: country_code)
      province_region = country_region.zone(code: province_code)

      if country_region.use_zone_code_as_short_name
        province_region.short_name
      else
        province_region.full_name
      end
    end

    def snake_to_camel_case(value)
      parts = value.to_s.split("_")
      (1..parts.length - 1).each do |index|
        parts[index] = parts[index].capitalize
      end
      parts.join
    end

    # Post-process to strip extraneous characters and whitespace
    def strip_extra_chars(lines:, excluded_fields:)
      result = []
      lines.each do |components|
        line = components.filter_map do |component|
          component unless component.empty?
        end

        line = strip_extra_japanese_chars(line: line, excluded_fields: excluded_fields)

        result << line.map(&:strip) unless blank?(line.join(""))
      end
      result
    end

    # For Japan (and, so far, only for Japan) we have a couple of special characters as part of the
    # address format string:
    #   - `様` ("-sama") is a gender-neutral, polite-form suffix that's appended to a name
    #   - `〒` ("yuubin" mark) is a prefix that's prepended to the postal code (zip)
    # If the associated field is excluded/empty, we need to suppress the associated special character.
    def strip_extra_japanese_chars(line:, excluded_fields:)
      return nil if line.nil?

      line.map do |field|
        stripped = field
        stripped.delete!("〒") if blank?(zip) || excluded_fields.include?("zip")
        stripped.delete!("様") if blank?(last_name) || excluded_fields.include?("lastName")
        stripped
      end
    end

    def script_from_string(str)
      script = "default"
      scripts = region.combined_address_format.except("default").keys
      return script if scripts.empty?

      detected_scripts = Worldwide::Scripts.identify(text: str).map(&:to_s)
      if detected_scripts.length == 1 && scripts.include?(detected_scripts.first)
        script = detected_scripts.first
      end
      script
    end

    def script_from_field(field)
      scripts = region.combined_address_format.except("default").keys
      script = scripts.find do |script|
        combined_address_format = region.combined_address_format.dig(script, field)
        additional_fields_string = combined_address_format.map { |field| send(field["key"].underscore.to_sym) }.join(" ")
        text_exclusively_uses_script?(additional_fields_string, script)
      end
      script.present? ? script : "default"
    end

    def text_exclusively_uses_script?(text, script)
      detected_scripts = Worldwide::Scripts.identify(text: text).map(&:to_s)
      detected_scripts.length == 1 && detected_scripts.include?(script)
    end

    def concatenate_fields(fields)
      concatenated_field = ""
      fields.each_with_index do |field, i|
        field_value = send(field["key"].underscore.to_sym)
        next if field_value.blank?

        delimiter = concatenation_delimiter(concatenated_field, field["decorator"], i)
        concatenated_field += delimiter + field_value
      end

      concatenated_field
    end

    def field_values(fields)
      fields.index_with do |field|
        send(field.underscore.to_sym)
      end.compact
    end

    def concatenation_delimiter(concatenated_field, decorator, field_index)
      if field_index == 0
        ""
      else
        concatenated_field.blank? ? RESERVED_DELIMITER : "#{decorator}#{RESERVED_DELIMITER}"
      end
    end

    def split_fields(field_definitions, field_values)
      return if field_definitions.empty?

      field_definitions.each_with_index.with_object({}) do |(field, i), split_fields|
        next unless field_values[i].present?

        field_name = field["key"].underscore
        split_fields[field_name] = strip_decorators(field_definitions[i + 1], field_values[i])
      end
    end

    def strip_decorators(next_field_definition, current_field_value)
      delimiter = next_field_definition&.fetch("decorator", nil) || ""
      current_field_value&.delete_suffix(delimiter)
    end
  end
end
