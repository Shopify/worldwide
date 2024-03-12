# frozen_string_literal: true

module Worldwide
  class Numbers
    JAPAN_MYRIAD_UNITS = ["", "万", "億", "兆", "京", "垓", "秭"].freeze

    CLDR_COMPACT_STYLE = [:short, :long].freeze
    COMPACT_DECIMAL_BASE_KEY = "numbers.latn.formats.decimal.patterns"
    DEFAULT_COMPACT_PATTERN = "0"

    def initialize(locale: I18n.locale)
      @locale = locale.to_sym
    end

    def format(amount, decimal_places: nil, humanize: nil, percent: false, relative: false)
      number = if percent
        amount * 100
      else
        amount
      end

      result = if CLDR_COMPACT_STYLE.include?(humanize)
        format_compact(number, decimal_places: decimal_places, style: humanize)
      else
        format_default(number, decimal_places: decimal_places, humanize: humanize)
      end

      result = add_percent_sign(result) if percent
      result = add_relative_marker(amount, result) if relative
      result
    end

    private

    attr_reader :locale

    def format_default(number, decimal_places:, humanize:)
      decimal_places = natural_decimal_places(number) if decimal_places.nil?

      # Format the number with no grouping and with a '.' decimal point
      result = Kernel.format("%.#{decimal_places}f", number)

      # Change the decimal marker to comma (or something else) if the locale expects it
      result.sub!(".", decimal_marker)

      # Add digit group markers
      result = if humanize == :japan
        add_japan_group_markers(result)
      else
        add_group_markers(result)
      end

      result
    end

    def add_group_markers(value)
      result = value

      group_size = group_positions.first
      secondary_group_size = group_positions.last

      position = value.index(decimal_marker)
      if position.nil?
        position = value.length
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
      @decimal_marker ||= Worldwide::Cldr.t("numbers.latn.symbols.decimal", default: ".", locale: @locale)
    end

    def group_marker
      @group_marker ||= Worldwide::Cldr.t("numbers.latn.symbols.group", default: ",", locale: @locale)
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
      @group_positions ||= begin
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
    def format_compact(number, decimal_places: nil, style:)
      matched_type = compact_format_type(number, style: style)
      if matched_type.nil?
        return format_default(
          number,
          decimal_places: decimal_places,
          humanize: nil,
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
      value = compact_number_format.sub(/0+/, format_default(scaled_number, decimal_places: decimals, humanize: nil))

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
      @percent_sign ||= Worldwide::Cldr.t("numbers.latn.symbols.percent_sign", default: "%", locale: locale).delete("\u200e").delete("\u200f")
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
      trailing = if locale.to_s.downcase.split("-").first == "he"
        # CLDR says Hebrew is right-to-left with a trailing % sign in character order,
        # which would imply a prefix % sign in numeric layout order, but Hebrew uses
        # a trailing % sign when considered in numeric layout order.  So, we override here.
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
