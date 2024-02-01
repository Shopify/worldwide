# frozen_string_literal: true

require "test_helper"

module Worldwide
  class ConfigTest < ActiveSupport::TestCase
    test ".expanded_locales_from_configuration when passing in nil" do
      locales = Worldwide::Config.send(:expanded_locales_from_configuration, Worldwide::RubyI18nConfig.new)

      assert_empty I18n.available_locales.map(&:to_s) - locales
      assert_includes locales, "root"
    end

    test ".expanded_locales_from_configuration uses I18n.default_locale when I18n.available_locales is empty" do
      config = Worldwide::RubyI18nConfig.new
      config.default_locale = :en
      config.available_locales = []

      expanded_locales = Worldwide::Config.send(:expanded_locales_from_configuration, config)

      ["en", "root"].each do |locale|
        assert_includes expanded_locales, locale
      end
    end

    test ".expanded_locales_from_configuration when they have customized I18n.available_locales" do
      config = Worldwide::RubyI18nConfig.new
      config.available_locales = [:en, :fr, :de]

      expanded_locales = Worldwide::Config.send(:expanded_locales_from_configuration, config)

      ["de", "en", "fr", "root"].each do |locale|
        assert_includes expanded_locales, locale
      end
    end

    test ".expanded_locales_from_configuration when they have customized I18n.fallbacks" do
      old_fallbacks = I18n.fallbacks
      I18n.fallbacks = I18n::Locale::Fallbacks.new([:"es-JP-POTATO"]) # Everything falls back to this strange locale.

      config = Worldwide::RubyI18nConfig.new
      config.available_locales = [:en, :fr, :de]

      expanded_locales = Worldwide::Config.send(:expanded_locales_from_configuration, config)

      ["de", "en", "es", "es-JP", "es-JP-POTATO", "fr", "root"].each do |locale|
        assert_includes(expanded_locales, locale)
      end
    ensure
      I18n.fallbacks = old_fallbacks
    end

    test "#configure_i18n extends I18n.available_locales to include derivatives of the specified locales" do
      config = Worldwide::RubyI18nConfig.new
      config.available_locales = [:en, :fr]

      Worldwide::Config.configure_i18n(i18n_config: config)

      [:en, :"en-GB", :"en-US", :fr, :"fr-CA", :"fr-CH", :"fr-FR"].each do |locale|
        assert_includes config.available_locales, locale, "Expected #{locale.inspect} to be available"
      end
    end

    test "#configure_i18n does not expand locales when expand_locales: false is passed" do
      config = Worldwide::RubyI18nConfig.new
      config.available_locales = [:en, :fr]

      Worldwide::Config.configure_i18n(i18n_config: config, expand_locales: false)

      assert_equal [:en, :fr], config.available_locales
    end

    test "#configure consults parent_locales.yml when determining derivatives of locales" do
      config = Worldwide::RubyI18nConfig.new
      config.available_locales = [:"en-001"]

      Worldwide::Config.configure_i18n(i18n_config: config)

      assert_includes config.available_locales, :"en-US"
    end

    test "#configure applies changes to I18n.config by default" do
      I18n.config.expects(:enforce_available_locales=).never
      I18n.config.expects(:load_path=).times(4)

      assert_instance_of I18n::Config, Worldwide::Config.configure_i18n
    end

    test "#configure sets enforce_available_locales to true if not explicitly set" do
      config = Worldwide::RubyI18nConfig.new
      Worldwide::Config.configure_i18n(i18n_config: config)

      assert config.enforce_available_locales
    end

    test "#configure sets default_locale to :en if not explicitly set" do
      config = Worldwide::RubyI18nConfig.new

      original_default_locale = I18n.config.class.remove_class_variable(:@@default_locale)

      Worldwide::Config.configure_i18n(i18n_config: config)

      assert_equal(:en, config.default_locale)
    ensure
      I18n.default_locale = original_default_locale
    end

    test "#configure does not set default_locale if explicitly set" do
      config = Worldwide::RubyI18nConfig.new
      config.default_locale = :fr

      Worldwide::Config.configure_i18n(i18n_config: config)

      assert_equal :fr, config.default_locale
    end

    test "#configure sets exception_handler to our custom handler" do
      config = Worldwide::RubyI18nConfig.new
      original_exception_handler = I18n.config.class.remove_class_variable(:@@exception_handler)

      Worldwide::Config.configure_i18n(i18n_config: config)

      assert_instance_of(Worldwide::I18nExceptionHandler, config.exception_handler)
    ensure
      I18n.exception_handler = original_exception_handler
    end
  end
end
