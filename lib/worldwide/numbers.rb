# frozen_string_literal: true

require "concurrent/map"

module Worldwide
  class Numbers
    JAPAN_MYRIAD_UNITS = ["", "万", "億", "兆", "京", "垓", "秭"].freeze
    # add_japan_group_markers writes one unit for every four characters before the decimal marker, a minus sign included.
    JAPAN_MAX_INTEGER_CHARACTERS = JAPAN_MYRIAD_UNITS.length * 4
    private_constant :JAPAN_MAX_INTEGER_CHARACTERS

    CLDR_COMPACT_STYLE = [:short, :long].freeze
    COMPACT_DECIMAL_BASE_KEY = "numbers.latn.formats.decimal.patterns"
    DEFAULT_COMPACT_PATTERN = "0"

    # RTL locales that CLDR marks as leading % in numeric layout order, but which
    # actually use a trailing % (e.g. "75%", "2%"). We override the placement for these.
    TRAILING_PERCENT_SIGN_LOCALES = ["he", "ur"].freeze

    ROUNDING_MODES = [:half_even, :half_up, :half_down, :up, :down, :ceiling, :floor].freeze
    GROUPINGS = [:always, :auto].freeze
    SIGN_DISPLAYS = [:auto, :negative].freeze
    # The most integer digits of a BigDecimal, or decimal places of any amount, that decimal arithmetic renders.
    # ICU has the same limit on fraction digits.
    MAX_EXACT_DIGITS = 999
    private_constant :MAX_EXACT_DIGITS
    CURRENCY_SYMBOLS = Concurrent::Map.new
    private_constant :CURRENCY_SYMBOLS

    def initialize(locale: I18n.locale)
      @locale = locale.to_sym
    end

    # Formats amount as a locale-appropriate string.
    #
    # rounding_mode: nil (the default) rounds BigDecimal amounts half-even with decimal arithmetic,
    # and formats every other amount as before, through Kernel.format's "%f".
    # A mode (:half_even, :half_up, :half_down, :up, :down, :ceiling or :floor) rounds any finite
    # Integer, Float, Rational or BigDecimal amount with decimal arithmetic, and any other object
    # that converts to a finite BigDecimal with to_d. A Float is first converted to its shortest
    # round-trip decimal, so 1.015 rounds as 1.015. :half_up and :half_down round ties away from
    # and towards zero. Without decimal_places:, every decimal of the exact value is shown, so a
    # Rational that has no finite decimal expansion raises ArgumentError. A String or nil amount
    # raises ArgumentError, even when bigdecimal/util gives it a to_d.
    # rounding_mode: is not supported with humanize: :short or :long.
    #
    # Decimal arithmetic renders at most 999 decimal places, and a BigDecimal with at most 999
    # integer digits, counted after percent: or humanize: :short or :long has scaled the amount.
    # Without rounding_mode:, a BigDecimal beyond that keeps the "%f" formatting.
    # With rounding_mode:, it raises ArgumentError.
    #
    # humanize: :japan has units for 28 integer digits, or 27 and a minus sign. Without rounding_mode:,
    # a BigDecimal that rounds to more keeps the "%f" formatting. With rounding_mode:, an amount that
    # rounds to more raises ArgumentError.
    #
    # grouping: :always (the default) groups the integer digits of every amount. :auto groups them only when
    # there are at least as many as the primary group size plus the locale's CLDR minimum grouping digits
    # (UTS #35), so with a minimum of 2, as in pl and es, 1234 is not grouped and 12345 is.
    # The rule applies to the digits shown, after rounding, after the scaling of humanize: :short or :long,
    # and before percent: and relative: add their signs. grouping: :auto is not supported with
    # humanize: :japan, which writes myriad units instead of grouping separators.
    #
    # sign_display: :auto (the default) shows the minus sign of every negative amount, even when it
    # rounds to zero. :negative drops the minus sign when every displayed digit is zero.
    # sign_display: :negative is not supported with relative: true, which always shows a sign.
    def format(amount, decimal_places: nil, humanize: nil, percent: false, relative: false, rounding_mode: nil, grouping: :always, sign_display: :auto)
      if @bundled_data_version.nil? && Worldwide::Cldr.bundled_data?
        return bundled_data_twin.format(
          amount,
          decimal_places: decimal_places,
          humanize: humanize,
          percent: percent,
          relative: relative,
          rounding_mode: rounding_mode,
          grouping: grouping,
          sign_display: sign_display,
        )
      end

      # The defaults are valid with every other option.
      unless rounding_mode.nil? && grouping == :always && sign_display == :auto
        validate_options(humanize: humanize, relative: relative, rounding_mode: rounding_mode, grouping: grouping, sign_display: sign_display)
      end

      number = if percent
        percentage_amount(amount, rounding_mode)
      else
        amount
      end

      result = if CLDR_COMPACT_STYLE.include?(humanize)
        format_compact(number, decimal_places: decimal_places, style: humanize, grouping: grouping, sign_display: sign_display)
      else
        format_default(
          number,
          decimal_places: decimal_places,
          humanize: humanize,
          rounding_mode: rounding_mode,
          grouping: grouping,
          sign_display: sign_display,
        )
      end

      result = add_percent_sign(result) if percent
      result = add_relative_marker(amount, result) if relative
      result
    end

    protected

    # Set on the instance that serves the calls made inside Worldwide::Cldr.with_bundled_data,
    # to the version of the bundled data that its memoized values come from.
    attr_accessor :bundled_data_version

    # Set on the instances that Worldwide::Currency formats amounts with, so that they write the decimal and group
    # separators that CLDR gives currency amounts.
    attr_accessor :currency_separators

    # Set with currency_separators to the code of the currency whose amounts the instance formats, so that it writes
    # the separators that CLDR gives that currency.
    attr_accessor :currency_code

    private

    attr_reader :locale

    # Returns a Numbers for the same locale that writes the separators of amounts in the currency currency_code.
    # A <currency> element can give its currency a decimal and a group separator, as en_150 does for EUR. Otherwise,
    # CLDR's currencyDecimal and currencyGroup replace the decimal and group symbols in currency formats, and a locale
    # that defines neither uses its decimal and group symbols, so the amounts of most locales are written as their
    # other numbers are.
    # https://www.unicode.org/reports/tr35/tr35-numbers.html#Number_Symbols
    # https://www.unicode.org/reports/tr35/tr35-numbers.html#Currencies
    def for_currency(currency_code)
      numbers = Numbers.new(locale: @locale)
      numbers.currency_separators = true
      numbers.currency_code = currency_code
      numbers
    end

    # Lookups inside Worldwide::Cldr.with_bundled_data read different data from lookups outside it, so an
    # instance hands the calls made inside the block to a second instance, whose memoized values all come
    # from bundled data. It is replaced when files are registered, as its values may then be out of date.
    # Shared values are read into locals once, so threads that share the instance cannot mix up their data.
    # Two threads may each build a second instance at the same time, and either one is correct.
    # If the caller's block has just returned, the version is nil, and the call reads the host's data instead.
    # The second instance is a plain Numbers. A subclass that overrides format and calls super gets its override
    # applied once, by the caller's instance; an instance of the subclass would apply it a second time. Private
    # methods that a subclass or an extended module overrides are not used inside the block.
    def bundled_data_twin
      version = Worldwide::Cldr::BundledData.current_version
      return self if version.nil?

      twin = @bundled_data_twin
      return twin if !twin.nil? && twin.bundled_data_version.equal?(version)

      twin = Numbers.new(locale: @locale)
      twin.bundled_data_version = version
      twin.currency_separators = currency_separators
      twin.currency_code = currency_code
      @bundled_data_twin = twin
    end

    # Reads a value to memoize. The instance that serves calls inside Worldwide::Cldr.with_bundled_data reads
    # it inside a block of its own, so the value comes from bundled data even if the block that the caller
    # runs in returns meanwhile, which can happen in a thread created inside the block.
    def read_cldr(&block)
      @bundled_data_version.nil? ? yield : Worldwide::Cldr.with_bundled_data(&block)
    end

    def validate_options(humanize:, relative:, rounding_mode:, grouping:, sign_display:)
      unless rounding_mode.nil? || ROUNDING_MODES.include?(rounding_mode)
        raise ArgumentError, "Unsupported value for rounding_mode: #{rounding_mode.inspect}"
      end

      unless GROUPINGS.include?(grouping)
        raise ArgumentError, "Unsupported value for grouping: #{grouping.inspect}"
      end

      unless SIGN_DISPLAYS.include?(sign_display)
        raise ArgumentError, "Unsupported value for sign_display: #{sign_display.inspect}"
      end

      if rounding_mode && CLDR_COMPACT_STYLE.include?(humanize)
        raise ArgumentError, "rounding_mode: is not supported with humanize: #{humanize.inspect}"
      end

      if relative && sign_display != :auto
        raise ArgumentError, "sign_display: #{sign_display.inspect} is not supported with relative: true, which always shows a sign"
      end

      if grouping == :auto && humanize == :japan
        raise ArgumentError, "grouping: :auto is not supported with humanize: :japan, which writes myriad units instead of grouping separators"
      end
    end

    # With a rounding mode, scale a Float's shortest decimal form, so that 0.07 gives 7 rather than 7.000000000000001.
    # Zero keeps its Float sign.
    def percentage_amount(amount, rounding_mode)
      validate_exact_amount(amount) if rounding_mode

      if rounding_mode && amount.is_a?(Float) && amount.finite? && !amount.zero?
        Rational(amount.to_s) * 100
      else
        amount * 100
      end
    end

    # Formats amount as format does without humanize:, percent: or relative:, but returns the minus sign apart
    # from the localized digits, as [negative, digits]. Currency#format_to_parts uses it to place the sign itself.
    def sign_and_digits(amount, decimal_places:, rounding_mode:, grouping:, sign_display:)
      if @bundled_data_version.nil? && Worldwide::Cldr.bundled_data?
        return bundled_data_twin.send(
          :sign_and_digits,
          amount,
          decimal_places: decimal_places,
          rounding_mode: rounding_mode,
          grouping: grouping,
          sign_display: sign_display,
        )
      end

      validate_options(humanize: nil, relative: false, rounding_mode: rounding_mode, grouping: grouping, sign_display: sign_display)

      digits = plain_digits(amount, decimal_places: decimal_places, rounding_mode: rounding_mode, sign_display: sign_display)
      negative = digits.start_with?("-")
      [negative, localize_digits(digits.delete_prefix("-"), humanize: nil, grouping: grouping)]
    end

    def format_default(number, decimal_places:, humanize:, rounding_mode: nil, grouping: :always, sign_display: :auto)
      result = plain_digits(number, decimal_places: decimal_places, rounding_mode: rounding_mode, sign_display: sign_display)

      if humanize == :japan && (result.index(".") || result.length) > JAPAN_MAX_INTEGER_CHARACTERS
        if rounding_mode
          raise ArgumentError, "humanize: :japan has units for #{JAPAN_MAX_INTEGER_CHARACTERS} integer digits, " \
            "or #{JAPAN_MAX_INTEGER_CHARACTERS - 1} and a minus sign, and #{number.inspect} rounds to more"
        end

        # Without rounding_mode:, keep the "%f" formatting that the amount had before decimal arithmetic was used.
        result = legacy_digits(number, decimal_places)
      end

      localize_digits(result, humanize: humanize, grouping: grouping)
    end

    # Rounds number and renders it with no grouping, with a '.' decimal point, and with a leading "-" if it is negative.
    def plain_digits(number, decimal_places:, rounding_mode:, sign_display:)
      # Without rounding_mode:, a Float or an Integer keeps the "%f" formatting, so the usual amounts skip these checks.
      unless rounding_mode.nil? && (number.is_a?(Float) || number.is_a?(Integer))
        exact_places = exact_decimal_places(decimal_places)
        exact_amount = exact_amount(number, exact_places, rounding_mode)
      end

      # Format the number with no grouping and with a '.' decimal point
      result = if exact_amount.nil?
        legacy_digits(number, decimal_places)
      elsif exact_places == false
        raise ArgumentError, "decimal_places: must be an Integer or a String of digits, got #{decimal_places.inspect}"
      else
        format_exact(exact_amount, decimal_places: exact_places, rounding_mode: rounding_mode || :half_even)
      end

      result = result.delete_prefix("-") if sign_display == :negative && result.match?(/\A-0+(\.0+)?\z/)
      result
    end

    def localize_digits(result, humanize:, grouping:)
      # Change the decimal marker to comma (or something else) if the locale expects it
      result.sub!(".", decimal_marker)

      # Add digit group markers
      result = if humanize == :japan
        add_japan_group_markers(result)
      else
        add_group_markers(result, grouping: grouping)
      end

      result
    end

    def add_group_markers(value, grouping: :always)
      result = value

      group_size = group_positions.first
      secondary_group_size = group_positions.last

      position = value.index(decimal_marker)
      if position.nil?
        position = value.length
      end

      # https://www.unicode.org/reports/tr35/tr35-numbers.html#Examples_of_minimumGroupingDigits
      # > The attribute value is used by adding it to the grouping separator value. If the input number has fewer
      # > integer digits, the grouping separator is suppressed.
      # Only a sign can precede the integer digits, so they are long enough if this position holds a digit.
      if grouping == :auto
        first_grouped_digit = position - group_size - minimum_grouping_digits
        return result if first_grouped_digit < 0 || !numeric?(result[first_grouped_digit])
      end

      # Walk back from the decimal marker to the front of the string,
      # until there's no longer space for more than one digit grouping.
      until (position - group_size) < 1
        insertion_point = position - group_size

        # If we encounter non-digits, then we've reached the front of the
        # portion of the string that might require grouping markers.
        break unless numeric?(result[insertion_point - 1])

        result = result.insert(insertion_point, group_marker)

        # Once we've inserted our first grouping marker, subsequent groups
        # should be of the secondary group size.  For some locales, this
        # is identical to the primary group size, but for others (e.g.,
        # en-IN), there is a difference.
        group_size = secondary_group_size

        position = insertion_point
      end

      result
    end

    def add_japan_group_markers(value)
      number, decimal = value.split(decimal_marker)

      result = number.reverse.scan(/.{1,4}/).zip(JAPAN_MYRIAD_UNITS).map do |segment, unit|
        segment.gsub!(/0*$/, "")
        Util.blank?(segment) ? "" : (unit + segment)
      end.join.reverse

      result = "0" if Util.blank?(result)
      result = "#{result}#{decimal_marker}#{decimal}" if decimal

      result
    end

    def add_percent_sign(value)
      specification = percentage_specification
      spacing = specification[:spacing]

      if specification[:trailing]
        "#{value}#{spacing}#{percent_sign}"
      else
        "#{percent_sign}#{spacing}#{value}"
      end
    end

    def add_relative_marker(amount, representation)
      if amount < 0
        "#{Worldwide::Cldr.t("numbers.latn.symbols.minus_sign")}#{representation.delete("-")}"
      else
        "#{Worldwide::Cldr.t("numbers.latn.symbols.plus_sign")}#{representation}"
      end
    end

    def decimal_marker
      @decimal_marker ||= read_cldr { number_symbol(:decimal, currency_index: 0, default: ".") }
    end

    def group_marker
      @group_marker ||= read_cldr { number_symbol(:group, currency_index: 1, default: ",") }
    end

    def number_symbol(key, currency_index:, default:)
      currency_symbol = currency_symbols[currency_index] if currency_separators
      currency_symbol || Worldwide::Cldr.t("numbers.latn.symbols.#{key}", default: default, locale: @locale)
    end

    # Returns the decimal and the group separator that CLDR gives amounts in the currency currency_code, from its
    # <currency> element or else from the locale's currencyDecimal and currencyGroup, each nil if neither defines it.
    # Worldwide::Currency formats every amount with a new instance, and most locales define none of them, so they are
    # read once for each locale, currency and version of the bundled data rather than for every amount, as a lookup
    # that finds no value takes longer than one that does. A version is nil for the host's data. Registering files
    # makes a new version, and as with Locale#name, the values read under earlier versions stay in the cache. Lookups
    # accept other locales when the host does not enforce available locales, and those are not cached, so that the
    # cache stays bounded, as Worldwide.locale does not cache unknown locales.
    def currency_symbols
      @currency_symbols ||= begin
        key = [@locale, currency_code, @bundled_data_version]
        CURRENCY_SYMBOLS.fetch(key) do
          symbols = [
            currency_separator(:decimal, locale_key: :currency_decimal),
            currency_separator(:group, locale_key: :currency_group),
          ].freeze
          CURRENCY_SYMBOLS[key] = symbols if Worldwide::Cldr.locale_available?(@locale)
          symbols
        end
      end
    end

    def currency_separator(key, locale_key:)
      separator = Worldwide::Cldr.t("numbers.currencies.#{currency_code}.#{key}", default: nil, locale: @locale) unless currency_code.nil?
      separator || Worldwide::Cldr.t("numbers.latn.symbols.#{locale_key}", default: nil, locale: @locale)
    end

    # The fewest integer digits that grouping: :auto groups, beyond the primary group size.
    # CLDR defines it for some locales; the others inherit it through the CLDR fallbacks.
    def minimum_grouping_digits
      @minimum_grouping_digits ||= read_cldr { Worldwide::Cldr.t("numbers.minimum_grouping_digits", default: 1, locale: @locale) }
    end

    # Returns an array of digit grouping sizes (for splitting large numbers, e.g., into thousands)
    # Either [primary_group_size, secondary_group_size], or [primary_group_size], depending on locale.
    #
    # Examples:
    #
    # Many locales group by thousands (sets of 3 digits).  Thus, one million is written 1,000,000.
    # The returned value will be [3] for those locales.
    #
    # The Indian subcontinent and Burma group the initial 3 digits together, but subsequently group by
    # sets of 2 digits.  Thus, one million is written as 10,00,000 (and spoken as "ten lakh").
    # The returned value will be [3, 2] for those locales.
    #
    def group_positions
      @group_positions ||= read_cldr do
        # default
        pattern = "#,##0.00"
        pattern = Worldwide::Cldr.t("#{COMPACT_DECIMAL_BASE_KEY}.default.standard", default: pattern, locale: locale)

        # Pattern may have both positive and negative forms.  If so, look only at the first (positive) form.
        if pattern.include?(";")
          pattern = pattern.split(";")[0]
        end

        # Note that CLDR always shows this pattern with ',' as the group_marker, and '.' as the decimal_marker,
        # even for cases like fr-FR where those are inverted in the locale.
        first_group_position = pattern.index(",")
        second_group_position = pattern.rindex(",")
        decimal_position = pattern.index(".")

        if first_group_position == second_group_position
          # All groupings are the same size.  Return just one grouping size.
          [decimal_position - second_group_position - 1]
        else
          # Grouping sizes vary.  CLDR only allows a primary and secondary size.
          # See:  https://unicode.org/reports/tr35/tr35-numbers.html#Number_Symbols
          [decimal_position - second_group_position - 1, second_group_position - first_group_position - 1]
        end
      end
    end

    # This approximately implements compact number formatting as described in CLDR
    # https://unicode.org/reports/tr35/tr35-numbers.html#Compact_Number_Formats
    # It's not quite right, since it relies on format_default, which doesn't quite follow CLDR's spec.
    def format_compact(number, decimal_places: nil, style:, grouping: :always, sign_display: :auto)
      matched_type = compact_format_type(number, style: style)
      if matched_type.nil?
        return format_default(
          number,
          decimal_places: decimal_places,
          humanize: nil,
          grouping: grouping,
          sign_display: sign_display,
        )
      end

      scaled_number = number / compact_format_scale_factor(matched_type, style: style)
      compact_number_format = Worldwide::Cldr.t("#{COMPACT_DECIMAL_BASE_KEY}.#{style}.standard.#{matched_type}", count: scaled_number, locale: locale)

      # https://unicode-org.github.io/cldr/ldml/tr35-numbers.html#Compact_Number_Formats
      # > However, for the “0” case by default...the maximum fractional digits are set to 0 (for both currencies and plain decimal).
      # > APIs may, however, allow these default behaviors to be overridden.
      #
      # https://github.com/unicode-org/icu/blob/9971c663ff89e1bf78f9c4805daa407af8a023cb/icu4j/main/classes/core/src/com/ibm/icu/number/Notation.java#L118-L121
      # > When compact notation is specified without an explicit rounding strategy, numbers are rounded off
      # > to the closest integer after scaling the number by the corresponding power of 10, but with a digit
      # > shown after the decimal separator if there is only one digit before the decimal separator.
      #
      # https://www.unicode.org/reports/tr35/tr35-numbers.html#Rounding
      # > An implementation may allow the specification of a rounding mode to determine how values are rounded.
      # > In the absence of such choices, the default is to round "half-even", as described in IEEE arithmetic.
      # > That is, it rounds towards the "nearest neighbor" unless both neighbors are equidistant, in which case, it rounds towards the even neighbor.
      if decimal_places.nil?
        if compact_number_format == DEFAULT_COMPACT_PATTERN
          scaled_number = scaled_number.round(half: :even)
          decimal_places = 0
        elsif scaled_number.to_s.split(".")[0].length == 1
          scaled_number = scaled_number.round(1, half: :even)
          decimal_places = 1
        else
          scaled_number = scaled_number.round(half: :even)
          decimal_places = 0
        end
      end

      decimals = decimal_places.nil? ? natural_decimal_places(scaled_number) : decimal_places
      formatted_number = format_default(scaled_number, decimal_places: decimals, humanize: nil, grouping: grouping, sign_display: sign_display)
      value = compact_number_format.sub(/0+/, formatted_number)

      # Remove single quotes surrounding string literals in the compact number format.
      value.gsub!(/'([^']+)'/, '\1')

      value
    end

    # Scan the list of number formats given in CLDR, and find the closest match
    # https://www.unicode.org/reports/tr35/tr35-numbers.html#Compact_Number_Formats
    # > To format a number N, the greatest type less than or equal to N is used,
    # > with the appropriate plural category.
    def compact_format_type(number, style:)
      formats = {}
      Worldwide::Cldr::Fallbacks.new[locale].each do |fallback|
        formats = Worldwide::Cldr.t("#{COMPACT_DECIMAL_BASE_KEY}.#{style}.standard", locale: fallback).merge(formats)
      end

      types = formats.keys.sort_by { |type| Integer(type.to_s) }.reverse
      types.find do |t|
        Integer(t.to_s) <= number.abs
      end
    end

    def numeric?(character)
      character =~ /[[:digit:]]/
    end

    # https://www.unicode.org/reports/tr35/tr35-numbers.html#Compact_Number_Formats
    # > N is divided by the type, after removing the number of zeros in the pattern, less 1.
    def compact_format_scale_factor(matched_type, style:)
      compact_number_format = Worldwide::Cldr.t("#{COMPACT_DECIMAL_BASE_KEY}.#{style}.standard.#{matched_type}", count: 5, locale: locale)

      return 1 if compact_number_format == DEFAULT_COMPACT_PATTERN

      # Technically, this would break if there were 0s that were ahead of the main pattern
      # FWIW, a similar hack is used by ICU: https://github.com/unicode-org/icu/blob/084d8bc8e2e33d85d68c5a7a038ee9d11d44be12/icu4j/main/classes/core/src/com/ibm/icu/impl/number/CompactData.java#L239-L251
      digits_to_remove = [compact_number_format.match(/0+/)[0].length - 1, 0].max

      divisor = Integer(digits_to_remove.zero? ? matched_type.to_s : matched_type.to_s[0..-(digits_to_remove + 1)])
      divisor.to_f
    end

    # Kernel.format reads "%.2f" and "%.#{"2"}f" alike, so a String of digits is a number of decimal places too.
    # Returns the number of decimal places, nil for the amount's own decimals, or false for any other value.
    def exact_decimal_places(decimal_places)
      if decimal_places.nil? || (decimal_places.is_a?(Integer) && !decimal_places.negative?)
        decimal_places
      elsif decimal_places.is_a?(String) && decimal_places.match?(/\A[0-9]+\z/)
        Integer(decimal_places, 10)
      else
        false
      end
    end

    # Returns the amount to format with decimal arithmetic, or nil to keep the "%f" formatting.
    # Without a rounding mode, only a finite BigDecimal takes decimal arithmetic, and only when
    # decimal_places is a number of decimal places and the result is within MAX_EXACT_DIGITS.
    # Kernel.format then decides what any other decimal_places value means, as it did before.
    def exact_amount(number, decimal_places, rounding_mode)
      if bigdecimal?(number)
        return unless number.finite?
        return if rounding_mode.nil? && (decimal_places == false || !within_exact_digits?(number, decimal_places))

        return number
      end
      return if rounding_mode.nil?

      validate_exact_amount(number)
      case number
      when Integer, Rational
        number
      when Float
        number if number.finite?
      else
        decimal = number.to_d if number.respond_to?(:to_d)
        unless bigdecimal?(decimal) && decimal.finite?
          raise ArgumentError, "rounding_mode: needs an amount that converts to a finite BigDecimal with to_d, got #{number.class}"
        end

        decimal
      end
    end

    # Kernel.format reads a String through Float() and raises for nil, but bigdecimal/util, which Rails loads,
    # gives both a to_d that returns zero for nil and for text it can't read. Decimal arithmetic takes neither.
    def validate_exact_amount(amount)
      if amount.nil? || amount.is_a?(String)
        raise ArgumentError, "rounding_mode: is not supported with a #{amount.nil? ? "nil" : "String"} amount"
      end
    end

    def bigdecimal?(number)
      defined?(BigDecimal) && number.is_a?(BigDecimal)
    end

    # The "%f" formatting that every amount had before decimal arithmetic was used.
    def legacy_digits(number, decimal_places)
      decimal_places = natural_decimal_places(number) if decimal_places.nil?
      Kernel.format("%.#{decimal_places}f", number)
    end

    # BigDecimal("1e100000000") is small, but has 100,000,001 integer digits.
    def within_exact_digits?(decimal, decimal_places)
      decimal_places = decimal.scale if decimal_places.nil?
      decimal.exponent <= MAX_EXACT_DIGITS && decimal_places <= MAX_EXACT_DIGITS
    end

    # Rounds and renders amount with no grouping and with a '.' decimal point.
    # amount is an Integer, Rational, finite Float or finite BigDecimal, and decimal_places a non-negative Integer or nil.
    def format_exact(amount, decimal_places:, rounding_mode:)
      if decimal_places && decimal_places > MAX_EXACT_DIGITS
        raise ArgumentError, "decimal_places: must be at most #{MAX_EXACT_DIGITS}, got #{decimal_places}"
      end

      if bigdecimal?(amount)
        unless within_exact_digits?(amount, decimal_places)
          raise ArgumentError, "#{amount.inspect} needs more than #{MAX_EXACT_DIGITS} integer digits or decimal places"
        end

        decimal_places = amount.scale if decimal_places.nil?
        # Round before converting, so the Rational stays as small as the result.
        value = amount.round(decimal_places, bigdecimal_rounding_mode(rounding_mode, amount)).to_r
      else
        # Float#to_s is the shortest decimal that reads back as the same Float.
        value = amount.is_a?(Float) ? Rational(amount.to_s) : amount.to_r
        decimal_places = terminating_decimal_places(value) if decimal_places.nil?
        if decimal_places.nil?
          raise ArgumentError, "decimal_places: is required to format #{amount.inspect}, which has no decimal expansion of at most #{MAX_EXACT_DIGITS} places"
        end
      end

      digits = round_to_integer(value * (10**decimal_places), rounding_mode).abs.to_s.rjust(decimal_places + 1, "0")

      result = +""
      # value loses the sign of a negative zero, which amount keeps (-0.0, BigDecimal("-0")).
      result << "-" if value.negative? || (value.zero? && amount.to_s.start_with?("-"))
      result << digits[0, digits.length - decimal_places]
      result << "." << digits[-decimal_places, decimal_places] if decimal_places.positive?
      result
    end

    def round_to_integer(value, rounding_mode)
      case rounding_mode
      when :half_even then value.round(half: :even)
      when :half_up then value.round(half: :up)
      when :half_down then value.round(half: :down)
      when :up then value.negative? ? value.floor : value.ceil
      when :down then value.truncate
      when :ceiling then value.ceil
      when :floor then value.floor
      end
    end

    # BigDecimal#round with ROUND_UP returns zero for some amounts far below the last place, such as
    # BigDecimal("1e-10").round(2, BigDecimal::ROUND_UP), so :up rounds towards the infinity on the amount's side.
    def bigdecimal_rounding_mode(rounding_mode, amount)
      case rounding_mode
      when :half_even then BigDecimal::ROUND_HALF_EVEN
      when :half_up then BigDecimal::ROUND_HALF_UP
      when :half_down then BigDecimal::ROUND_HALF_DOWN
      when :up then amount.negative? ? BigDecimal::ROUND_FLOOR : BigDecimal::ROUND_CEILING
      when :down then BigDecimal::ROUND_DOWN
      when :ceiling then BigDecimal::ROUND_CEILING
      when :floor then BigDecimal::ROUND_FLOOR
      end
    end

    # Returns the number of decimal places in the decimal expansion of a Rational,
    # or nil if the expansion does not terminate within MAX_EXACT_DIGITS places.
    def terminating_decimal_places(value)
      denominator = value.denominator
      places = 0
      until denominator == 1
        divisor = denominator.gcd(10)
        return if divisor == 1 || places == MAX_EXACT_DIGITS

        denominator /= divisor
        places += 1
      end
      places
    end

    # Figure out how many decimal places would naturally be required to display the given number.
    def natural_decimal_places(number)
      natural_format = number.to_s.sub(/\.0+\Z/, "")
      position = natural_format.index(".")
      if position
        natural_format.length - position - 1
      else
        0
      end
    end

    def percent_sign
      # Strip U+200E and U+200F (left-to-right mark and right-to-left mark)
      @percent_sign ||= read_cldr do
        Worldwide::Cldr.t("numbers.latn.symbols.percent_sign", default: "%", locale: locale).delete("\u200e").delete("\u200f")
      end
    end

    # Returns true if the current locale uses a trailing percent sign (e.g., "50%") in
    # numeric layout order (which is always left-to-right, regardless of locale).
    # Otherwise (if the locale uses a leading percent sign, e.g., "%50") returns false.
    def percentage_specification
      character_order = Worldwide::Cldr.t("layout.orientation.character_order", default: "left-to-right", locale: locale)

      format = Worldwide::Cldr.t("numbers.latn.formats.percent.patterns.default.standard", locale: locale)
        .delete("#")
        .delete(",")
        .delete("\u200e") # left-to-right mark
        .delete("\u200f") # right-to-left mark

      percent_pos = format.index(percent_sign)
      digit_pos = format.index("0")

      return { spacing: "", trailing: true } if percent_pos.nil? || digit_pos.nil?

      first = [digit_pos, percent_pos].min
      second = [digit_pos, percent_pos].max

      spacing = format[(first + 1)..(second - 1)]
      trailing = if TRAILING_PERCENT_SIGN_LOCALES.include?(locale.to_s.downcase.split("-").first)
        true
      elsif character_order == "right-to-left"
        digit_pos > percent_pos
      else
        digit_pos < percent_pos
      end

      {
        spacing: spacing,
        trailing: trailing,
      }
    end
  end
end
