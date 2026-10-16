# frozen_string_literal: true

require "test_helper"

module Worldwide
  module Cldr
    class FallbacksTest < ActiveSupport::TestCase
      setup do
        @cldr_fallbacks = Worldwide::Cldr::Fallbacks.new
      end

      test "fallbacks does basic hyphen chopping" do
        assert_equal [:root], @cldr_fallbacks[:root]
        assert_equal [:en, :root], @cldr_fallbacks[:en]
        assert_equal [:"fr-CA", :fr, :root], @cldr_fallbacks[:"fr-CA"]
        assert_equal [:"zh-Hant-HK", :"zh-Hant", :root], @cldr_fallbacks[:"zh-Hant-HK"]
      end

      test "fallbacks observe explicit parent overrides" do
        # These get their info from parent_locales.yml
        assert_equal [:"az-Arab", :root], @cldr_fallbacks[:"az-Arab"]
        assert_equal [:"en-CH", :"en-150", :"en-001", :en, :root], @cldr_fallbacks[:"en-CH"]
        assert_equal [:"zh-Hant", :root], @cldr_fallbacks[:"zh-Hant"]
        assert_equal [:"zh-TW", :root], @cldr_fallbacks[:"zh-TW"]
      end

      test "copied locales have same fallbacks as the originals" do
        assert_equal @cldr_fallbacks[:"zh-Hant-HK"][1..], @cldr_fallbacks[:"zh-HK"][1..]
        assert_equal @cldr_fallbacks[:"zh-Hant"][1..], @cldr_fallbacks[:"zh-TW"][1..]
        assert_equal @cldr_fallbacks[:"zh-Hans"][1..], @cldr_fallbacks[:"zh-CN"][1..]
      end

      test "fallbacks work with string input" do
        assert_equal [:"en-CH", :"en-150", :"en-001", :en, :root], @cldr_fallbacks["en-CH"]
      end

      test "descendants finds expected locales" do
        assert_includes @cldr_fallbacks.descendants(:"en-001"), :"en-AU"
        assert_includes @cldr_fallbacks.descendants(:"es-419"), :"es-US"

        assert_equal :en, @cldr_fallbacks.descendants(:en).first
        assert_includes @cldr_fallbacks.descendants(:en), :"en-CA"
        assert_includes @cldr_fallbacks.descendants(:en), :"en-US"
        assert_includes @cldr_fallbacks.descendants(:en), :"en-001"

        refute_includes @cldr_fallbacks.descendants(:en), :fr
        refute_includes @cldr_fallbacks.descendants(:en), :"fr-CA"
        refute_includes @cldr_fallbacks.descendants(:en), :"fr-FR"
      end
    end
  end
end
