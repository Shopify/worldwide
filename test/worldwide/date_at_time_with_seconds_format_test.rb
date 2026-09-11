# frozen_string_literal: true

require "test_helper"

module Worldwide
  # `:date_at_time_with_seconds` is a compact, 24-hour, second-precision timestamp
  # (abbreviated month + day, year omitted) whose ordering and separators are owned
  # by each locale. It exists for cross-system log/event correlation, where the exact
  # second matters and an unambiguous 24-hour clock is preferable to a localized am/pm.
  class DateAtTimeWithSecondsFormatTest < ActiveSupport::TestCase
    # A fixed instant: 2018-12-26 13:23:45 UTC.
    SAMPLE = Time.utc(2018, 12, 26, 13, 23, 45)

    test "renders with locale-controlled order and separators on a 24-hour clock" do
      expected = {
        en: "Dec 26, 13:23:45",        # comma separator, 24-hour clock
        "en-US": "Dec 26, 13:23:45",   # 24h even though en-US defaults to a 12-hour clock
        fr: "26 déc. 13:23:45",        # day before month
        vi: "13:23:45, 26 Thg 12",     # time before date
        da: "26. dec. 13.23.45",       # "." as the time separator
        ja: "12月26日 13:23:45",
        ko: "12월 26일 13시 23분 45초",
      }

      expected.each do |locale, string|
        assert_equal(
          string,
          I18n.l(SAMPLE, format: :date_at_time_with_seconds, locale: locale),
          "unexpected :date_at_time_with_seconds rendering for #{locale}",
        )
      end
    end

    test "is defined for every supported locale, always with second precision on a 24-hour clock" do
      Worldwide::Locales.known.each do |locale|
        rendered = I18n.l(SAMPLE, format: :date_at_time_with_seconds, locale: locale)

        assert_includes rendered, "45", "#{locale} is missing seconds"
        assert_includes rendered, "13", "#{locale} is not using a 24-hour clock"
      end
    end
  end
end
