# frozen_string_literal: true

require "test_helper"

module Worldwide
  class TimeZoneTest < ActiveSupport::TestCase
    test "#to_supported converts as expected" do
      data = [
        ["Africa/Abidjan", "Africa/Abidjan"],
        ["America/Toronto", "America/Toronto"],
        ["Australia/NSW", "Australia/Sydney"],
        ["Canada/Central", "America/Winnipeg"],
        ["Canada/Eastern", "America/Toronto"],
        ["Canada/Mountain", "America/Edmonton"],
        ["Canada/Pacific", "America/Vancouver"],
        ["Canada/Yukon", "America/Whitehorse"],
        ["Europe/Berlin", "Europe/Berlin"],
        ["Iran", "Asia/Tehran"],
        ["PRC", "Asia/Shanghai"],
        ["ROC", "Asia/Taipei"],
      ]

      data.each do |input, expected|
        actual = Worldwide::DeprecatedTimeZoneMapper.to_supported(input)

        assert_equal expected, actual
      end
    end

    test "#to_supported keeps Rainy River on Central Time without changing Winnipeg" do
      actual = Worldwide::DeprecatedTimeZoneMapper.to_supported("America/Rainy_River")

      assert_equal "America/Chicago", actual
      assert_equal "America/Winnipeg", Worldwide::DeprecatedTimeZoneMapper.to_supported("America/Winnipeg")

      zone = ActiveSupport::TimeZone.new(actual)

      {
        Time.utc(2026, 7, 15) => -5 * 3600,
        Time.utc(2026, 11, 1, 6, 59, 59) => -5 * 3600,
        Time.utc(2026, 11, 1, 7) => -6 * 3600,
        Time.utc(2026, 12, 15) => -6 * 3600,
        Time.utc(2027, 7, 15) => -5 * 3600,
      }.each do |time, expected_offset|
        assert_equal expected_offset, zone.tzinfo.period_for_utc(time).utc_total_offset, "Rainy River has the wrong offset at #{time}"
      end
    end

    test "#to_rails converts as expected" do
      iana_data_input_expected.each do |input, expected|
        actual = Worldwide::DeprecatedTimeZoneMapper.to_rails(input)

        assert_equal expected, actual
      end
    end

    test "#to_rails maps permanent Canadian zones to curated Rails equivalents" do
      {
        "America/Vancouver" => "America/Phoenix",
        "America/Whitehorse" => "America/Phoenix",
        "America/Dawson" => "America/Phoenix",
        "America/Edmonton" => "America/Regina",
        "America/Yellowknife" => "America/Regina",
        "America/Inuvik" => "America/Regina",
        "America/Winnipeg" => "America/Bogota",
      }.each do |name, expected|
        actual = Worldwide::DeprecatedTimeZoneMapper.to_rails(name)

        assert_equal expected, actual
        assert_not_nil ActiveSupport::TimeZone::MAPPING.key(actual), "#{name} has no Rails-friendly fallback name"
      end
    end

    test "#to_rails maps Canadian aliases to curated Rails equivalents" do
      {
        "Canada/Central" => "America/Bogota",
        "Canada/Mountain" => "America/Regina",
        "Canada/Pacific" => "America/Phoenix",
        "Canada/Yukon" => "America/Phoenix",
      }.each do |name, expected|
        assert_equal expected, Worldwide::DeprecatedTimeZoneMapper.to_rails(name)
      end
    end

    test "#to_rails keeps the Ontario Central-time fallback for Rainy River" do
      assert_equal "America/Chicago", Worldwide::DeprecatedTimeZoneMapper.to_rails("America/Rainy_River")
    end

    test "#to_rails keeps permanent Canadian fallback offsets in winter and summer" do
      {
        "America/Vancouver" => -7 * 3600,
        "America/Whitehorse" => -7 * 3600,
        "America/Edmonton" => -6 * 3600,
        "America/Yellowknife" => -6 * 3600,
        "America/Inuvik" => -6 * 3600,
        "America/Winnipeg" => -5 * 3600,
      }.each do |name, expected_offset|
        zone = ActiveSupport::TimeZone[Worldwide::DeprecatedTimeZoneMapper.to_rails(name)]

        [Time.utc(2026, 12, 15), Time.utc(2027, 7, 15)].each do |time|
          assert_equal expected_offset, zone.tzinfo.period_for_utc(time).utc_total_offset, "#{name} has the wrong fallback offset at #{time}"
        end
      end
    end

    test "#to_supported returns nil when passed nil" do
      assert_nil Worldwide::DeprecatedTimeZoneMapper.to_supported(nil)
    end

    test "#to_rails returns nil when passed nil" do
      assert_nil Worldwide::DeprecatedTimeZoneMapper.to_rails(nil)
    end

    test "#to_rails returns nil when passed an unsupported timezone" do
      assert_nil Worldwide::DeprecatedTimeZoneMapper.to_rails("Timezone/Unsupported")
    end

    private

    def iana_data_input_expected
      [
        ["Africa/Abidjan", "Africa/Monrovia"],
        ["Africa/Monrovia", "Africa/Monrovia"],
        ["Africa/Nairobi", "Africa/Nairobi"],
        ["America/Argentina/Buenos_Aires", "America/Argentina/Buenos_Aires"],
        ["America/Argentina/Catamarca", "America/Argentina/Buenos_Aires"],
        ["Asia/Dhaka", "Asia/Dhaka"],
        ["Etc/UTC", "Etc/UTC"],
        ["Etc/Zulu", "Etc/UTC"],
      ]
    end
  end
end
