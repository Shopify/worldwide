# frozen_string_literal: true

require "test_helper"

module Worldwide
  class TimeFormatterTest < ActiveSupport::TestCase
    test "hour minute separator is not nil" do
      Worldwide::Locales.each do |locale|
        formatter = TimeFormatter.new(locale: locale)

        refute_nil formatter.hour_minute_separator

        I18n.with_locale(locale) do
          refute_nil TimeFormatter.new.hour_minute_separator
        end
      end
    end

    test "hour_minute_separator returns the expected separators" do
      data = {
        "en-US": ":",
        "fr-CA": " h ",
        "da-DK": ".",
      }

      data.each do |locale, expected_separator|
        formatter = TimeFormatter.new(locale: locale)

        assert_equal expected_separator, formatter.hour_minute_separator

        I18n.with_locale(locale) do
          assert_equal expected_separator, TimeFormatter.new.hour_minute_separator
        end
      end
    end

    test "twelve_hour_clock? returns expected values for a selected sample of locales" do
      data = {
        "de-DE": false,
        "en-DK": false,
        "en-US": true,
        "fr-FR": false,
        "zh-CN": false,
      }

      data.each do |locale, expected|
        assert_equal "#{locale} #{expected}", "#{locale} #{TimeFormatter.new(locale: locale).twelve_hour_clock?}"

        I18n.with_locale(locale) do
          assert_equal "#{locale} #{expected}", "#{locale} #{TimeFormatter.new.twelve_hour_clock?}"
        end
      end
    end
  end
end
