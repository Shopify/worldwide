# frozen_string_literal: true

require "bigdecimal"
# Rails loads bigdecimal/util, which gives String and nil a to_d.
require "bigdecimal/util"
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

    test "Currency rejects malformed codes" do
      cache = Worldwide.instance_variable_get(:@currencies_cache)
      original_keys = cache.keys

      ["USD-1", "1USD", "USDX", "USDT", "USD\n", "840x", "x840", "0840", "840\n", "!"].each do |code|
        assert_raises(ArgumentError, code.inspect) { Worldwide.currency(code: code) }
        assert_raises(ArgumentError, code.inspect) { Currency.new(code: code) }
      end

      assert_equal original_keys, cache.keys
    end

    test "Currency accepts explicitly supported non-ISO codes" do
      currency = Worldwide.currency(code: "usdc")

      assert_equal "USDC", currency.currency_code
      assert_nil currency.numeric_code
      assert_same currency, Worldwide.currency(code: :USDC)
      assert_equal "USDC", Currency.new(code: "USDC").currency_code
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

    test "XCG (Caribbean guilder) is recognized" do
      xcg = Worldwide.currency(code: "xcg")

      assert_equal "XCG", xcg.currency_code
      assert_nil xcg.numeric_code
      assert_equal 2, xcg.decimals
      assert_equal "Cg", xcg.symbol(locale: :en)
      assert_equal "Cg12.50", xcg.format_short(12.5, locale: :en)
      assert_equal "Cg12.50 XCG", xcg.format_explicit(12.5, locale: :en)

      I18n.with_locale(:en) do
        assert_equal "Caribbean Guilder", xcg.name
        assert_equal "Caribbean guilder", xcg.label(count: 1)
        assert_equal "Caribbean guilders", xcg.label(count: 2)
      end

      I18n.with_locale(:nl) do
        assert_equal "Caribische gulden", xcg.name
        assert_equal "Caribische gulden", xcg.label(count: 2)
      end

      [:es, :"es-419", :"es-MX"].each do |locale|
        I18n.with_locale(locale) do
          assert_equal "florín caribeño", xcg.name
          assert_equal "florín caribeño", xcg.label(count: 1)
          assert_equal "florines caribeños", xcg.label(count: 2)
          assert_equal "florines caribeños", xcg.label(count: 1_000_000)
        end
      end

      assert_equal "Cg", xcg.symbol(locale: :nl)
      assert_equal "Cg 12,50", xcg.format_short(12.5, locale: :nl)
    end

    test "ANG (Netherlands Antillean guilder) is still recognized alongside XCG" do
      ang = Worldwide.currency(code: "ang")

      assert_equal "ANG", ang.currency_code
      assert_equal 532, ang.numeric_code
      assert_equal 2, ang.decimals
      assert_nil ang.symbol(locale: :en)
      assert_equal "ANG12.50", ang.format_short(12.5, locale: :en)

      I18n.with_locale(:en) do
        assert_equal "Netherlands Antillean Guilder", ang.name
        assert_equal "Netherlands Antillean guilders", ang.label(count: 2)
      end
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

    test "#format_short and #format_explicit keep every digit of a large BigDecimal amount" do
      eur = Worldwide.currency(code: "EUR")

      assert_equal "123.456.789.012.345,01\u00A0€", eur.format_short(BigDecimal("123456789012345.01"), locale: :"de-DE")
      assert_equal "9.007.199.254.740.992,01\u00A0€", eur.format_short(BigDecimal("9007199254740992.01"), locale: :"de-DE")
      assert_equal "9.007.199.254.740.992,01\u00A0€ EUR", eur.format_explicit(BigDecimal("9007199254740992.01"), locale: :"de-DE")
      assert_equal "-0,00\u00A0€", eur.format_short(BigDecimal("-0.004"), locale: :"de-DE")
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

    test "#format_short and #format_explicit output across layouts, signs and options" do
      [
        # Symbol before the number, no space
        ["USD", :en, 1234.5, {}, ["$1,234.50", "$1,234.50 USD"]],
        ["USD", :en, -1234.5, {}, ["-$1,234.50", "-$1,234.50 USD"]],
        ["USD", :en, 0, {}, ["$0.00", "$0.00 USD"]],
        ["USD", :en, -0.004, {}, ["-$0.00", "-$0.00 USD"]],
        ["USD", :en, BigDecimal("-1234.565"), {}, ["-$1,234.56", "-$1,234.56 USD"]],
        ["USD", :en, 1234567, {}, ["$1,234,567.00", "$1,234,567.00 USD"]],
        # Symbol before the number, with a space
        ["EUR", :"de-AT", 1234.5, {}, ["€\u00A01\u00A0234,50", "€\u00A01\u00A0234,50 EUR"]],
        ["EUR", :"de-AT", -1234.5, {}, ["-€\u00A01\u00A0234,50", "-€\u00A01\u00A0234,50 EUR"]],
        ["EUR", :"de-AT", 0, {}, ["€\u00A00,00", "€\u00A00,00 EUR"]],
        ["EUR", :"de-AT", -0.004, {}, ["-€\u00A00,00", "-€\u00A00,00 EUR"]],
        ["EUR", :"de-AT", BigDecimal("-1234.565"), {}, ["-€\u00A01\u00A0234,56", "-€\u00A01\u00A0234,56 EUR"]],
        ["EUR", :"de-AT", 1234567, {}, ["€\u00A01\u00A0234\u00A0567,00", "€\u00A01\u00A0234\u00A0567,00 EUR"]],
        # Symbol after the number, with a space
        ["EUR", :fr, 1234.5, {}, ["1\u202F234,50\u00A0€", "1\u202F234,50\u00A0€ EUR"]],
        ["EUR", :fr, -1234.5, {}, ["-1\u202F234,50\u00A0€", "-1\u202F234,50\u00A0€ EUR"]],
        ["EUR", :fr, 0, {}, ["0,00\u00A0€", "0,00\u00A0€ EUR"]],
        ["EUR", :fr, -0.004, {}, ["-0,00\u00A0€", "-0,00\u00A0€ EUR"]],
        ["EUR", :fr, BigDecimal("-1234.565"), {}, ["-1\u202F234,56\u00A0€", "-1\u202F234,56\u00A0€ EUR"]],
        ["EUR", :fr, 1234567, {}, ["1\u202F234\u202F567,00\u00A0€", "1\u202F234\u202F567,00\u00A0€ EUR"]],
        # Symbol after the number, no space, with 3/2 grouping
        ["USD", :bn, 1234.5, {}, ["1,234.50$", "1,234.50$ USD"]],
        ["USD", :bn, -1234.5, {}, ["-1,234.50$", "-1,234.50$ USD"]],
        ["USD", :bn, 0, {}, ["0.00$", "0.00$ USD"]],
        ["USD", :bn, -0.004, {}, ["-0.00$", "-0.00$ USD"]],
        ["USD", :bn, BigDecimal("-1234.565"), {}, ["-1,234.56$", "-1,234.56$ USD"]],
        ["USD", :bn, 1234567, {}, ["12,34,567.00$", "12,34,567.00$ USD"]],
        # Currencies with 0 and 3 decimals
        ["JPY", :ja, 1234.5, {}, ["￥1,234", "￥1,234 JPY"]],
        ["JPY", :ja, -1234.5, {}, ["-￥1,234", "-￥1,234 JPY"]],
        ["JPY", :ja, 0.5, {}, ["￥0", "￥0 JPY"]],
        ["KWD", :en, 1234.5, {}, ["KWD1,234.500", "KWD1,234.500"]],
        ["KWD", :en, -1234.5, {}, ["-KWD1,234.500", "-KWD1,234.500"]],
        ["KWD", :ar, 1234.5, {}, ["\u200F1,234.500\u00A0د.ك.\u200F", "\u200F1,234.500\u00A0د.ك.\u200F KWD"]],
        ["KWD", :ar, -1234.5, {}, ["-\u200F1,234.500\u00A0د.ك.\u200F", "-\u200F1,234.500\u00A0د.ك.\u200F KWD"]],
        ["EUR", :en, 0.5, {}, ["€0.50", "€0.50 EUR"]],
        # HKD keeps its HK$ symbol
        ["HKD", :en, 1234.5, {}, ["HK$1,234.50", "HK$1,234.50 HKD"]],
        ["HKD", :"zh-HK", -1234.5, {}, ["-HK$1,234.50", "-HK$1,234.50 HKD"]],
        ["HKD", :fr, 1234.5, {}, ["1\u202F234,50\u00A0HK$", "1\u202F234,50\u00A0HK$ HKD"]],
        # The currency code stands in for a missing symbol, and is not repeated
        ["ANG", :en, -1234.5, {}, ["-ANG1,234.50", "-ANG1,234.50"]],
        ["ANG", :fr, 1234.5, {}, ["1\u202F234,50\u00A0ANG", "1\u202F234,50\u00A0ANG"]],
        ["CHF", :"de-CH", -1234.5, {}, ["-CHF\u00A01'234.50", "-CHF\u00A01'234.50"]],
        # Symbol after the number with a space in no, which nb inherits
        ["NOK", :nb, 1234.5, {}, ["1\u00A0234,50\u00A0kr", "1\u00A0234,50\u00A0kr NOK"]],
        ["NOK", :nb, -1234.5, {}, ["-1\u00A0234,50\u00A0kr", "-1\u00A0234,50\u00A0kr NOK"]],
        # Right-to-left locales
        ["ILS", :he, 1234.5, {}, ["\u200F1,234.50\u00A0\u200F₪", "\u200F1,234.50\u00A0\u200F₪ ILS"]],
        ["ILS", :he, -1234.5, {}, ["-\u200F1,234.50\u00A0\u200F₪", "-\u200F1,234.50\u00A0\u200F₪ ILS"]],
        ["SAR", :ar, 1234.5, {}, ["\u200F1,234.50\u00A0ر.س.\u200F", "\u200F1,234.50\u00A0ر.س.\u200F SAR"]],
        ["SAR", :ar, -1234.5, {}, ["-\u200F1,234.50\u00A0ر.س.\u200F", "-\u200F1,234.50\u00A0ر.س.\u200F SAR"]],
        ["USD", :ar, -1234.5, {}, ["-\u200F1,234.50\u00A0$", "-\u200F1,234.50\u00A0$ USD"]],
        ["AED", :"ar-AE", 1234.5, {}, ["\u200F1,234.50\u00A0د.إ.\u200F", "\u200F1,234.50\u00A0د.إ.\u200F AED"]],
        ["IRR", :fa, -1234.5, {}, ["-\u200Eریال\u00A01,234.50", "-\u200Eریال\u00A01,234.50 IRR"]],
        # 3/2 grouping
        ["INR", :"en-IN", 1234567.891, {}, ["₹12,34,567.89", "₹12,34,567.89 INR"]],
        ["INR", :"en-IN", -1234567.891, {}, ["-₹12,34,567.89", "-₹12,34,567.89 INR"]],
        ["INR", :"en-IN", BigDecimal("123456789.5"), {}, ["₹12,34,56,789.50", "₹12,34,56,789.50 INR"]],
        ["INR", :hi, 1234567.891, {}, ["₹12,34,567.89", "₹12,34,567.89 INR"]],
        # decimal_places:
        ["USD", :en, 1234.5678, { decimal_places: 0 }, ["$1,235", "$1,235 USD"]],
        ["EUR", :fr, -1234.5678, { decimal_places: 3 }, ["-1\u202F234,568\u00A0€", "-1\u202F234,568\u00A0€ EUR"]],
        # humanize: :short and :long
        ["USD", :en, 1234567, { humanize: :short }, ["$1.2M", "$1.2M USD"]],
        ["USD", :en, 1234567, { humanize: :long }, ["$1.2 million", "$1.2 million USD"]],
        ["USD", :en, -1234567, { humanize: :short }, ["-$1M", "-$1M USD"]],
        ["USD", :en, -1234567, { humanize: :long }, ["-$1 million", "-$1 million USD"]],
        ["USD", :en, -999, { humanize: :short }, ["-$999", "-$999 USD"]],
        ["EUR", :"fr-FR", 1234567, { humanize: :short }, ["1,2\u00A0M\u00A0€", "1,2\u00A0M\u00A0€ EUR"]],
        ["EUR", :"fr-FR", 1234567, { humanize: :long }, ["1,2 million\u00A0€", "1,2 million\u00A0€ EUR"]],
        ["EUR", :"fr-FR", -1234567, { humanize: :short }, ["-1\u00A0M\u00A0€", "-1\u00A0M\u00A0€ EUR"]],
        ["EUR", :"de-AT", -1234567, { humanize: :short }, ["-€\u00A01\u00A0Mio.", "-€\u00A01\u00A0Mio. EUR"]],
        ["EUR", :"de-AT", -1234567, { humanize: :long }, ["-€\u00A01 Millionen", "-€\u00A01 Millionen EUR"]],
        ["USD", :sw, 1234567, { humanize: :short }, ["$\u00A01.2M", "$\u00A01.2M USD"]],
        # The sw compact pattern has a negative subpattern, which is kept, and its minus sign moves before the symbol
        ["USD", :sw, 1234567, { humanize: :long }, ["-$\u00A0milioni 1.2;milioni 0", "-$\u00A0milioni 1.2;milioni 0 USD"]],
        # humanize: :japan
        ["JPY", :ja, 12345, { humanize: :japan }, ["1万2345円", "1万2345円 JPY"]],
        ["JPY", :ja, -12345, { humanize: :japan }, ["-1万2345円", "-1万2345円 JPY"]],
        ["JPY", :ja, 0, { humanize: :japan }, ["0円", "0円 JPY"]],
        ["JPY", :ja, 1234.5, { humanize: :japan }, ["1234.5円", "1234.5円 JPY"]],
        ["USD", :en, 12345, { humanize: :japan }, ["1万2345$", "1万2345$ USD"]],
        ["EUR", :fr, 1234.5, { humanize: :japan }, ["1234,5€", "1234,5€ EUR"]],
        ["JPY", :ja, 12345, { humanize: :japan, use_symbol: false }, ["1万2345", "1万2345 JPY"]],
        # as_minor_units: true, with and without a minor unit symbol
        ["USD", :en, 0.75, { as_minor_units: true }, ["75¢", "75¢ USD"]],
        ["USD", :en, -0.75, { as_minor_units: true }, ["-75¢", "-75¢ USD"]],
        ["USD", :en, 1.219, { as_minor_units: true }, ["122¢", "122¢ USD"]],
        ["USD", :en, 0, { as_minor_units: true }, ["0¢", "0¢ USD"]],
        ["USD", :en, 0.29, { as_minor_units: true }, ["29¢", "29¢ USD"]],
        ["USD", :en, BigDecimal("0.295"), { as_minor_units: true }, ["30¢", "30¢ USD"]],
        ["USD", :en, 1.219, { as_minor_units: true, decimal_places: 3 }, ["121.9¢", "121.9¢ USD"]],
        ["USD", :en, 0.75, { as_minor_units: true, use_symbol: false }, ["75¢", "75¢ USD"]],
        ["GBP", :en, -0.75, { as_minor_units: true }, ["-75p", "-75p GBP"]],
        ["CAD", :"fr-CA", 0.75, { as_minor_units: true }, ["75¢", "75¢ CAD"]],
        ["EUR", :fr, 0.75, { as_minor_units: true }, ["0,75\u00A0€", "0,75\u00A0€ EUR"]],
        ["EUR", :fr, -0.75, { as_minor_units: true }, ["-0,75\u00A0€", "-0,75\u00A0€ EUR"]],
        ["EUR", :en, 1.219, { as_minor_units: true }, ["€1.22", "€1.22 EUR"]],
        ["JPY", :ja, 0.75, { as_minor_units: true }, ["￥1", "￥1 JPY"]],
        # use_symbol: false
        ["USD", :en, -1234.5, { use_symbol: false }, ["-1,234.50", "-1,234.50 USD"]],
        ["EUR", :fr, 1234.5, { use_symbol: false }, ["1\u202F234,50", "1\u202F234,50 EUR"]],
        ["EUR", :"de-AT", -1234.5, { use_symbol: false }, ["-1\u00A0234,50", "-1\u00A0234,50 EUR"]],
        # Amounts that are not finite
        ["USD", :en, Float::NAN, {}, ["$NaN", "$NaN USD"]],
        ["USD", :en, -Float::INFINITY, {}, ["-$Inf", "-$Inf USD"]],
        ["EUR", :fr, -Float::INFINITY, {}, ["-Inf\u00A0€", "-Inf\u00A0€ EUR"]],
      ].each do |code, locale, amount, options, expected|
        currency = Worldwide.currency(code: code)
        message = "#{code} #{locale} #{amount.inspect} #{options.inspect}"

        assert_equal expected[0], currency.format_short(amount, locale: locale, **options), message
        assert_equal expected[1], currency.format_explicit(amount, locale: locale, **options), message
      end
    end

    test "#format_to_parts returns the parts of #format_short in display order" do
      assert_equal(
        [
          { type: :minus_sign, value: "-" },
          { type: :currency, value: "€" },
          { type: :literal, value: "\u00A0" },
          { type: :number, value: "1\u00A0234,50" },
        ],
        Worldwide.currency(code: "EUR").format_to_parts(-1234.5, locale: :"de-AT"),
      )

      [
        ["USD", :en, 1234.5, {}, [[:currency, "$"], [:number, "1,234.50"]]],
        ["USD", :en, -1234.5, {}, [[:minus_sign, "-"], [:currency, "$"], [:number, "1,234.50"]]],
        ["USD", :en, -0.004, {}, [[:minus_sign, "-"], [:currency, "$"], [:number, "0.00"]]],
        ["USD", :en, 1234.5678, { decimal_places: 0 }, [[:currency, "$"], [:number, "1,235"]]],
        ["EUR", :"de-AT", 0, {}, [[:currency, "€"], [:literal, "\u00A0"], [:number, "0,00"]]],
        ["EUR", :fr, 1234.5, {}, [[:number, "1\u202F234,50"], [:literal, "\u00A0"], [:currency, "€"]]],
        ["EUR", :fr, -1234.5, {}, [[:minus_sign, "-"], [:number, "1\u202F234,50"], [:literal, "\u00A0"], [:currency, "€"]]],
        ["EUR", :fr, BigDecimal("-0.004"), {}, [[:minus_sign, "-"], [:number, "0,00"], [:literal, "\u00A0"], [:currency, "€"]]],
        ["USD", :bn, -1234.5, {}, [[:minus_sign, "-"], [:number, "1,234.50"], [:currency, "$"]]],
        ["JPY", :ja, -1234.5, {}, [[:minus_sign, "-"], [:currency, "￥"], [:number, "1,234"]]],
        ["KWD", :en, 1234.5, {}, [[:currency, "KWD"], [:number, "1,234.500"]]],
        ["KWD", :ar, -1234.5, {}, [[:minus_sign, "-"], [:literal, "\u200F"], [:number, "1,234.500"], [:literal, "\u00A0"], [:currency, "د.ك.\u200F"]]],
        ["ILS", :he, -1234.5, {}, [[:minus_sign, "-"], [:literal, "\u200F"], [:number, "1,234.50"], [:literal, "\u00A0\u200F"], [:currency, "₪"]]],
        ["HKD", :en, 12.5, {}, [[:currency, "HK$"], [:number, "12.50"]]],
        ["ANG", :en, -12.5, {}, [[:minus_sign, "-"], [:currency, "ANG"], [:number, "12.50"]]],
        ["INR", :"en-IN", BigDecimal("123456789.5"), {}, [[:currency, "₹"], [:number, "12,34,56,789.50"]]],
        ["EUR", :"de-DE", BigDecimal("9007199254740992.01"), {}, [[:number, "9.007.199.254.740.992,01"], [:literal, "\u00A0"], [:currency, "€"]]],
        ["USD", :en, Float::NAN, {}, [[:currency, "$"], [:number, "NaN"]]],
        ["USD", :en, -Float::INFINITY, {}, [[:minus_sign, "-"], [:currency, "$"], [:number, "Inf"]]],
      ].each do |code, locale, amount, options, expected|
        currency = Worldwide.currency(code: code)
        message = "#{code} #{locale} #{amount.inspect} #{options.inspect}"
        parts = currency.format_to_parts(amount, locale: locale, **options)

        assert_equal expected, parts.map { |part| [part[:type], part[:value]] }, message
        assert_equal currency.format_short(amount, locale: locale, **options), parts.map { |part| part[:value] }.join, message
      end
    end

    test "#format_to_parts uses I18n.locale by default" do
      I18n.with_locale(:fr) do
        assert_equal(
          [[:number, "12,50"], [:literal, "\u00A0"], [:currency, "€"]],
          Worldwide.currency(code: "EUR").format_to_parts(12.5).map { |part| [part[:type], part[:value]] },
        )
      end
    end

    test "#format_to_parts joins to #format_short for every currency across locales, amounts and options" do
      # Symbol before or after the number, with or without a space, right-to-left, 3/2 grouping, minimum grouping digits of 2
      locales = [:en, :"en-IN", :bn, :ja, :"zh-HK", :"de-AT", :"de-CH", :nl, :ar, :"ar-EG", :sw, :ur, :fr, :"fr-CA", :de, :pl, :es, :"pt-PT", :"pt-BR", :bg, :he, :fa]
      option_sets = [
        {},
        { decimal_places: 0 },
        { rounding_mode: :half_up },
        { rounding_mode: :floor },
        { grouping: :auto },
        { sign_display: :negative },
        { rounding_mode: :half_even, grouping: :auto, sign_display: :negative },
      ]
      amounts = [12345.675, -12345.675, 0, -0.004, BigDecimal("-123456789012345678.905")]
      codes = Currencies.all.map(&:currency_code)
      sampled_codes = ["USD", "EUR", "JPY", "KWD", "CLP", "HKD", "ANG", "INR", "ILS", "USDC"]

      assert_operator codes.size, :>, 250

      layout = /\A(minus_sign )?(literal )?(currency (literal )?number|number (literal )?currency)\z/

      cases = codes.product(locales, [-12345.675], [{}]) + sampled_codes.product(locales, amounts, option_sets)
      cases.each do |code, locale, amount, options|
        currency = Worldwide.currency(code: code)
        message = "#{code} #{locale} #{amount.inspect} #{options.inspect}"
        parts = currency.format_to_parts(amount, locale: locale, **options)
        short = currency.format_short(amount, locale: locale, **options)

        assert_equal short, parts.map { |part| part[:value] }.join, message
        assert_match layout, parts.map { |part| part[:type] }.join(" "), message
        assert(parts.all? { |part| part.keys == [:type, :value] && !part[:value].empty? }, message)
        assert_equal currency.symbol(locale: locale) || code, parts.find { |part| part[:type] == :currency }[:value], message
        assert_equal short.start_with?("-"), parts.first[:type] == :minus_sign, message
      end
    end

    test "rounding_mode:, grouping: and sign_display: change #format_short, #format_explicit and #format_to_parts" do
      [
        # pl and es have CLDR minimum grouping digits of 2
        ["PLN", :pl, 1234.5, {}, [[:number, "1\u00A0234,50"], [:literal, "\u00A0"], [:currency, "zł"]]],
        ["PLN", :pl, 1234.5, { grouping: :auto }, [[:number, "1234,50"], [:literal, "\u00A0"], [:currency, "zł"]]],
        ["PLN", :pl, -12345.5, { grouping: :auto }, [[:minus_sign, "-"], [:number, "12\u00A0345,50"], [:literal, "\u00A0"], [:currency, "zł"]]],
        ["EUR", :es, 1234.5, { grouping: :auto }, [[:number, "1234,50"], [:literal, "\u00A0"], [:currency, "€"]]],
        ["EUR", :"pt-PT", -1234.5, { grouping: :auto }, [[:minus_sign, "-"], [:number, "1234,50"], [:literal, "\u00A0"], [:currency, "€"]]],
        ["USD", :en, 1234.5, { grouping: :auto }, [[:currency, "$"], [:number, "1,234.50"]]],
        # it and hu have minimum grouping digits of 2 in CLDR 48, and it-CH inherits it from it
        ["EUR", :it, 1234.5, {}, [[:number, "1.234,50"], [:literal, "\u00A0"], [:currency, "€"]]],
        ["EUR", :it, 1234.5, { grouping: :auto }, [[:number, "1234,50"], [:literal, "\u00A0"], [:currency, "€"]]],
        ["EUR", :"it-CH", 1234.5, { grouping: :auto }, [[:currency, "€"], [:literal, "\u00A0"], [:number, "1234.50"]]],
        ["HUF", :hu, -1234.5, { grouping: :auto }, [[:minus_sign, "-"], [:number, "1234,50"], [:literal, "\u00A0"], [:currency, "Ft"]]],
        # A tie, rounded half-even by default for a BigDecimal
        ["USD", :en, BigDecimal("0.125"), {}, [[:currency, "$"], [:number, "0.12"]]],
        ["USD", :en, BigDecimal("0.125"), { rounding_mode: :half_up }, [[:currency, "$"], [:number, "0.13"]]],
        ["USD", :en, BigDecimal("-0.125"), { rounding_mode: :half_up }, [[:minus_sign, "-"], [:currency, "$"], [:number, "0.13"]]],
        ["JPY", :ja, 2.5, {}, [[:currency, "￥"], [:number, "2"]]],
        ["JPY", :ja, 2.5, { rounding_mode: :half_up }, [[:currency, "￥"], [:number, "3"]]],
        ["USD", :en, -1.234, { rounding_mode: :floor }, [[:minus_sign, "-"], [:currency, "$"], [:number, "1.24"]]],
        ["KWD", :ar, 1.0005, { rounding_mode: :ceiling }, [[:literal, "\u200F"], [:number, "1.001"], [:literal, "\u00A0"], [:currency, "د.ك.\u200F"]]],
        # A negative amount that rounds to zero
        ["USD", :en, -0.004, { sign_display: :negative }, [[:currency, "$"], [:number, "0.00"]]],
        ["USD", :en, -0.005, { sign_display: :negative }, [[:minus_sign, "-"], [:currency, "$"], [:number, "0.01"]]],
        ["EUR", :fr, BigDecimal("-0.004"), { sign_display: :negative }, [[:number, "0,00"], [:literal, "\u00A0"], [:currency, "€"]]],
        ["EUR", :"de-AT", -0.0, { sign_display: :negative }, [[:currency, "€"], [:literal, "\u00A0"], [:number, "0,00"]]],
        ["JPY", :ja, -0.4, { sign_display: :negative }, [[:currency, "￥"], [:number, "0"]]],
        ["JPY", :ja, -0.5, { rounding_mode: :half_up, sign_display: :negative }, [[:minus_sign, "-"], [:currency, "￥"], [:number, "1"]]],
      ].each do |code, locale, amount, options, expected|
        currency = Worldwide.currency(code: code)
        message = "#{code} #{locale} #{amount.inspect} #{options.inspect}"
        expected_short = expected.map(&:last).join

        assert_equal expected, currency.format_to_parts(amount, locale: locale, **options).map { |part| [part[:type], part[:value]] }, message
        assert_equal expected_short, currency.format_short(amount, locale: locale, **options), message
        assert_equal "#{expected_short} #{code}", currency.format_explicit(amount, locale: locale, **options), message
      end
    end

    test "rounding_mode:, grouping: and sign_display: apply with humanize:, as_minor_units: and use_symbol: false" do
      [
        ["EUR", :es, 1_234_567_890, { humanize: :short }, "1.235\u00A0M\u00A0€"],
        ["EUR", :es, 1_234_567_890, { humanize: :short, grouping: :auto }, "1235\u00A0M\u00A0€"],
        ["USD", :en, -0.0, { humanize: :short }, "-$0"],
        ["USD", :en, -0.0, { humanize: :long, sign_display: :negative }, "$0"],
        ["JPY", :ja, 12344.5, { humanize: :japan, decimal_places: 0 }, "1万2344円"],
        ["JPY", :ja, 12344.5, { humanize: :japan, decimal_places: 0, rounding_mode: :half_up }, "1万2345円"],
        ["JPY", :ja, -0.0, { humanize: :japan }, "-0円"],
        ["JPY", :ja, -0.0, { humanize: :japan, sign_display: :negative }, "0円"],
        ["USD", :en, 0.285, { as_minor_units: true }, "28¢"],
        ["USD", :en, 0.285, { as_minor_units: true, rounding_mode: :half_up }, "29¢"],
        ["USD", :en, 0.29, { as_minor_units: true, rounding_mode: :floor }, "29¢"],
        ["USD", :en, -0.29, { as_minor_units: true, rounding_mode: :ceiling }, "-29¢"],
        ["USD", :en, BigDecimal("1.005"), { as_minor_units: true }, "100¢"],
        ["USD", :en, BigDecimal("1.005"), { as_minor_units: true, rounding_mode: :half_up }, "101¢"],
        ["USD", :en, 1.2195, { as_minor_units: true, decimal_places: 3, rounding_mode: :half_down }, "121.9¢"],
        ["USD", :en, -0.004, { as_minor_units: true }, "-0¢"],
        ["USD", :en, -0.004, { as_minor_units: true, sign_display: :negative }, "0¢"],
        ["USD", :es, 12.345, { as_minor_units: true }, "1.234¢"],
        ["USD", :es, 12.345, { as_minor_units: true, grouping: :auto }, "1234¢"],
        ["EUR", :es, 1234.5, { as_minor_units: true, grouping: :auto }, "1234,50\u00A0€"],
        ["PLN", :pl, 1234.5, { use_symbol: false }, "1\u00A0234,50"],
        ["PLN", :pl, 1234.5, { use_symbol: false, grouping: :auto }, "1234,50"],
        ["USD", :en, BigDecimal("0.125"), { use_symbol: false, rounding_mode: :half_up }, "0.13"],
        ["USD", :en, -0.004, { use_symbol: false, sign_display: :negative }, "0.00"],
      ].each do |code, locale, amount, options, expected_short|
        currency = Worldwide.currency(code: code)
        message = "#{code} #{locale} #{amount.inspect} #{options.inspect}"

        assert_equal expected_short, currency.format_short(amount, locale: locale, **options), message
        assert_equal "#{expected_short} #{code}", currency.format_explicit(amount, locale: locale, **options), message
      end
    end

    test "rounding_mode: :up rounds an amount far below the last decimal place away from zero on every formatting path" do
      usd = Worldwide.currency(code: "USD")
      jpy = Worldwide.currency(code: "JPY")
      signs = [["", []], ["-", [[:minus_sign, "-"]]]]

      ["1e-10", "1e-30", "0.0000000000000000000000000000000000000001"].each do |digits|
        signs.each do |sign, sign_parts|
          amount = BigDecimal("#{sign}#{digits}")
          message = amount.inspect

          assert_equal sign_parts + [[:currency, "$"], [:number, "0.01"]],
            usd.format_to_parts(amount, locale: :en, rounding_mode: :up).map { |part| [part[:type], part[:value]] },
            message
          assert_equal "#{sign}$0.01", usd.format_short(amount, locale: :en, rounding_mode: :up), message
          assert_equal "#{sign}$0.01 USD", usd.format_explicit(amount, locale: :en, rounding_mode: :up), message
          assert_equal "#{sign}1¢", usd.format_short(amount, locale: :en, as_minor_units: true, rounding_mode: :up), message
          assert_equal "#{sign}1¢ USD", usd.format_explicit(amount, locale: :en, as_minor_units: true, rounding_mode: :up), message
          assert_equal "#{sign}0.01", usd.format_short(amount, locale: :en, use_symbol: false, rounding_mode: :up), message
          assert_equal "#{sign}1円", jpy.format_short(amount, locale: :ja, humanize: :japan, decimal_places: 0, rounding_mode: :up), message
          assert_equal "#{sign}$0.00", usd.format_short(amount, locale: :en, rounding_mode: :down), message
        end
      end
    end

    test "a nil or String amount with rounding_mode: raises ArgumentError on every formatting path" do
      usd = Worldwide.currency(code: "USD")
      paths = [{}, { humanize: :japan }, { as_minor_units: true }, { use_symbol: false }]
      methods = [:format_short, :format_explicit]

      assert_respond_to nil, :to_d
      [[nil, "nil"], ["12.5", "String"]].each do |amount, kind|
        message = "rounding_mode: is not supported with a #{kind} amount"

        paths.each do |path|
          methods.each do |method|
            error = assert_raises(ArgumentError, "#{method} #{amount.inspect} #{path.inspect}") do
              usd.public_send(method, amount, locale: :en, rounding_mode: :half_even, **path)
            end

            assert_includes error.message, message
          end
        end
        error = assert_raises(ArgumentError, amount.inspect) { usd.format_to_parts(amount, locale: :en, rounding_mode: :up) }

        assert_includes error.message, message
      end
    end

    test "unsupported keyword combinations raise ArgumentError from Numbers#format" do
      usd = Worldwide.currency(code: "USD")

      [
        [{ humanize: :short, rounding_mode: :half_up }, "rounding_mode: is not supported with humanize: :short"],
        [{ humanize: :long, rounding_mode: :half_even }, "rounding_mode: is not supported with humanize: :long"],
        [{ humanize: :japan, grouping: :auto }, "grouping: :auto is not supported with humanize: :japan"],
        [{ humanize: :japan, grouping: :auto, use_symbol: false }, "grouping: :auto is not supported with humanize: :japan"],
        [{ humanize: :short, rounding_mode: :up, use_symbol: false }, "rounding_mode: is not supported with humanize: :short"],
      ].each do |options, message|
        error = assert_raises(ArgumentError, options.inspect) { usd.format_short(1234.5, locale: :en, **options) }

        assert_includes error.message, message
        error = assert_raises(ArgumentError, options.inspect) { usd.format_explicit(1234.5, locale: :en, **options) }

        assert_includes error.message, message
      end
    end

    test "unsupported keyword values raise ArgumentError on every formatting path" do
      usd = Worldwide.currency(code: "USD")
      eur = Worldwide.currency(code: "EUR")
      paths = [{}, { humanize: :short }, { humanize: :japan }, { as_minor_units: true }, { use_symbol: false }]

      [
        [{ rounding_mode: :nearest }, "Unsupported value for rounding_mode: :nearest"],
        [{ grouping: :min2 }, "Unsupported value for grouping: :min2"],
        [{ sign_display: :never }, "Unsupported value for sign_display: :never"],
      ].each do |options, message|
        paths.each do |path|
          [usd, eur].each do |currency|
            error = assert_raises(ArgumentError) { currency.format_short(1234.5, locale: :en, **path, **options) }

            assert_includes error.message, message
            error = assert_raises(ArgumentError) { currency.format_explicit(1234.5, locale: :en, **path, **options) }

            assert_includes error.message, message
          end
        end
        error = assert_raises(ArgumentError) { usd.format_to_parts(1234.5, locale: :en, **options) }

        assert_includes error.message, message
      end
    end

    test "the direction marks of a currency pattern are written as in the pattern" do
      # he: "\u200F#,##0.00\u00A0\u200F¤;\u200F-#,##0.00\u00A0\u200F¤", fa: "\u200E¤\u00A0#,##0.00"
      assert_equal "\u200F1,234.50\u00A0\u200F₪", Worldwide.currency(code: "ILS").format_short(1234.5, locale: :"he-IL")
      assert_equal "-\u200F1,234.50\u00A0\u200F₪", Worldwide.currency(code: "ILS").format_short(-1234.5, locale: :"he-IL")
      assert_equal "\u200F1,234.50\u00A0\u200F$ USD", Worldwide.currency(code: "USD").format_explicit(1234.5, locale: :"he-IL")
      assert_equal "\u200E$\u00A01,234.50", Worldwide.currency(code: "USD").format_short(1234.5, locale: :fa)
      assert_equal "\u200E$\u00A01,234.50", Worldwide.currency(code: "USD").format_short(1234.5, locale: :"fa-IR")
      assert_equal(
        [{ type: :minus_sign, value: "-" }, { type: :literal, value: "\u200E" }, { type: :currency, value: "$" }, { type: :literal, value: "\u00A0" }, { type: :number, value: "1,234.50" }],
        Worldwide.currency(code: "USD").format_to_parts(-1234.5, locale: :fa),
      )
      # ar: "\u200F#,##0.00\u00A0¤;\u200F-#,##0.00\u00A0¤"
      assert_equal "\u200F1,234.50\u00A0$", Worldwide.currency(code: "USD").format_short(1234.5, locale: :ar)
      assert_equal "\u200F1,234.50\u00A0E£", Worldwide.currency(code: "EGP").format_short(1234.5, locale: :"ar-EG")
      assert_equal "\u200F1,234.50\u00A0$", Worldwide::Cldr.with_bundled_data { Worldwide.currency(code: "USD").format_short(1234.5, locale: :"ar-AE") }
    end

    test "CLDR 42 gives he a right-to-left mark before the currency symbol" do
      ils = Worldwide.currency(code: "ILS")

      [:he, :"he-IL"].each do |locale|
        assert_equal "\u200F1,234.50\u00A0\u200F₪", ils.format_short(1234.5, locale: locale), locale
        assert_equal "\u200F1,234.50\u00A0\u200F₪ ILS", ils.format_explicit(1234.5, locale: locale), locale
        assert_equal(
          [{ type: :literal, value: "\u200F" }, { type: :number, value: "1,234.50" }, { type: :literal, value: "\u00A0\u200F" }, { type: :currency, value: "₪" }],
          ils.format_to_parts(1234.5, locale: locale),
          locale,
        )
      end
    end

    test "#format_to_parts covers the symbol format only" do
      usd = Worldwide.currency(code: "USD")

      [{ humanize: :short }, { as_minor_units: true }, { use_symbol: false }].each do |options|
        assert_raises(ArgumentError, options.inspect) { usd.format_to_parts(12.5, locale: :en, **options) }
      end
    end

    test "parts can be recomposed with another symbol, spacing and sign" do
      recompose = lambda do |parts, symbol:|
        parts.filter_map do |part|
          case part[:type]
          when :minus_sign then nil
          when :currency then symbol
          when :literal then part[:value].tr("\u00A0", " ")
          else part[:value]
          end
        end.join
      end

      assert_equal "1\u202F234,50 EUR", recompose.call(Worldwide.currency(code: "EUR").format_to_parts(-1234.5, locale: :fr), symbol: "EUR")
      assert_equal "US$ 1\u00A0234,50", recompose.call(Worldwide.currency(code: "USD").format_to_parts(-1234.5, locale: :"de-AT"), symbol: "US$")
      assert_equal "US$1,234.50", recompose.call(Worldwide.currency(code: "USD").format_to_parts(-1234.5, locale: :en), symbol: "US$")
      assert_equal "-$\u00A01\u00A0234,50", Worldwide.currency(code: "USD").format_short(-1234.5, locale: :"de-AT")
    end

    test "#format_to_parts returns new objects that the caller can change" do
      [["USD", :en], ["EUR", :fr], ["HKD", :en], ["ANG", :en], ["KWD", :en], ["ILS", :he], ["USD", :fa]].each do |code, locale|
        currency = Worldwide.currency(code: code)
        symbol = currency.symbol(locale: locale)
        expected = currency.format_to_parts(-1234.5, locale: locale)
        expected_values = expected.map { |part| part[:value].dup }

        parts = currency.format_to_parts(-1234.5, locale: locale)

        refute_same expected, parts
        parts.each_with_index do |part, index|
          refute_same expected[index], part
          refute_same expected[index][:value], part[:value]
          refute_predicate part[:value], :frozen?
          part[:value] << "!"
          part[:type] = :changed
        end
        parts << { type: :literal, value: "?" }

        assert_equal expected_values, expected.map { |part| part[:value] }, code
        assert_equal expected_values, currency.format_to_parts(-1234.5, locale: locale).map { |part| part[:value] }, code
        assert_equal expected_values.join, currency.format_short(-1234.5, locale: locale), code
        assert_equal [symbol], [currency.symbol(locale: locale)], code
        assert_equal code, currency.currency_code
      end
    end
  end
end
