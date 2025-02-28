# frozen_string_literal: true

require "test_helper"

module Worldwide
  class PluralizationHelperTest < ActiveSupport::TestCase
    class TestClass
      include PluralizationHelper
    end

    setup do
      @instance = TestClass.new
      @key = "key"
    end

    attr_reader :instance, :key

    test "#translate_plural translates pluralization key for en-US" do
      locale = :"en-US"
      expected = "Test"
      count = 3
      Worldwide::Cldr.expects(:fallbacks).at_least_once.returns({ locale => [:"en-US", :en] })
      Worldwide::Cldr.expects(:t).with(key, locale: locale, count: count).returns(expected)

      actual = instance.translate_plural(key, locale: locale, count: count)

      assert_equal expected, actual
    end

    test "#translate_plural falls back to en when en-US raises exception" do
      locale = :"en-US"
      expected = "Test"
      count = 3
      Worldwide::Cldr.expects(:fallbacks).at_least_once.returns({ locale => [:"en-US", :en] })
      Worldwide::Cldr.expects(:t).with(key, locale: locale, count: count)
        .raises(I18n::InvalidPluralizationData.new({ one: "One" }, count, "other"))
      Worldwide::Cldr.expects(:t).with(key, locale: :en, count: count)
        .returns(expected)

      actual = instance.translate_plural(key, locale: locale, count: count)

      assert_equal expected, actual
    end

    test "#translate_plural raises InvalidPluralizationData exception when en and en-US raises exception" do
      locale = :"en-US"
      count = 3
      Worldwide::Cldr.expects(:fallbacks).at_least_once.returns({ locale => [:"en-US", :en] })
      Worldwide::Cldr.expects(:t).with(key, locale: locale, count: count)
        .raises(I18n::InvalidPluralizationData.new({ many: "One" }, count, "other"))
      Worldwide::Cldr.expects(:t).with(key, locale: :en, count: count)
        .raises(I18n::InvalidPluralizationData.new({ many: "One" }, count, "other"))

      err = assert_raises(I18n::InvalidPluralizationData) do
        instance.translate_plural(key, locale: locale, count: count)
      end

      if RUBY_VERSION < "3.4"
        assert_equal "translation data {:many=>\"One\"} can not be used with :count => #{count}. key 'other' is missing.", err.message
      else
        assert_equal "translation data {many: \"One\"} can not be used with :count => #{count}. key 'other' is missing.", err.message
      end
    end
  end
end
