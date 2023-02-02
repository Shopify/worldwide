# frozen_string_literal: true

module Worldwide
  module Calendar
    class Gregorian
      class << self
        # We intentionally don't support `short` weekday names, as we haven't found anyone asking for them.
        # People usually want the full weekday name, or the abbreviated version.
        VALID_WEEKDAY_WIDTHS = [:abbreviated, :narrow, :wide].freeze
        def weekday_names(width: :wide, locale: I18n.locale)
          raise ArgumentError, "Invalid width: #{width}" unless VALID_WEEKDAY_WIDTHS.include?(width)

          Worldwide::Cldr.t("calendars.gregorian.days.stand_alone.#{width}", locale: locale)
        end

        VALID_MONTH_WIDTHS = [:abbreviated, :narrow, :wide].freeze
        def month_names(width: :wide, locale: I18n.locale)
          raise ArgumentError, "Invalid width: #{width}" unless VALID_MONTH_WIDTHS.include?(width)

          Worldwide::Cldr.t("calendars.gregorian.months.stand_alone.#{width}", locale: locale).values
        end

        def quarter(date, locale: I18n.locale)
          format_string = Worldwide::Cldr.t("calendars.gregorian.additional_formats.yQQQ", locale: locale)
          Worldwide::Cldr::DateFormatPattern.format(date, format_string, locale: locale)
        end
      end
    end
  end
end
