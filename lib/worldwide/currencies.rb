# frozen_string_literal: true

module Worldwide
  module Currencies
    include Enumerable
    extend self

    CURRENCY_CODES = YAML.safe_load_file(
      File.join(Worldwide::Paths::CURRENCY_MAPPINGS, "codes.yml"),
      freeze: true,
    )
    private_constant :CURRENCY_CODES

    NUMERIC_THREE_TO_ALPHA_THREE_DB = CURRENCY_CODES.to_h do |key, value|
      [value["three_digit_code"].to_i, key.to_s.upcase.to_sym]
    end.freeze
    private_constant :NUMERIC_THREE_TO_ALPHA_THREE_DB

    def each(&block)
      ALL_CURRENCIES.each(&block)
    end

    def all
      ALL_CURRENCIES
    end

    # Convert ISO-4217 numeric-three code to ISO-4217 alpha-three code
    # Returns nil if there is no such numeric code.
    def alpha_code_for(numeric_code)
      lookup_code = if numeric_code.is_a?(Integer)
        numeric_code
      else
        numeric_code&.to_s&.to_i
      end
      NUMERIC_THREE_TO_ALPHA_THREE_DB[lookup_code]&.to_s
    end

    # Convert ISO-4217 alpha-three code to ISO-4217 numeric-three code
    # Note that we support some currencies (e.g. JEP) that are not recognized by ISO,
    # and there is no numeric-three code for these currencies, so nil will be returned.
    def numeric_code_for(alpha_code)
      CURRENCY_CODES.dig(alpha_code&.to_s&.upcase, "three_digit_code")&.to_i
    end

    currencies = YAML.load_file(
      File.join(Worldwide::Paths::CLDR_ROOT, "locales/en/currencies.yml"),
      freeze: true,
    )
    ALL_CURRENCIES = currencies["en"]["currencies"].map do |code, _name|
      Currency.new(code: code)
    end
    ALL_CURRENCIES.sort_by!(&:currency_code)
    ALL_CURRENCIES.freeze
    private_constant :ALL_CURRENCIES
  end
end
