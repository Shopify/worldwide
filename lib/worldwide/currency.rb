# frozen_string_literal: true

require "concurrent/map"
require_relative "pluralization_helper"
module Worldwide
  class Currency
    include PluralizationHelper

    EXCEPTIONS = { HKD: "HK$" }
    # Extended codes must be explicit so the process cache remains bounded.
    SUPPORTED_NON_ISO_CODES = ["USDC"].freeze
    SUPPORTED_ALTERNATE_FORMATS = [:japan]
    TEXT_ENCLOSED_BY_PARENTHESES = /\((.)+\)/
    # The direction marks that CLDR writes in currency patterns: U+200E LEFT-TO-RIGHT MARK, U+200F RIGHT-TO-LEFT MARK
    # and U+061C ARABIC LETTER MARK. The ar and he patterns start with U+200F, so that the amount reads right to left,
    # and the fa pattern starts with U+200E.
    DIRECTION_MARKS = "\u200E\u200F\u061C"
    # The positive part of a currency pattern: the text before the first of the symbol and the number, that one, the
    # text between them, and the other one.
    POSITIVE_PATTERN = /\A([^¤#0,.]*)(¤|[#0,.]+)([^¤#0,.]*)(¤|[#0,.]+)/
    OWN_PATTERNS = Concurrent::Map.new
    private_constant :SUPPORTED_NON_ISO_CODES, :TEXT_ENCLOSED_BY_PARENTHESES, :DIRECTION_MARKS, :POSITIVE_PATTERN, :OWN_PATTERNS

    class << self
      def digits_and_rounding
        @digits_and_rounding ||= YAML.safe_load_file(
          File.join(Worldwide::Paths::CURRENCY_MAPPINGS, "digits.yml"),
        ).freeze
      end

      def minor_symbols
        @minor_symbols ||= YAML.safe_load_file(
          File.join(Worldwide::Paths::CURRENCY_MAPPINGS, "minor_symbols.yml"),
        ).freeze
      end
    end

    attr_reader :currency_code, :numeric_code

    def initialize(code:)
      adjusted_code = code.to_s.upcase.rjust(3, "0")
      if adjusted_code.match?(/\A[A-Z]{3}\z/) || SUPPORTED_NON_ISO_CODES.include?(adjusted_code)
        @currency_code = adjusted_code
        @numeric_code = Currencies.numeric_code_for(adjusted_code)
      elsif adjusted_code.match?(/\A[0-9]{3}\z/)
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
    #
    # rounding_mode:, grouping: and sign_display: are passed to Numbers#format, with the same defaults and the
    # same meaning, on every path: with the symbol, with humanize:, with as_minor_units: and with use_symbol: false.
    # Numbers#format raises ArgumentError for the combinations it does not support, such as rounding_mode: with
    # humanize: :short or :long, and grouping: :auto with humanize: :japan.
    # With as_minor_units: and rounding_mode:, a Float amount is scaled to the minor unit through its shortest
    # decimal form, so 0.29 rounds as 29 cents rather than as 28.999999999999996.
    def format_short(
      amount,
      as_minor_units: false,
      decimal_places: nil,
      humanize: nil,
      locale: I18n.locale,
      use_symbol: true,
      rounding_mode: nil,
      grouping: :always,
      sign_display: :auto
    )
      decimal_places = humanize ? nil : decimals if decimal_places.nil?
      use_symbol = true if as_minor_units
      number_options = { rounding_mode: rounding_mode, grouping: grouping, sign_display: sign_display }

      if SUPPORTED_ALTERNATE_FORMATS.include?(humanize)
        return format_alternate(
          amount,
          decimal_places: decimal_places,
          humanize: humanize,
          locale: locale,
          use_symbol: use_symbol,
          **number_options,
        )
      end

      if as_minor_units && has_minor_symbol?
        return format_minor_units(
          amount,
          decimal_places: decimal_places,
          humanize: humanize,
          locale: locale,
          **number_options,
        )
      end

      unless use_symbol
        return formatted_amount(amount, decimal_places: decimal_places, humanize: humanize, locale: locale, **number_options)
      end

      if humanize
        combine(
          amount: amount,
          decimal_places: decimal_places,
          humanize: humanize,
          locale: locale,
          symbol: symbol(locale: locale) || @currency_code,
          **number_options,
        )
      else
        format_to_parts(amount, decimal_places: decimal_places, locale: locale, **number_options).map { |part| part[:value] }.join
      end
    end

    # returns the amount formatted using the explicit currency code in the given locale
    # It takes the same keyword arguments as format_short.
    def format_explicit(
      amount,
      as_minor_units: false,
      decimal_places: nil,
      humanize: nil,
      locale: I18n.locale,
      use_symbol: true,
      rounding_mode: nil,
      grouping: :always,
      sign_display: :auto
    )
      short_version = format_short(
        amount,
        as_minor_units: as_minor_units,
        decimal_places: decimal_places,
        humanize: humanize,
        locale: locale,
        use_symbol: use_symbol,
        rounding_mode: rounding_mode,
        grouping: grouping,
        sign_display: sign_display,
      )
      if short_version.include?(@currency_code)
        short_version
      else
        "#{short_version} #{@currency_code}"
      end
    end

    # Returns the amount formatted with the currency's symbol, as format_short formats it without humanize:,
    # as_minor_units: or use_symbol: false, split into parts. Each part is a Hash with a :type and a String :value,
    # in display order:
    #
    # - :minus_sign, the "-" of a negative amount. It comes first, before the symbol or the number.
    # - :currency, the symbol, or the currency code if the locale has no symbol for the currency.
    # - :literal, the direction marks that the locale's currency pattern writes before the symbol and the number, such
    #   as the U+200F RIGHT-TO-LEFT MARK of ar and he, or the no-break space and direction marks that it writes
    #   between them.
    # - :number, the localized number, without its sign.
    #
    # A part that would be empty is left out, and joining the values gives the result of format_short.
    # decimal_places:, rounding_mode:, grouping: and sign_display: work as they do for format_short.
    # Every call returns new objects, which the caller can change.
    #
    #   Worldwide.currency(code: "EUR").format_to_parts(-1234.5, locale: :fr)
    #   # => [{ type: :minus_sign, value: "-" }, { type: :number, value: "1\u202F234,50" },
    #   #     { type: :literal, value: "\u00A0" }, { type: :currency, value: "€" }]
    def format_to_parts(
      amount,
      decimal_places: nil,
      locale: I18n.locale,
      rounding_mode: nil,
      grouping: :always,
      sign_display: :auto
    )
      decimal_places = decimals if decimal_places.nil?
      currency_symbol = symbol(locale: locale) || @currency_code
      layout = pattern_layout(locale)
      negative, number = Numbers.new(locale: locale).send(:for_currency, @currency_code).send(
        :sign_and_digits,
        amount,
        decimal_places: decimal_places,
        rounding_mode: rounding_mode,
        grouping: grouping,
        sign_display: sign_display,
      )

      arrange_parts(negative: negative, number: number, symbol: currency_symbol, layout: layout)
    end

    def symbol(locale: I18n.locale)
      raw_symbol = Worldwide::Cldr.t("currencies.#{@currency_code}.narrow_symbol", default: nil, locale: locale) ||
        Worldwide::Cldr.t("currencies.#{@currency_code}.symbol", default: nil, locale: locale)

      return if raw_symbol.nil?

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

    # Formats a humanize: :short or :long amount with the symbol. The amount is written inside a CLDR compact
    # pattern, which can hold a minus sign of its own, so the sign is found in the text: it moves in front of a
    # leading symbol, and stays where it is when the symbol follows the number.
    def combine(amount:, decimal_places:, humanize:, locale:, symbol:, **number_options)
      layout = pattern_layout(locale)

      formatted = formatted_amount(
        amount,
        decimal_places: decimal_places,
        humanize: humanize,
        locale: locale,
        **number_options,
      )

      negative = layout[:prefix] && formatted.include?("-")
      number = negative ? formatted.sub("-", "") : formatted

      arrange_parts(negative: negative, number: number, symbol: symbol, layout: layout).map { |part| part[:value] }.join
    end

    # Returns the parts of a formatted amount in display order: the minus sign if negative, the direction marks that
    # the pattern starts with, then the symbol and the number in the pattern's order, with the literal between them.
    def arrange_parts(negative:, number:, symbol:, layout:)
      currency = { type: :currency, value: symbol.dup }
      digits = { type: :number, value: number }

      parts = []
      parts << { type: :minus_sign, value: +"-" } if negative
      parts << { type: :literal, value: layout[:leading].dup } unless layout[:leading].empty?
      parts << (layout[:prefix] ? currency : digits)
      parts << { type: :literal, value: layout[:between].dup } unless layout[:between].empty?
      parts << (layout[:prefix] ? digits : currency)
      parts
    end

    # Supports alternative formatting, specified in the humanize: keyword argument.
    # Currently, only :japan is available, which will use the 円 style for JPY.
    def format_alternate(amount, decimal_places:, humanize:, locale:, use_symbol:, **number_options)
      case humanize
      when :japan
        formatted = formatted_amount(
          amount,
          decimal_places: decimal_places,
          humanize: humanize,
          locale: locale,
          **number_options,
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

    def format_minor_units(amount, decimal_places:, humanize:, locale:, **number_options)
      # number of decimal places (relative to the major unit) that we've been asked to display
      specified_decimals = decimal_places.nil? ? decimals : decimal_places

      # number of decimal places needed to show the minor units in full detail
      exponent = decimals

      amount_in_minor_units = minor_units_amount(amount, exponent, number_options[:rounding_mode])
      minor_decimal_places = [0, specified_decimals - exponent].max

      "#{formatted_amount(amount_in_minor_units, decimal_places: minor_decimal_places, humanize: humanize, locale: locale, **number_options)}#{minor_symbol}"
    end

    # With a rounding mode, scale a Float's shortest decimal form, as Numbers#format does for percent:,
    # so that 0.29 gives 29 rather than 28.999999999999996. Zero keeps its Float sign.
    # With a rounding mode, a nil or String amount raises ArgumentError before it is scaled, through the private
    # check that Numbers#format uses for percent:. Without one, every amount is scaled as before.
    def minor_units_amount(amount, exponent, rounding_mode)
      Numbers.new.send(:validate_exact_amount, amount) if rounding_mode

      if rounding_mode && amount.is_a?(Float) && amount.finite? && !amount.zero?
        Rational(amount.to_s) * (10**exponent)
      else
        amount * (10**exponent)
      end
    end

    def formatted_amount(amount, decimal_places:, humanize:, locale:, **number_options)
      Numbers.new(locale: locale).send(:for_currency, @currency_code).format(
        amount,
        decimal_places: decimal_places,
        humanize: humanize,
        **number_options,
      )
    end

    def has_minor_symbol?
      !minor_symbol.nil?
    end

    # Returns the pattern that CLDR gives amounts in this currency: the pattern of its <currency> element, as en_150
    # gives EUR, or else the locale's standard currency pattern.
    # https://www.unicode.org/reports/tr35/tr35-numbers.html#Currencies
    def currency_pattern(locale)
      own_pattern(locale) || Worldwide::Cldr.t("numbers.latn.formats.currency.patterns.default.standard", locale: locale)
    end

    # Returns the pattern of this currency's <currency> element, or nil. Most currencies have none, and a lookup that
    # finds no value takes longer than one that does, so it is read once for each locale and version of the bundled
    # data rather than for every amount, and kept as Numbers keeps currency separators.
    def own_pattern(locale)
      key = [locale&.to_sym, @currency_code, Worldwide::Cldr::BundledData.current_version]
      OWN_PATTERNS.fetch(key) do
        pattern = Worldwide::Cldr.t("numbers.currencies.#{@currency_code}.pattern", default: nil, locale: locale)
        OWN_PATTERNS[key] = pattern if Worldwide::Cldr.locale_available?(locale)
        pattern
      end
    end

    # Returns how the positive part of the currency pattern lays out an amount: whether the symbol comes before the
    # number, the direction marks that the pattern starts with, and the text between the symbol and the number, of
    # which the spaces, written as U+00A0 NO-BREAK SPACE, and the direction marks are kept.
    # The he pattern "\u200F#,##0.00\u00A0\u200F¤" has the layout { prefix: false, leading: "\u200F", between: "\u00A0\u200F" }.
    def pattern_layout(locale)
      pattern = currency_pattern(locale).split(";").first
      match = POSITIVE_PATTERN.match(pattern)
      return { prefix: pattern.start_with?("¤"), leading: "", between: "" } if match.nil?

      leading, first, between = match.captures
      {
        prefix: first == "¤",
        leading: leading.delete("^#{DIRECTION_MARKS}"),
        between: between.tr(" ", "\u00A0").delete("^\u00A0#{DIRECTION_MARKS}"),
      }
    end

    def minor_symbol
      key = @currency_code

      return unless Currency.minor_symbols.key?(key)

      Currency.minor_symbols[key]["symbol"]
    end
  end
end
