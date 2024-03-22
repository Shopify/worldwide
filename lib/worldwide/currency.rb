# frozen_string_literal: true

require_relative "pluralization_helper"
module Worldwide
  class Currency
    include PluralizationHelper

    EXCEPTIONS = { HKD: "HK$" }
    SUPPORTED_ALTERNATE_FORMATS = [:japan]
    TEXT_ENCLOSED_BY_PARENTHESES = /\((.)+\)/
    private_constant :TEXT_ENCLOSED_BY_PARENTHESES

    class << self
      def digits_and_rounding
        @digits_and_rounding ||= YAML.safe_load_file(File.join(Worldwide::Paths::OTHER_DATA_ROOT, "currency", "digits.yml")).freeze
      end

      def minor_symbols
        @minor_symbols ||= YAML.safe_load_file(File.join(Worldwide::Paths::OTHER_DATA_ROOT, "currency", "minor_symbols.yml")).freeze
      end
    end

    attr_reader :currency_code, :numeric_code

    def initialize(code:)
      adjusted_code = code.to_s.upcase.rjust(3, "0")
      if adjusted_code.match?(/[A-Z][A-Z][A-Z]/)
        @currency_code = adjusted_code
        @numeric_code = Currencies.numeric_code_for(adjusted_code)
      elsif adjusted_code.match?(/[0-9]+/)
        @currency_code = Currencies.alpha_code_for(adjusted_code)
        @numeric_code = adjusted_code
      else
        raise ArgumentError, "Currency code must be an ISO-4217 code, either alpha-three or numeric-three"
      end
    end

    # Returns the number of decimal places needed to represent the currency's minor unit
    def decimals
      Currency.digits_and_rounding.dig(@currency_code, "digits") || 2
    end

    # returns the amount formatted using the short-form symbol in the given locale
    def format_short(
      amount,
      as_minor_units: false,
      decimal_places: nil,
      humanize: nil,
      locale: I18n.locale,
      use_symbol: true
    )
      decimal_places = humanize ? nil : decimals if decimal_places.nil?
      use_symbol = true if as_minor_units

      if SUPPORTED_ALTERNATE_FORMATS.include?(humanize)
        return format_alternate(
          amount,
          decimal_places: decimal_places,
          humanize: humanize,
          locale: locale,
          use_symbol: use_symbol,
        )
      end

      if as_minor_units && has_minor_symbol?
        return format_minor_units(
          amount,
          decimal_places: decimal_places,
          humanize: humanize,
          locale: locale,
        )
      end

      if use_symbol
        currency_symbol = symbol(locale: locale) || @currency_code
        combine(
          amount: amount,
          decimal_places: decimal_places,
          humanize: humanize,
          locale: locale,
          symbol: currency_symbol,
        )
      else
        formatted_amount(amount, decimal_places: decimal_places, humanize: humanize, locale: locale)
      end
    end

    # returns the amount formatted using the explicit currency code in the given locale
    def format_explicit(
      amount,
      as_minor_units: false,
      decimal_places: nil,
      humanize: nil,
      locale: I18n.locale,
      use_symbol: true
    )
      short_version = format_short(
        amount,
        as_minor_units: as_minor_units,
        decimal_places: decimal_places,
        humanize: humanize,
        locale: locale,
        use_symbol: use_symbol,
      )
      if short_version.include?(@currency_code)
        short_version
      else
        "#{short_version} #{@currency_code}"
      end
    end

    def symbol(locale: I18n.locale)
      raw_symbol = Worldwide::Cldr.t("currencies.#{@currency_code}.narrow_symbol", default: nil, locale: locale) ||
        Worldwide::Cldr.t("currencies.#{@currency_code}.symbol", default: nil, locale: locale)

      return nil if raw_symbol.nil?

      # For some locales (e.g., HK), in-market folks have requested that we leave the CLDR behaviour untouched
      exceptional_symbol = EXCEPTIONS.fetch(@currency_code.to_sym, nil)
      return exceptional_symbol if exceptional_symbol

      # For some locales, CLDR defines the "symbol" to be the ISO currency code.
      # In those cases, we want to leave the raw_symbol unaltered.
      return raw_symbol if raw_symbol == @currency_code.to_s

      # For some currencies in some locales, CLDR includes alphabetic characters along with the symbol.
      # For example, CLDR defines the "symbol" as "$US" for :USD in :fr, and as "CA$" for :CAD in :'en'.
      # So, let's see what we have left after stripping the country code, if present, from the symbol.

      country_code = @currency_code.to_s[0..1]
      bare_symbol = raw_symbol.gsub(country_code, "")

      if bare_symbol.empty? || bare_symbol == "."
        raw_symbol
      else
        bare_symbol
      end
    end

    def label(count: 1)
      format_currency_text(translate_plural("currencies.#{@currency_code}", count: count))
    rescue I18n::InvalidPluralizationData
      name
    end

    def name
      format_currency_text(Worldwide::Cldr.t("currencies.#{@currency_code}.name"))
    end

    private

    def combine(amount:, decimal_places:, humanize:, locale:, symbol:)
      space = if has_space(locale)
        # This is U+00A0, the Unicode non-breaking space character
        [160].pack("U*")
      else
        ""
      end

      formatted = formatted_amount(
        amount,
        decimal_places: decimal_places,
        humanize: humanize,
        locale: locale,
      )

      if prefix?(locale)
        if formatted.include?("-")
          "-#{symbol}#{space}#{formatted.sub("-", "")}"
        else
          "#{symbol}#{space}#{formatted}"
        end
      else
        "#{formatted}#{space}#{symbol}"
      end
    end

    # Supports alternative formatting, specified in the humanize: keyword argument.
    # Currently, only :japan is available, which will use the 円 style for JPY.
    def format_alternate(amount, decimal_places:, humanize:, locale:, use_symbol:)
      case humanize
      when :japan
        formatted = formatted_amount(
          amount,
          decimal_places: decimal_places,
          humanize: humanize,
          locale: locale,
        )

        symbol = if use_symbol
          if "JPY" == @currency_code
            "円"
          else
            symbol(locale: locale) || @currency_code
          end
        else
          ""
        end

        "#{formatted}#{symbol}"
      else
        raise ArgumentError, "Unsupported value for humanize: #{humanize.inspect}"
      end
    end

    def format_currency_text(label)
      label.sub(TEXT_ENCLOSED_BY_PARENTHESES, "").strip
    end

    def format_minor_units(amount, decimal_places:, humanize:, locale:)
      # number of decimal places (relative to the major unit) that we've been asked to display
      specified_decimals = decimal_places.nil? ? decimals : decimal_places

      # number of decimal places needed to show the minor units in full detail
      exponent = decimals

      amount_in_minor_units = amount * (10**exponent)
      minor_decimal_places = [0, specified_decimals - exponent].max

      "#{formatted_amount(amount_in_minor_units, decimal_places: minor_decimal_places, humanize: humanize, locale: locale)}#{minor_symbol}"
    end

    def formatted_amount(amount, decimal_places:, humanize:, locale:)
      Numbers.new(locale: locale).format(
        amount,
        decimal_places: decimal_places,
        humanize: humanize,
      )
    end

    def has_minor_symbol?
      !minor_symbol.nil?
    end

    # Returns true if there should be a space between the amount and the currency symbol
    def has_space(locale)
      pattern = Worldwide::Cldr.t("numbers.latn.formats.currency.patterns.default.standard", locale: locale)

      # Note that CLDR uses these characters in its currency formats:
      # 160 (U+00A0) is the Unicode non-breaking space character
      # 164 (U+00A4) is the Unicode generic currency character ('¤')

      pattern.start_with?("¤ ", [164, 160].pack("U*")) || pattern.end_with?(" ¤", [160, 164].pack("U*"))
    end

    def minor_symbol
      key = @currency_code

      return nil unless Currency.minor_symbols.key?(key)

      Currency.minor_symbols[key]["symbol"]
    end

    # Returns true if the currency symbol is a prefix, e.g. "$ 12.00".
    # Returns false if the currency symbol is a suffix. e.g. "12.00 $".
    def prefix?(locale)
      Worldwide::Cldr.t("numbers.latn.formats.currency.patterns.default.standard", locale: locale).start_with?("¤")
    end
  end
end
