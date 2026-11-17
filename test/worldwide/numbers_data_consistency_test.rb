# frozen_string_literal: true

require "test_helper"

# Assertions about the minimum grouping digits in data/cldr/locales/*/numbers.yml,
# which `rake cldr:data:patch` reads from the CLDR locale XML.

module Worldwide
  class NumbersDataConsistencyTest < ActiveSupport::TestCase
    setup do
      @minimum_grouping_digits = Dir[File.join(Worldwide::Paths::CLDR_ROOT, "locales", "*", "numbers.yml")].each_with_object({}) do |path, values|
        locale = File.basename(File.dirname(path))
        numbers = YAML.safe_load_file(path, permitted_classes: [Symbol]).fetch(locale).fetch("numbers", {})
        values[locale] = numbers["minimum_grouping_digits"] if numbers.key?("minimum_grouping_digits")
      end
    end

    test "every minimum_grouping_digits value is a positive Integer" do
      refute_empty @minimum_grouping_digits
      @minimum_grouping_digits.each do |locale, value|
        assert_kind_of Integer, value, locale
        assert_operator value, :>=, 1, locale
      end
    end

    test "minimum_grouping_digits has the CLDR value for locales that define it" do
      {
        "root" => 1,
        "en-GB" => 1,
        "de" => 1,
        "pl" => 2,
        "es" => 2,
        "es-419" => 1,
        "pt" => 1,
        "pt-PT" => 2,
        "pt-AO" => 1,
        "ru" => 1,
        "ru-UA" => 2,
        "ee" => 3,
      }.each do |locale, expected|
        assert_equal expected, @minimum_grouping_digits[locale], locale
      end
    end

    test "minimum_grouping_digits is only set where the CLDR locale defines it" do
      # es-MX inherits from es-419, pt-MZ from pt-PT, and en-IN from en-001 and en.
      # kab marks its value as unconfirmed, below the draft status that the import keeps.
      ["es-MX", "es-ES", "pt-BR", "pt-MZ", "en", "en-IN", "kab"].each do |locale|
        refute @minimum_grouping_digits.key?(locale), locale
      end
    end

    test "minimum_grouping_digits resolves through the CLDR fallbacks" do
      {
        "es-ES": 2,
        "es-MX": 1,
        "es-AR": 1,
        "pt-BR": 1,
        "pt-MZ": 2,
        "pt-AO": 1,
        "ru-UA": 2,
        "pl-PL": 2,
        "en-IN": 1,
        "zh-TW": 1,
        kab: 1,
      }.each do |locale, expected|
        assert_equal expected, Worldwide::Cldr.t("numbers.minimum_grouping_digits", locale: locale), locale
      end
    end
  end
end
