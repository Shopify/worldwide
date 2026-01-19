# frozen_string_literal: true

require "test_helper"

module Worldwide
  class NamesFallbackTest < ActiveSupport::TestCase
    setup do
      @original_exception_handler = I18n.exception_handler
    end

    teardown do
      I18n.exception_handler = @original_exception_handler
    end

    test "full falls back to English when translation is missing" do
      I18n.exception_handler = I18n::ExceptionHandler.new

      I18n.with_locale(:uk) do
        result = Names.full(given: "John", surname: "Smith")
        assert_equal("John Smith", result)
        refute_match(/Translation missing/, result)
      end
    end

    test "greeting falls back to English when translation is missing" do
      I18n.exception_handler = I18n::ExceptionHandler.new

      I18n.with_locale(:uk) do
        result = Names.greeting(given: "John", surname: "Smith")
        assert_equal("John", result)
        refute_match(/Translation missing/, result)
      end
    end

    test "full works normally for supported locales" do
      I18n.exception_handler = I18n::ExceptionHandler.new

      I18n.with_locale(:en) do
        result = Names.full(given: "John", surname: "Smith")
        assert_equal("John Smith", result)
      end
    end

    test "full handles Japanese name ordering for supported locales" do
      I18n.exception_handler = I18n::ExceptionHandler.new

      I18n.with_locale(:ja) do
        result = Names.full(given: "太郎", surname: "山田")
        assert_equal("山田太郎", result)
      end
    end
  end
end
