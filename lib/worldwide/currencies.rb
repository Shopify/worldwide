# frozen_string_literal: true

module Worldwide
  module Currencies
    include Enumerable
    extend self
    CURRENCIES_FILE_PATH = File.join(Worldwide::Paths::CLDR_ROOT, "locales", "en", "currencies.yml")
    CURRENCY_CODES_FILE_PATH = File.join(Worldwide::Paths::OTHER_DATA_ROOT, "currency", "codes.yml")

    def each(&block)
      all_currencies.each(&block)
    end

    def all
      all_currencies
    end

    # Convert ISO-4217 numeric-three code to ISO-4217 alpha-three code
    # Returns nil if there is no such numeric code.
    def alpha_code_for(numeric_code)
      lookup_code = if numeric_code.is_a?(Integer)
        numeric_code
      else
        numeric_code&.to_s&.to_i
      end
      numeric_three_to_alpha_three_db[lookup_code]&.to_s
    end

    # Convert ISO-4217 alpha-three code to ISO-4217 numeric-three code
    # Note that we support some currencies (e.g. JEP) that are not recognized by ISO,
    # and there is no numeric-three code for these currencies, so nil will be returned.
    def numeric_code_for(alpha_code)
      currency_codes.dig(alpha_code&.to_s&.upcase, "three_digit_code")&.to_i
    end

    private

    def all_currencies
      @all_currencies ||= begin
        currencies = {}
        YAML.load_file(CURRENCIES_FILE_PATH)["en"]["currencies"].map do |code, _name|
          currencies[code] = Currency.new(code: code)
        end.sort_by(&:currency_code)
      end
    end

    def currency_codes
      @currency_codes ||= YAML.safe_load_file(CURRENCY_CODES_FILE_PATH)
    end

    def map_alpha_three_to_numeric_three
      currency_codes
    end

    def numeric_three_to_alpha_three_db
      @map_numeric_three_to_alpha_three ||= currency_codes.to_h do |key, value|
        [value["three_digit_code"].to_i, key.to_s.upcase.to_sym]
      end
    end
  end
end
