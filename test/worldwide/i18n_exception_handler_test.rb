# frozen_string_literal: true

require "test_helper"

module Worldwide
  class I18nExceptionHandlerTest < ActiveSupport::TestCase
    test "passes along exceptions that aren't I18n::MissingTranslation" do
      with_handler do
        I18n.exception_handler
          .expects(:log_missing)
          .never

        I18n.exception_handler
          .expects(:report_error)
          .never

        exception = I18n::InvalidPluralizationData.new({}, 1, "abcd.efg")
        exc = assert_raises(I18n::InvalidPluralizationData) do
          I18n.exception_handler.call(exception, :fr, "abcd.efg", {})
        end

        assert_equal "translation data {} can not be used with :count => 1. key 'abcd.efg' is missing.", exc.message
      end
    end

    test "logs and reports missing translation" do
      with_handler do
        I18n.exception_handler
          .expects(:log_missing)
          .twice

        I18n.exception_handler
          .expects(:report_error)

        I18n.with_locale(:fi) do
          assert_equal("def", I18n.translate("abc.def"))
        end
      end
    end

    test "missing translation for a non-`en` locale will fallback to the context passed as argument" do
      context = mock
      context.expects(:default_locale).returns(:en)
      context.expects(:t).with(:test, a: 1, locale: :en).returns("Test fallback")

      options = { a: 1 }
      exception = I18n::MissingTranslation.new(:fr, :test, **options)

      with_handler do
        assert_equal(
          "Test fallback",
          I18n.exception_handler.call(exception, exception.locale, exception.key, options, context),
        )
      end
    end

    test "missing translations with custom separator" do
      with_handler do
        assert_equal("interesting entry", I18n.translate("abc-def-interesting_entry", separator: "-"))
      end
    end

    private

    def with_handler
      old_handler = I18n.exception_handler
      I18n.exception_handler = I18nExceptionHandler.new
      yield
    ensure
      I18n.exception_handler = old_handler
    end
  end
end
