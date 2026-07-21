# frozen_string_literal: true

require "test_helper"

module Worldwide
  class CldrTest < ActiveSupport::TestCase
    test "applies the CLDR config and fallbacks while translating" do
      # Regression guard: on i18n 1.15 the config and fallbacks live in fiber
      # storage, so a Thread.current[:i18n_config] write is silently ignored and
      # the CLDR symbol lookup falls back to the ISO code ("EUR").
      assert_equal "€1,234.50 EUR", Worldwide.currency(code: :EUR).format_explicit(1234.5, locale: :"en-IE")
    end

    test "restores the previous config and fallbacks after translating" do
      before_config = I18n.config
      before_fallbacks = I18n.fallbacks

      Worldwide::Cldr.t("currencies.EUR.symbol", locale: :en, default: nil)

      assert_same before_config, I18n.config
      assert_same before_fallbacks, I18n.fallbacks
    end

    test "restores the previous config and fallbacks even when the translation raises" do
      before_config = I18n.config
      before_fallbacks = I18n.fallbacks

      assert_raises(I18n::MissingTranslationData) do
        Worldwide::Cldr.translate!(:__worldwide_cldr_missing_key__)
      end

      assert_same before_config, I18n.config
      assert_same before_fallbacks, I18n.fallbacks
    end

    test "preserves the host application's custom fallbacks across a translation" do
      old_fallbacks = I18n.fallbacks
      custom_fallbacks = I18n::Locale::Fallbacks.new([:"es-JP-POTATO"])
      I18n.fallbacks = custom_fallbacks

      Worldwide::Cldr.t("currencies.EUR.symbol", locale: :"en-IE", default: nil)

      assert_same(custom_fallbacks, I18n.fallbacks)
    ensure
      I18n.fallbacks = old_fallbacks
    end
  end
end
