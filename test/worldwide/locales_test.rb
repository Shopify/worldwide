# frozen_string_literal: true

require "test_helper"

module Worldwide
  class LocalesTest < ActiveSupport::TestCase
    test "#each should allow locales to be enumerable" do
      Worldwide.locales.each do |locale|
        assert_not_nil locale
      end
    end

    test "#known should allow locales to be enumerable" do
      Worldwide.locales.known.each do |locale|
        assert_not_nil locale
      end
    end

    test "sub_locales returns a list of locales concatenated with region code for it" do
      assert_equal [:"it-CH", :"it-IT", :"it-SM", :"it-VA"], Worldwide.locale(code: "it").sub_locales.sort
    end

    test "sub_locales respects parent_locales" do
      # Example: `zh` is not a parent of `zh-Hant`
      expected = [:"zh-CN", :"zh-Hans", :"zh-Hans-CN", :"zh-Hans-HK", :"zh-Hans-MO", :"zh-Hans-SG"]

      assert_equal expected, Worldwide.locale(code: "zh").sub_locales.sort
    end

    test "sub_locales returns an empty array for an invalid locale" do
      assert_empty Worldwide.locale(code: "xx").sub_locales
    end

    test "sub_locales does not return other locales starting with the same letter but different locale" do
      assert_not_includes Worldwide.locale(code: "mg").sub_locales, "mgh-MZ"
    end
  end
end
