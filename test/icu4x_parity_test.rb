# frozen_string_literal: true

require "test_helper"

module Worldwide
  class Icu4xParityTest < ActiveSupport::TestCase
    TEST_LOCALES = ["en", "es", "fr", "de", "ja", "zh"].freeze
    TEST_NUMBERS = [1234.56, 0, 1, 2, 5, 10].freeze
    TEST_CURRENCIES = ["USD", "EUR", "JPY"].freeze

    test "number formatting works with Numbers API" do
      TEST_LOCALES.each do |locale_code|
        numbers = Worldwide::Numbers.new(locale: locale_code)

        TEST_NUMBERS.each do |number|
          ruby_formatted = numbers.format(number, decimal_places: 2)

          # For now, just verify Ruby formatting works
          # Later: compare with ICU4X output
          assert_kind_of(String, ruby_formatted)
          assert(!ruby_formatted.empty?)
        end
      end
    end

    test "currency formatting works with Currency API" do
      TEST_LOCALES.each do |locale_code|
        TEST_CURRENCIES.each do |currency_code|
          currency = Worldwide.currency(code: currency_code)
          amount = 1234.56

          ruby_formatted = currency.format_short(amount, locale: locale_code)

          # Verify Ruby currency formatting works
          assert_kind_of(String, ruby_formatted)
          assert(!ruby_formatted.empty?)
        end
      end
    end

    test "date formatting works with strftime" do
      TEST_LOCALES.each do |locale_code|
        I18n.with_locale(locale_code) do
          date = Time.new(2023, 12, 25, 14, 30, 0, "+00:00")

          # Use standard strftime for date formatting
          ruby_formatted = I18n.l(date, format: :long)

          # Verify Ruby date formatting works
          assert_kind_of(String, ruby_formatted)
          assert(!ruby_formatted.empty?)
        end
      end
    end

    test "territory names work with Region API" do
      TEST_LOCALES.each do |locale_code|
        # Test some common territories
        ["US", "CA", "GB", "FR", "DE", "JP"].each do |territory|
          region = Worldwide.region(code: territory)
          name = region.full_name(locale: locale_code)

          assert_kind_of(String, name)
          assert(!name.empty?)
        end
      end
    end

    test "YAML to JSON conversion works" do
      skip "Manual test - requires vendor/cldr-json cleanup"

      # Clean up any existing JSON data
      require "fileutils"
      json_dir = File.join(Dir.pwd, "vendor", "cldr-json")
      FileUtils.rm_rf(json_dir) if File.exist?(json_dir)

      # Run conversion
      system("bundle exec rake icu4x:convert", exception: true)

      # Verify JSON files exist
      assert(File.exist?(json_dir), "vendor/cldr-json directory should exist")

      # Check for at least some expected files
      en_numbers = File.join(json_dir, "cldr-numbers-full", "main", "en", "numbers.json")
      assert(File.exist?(en_numbers), "English numbers.json should exist")
    end

    test "full blob generation pipeline works" do
      skip "Manual test - requires full build and Rust toolchain"

      # Test the full pipeline
      system("bundle exec rake icu4x:all", exception: true)

      # Verify output files exist
      blob_path = File.join(Dir.pwd, "lang", "rust", "worldwide-icu4x-data", "data", "icu4x.postcard")
      assert(File.exist?(blob_path), "ICU4X blob should be generated")
      assert_operator(File.size(blob_path), :>, 1_000_000, "Blob should be > 1MB")

      # Verify Rust crate builds
      Dir.chdir(File.join(Dir.pwd, "lang", "rust")) do
        system("cargo build", exception: true)
        system("cargo test", exception: true)
      end
    end
  end
end
