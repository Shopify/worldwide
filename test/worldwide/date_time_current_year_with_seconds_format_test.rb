# frozen_string_literal: true

require "test_helper"

module Worldwide
  # `:date_time_current_year_with_seconds` is `:date_time_current_year` (a compact,
  # year-omitted "MMM d + time" timestamp) with the time upgraded to second precision.
  # It exists for cross-system log/event correlation, where the exact second matters.
  # Like the base format, each locale owns the field order, separators, and 12h/24h
  # clock (e.g. Vietnamese renders time-first; Danish uses "." separators; en stays 12h).
  class DateTimeCurrentYearWithSecondsFormatTest < ActiveSupport::TestCase
    # A fixed instant: 2018-12-26 13:23:45 UTC.
    SAMPLE = Time.utc(2018, 12, 26, 13, 23, 45)

    test "renders with each locale's own order, separators, and clock, always with seconds" do
      expected = {
        en: "Dec 26, 1:23:45 pm",        # 12-hour clock, comma separator
        "en-US": "Dec 26, 1:23:45 pm",   # en's own 12-hour clock
        fr: "26 déc. 13:23:45",          # 24-hour, day before month
        vi: "13:23:45, 26 Thg 12",       # time before the date
        da: "26. dec. 13.23.45",         # "." as the time separator
        ja: "12月26日 13:23:45",
        ko: "12월 26일 오후 1:23:45", # 12-hour with a localized pm marker
      }

      expected.each do |locale, string|
        assert_equal(
          string,
          I18n.l(SAMPLE, format: :date_time_current_year_with_seconds, locale: locale),
          "unexpected :date_time_current_year_with_seconds rendering for #{locale}",
        )
      end
    end

    test "is defined for every supported locale, always with a seconds field in the pattern" do
      # Assert on the raw strftime pattern rather than a rendered substring: this catches a
      # locale that falls back to a different format or drops seconds, which a digit check
      # against a sample time would miss.
      Worldwide::Locales.known.each do |locale|
        pattern = I18n.t("time.formats.date_time_current_year_with_seconds", locale: locale)

        assert_kind_of String, pattern, "#{locale} is missing :date_time_current_year_with_seconds"
        assert_match(/%-?S/, pattern, "#{locale} pattern has no seconds field: #{pattern.inspect}")
      end
    end
  end
end
