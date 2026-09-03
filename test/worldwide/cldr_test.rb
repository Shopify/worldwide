# frozen_string_literal: true

require "test_helper"

module Worldwide
  class CldrTest < ActiveSupport::TestCase
    test "selects storage based on i18n config behavior" do
      expected_storage = I18n::Config.method_defined?(:owned_by?) ? Cldr::FiberStorage : Cldr::ThreadStorage

      assert_same expected_storage, Cldr::STORAGE
    end

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

    test "#resolved_hash follows a CLDR alias and reads it back in the requested locale" do
      # `en` has no `days.stand_alone.wide` of its own: `root` holds an alias to
      # `days.format.wide`, which has to be resolved against `en`, not against `root`.
      assert_nil Worldwide::Cldr.t("calendars.gregorian.days.stand_alone.wide", locale: :en, default: nil, fallback: false)
      assert_equal "Sun", Worldwide::Cldr.t("calendars.gregorian.days.format.wide", locale: :root)[:sun]

      assert_equal "Sunday", Worldwide::Cldr.resolved_hash("calendars.gregorian.days.stand_alone.wide", locale: :en)[:sun]
    end

    test "#resolved_hash merges every ancestor rather than stopping at the first match" do
      # `en-CA` overrides only September, so `t` returns a single entry.
      assert_equal({ 9 => "Sept" }, Worldwide::Cldr.t("calendars.gregorian.months.stand_alone.abbreviated", locale: :"en-CA"))

      resolved = Worldwide::Cldr.resolved_hash("calendars.gregorian.months.stand_alone.abbreviated", locale: :"en-CA")

      assert_equal (1..12).to_a, resolved.keys.sort
      assert_equal "Sept", resolved[9]
      assert_equal "Jan", resolved[1]
    end

    test "#resolved_hash returns an empty hash for a missing key instead of degrading it" do
      # `t` humanizes the last segment of a key it cannot find, which is how a missing
      # weekday lookup used to come back as the string "wide".
      assert_equal "wide", Worldwide::Cldr.t("calendars.gregorian.__missing__.wide", locale: :en)

      assert_empty Worldwide::Cldr.resolved_hash("calendars.gregorian.__missing__.wide", locale: :en)
    end
  end
end
