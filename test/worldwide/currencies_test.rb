# frozen_string_literal: true

require "test_helper"

module Worldwide
  class CurrenciesTest < ActiveSupport::TestCase
    test ".all should return an array of currency objects" do
      currencies = Worldwide::Currencies.all

      refute_empty currencies

      currencies.each do |currency|
        assert currency.is_a?(Worldwide::Currency)
      end
    end

    test ".each should allow currencies to be enumerable" do
      Worldwide::Currencies.each do |currency|
        assert currency.is_a?(Worldwide::Currency)
      end
    end

    test "mapping from alpha-three to numeric-three codes" do
      [
        ["CHF", 756],
        ["chf", 756],
        ["Chf", 756],
        [:CHF, 756],
        [:chf, 756],
        [:Chf, 756],
        ["QAR", 634],
      ].each do |alpha_code, expected_numeric|
        actual_numeric = Currencies.numeric_code_for(alpha_code)

        assert_equal expected_numeric, actual_numeric
      end
    end

    test "mapping from numeric-three to alpha-three codes" do
      [
        [4, "AFA"],
        ["756", "CHF"],
        [:"756", "CHF"],
        [756, "CHF"],
        ["634", "QAR"],
      ].each do |numeric_code, expected_alpha|
        actual_alpha = Currencies.alpha_code_for(numeric_code)

        assert_equal expected_alpha, actual_alpha
      end
    end

    test "no two currencies use the same (non-nil) numeric-three code" do
      seen = {}
      Currencies.each do |currency|
        next if currency.numeric_code.nil?

        assert_nil seen[currency.numeric_code]
        seen[currency.numeric_code] = currency.currency_code
      end
    end
  end
end
