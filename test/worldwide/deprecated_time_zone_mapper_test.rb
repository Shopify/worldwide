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

    test "#to_supported returns nil when passed nil" do
      assert_nil Worldwide::DeprecatedTimeZoneMapper.to_supported(nil)
    end
  end
end
