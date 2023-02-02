# frozen_string_literal: true

require "test_helper"

module Worldwide
  class CurrencyTest < ActiveSupport::TestCase
    include PluralizationHelper

    setup do
      @usd_currency = Worldwide.currency(code: "usd")
    end

    test "#currency_code returns an upcased string" do
      assert_equal "USD", @usd_currency.currency_code
    end

    test "#symbol returns a symbol for a given currency iso code if it exists" do
      assert_equal "$", @usd_currency.symbol
    end

    test "#symbol returns nil if the country iso code does not exist" do
      assert_nil Worldwide.currency(code: "ADP").symbol
    end

    test "#symbol correctly returns the currency symbol for overridden CLDR currency entries" do
      assert_equal "£", Worldwide.currency(code: "JEP").symbol
    end

    test "#label returns the translated values of a currency for USD currency iso code in en" do
      assert_equal "US dollar", @usd_currency.label(count: 1)
      assert_equal "US dollars", @usd_currency.label(count: 2)
    end

    test "#label correctly formats the label for currencies that have metadata in the CLDR label data" do
      assert_includes I18n.t("currencies.STD", count: 1), "(1977–2017)"
      assert_includes I18n.t("currencies.STD", count: 2), "(1977–2017)"

      assert_equal "São Tomé & Príncipe dobra", Worldwide.currency(code: "STD").label(count: 1)
      assert_equal "São Tomé & Príncipe dobras", Worldwide.currency(code: "STD").label(count: 2)
    end

    test "#label correctly returns the currency label for overridden CLDR currency entries" do
      assert_equal "Jersey Pound", Worldwide.currency(code: "JEP").name
      assert_equal "Jersey pound", Worldwide.currency(code: "JEP").label(count: 1)
      assert_equal "Jersey pounds", Worldwide.currency(code: "JEP").label(count: 2)
    end

    test "#label uses the region pluralization keys over the parent's when officially supported" do
      I18n.with_locale(:en) do
        assert_equal "British pound", Worldwide.currency(code: "GBP").label
        assert_equal "British pounds", Worldwide.currency(code: "GBP").label(count: 2)
      end

      I18n.with_locale(:"en-IM") do
        assert_equal "UK pound", Worldwide.currency(code: "GBP").label
        assert_equal "UK pounds", Worldwide.currency(code: "GBP").label(count: 2)
      end
    end

    test "#label falls back to parent pluralization keys when they are missing for the region" do
      I18n.with_locale(:en) do
        assert_equal "Canadian dollar", Worldwide.currency(code: "CAD").label
        assert_equal "Canadian dollars", Worldwide.currency(code: "CAD").label(count: 2)
      end

      I18n.with_locale(:"en-CA") do
        # There are no pluralization keys for `CAD` in `en-CA`; It just uses `en`'s.
        assert_nil I18n.t("currencies.CAD.other", locale: "en-CA", exception_handler: proc {}, fallback: false)
        assert_equal "Canadian dollar", Worldwide.currency(code: "CAD").label
        assert_equal "Canadian dollars", Worldwide.currency(code: "CAD").label(count: 2)
      end
    end

    test "#label use #name if there is no pluralization data at all in the locale nor its fallback chain" do
      I18n.with_locale(:pl) do
        assert_raises(I18n::InvalidPluralizationData) do
          translate_plural("currencies.ESP", count: 1) # `pl` still doesn't have this data. Future-proofing for the test.
        end

        assert_equal "peseta hiszpańska", Worldwide.currency(code: "ESP").label
      end
    end

    test "name returns the currency name" do
      I18n.with_locale(:en) do
        assert_equal "British Pound", Worldwide.currency(code: "GBP").name
      end
    end

    test "#format_explicit behaves as expected" do
      data = [
        [:da, :DKK, 1.5, "1,50 kr. DKK"],
        [:"da-DK", :DKK, 1.5, "1,50 kr. DKK"],
        [:de, :CHF, 2.55, "2,55 CHF"],
        [:"de-AT", :EUR, 98765.43, "€ 98 765,43 EUR"],
        [:en, :OMR, 1.7, "OMR1.700"],
        [:en, :USD, 2.4, "$2.40 USD"],
        [:"en-CA", :CAD, 12.37, "$12.37 CAD"],
        [:"en-IE", :EUR, 1234.5, "€1,234.50 EUR"],
        [:"en-IN", :INR, 1234567, "₹12,34,567.00 INR"],
        [:"en-US", :USD, 12.37, "$12.37 USD"],
        [:"en-US", :USD, 1234567, "$1,234,567.00 USD"],
        [:"en-US", :USD, 0.75, "$0.75 USD"],
        [:fr, :EUR, 2.5, "2,50 € EUR"],
        [:fr, :USD, 1.25, "1,25 $ USD"],
        # Note that CLDR instructs us to provide the following output for JPY; it's arguably wrong.
        # Use `humanize: :japan` for Japanese-style formatting of JPY.
        [:ja, :JPY, 1200, "￥1,200 JPY"],
        [:ja, :JPY, -23400, "-￥23,400 JPY"],
        [:"en-CA", :CAD, -123.45, "-$123.45 CAD"],
        [:"sv-SE", :USD, -123.45, "-123,45 $ USD"],
        [:"pt-BR", :BRL, 1.25, "R$ 1,25 BRL"],
        [:"zh-CN", :CNY, 12345, "¥12,345.00 CNY"],
        [:"zh-TW", :CNY, 12345, "¥12,345.00 CNY"],
        [:"zh-TW", :TWD, 12345, "$12,345.00 TWD"],
        [:en, :HKD, 12345, "HK$12,345.00 HKD"],
      ]

      data.each do |locale, currency_code, input, expected|
        # First, check that we can explicitly pass in the locale
        I18n.with_locale(:"it-VA") do
          actual = Worldwide.currency(code: currency_code).format_explicit(input, locale: locale)

          assert_equal expected, actual, "boom #{locale}"
        end

        # Second, check that we can implicitly use the current active locale
        I18n.with_locale(locale) do
          actual = Worldwide.currency(code: currency_code).format_explicit(input)

          assert_equal expected, actual
        end
      end
    end

    test "#format_short behaves as expected" do
      data = [
        [:da, :DKK, 1.50, "1,50 kr."],
        [:"da-DK", :DKK, 1.50, "1,50 kr."],
        [:de, :CHF, 2.55, "2,55 CHF"],
        [:"de-AT", :EUR, 98765.43, "€ 98 765,43"],
        [:en, :OMR, 1.7, "OMR1.700"],
        [:en, :USD, 2.4, "$2.40"],
        [:"en-CA", :CAD, 12.37, "$12.37"],
        [:"en-IE", :EUR, 1234.5, "€1,234.50"],
        [:"en-IN", :INR, 1234567, "₹12,34,567.00"],
        [:"en-US", :USD, 12.37, "$12.37"],
        [:"en-US", :USD, 1234567, "$1,234,567.00"],
        [:"en-US", :USD, 0.75, "$0.75"],
        [:fr, :EUR, 2.5, "2,50 €"],
        [:fr, :USD, 1.25, "1,25 $"],
        # Note that CLDR instructs us to provide the following output for JPY; it's arguably wrong.
        [:ja, :JPY, 1200, "￥1,200"],
        [:ja, :JPY, -23400, "-￥23,400"],
        [:"en-CA", :CAD, -123.45, "-$123.45"],
        [:"se-SE", :USD, -123.45, "-123,45 $"],
        [:"pt-BR", :BRL, 1.25, "R$ 1,25"],
        [:"zh-CN", :CNY, 12345, "¥12,345.00"],
        [:"zh-TW", :CNY, 12345, "¥12,345.00"],
        [:"zh-TW", :TWD, 12345, "$12,345.00"],
        [:"es-US", :USD, 12345, "$12,345.00"],
        [:"es-US", :USD, 12.37, "$12.37"],
        [:"es-MX", :USD, 12345, "$12,345.00"],
        [:"es-MX", :USD, 12.37, "$12.37"],
        [:en, :HKD, 12345, "HK$12,345.00"],
        [:"en-AU", :USD, 12.37, "$12.37"],
        [:"en-AU", :EUR, 12.37, "€12.37"],
      ]

      data.each do |locale, currency_code, input, expected|
        # First, check that we can explicitly pass in the locale
        I18n.with_locale(:"it-VA") do
          actual = Worldwide.currency(code: currency_code).format_short(input, locale: locale)

          assert_equal expected, actual, "boom!: #{locale}"
        end

        # Second, check that we can implicitly use the current active locale
        I18n.with_locale(locale) do
          actual = Worldwide.currency(code: currency_code).format_short(input)

          assert_equal expected, actual
        end
      end
    end

    test "#format_short and #format_explicit support decimal_places: argument" do
      data = [
        [:da, :DKK, 10000, 0, "10.000 kr.", "10.000 kr. DKK"],
        [:"en-AU", :AUD, 10000, 0, "$10,000", "$10,000 AUD"],
        [:fr, :EUR, 10000, 0, "10 000 €", "10 000 € EUR"],
      ]

      data.each do |locale, currency_code, input, decimals, expected_short, expected_explicit| # rubocop:disable Metrics/ParameterLists
        I18n.with_locale(locale) do
          currency = Worldwide.currency(code: currency_code)

          actual = currency.format_short(input, decimal_places: decimals)

          assert_equal expected_short, actual

          actual = currency.format_explicit(input, decimal_places: decimals)

          assert_equal expected_explicit, actual
        end
      end
    end

    test "#format_short and #format_explicit have sane default decimal places" do
      data = [
        [:da, :DKK, 10000, "10.000,00 kr.", "10.000,00 kr. DKK"],
        [:"en-AU", :AUD, 10000, "$10,000.00", "$10,000.00 AUD"],
        [:fr, :EUR, 10000, "10 000,00 €", "10 000,00 € EUR"],
        [:en, :OMR, 10000, "OMR10,000.000", "OMR10,000.000"],
      ]

      data.each do |locale, currency_code, input, expected_short, expected_explicit|
        I18n.with_locale(locale) do
          currency = Worldwide.currency(code: currency_code)

          actual = currency.format_short(input)

          assert_equal expected_short, actual

          actual = currency.format_explicit(input)

          assert_equal expected_explicit, actual
        end
      end
    end

    test "#format_explicit supports humanize: as expected" do
      data = [
        [:en, :USD, 10_000_000, "$10M USD", "$10 million USD"],
      ]

      data.each do |locale, currency_code, amount, expected_short, expected_long|
        I18n.with_locale(locale) do
          currency = Worldwide.currency(code: currency_code)

          actual = currency.format_explicit(amount, humanize: :short)

          assert_equal expected_short, actual

          actual = currency.format_explicit(amount, humanize: :long)

          assert_equal expected_long, actual
        end
      end
    end

    test "#format_short supports humanize: as expected" do
      data = [
        [:en, :USD, 10_000_000, "$10M", "$10 million"],
        [:"fr-FR", :EUR, 2_400_000_000, "2,4 Md €", "2,4 milliards €"],
      ]

      data.each do |locale, currency_code, amount, expected_short, expected_long|
        I18n.with_locale(locale) do
          currency = Worldwide.currency(code: currency_code)

          actual = currency.format_short(amount, humanize: :short)

          assert_equal expected_short, actual

          actual = currency.format_short(amount, humanize: :long)

          assert_equal expected_long, actual
        end
      end
    end

    test "#format_short and #format_explicit use minor unit symbol where available" do
      data = [
        [:"de-DE", :EUR, 0.20, "0,20 €", "0,20 € EUR"],
        [:en, :AUD, 0.03, "3¢", "3¢ AUD"],
        [:en, :GBP, 0.99, "99p", "99p GBP"],
        [:en, :JPY, 0.99, "¥1", "¥1 JPY"],
        [:en, :USD, 0.30, "30¢", "30¢ USD"],
        [:"fr-CA", :CAD, 0.02, "2¢", "2¢ CAD"],
        [:"fr-FR", :CAD, 0.25, "25¢", "25¢ CAD"],
        [:ja, :JPY, 0.99, "￥1", "￥1 JPY"],
      ]

      data.each do |locale, currency_code, amount, expected_short, expected_explicit|
        I18n.with_locale(locale) do
          currency = Worldwide.currency(code: currency_code)

          actual = currency.format_short(amount, as_minor_units: true)

          assert_equal expected_short, actual

          actual = currency.format_explicit(amount, as_minor_units: true)

          assert_equal expected_explicit, actual
        end
      end
    end

    test "#minor_symbol returns expected symbols" do
      data = [
        [:CAD, "¢"],
        [:GBP, "p"],
        [:USD, "¢"],
      ]

      data.each do |currency_code, expected|
        currency = Worldwide.currency(code: currency_code)

        actual = currency.send(:has_minor_symbol?)

        assert actual

        actual = currency.send(:minor_symbol)

        assert_equal expected, actual
      end
    end

    test "#minor_symbol returns nil for currencies that don't have one" do
      data = [
        :DKK,
        :EUR,
        :JPY,
        :SEK,
      ]

      data.each do |currency_code|
        currency = Worldwide.currency(code: currency_code)

        presence = currency.send(:has_minor_symbol?)

        refute presence

        symbol = currency.send(:minor_symbol)

        assert_nil symbol
      end
    end

    test "Formatting minor symbols with additional decimal places" do
      data = [
        [:en, :CAD, 1.219, 3, "121.9¢", "121.9¢ CAD"],
        [:fr, :EUR, 1.219, 3, "1,219 €", "1,219 € EUR"],
      ]

      data.each do |locale, currency_code, amount, decimals, expected_short, expected_explicit| # rubocop:disable Metrics/ParameterLists
        I18n.with_locale(locale) do
          currency = Worldwide.currency(code: currency_code)

          actual = currency.format_short(amount, as_minor_units: true, decimal_places: decimals)

          assert_equal expected_short, actual

          actual = currency.format_explicit(amount, as_minor_units: true, decimal_places: decimals)

          assert_equal expected_explicit, actual
        end
      end
    end

    test "humanize: :japan does not override the symbol unless the currency_code is JPY" do
      ["aud", "eur", "gbp", "usd", "vnd"].each do |currency_code|
        currency = Worldwide.currency(code: currency_code)

        refute_includes "円", currency.format_short(123, humanize: :japan)
        refute_includes "円", currency.format_explicit(123, humanize: :japan)
      end
    end

    test "formatting JPY Japanese-style" do
      jpy = Worldwide.currency(code: "JPY")

      [
        [:en, 1, "1円", "1円 JPY"],
        [:ja, 1, "1円", "1円 JPY"],
        [:ja, 1234, "1234円", "1234円 JPY"],
        [:ja, 12_345, "1万2345円", "1万2345円 JPY"],
        [:ja, 12_3456, "12万3456円", "12万3456円 JPY"],
        [:ja, 123_456, "12万3456円", "12万3456円 JPY"],
        [:ja, 123_456_789, "1億2345万6789円", "1億2345万6789円 JPY"],
      ].each do |locale, amount, expected_short, expected_explicit|
        actual_short = jpy.format_short(amount, locale: locale, humanize: :japan)

        assert_equal expected_short, actual_short

        actual_explicit = jpy.format_explicit(amount, locale: locale, humanize: :japan)

        assert_equal expected_explicit, actual_explicit
      end
    end

    test "humanize: output extrapolates reasonably beyond provided data" do
      I18n.with_locale("fr-CA") do
        assert_equal "1,5 million $", Worldwide.currency(code: "usd").format_short(1_500_000, humanize: :long)
      end
    end

    test "currency symbols are sensible in various edge cases" do
      [
        ["pt", "BRL", "R$"],
        ["en", "CZK", "Kč"],
        ["es-PA", "PAB", "B/."],
        ["es-PE", "PEN", "S/"],
        ["pl", "PLN", "zł"],
      ].each do |locale, currency_code, expected_symbol|
        assert_equal expected_symbol, Worldwide.currency(code: currency_code).symbol(locale: locale)
      end
    end

    test "Currency can be constructed with a numeric code" do
      [
        [32, "ARS"],
        ["032", "ARS"],
        [:"032", "ARS"],
        [840, "USD"],
        ["840", "USD"],
        [:"840", "USD"],
      ].each do |numeric_code, alpha_code|
        assert_equal alpha_code, Worldwide.currency(code: numeric_code).currency_code
      end
    end

    test "Currency can be formatted without the symbol" do
      [
        [:"de-CH", :CHF, 1, "1.00", "1.00 CHF"],
        [:en, :CAD, 1, "1.00", "1.00 CAD"],
        [:fr, :EUR, 1, "1,00", "1,00 EUR"],
      ].each do |locale, currency_code, amount, expected_short, expected_explicit|
        I18n.with_locale(locale) do
          actual = Worldwide.currency(code: currency_code).format_short(amount, use_symbol: false)

          assert_equal expected_short, actual
          actual = Worldwide.currency(code: currency_code).format_explicit(amount, use_symbol: false)

          assert_equal expected_explicit, actual
        end
      end
    end

    test "as_minor_units: true overrides use_symbol: false" do
      [
        [:en, :USD, 0.25, "25¢", "25¢ USD"],
        [:en, :USD, 1.25, "125¢", "125¢ USD"],
        [:ja, :JPY, 0.25, "￥0", "￥0 JPY"],
        [:ja, :JPY, 1.75, "￥2", "￥2 JPY"],
      ].each do |locale, currency_code, amount, expected_short, expected_explicit|
        I18n.with_locale(locale) do
          currency = Worldwide.currency(code: currency_code)

          assert_equal expected_short, currency.format_short(amount, as_minor_units: true, use_symbol: false)
          assert_equal expected_explicit, currency.format_explicit(amount, as_minor_units: true, use_symbol: false)
        end
      end
    end

    test "humanize: :japan combined with use_symbol: false" do
      [
        [:en, :USD, 1, "1", "1 USD"],
        [:en, :USD, 12345, "1万2345", "1万2345 USD"],
        [:ja, :JPY, 1, "1", "1 JPY"],
        [:ja, :JPY, 12345, "1万2345", "1万2345 JPY"],
      ].each do |locale, currency_code, amount, expected_short, expected_explicit|
        I18n.with_locale(locale) do
          currency = Worldwide.currency(code: currency_code)

          assert_equal expected_short, currency.format_short(amount, humanize: :japan, use_symbol: false)
          assert_equal expected_explicit, currency.format_explicit(amount, humanize: :japan, use_symbol: false)
        end
      end
    end
  end
end
