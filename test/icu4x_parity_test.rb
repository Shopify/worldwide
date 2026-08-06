# frozen_string_literal: true

require "test_helper"
require "open3"
require "json"

module Worldwide
  class Icu4xParityTest < ActiveSupport::TestCase
    # Path to the parity CLI binary (workspace root target dir)
    PARITY_CLI = File.expand_path("../target/release/worldwide-icu4x-parity", __dir__)

    # Known differences between Ruby and ICU4X implementations.
    # These are documented discrepancies, not bugs in the parity test.
    # In all cases, ICU4X is correct per CLDR spec; Ruby has bugs in ruby-cldr's parser.
    # Fixing Ruby would be a breaking change for worldwide users.
    #
    # Portuguese (pt, pt-PT): Ruby says 0 is "other", ICU4X says "one"
    #   - CLDR YAML rule: `one: i = 0..1` (meaning 0 and 1 should both be "one")
    #   - ruby-cldr generates: `n.to_i == 1` (only matches 1, not 0)
    #
    # Breton (br): Ruby says 13, 14, 19 are "few", ICU4X says "other"
    #   - CLDR YAML rule: `few: n % 10 = 3..4,9 and n % 100 != 10..19,70..79,90..99`
    #   - 13, 14, 19 have n % 100 in 10..19, so they should be "other"
    #   - ruby-cldr incorrectly parses the exclusion ranges
    KNOWN_DIFFERENCES = {
      "pt/0" => { ruby: "other", icu4x: "one" },
      "pt-PT/0" => { ruby: "other", icu4x: "one" },
      "br/13" => { ruby: "few", icu4x: "other" },
      "br/14" => { ruby: "few", icu4x: "other" },
      "br/19" => { ruby: "few", icu4x: "other" },
    }.freeze

    # Comprehensive set of numbers that exercise all plural categories across languages:
    # - 0: zero category (Arabic, Welsh, etc.)
    # - 1: one category (most languages)
    # - 2: two category (Arabic, Welsh, Slovenian, etc.)
    # - 3-4: few category (Slavic languages, etc.)
    # - 5-10: transitions between categories
    # - 11-14: special cases (e.g., English ordinals, Russian)
    # - 20-25: cycling through categories again
    # - 100-102: large number behavior
    # - 1000000: million (for "many" in some languages like Portuguese)
    EXHAUSTIVE_TEST_NUMBERS = [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
      11, 12, 13, 14, 15, 19, 20, 21, 22, 23, 24, 25,
      100, 101, 102, 103, 111, 112, 121, 122,
    ].freeze

    class << self
      attr_accessor :parity_cli_available
    end

    setup do
      unless File.executable?(PARITY_CLI)
        skip "ICU4X parity CLI not built. Run: cargo build -p worldwide-icu4x-parity --release"
      end
    end

    # Helper to call the ICU4X parity CLI
    def icu4x_call(request)
      output, status = Open3.capture2(
        PARITY_CLI,
        stdin_data: request.to_json,
      )
      raise "ICU4X parity CLI failed: #{output}" unless status.success?

      JSON.parse(output)
    end

    def icu4x_plural_cardinal(locale:, number:)
      result = icu4x_call(op: "plural_cardinal", locale: locale, number: number)
      if result["error"]
        raise "ICU4X error for #{locale}/#{number}: #{result["error"]}"
      end

      result["result"]
    end

    def icu4x_plural_ordinal(locale:, number:)
      result = icu4x_call(op: "plural_ordinal", locale: locale, number: number)
      if result["error"]
        raise "ICU4X error for #{locale}/#{number}: #{result["error"]}"
      end

      result["result"]
    end

    # Get Ruby's plural category for cardinal numbers
    def ruby_plural_cardinal(locale:, number:)
      Worldwide::Plurals.send(:cardinal_key_for, locale, number).to_s
    end

    # Get all locales that have plural rules
    def all_plural_locales
      locales_dir = File.join(Worldwide::Paths::CLDR_ROOT, "locales")
      Dir.glob(File.join(locales_dir, "*", "plurals.rb")).map do |path|
        File.basename(File.dirname(path))
      end.reject { |l| l == "root" }.sort
    end

    # =========================================================================
    # Exhaustive Cardinal Plural Tests - One test per locale
    # =========================================================================

    # Dynamically generate a test for each locale with plural rules
    # This creates ~170 individual tests, one per locale
    PLURAL_LOCALES = begin
      locales_dir = File.expand_path("../data/cldr/locales", __dir__)
      Dir.glob(File.join(locales_dir, "*", "plurals.rb")).map do |path|
        File.basename(File.dirname(path))
      end.reject { |l| l == "root" }.sort
    end

    PLURAL_LOCALES.each do |locale|
      test "cardinal plural parity for #{locale} (exhaustive)" do
        failures = []

        EXHAUSTIVE_TEST_NUMBERS.each do |number|
          key = "#{locale}/#{number}"

          # Skip known differences
          next if KNOWN_DIFFERENCES.key?(key)

          ruby_result = ruby_plural_cardinal(locale: locale, number: number)

          begin
            icu4x_result = icu4x_plural_cardinal(locale: locale, number: number)
          rescue => e
            failures << "#{number}: ICU4X error - #{e.message}"
            next
          end

          if ruby_result != icu4x_result
            failures << "#{number}: Ruby=#{ruby_result}, ICU4X=#{icu4x_result}"
          end
        end

        assert_empty failures, "Cardinal plural mismatches for #{locale}:\n#{failures.join("\n")}"
      end
    end

    # =========================================================================
    # Known Differences Tests
    # =========================================================================

    test "known differences are documented correctly" do
      KNOWN_DIFFERENCES.each do |key, expected|
        locale, number = key.split("/")
        number = number.to_i

        ruby_result = ruby_plural_cardinal(locale: locale, number: number)
        icu4x_result = icu4x_plural_cardinal(locale: locale, number: number)

        assert_equal expected[:ruby], ruby_result,
          "Ruby result for #{key} doesn't match documented value"
        assert_equal expected[:icu4x], icu4x_result,
          "ICU4X result for #{key} doesn't match documented value"
      end
    end

    # =========================================================================
    # Basic API Tests
    # =========================================================================

    test "ICU4X parity CLI responds to plural_cardinal" do
      result = icu4x_call(op: "plural_cardinal", locale: "en", number: 1)

      assert_equal "one", result["result"]
      assert_nil result["error"]
    end

    test "ICU4X parity CLI responds to plural_ordinal" do
      result = icu4x_call(op: "plural_ordinal", locale: "en", number: 1)

      assert_equal "one", result["result"]
      assert_nil result["error"]
    end

    test "ICU4X parity CLI handles invalid locale gracefully" do
      result = icu4x_call(op: "plural_cardinal", locale: "invalid-locale-xyz", number: 1)

      # ICU4X should either return an error or fall back to a default
      # Accept either behavior as long as it doesn't crash
      assert(result["result"] || result["error"], "Expected either result or error")
    end

    test "ICU4X parity CLI handles unknown operation" do
      result = icu4x_call(op: "unknown_operation", locale: "en", number: 1)

      assert_nil result["result"]
      assert_match(/unknown/i, result["error"])
    end

    # =========================================================================
    # Decimal Formatting Tests
    # =========================================================================

    # Test numbers that exercise various formatting aspects:
    # - Small integers, large integers
    # - Negative numbers
    # - Numbers needing grouping separators (thousands)
    DECIMAL_TEST_NUMBERS = [
      0, 1, 12, 123, 1234, 12345, 123456, 1234567,
      -1, -42, -1234,
    ].freeze

    def icu4x_format_decimal(locale:, number:)
      result = icu4x_call(op: "format_decimal", locale: locale, number: number)
      if result["error"]
        raise "ICU4X error for #{locale}/#{number}: #{result["error"]}"
      end

      result["result"]
    end

    def ruby_format_decimal(locale:, number:)
      Worldwide::Numbers.new(locale: locale).format(number)
    end

    # Locales to test decimal formatting - all locales with numbers.yml data
    DECIMAL_LOCALES = begin
      locales_dir = File.expand_path("../data/cldr/locales", __dir__)
      Dir.glob(File.join(locales_dir, "*", "numbers.yml")).map do |path|
        File.basename(File.dirname(path))
      end.reject { |l| l == "root" }.sort
    end

    # TODO: Enable these tests once decimal symbols are exported to ICU4X blob.
    # Currently blocked because ICU4X requires decimalFormats-numberSystem-latn
    # with format patterns (e.g., "#,##0.###") in addition to symbols.
    # Worldwide's YAML only contains symbols, not format patterns.
    # See main.rs TODO for details.
    DECIMAL_LOCALES.each do |locale|
      test "decimal formatting parity for #{locale}" do
        skip "Decimal symbols not yet exported to ICU4X blob (missing format patterns)"

        failures = []

        DECIMAL_TEST_NUMBERS.each do |number|
          ruby_result = ruby_format_decimal(locale: locale, number: number)

          begin
            icu4x_result = icu4x_format_decimal(locale: locale, number: number)
          rescue => e
            failures << "#{number}: ICU4X error - #{e.message}"
            next
          end

          if ruby_result != icu4x_result
            failures << "#{number}: Ruby=#{ruby_result}, ICU4X=#{icu4x_result}"
          end
        end

        assert_empty failures, "Decimal formatting mismatches for #{locale}:\n#{failures.join("\n")}"
      end
    end

    test "ICU4X parity CLI responds to format_decimal" do
      skip "Decimal symbols not yet exported to ICU4X blob (missing format patterns)"

      result = icu4x_call(op: "format_decimal", locale: "en", number: 1234)

      assert_equal "1,234", result["result"]
      assert_nil result["error"]
    end

    # =========================================================================
    # Complex Plural Rule Verification
    # =========================================================================

    test "Russian cardinal plurals (one/few/many/other)" do
      test_cases = {
        1 => "one",
        2 => "few",
        5 => "many",
        21 => "one",
        22 => "few",
        25 => "many",
        100 => "many",
        101 => "one",
      }

      test_cases.each do |number, expected|
        ruby_result = ruby_plural_cardinal(locale: "ru", number: number)
        icu4x_result = icu4x_plural_cardinal(locale: "ru", number: number)

        assert_equal expected, ruby_result, "Ruby result mismatch for ru/#{number}"
        assert_equal expected, icu4x_result, "ICU4X result mismatch for ru/#{number}"
      end
    end

    test "Arabic cardinal plurals (zero/one/two/few/many/other)" do
      test_cases = {
        0 => "zero",
        1 => "one",
        2 => "two",
        3 => "few",
        11 => "many",
        100 => "other",
      }

      test_cases.each do |number, expected|
        ruby_result = ruby_plural_cardinal(locale: "ar", number: number)
        icu4x_result = icu4x_plural_cardinal(locale: "ar", number: number)

        assert_equal expected, ruby_result, "Ruby result mismatch for ar/#{number}"
        assert_equal expected, icu4x_result, "ICU4X result mismatch for ar/#{number}"
      end
    end

    test "English ordinal plurals (one/two/few/other)" do
      test_cases = {
        1 => "one",   # 1st
        2 => "two",   # 2nd
        3 => "few",   # 3rd
        4 => "other", # 4th
        11 => "other", # 11th (exception)
        12 => "other", # 12th (exception)
        13 => "other", # 13th (exception)
        21 => "one",   # 21st
        22 => "two",   # 22nd
        23 => "few",   # 23rd
      }

      test_cases.each do |number, expected|
        icu4x_result = icu4x_plural_ordinal(locale: "en", number: number)

        assert_equal expected, icu4x_result, "ICU4X ordinal mismatch for en/#{number}"
      end
    end
  end
end
