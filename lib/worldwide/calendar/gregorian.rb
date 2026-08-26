# frozen_string_literal: true

module Worldwide
  module Calendar
    class Gregorian
      class MissingCalendarDataError < StandardError; end

      class << self
        # We intentionally don't support `short` weekday names, as we haven't found anyone asking for them.
        # People usually want the full weekday name, or the abbreviated version.
        VALID_WEEKDAY_WIDTHS = [:abbreviated, :narrow, :wide].freeze
        WEEKDAYS = [:sun, :mon, :tue, :wed, :thu, :fri, :sat].freeze
        def weekday_names(width: :wide, locale: I18n.locale)
          raise ArgumentError, "Invalid width: #{width}" unless VALID_WEEKDAY_WIDTHS.include?(width)

          complete_names("calendars.gregorian.days.stand_alone.#{width}", WEEKDAYS, locale)
        end

        VALID_MONTH_WIDTHS = [:abbreviated, :narrow, :wide].freeze
        MONTHS = (1..12).to_a.freeze
        def month_names(width: :wide, locale: I18n.locale)
          raise ArgumentError, "Invalid width: #{width}" unless VALID_MONTH_WIDTHS.include?(width)

          complete_names("calendars.gregorian.months.stand_alone.#{width}", MONTHS, locale).values
        end

        def quarter(date, locale: I18n.locale)
          format_string = Worldwide::Cldr.t("calendars.gregorian.additional_formats.yQQQ", locale: locale)
          Worldwide::Cldr::DateFormatPattern.format(date, format_string, locale: locale)
        end

        private

        # `stand_alone` is an alias to `format` in CLDR for most locales, and many locales
        # override only a handful of entries, so these names have to be assembled with
        # CLDR's inheritance rules rather than read out of a single locale's data.
        #
        # Anything still missing afterwards is a data bug. Raise rather than let it through:
        # `Worldwide::Cldr.t` degrades a missing key into a humanized version of its last
        # segment, so the alternative is silently handing back the string "wide".
        def complete_names(key, expected_keys, locale)
          names = Worldwide::Cldr.resolved_hash(key, locale: locale)
          missing = expected_keys - names.keys

          unless missing.empty?
            raise MissingCalendarDataError, "Missing CLDR data for '#{key}' in locale '#{locale}': #{missing.join(", ")}"
          end

          expected_keys.to_h { |name_key| [name_key, names.fetch(name_key)] }
        end
      end
    end
  end
end
