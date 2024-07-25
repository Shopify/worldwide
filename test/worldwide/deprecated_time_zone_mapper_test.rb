# frozen_string_literal: true

require "test_helper"

module Worldwide
  class TimeZoneTest < ActiveSupport::TestCase
    test "#to_supported converts as expected" do
      data = [
        ["Africa/Abidjan", "Africa/Abidjan"],
        ["America/Toronto", "America/Toronto"],
        ["Australia/NSW", "Australia/Sydney"],
        ["Canada/Eastern", "America/Toronto"],
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

    test "#to_rails converts as expected" do
      iana_data_input_expected.each do |input, expected|
        actual = Worldwide::DeprecatedTimeZoneMapper.to_rails(input)

        assert_equal expected, actual
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
