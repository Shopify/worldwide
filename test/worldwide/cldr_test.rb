# frozen_string_literal: true

require "test_helper"
require "active_support/core_ext/object/deep_dup"
require "minitest/mock"

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

    test "keeps buyer Serbian Latin separate from explicit Cyrillic locales" do
      assert_equal "januar", Worldwide::Cldr.t("date.month_names", locale: :sr).fetch(1)
      assert_equal "Danas u %02k:%M", Worldwide::Cldr.t("date.formats.today_at_time", locale: :sr)
      assert_equal "Sjedinjene Države", Worldwide::Cldr.t("territories.US", locale: :sr)
      assert_equal "Evro", Worldwide::Cldr.t("currencies.EUR.name", locale: :sr)
      assert_equal "engleski", Worldwide::Cldr.t("languages.en", locale: :sr)
      assert_equal(
        "(GMT-07:00) Britanska Kolumbija",
        Worldwide::Cldr.t("timezones.America/Vancouver", locale: :sr),
      )

      I18n.with_locale(:sr) do
        assert_equal "Sjedinjene Države", Worldwide::Cldr.t("territories.US")
      end

      assert_equal "Danas u %02k:%M", Worldwide::Cldr.t("date.formats.today_at_time", locale: :"sr-Latn")
      assert_equal "јануар", Worldwide::Cldr.t("date.month_names", locale: :"sr-Cyrl").fetch(1)
      assert_equal "%02k:%M данас", Worldwide::Cldr.t("date.formats.today_at_time", locale: :"sr-Cyrl")
      assert_equal "Сједињене Државе", Worldwide::Cldr.t("territories.US", locale: :"sr-Cyrl")
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

    test "applies the CLDR fallbacks for hosts that read fallbacks from Thread.current" do
      # Mirrors hosts that patch I18n.fallbacks to read the slot used before i18n 1.15.
      # English short lumens only exist in root, so the lookup needs the CLDR chain.
      original_thread_fallbacks = Thread.current[:i18n_fallbacks]
      host_fallbacks = I18n::Locale::Fallbacks.new([:en])
      Thread.current[:i18n_fallbacks] = host_fallbacks

      I18n.stub(:fallbacks, -> { Thread.current[:i18n_fallbacks] }) do
        assert_equal("800 lm", Worldwide.units.format(800, :lumens))
      end

      assert_same(host_fallbacks, Thread.current[:i18n_fallbacks])
    ensure
      Thread.current[:i18n_fallbacks] = original_thread_fallbacks
    end

    test "#resolved_hash follows a CLDR alias against the requested locale" do
      assert_equal "Sunday", Worldwide::Cldr.resolved_hash(
        "calendars.gregorian.days.stand_alone.wide",
        locale: :en,
      ).fetch(:sun)
    end

    test "#resolved_hash merges locale contributions from the fallback chain" do
      key = "calendars.gregorian.months.stand_alone.abbreviated"

      assert_equal({ 9 => "Sept" }, Worldwide::Cldr.t(key, locale: :"en-CA"))

      resolved = Worldwide::Cldr.resolved_hash(key, locale: :"en-CA")

      assert_equal (1..12).to_a, resolved.keys.sort
      assert_equal "Jan", resolved.fetch(1)
      assert_equal "Sept", resolved.fetch(9)
    end

    test "#resolved_hash returns an empty hash for a missing node" do
      assert_empty Worldwide::Cldr.resolved_hash("calendars.gregorian.__missing__.wide", locale: :en)
    end

    test "#resolved_hash does not mutate the source translations" do
      key = "calendars.gregorian.months"
      parent_data = Worldwide::Cldr.t(key, locale: :en, fallback: false, resolve: false).deep_dup

      Worldwide::Cldr.resolved_hash(key, locale: :"en-CA")

      assert_equal parent_data, Worldwide::Cldr.t(key, locale: :en, fallback: false, resolve: false)
    end
  end
end
