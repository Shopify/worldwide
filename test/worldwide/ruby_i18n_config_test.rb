# frozen_string_literal: true

require "set"
require "test_helper"

module Worldwide
  class RubyI18nConfigTest < ActiveSupport::TestCase
    test "setters don't affect class variables" do
      config_1 = Worldwide::RubyI18nConfig.new
      config_2 = Worldwide::RubyI18nConfig.new

      attributes = {
        available_locales: [],
        backend: I18n::Backend::Simple.new,
        default_locale: :"ja-JP",
        default_separator: "-",
        enforce_available_locales: nil,
        exception_handler: nil,
        interpolation_patterns: nil,
        load_path: [],
        locale: :fr,
        missing_interpolation_argument_handler: nil,
      }

      attributes.keys.each do |attribute|
        assert_equal config_1.send(attribute), config_2.send(attribute), "Attribute `#{attribute}` doesn't have the same value, despite being brand new."
      end

      attributes.each do |attribute, new_value|
        setter = "#{attribute}=".to_sym
        config_2.send(setter, new_value)
      end

      attributes.keys.each do |attribute|
        assert_not_equal config_1.send(attribute), config_2.send(attribute), "Attribute `#{attribute}` still has the same value, despite being modified."
      end

      attributes.keys.each do |attribute|
        instance_variable = "@#{attribute}".to_sym
        config_2.remove_instance_variable(instance_variable)
      end

      attributes.keys.each do |attribute|
        assert_equal config_1.send(attribute), config_2.send(attribute), "Attribute `#{attribute}` still has a different value, despite the instance variable being removed."
      end
    end

    test "#available_locales_set caches the @available_locales instance variable, and can be reset using #clear_available_locales_set" do
      config = Worldwide::RubyI18nConfig.new
      class_level_available_locales = config.available_locales
      expected_class_level_available_locales_set = Set.new(class_level_available_locales) + Set.new(class_level_available_locales.map(&:to_s))

      assert_equal expected_class_level_available_locales_set, config.available_locales_set # Sanity

      # Override available_locales
      config.available_locales = [:"ja-JP"]

      assert_not_equal class_level_available_locales, config.available_locales # Sanity
      assert_equal Set.new([:"ja-JP", "ja-JP"]), config.available_locales_set

      # Override modify overriden available_locales
      config.available_locales += [:fr]

      assert_equal Set.new([:fr, "fr", :"ja-JP", "ja-JP"]), config.available_locales_set
      config.clear_available_locales_set

      assert_equal Set.new([:fr, "fr", :"ja-JP", "ja-JP"]), config.available_locales_set

      # Remove available_locales override
      config.remove_instance_variable(:@available_locales)

      assert_equal class_level_available_locales, config.available_locales
      assert_equal expected_class_level_available_locales_set, config.available_locales_set
    end

    test "#available_locales_initialized?" do
      config = Worldwide::RubyI18nConfig.new
      config.available_locales = nil

      refute_predicate config, :available_locales_initialized?
      config.available_locales = [:"ja-JP"]

      assert_predicate config, :available_locales_initialized?
    end
  end
end
