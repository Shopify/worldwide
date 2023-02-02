# frozen_string_literal: true

require "date"

module Worldwide
  module Cldr
    class DateFormatPattern
      class InvalidPattern < StandardError; end

      class << self
        # Populate a CLDR format string using a Date
        # TODO: Implement all the date fields
        def format(date, format, locale: I18n.locale)
          tokens = tokenize(format)

          formatted = tokens.map do |token|
            case token
            when Field
              token.format(date, locale: locale)
            when Literal
              token.value
            end
          end
          formatted.join("")
        end

        def tokenize(format)
          tokens = []
          i = 0
          while i < format.length
            token, length = parse_field(format[i..-1]) ||
              parse_single_quote(format[i..-1]) ||
              parse_quoted_literal(format[i..-1]) ||
              parse_unquoted_literal(format[i..-1])

            raise InvalidPattern, "Invalid token at index #{i}: #{format[i..5].inspect}" unless token

            tokens << token
            i += length
          end

          tokens
        end

        private

        PATTERN_FIELD = /([a-zA-Z])\1*/
        SINGLE_QUOTE_LITERAL = /''/
        QUOTED_LITERAL = /'(([^']|#{SINGLE_QUOTE_LITERAL})*[^'])'/
        UNQUOTED_LITERAL = /[^a-zA-Z']+/

        def parse_field(format)
          return nil unless format.start_with?(PATTERN_FIELD)

          match = PATTERN_FIELD.match(format)
          [Field.from(match[0]), match.end(0)]
        end

        def parse_single_quote(format)
          return nil unless format.start_with?(SINGLE_QUOTE_LITERAL)

          match = SINGLE_QUOTE_LITERAL.match(format)
          [Literal.new("'"), match.end(0)]
        end

        def parse_quoted_literal(format)
          return nil unless format.start_with?(QUOTED_LITERAL)

          match = QUOTED_LITERAL.match(format)
          [Literal.new(match[1].gsub(SINGLE_QUOTE_LITERAL, "'")), match.end(0)]
        end

        def parse_unquoted_literal(format)
          return nil unless format.start_with?(UNQUOTED_LITERAL)

          match = UNQUOTED_LITERAL.match(format)
          [Literal.new(match[0]), match.end(0)]
        end
      end

      class Field
        class << self
          def from(pattern)
            klass = Worldwide::Cldr::DateFormatPattern::FIELD_CLASSES[pattern[0].to_sym] || Field
            klass.new(pattern)
          end
        end

        attr_reader :pattern

        def initialize(pattern)
          @pattern = pattern
        end

        def format(date, locale: I18n.locale)
          raise NotImplementedError, "Unimplemented field: #{pattern}"
        end
      end
      Literal = Struct.new(:value)

      class EraField < Field
        GREGORIAN_COMMON_ERA_BOUNDARY = Date.new(1, 1, 1)

        def format(date, locale: I18n.locale)
          era_number = date < GREGORIAN_COMMON_ERA_BOUNDARY ? 0 : 1
          case pattern.length
          when 1..3 # Era name, Abbreviated ("BC", "AD", "CE")
            Worldwide::Cldr.t("calendars.gregorian.eras.abbr.#{era_number}", locale: locale)
          when 4 # Era name, wide (e.g., "Anno Domini")
            Worldwide::Cldr.t("calendars.gregorian.eras.name.#{era_number}", locale: locale)
          when 5 # Era name, narrow (e.g., "A")
            Worldwide::Cldr.t("calendars.gregorian.eras.narrow.#{era_number}", locale: locale)
          else
            raise ArgumentError, "Invalid token: #{pattern}"
          end
        end
      end

      class QuarterField < Field
        def initialize(pattern)
          super
          @format_type = pattern.downcase == pattern ? :stand_alone : :format
        end

        def format(date, locale: I18n.locale)
          quarter_number = (date.month - 1) / 3 + 1

          case pattern.length
          when 1 # "Q" Quarter number (e.g., "1")
            quarter_number.to_s
          when 2 # "QQ" Quarter number, zero padded to 2 digits (e.g., "01")
            quarter_number.to_s.rjust(2, "0")
          when 3 # "QQQ" Quarter name, abbreviated (e.g., "Q1")
            Worldwide::Cldr.t("calendars.gregorian.quarters.#{format_type}.abbreviated.#{quarter_number}", locale: locale)
          when 4 # "QQQQ" Quarter name, wide (e.g., "1st quarter")
            Worldwide::Cldr.t("calendars.gregorian.quarters.#{format_type}.wide.#{quarter_number}", locale: locale)
          when 5 # "QQQQQ" Quarter name, narrow (e.g., "1")
            Worldwide::Cldr.t("calendars.gregorian.quarters.#{format_type}.narrow.#{quarter_number}", locale: locale)
          else
            raise ArgumentError, "Invalid token: #{pattern}"
          end
        end

        private

        attr_reader :format_type
      end

      class YearField < Field
        def format(date, locale: I18n.locale)
          if pattern.length == 2
            # Calendar year (numeric), final 2 digits (e.g., 2019 -> 19)
            date.year.abs.to_s[-2..]
          else # Calendar year (numeric), all digits, zero padded to the number of "y" characters (e.g., 2019)
            date.year.abs.to_s.rjust(pattern.length, "0")
          end
        end
      end

      FIELD_CLASSES = {
        G: EraField,
        q: QuarterField,
        Q: QuarterField,
        y: YearField,
      }
    end
  end
end
