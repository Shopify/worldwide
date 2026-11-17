# frozen_string_literal: true

require "bigdecimal"
# Rails loads bigdecimal/util, which gives String and nil a to_d.
require "bigdecimal/util"
require "test_helper"
require "worldwide/cldr/bundled_data_test_helper"

module Worldwide
  class NumbersTest < ActiveSupport::TestCase
    include Worldwide::BundledDataTestHelper

    test "number format for en-US" do
      data = [
        [12, "12.00"],
        [0.34, "0.34"],
        [1234567.8, "1,234,567.80"],
        [311.3148, "311.31"],
        [123456789012.21, "123,456,789,012.21"],
        [-1, "-1.00"],
        [-123.45, "-123.45"],
        [-1234.5, "-1,234.50"],
      ]

      number_formatter = Worldwide::Numbers.new(locale: "en-US")
      data.each do |input, expected|
        actual = number_formatter.format(input, decimal_places: 2)

        assert_equal expected, actual
      end
    end

    test "number format for en-US with natural decimal places" do
      data = [
        [12, "12"],
        ["12.00", "12"],
        [0.34, "0.34"],
        [1234567.8, "1,234,567.8"],
        [311.3148, "311.3148"],
        [123456789012.21, "123,456,789,012.21"],
        [-1, "-1"],
        ["-1.0", "-1"],
        [-123.45, "-123.45"],
        [-1234.5, "-1,234.5"],
        [-1234.05, "-1,234.05"],
        ["-1234.05", "-1,234.05"],
        [99.00101, "99.00101"],
        ["99.00101", "99.00101"],
      ]

      number_formatter = Worldwide::Numbers.new(locale: "en-US")
      data.each do |input, expected|
        actual = number_formatter.format(input, decimal_places: nil)

        assert_equal expected, actual
      end
    end

    test "number format for en-IN" do
      data = [
        [1, "1.00"],
        [12.34, "12.34"],
        [1234.56, "1,234.56"],
        [12345.67, "12,345.67"],
        [1234567.89, "12,34,567.89"],
        [78901234.56, "7,89,01,234.56"],
        [-1, "-1.00"],
        [-123.45, "-123.45"],
        [-1234.56, "-1,234.56"],
        [-1234567.89, "-12,34,567.89"],
      ]

      number_formatter = Worldwide::Numbers.new(locale: "en-IN")
      data.each do |input, expected|
        actual = number_formatter.format(input, decimal_places: 2)

        assert_equal expected, actual
      end
    end

    test "short number format for es" do
      data = [
        [31_415_925_600, "31.416 M"],
        [314_159_256_000, "314.159 M"],
      ]

      number_formatter = Worldwide::Numbers.new(locale: "es")
      data.each do |input, expected|
        actual = number_formatter.format(input, humanize: :short)

        assert_equal expected, actual
      end
    end

    test "Values using the default compact pattern ('0') instead uses the default formatting for the locale" do
      # https://unicode-org.github.io/cldr/ldml/tr35-numbers.html#Compact_Number_Formats

      # First, ensure that the data still use the default pattern
      # If CLDR data changes, we'll need to update this test
      assert_equal(Worldwide::Cldr.t("numbers.latn.formats.decimal.patterns.short.standard.1000", count: 1, locale: :de), Worldwide::Numbers::DEFAULT_COMPACT_PATTERN)
      assert_equal(Worldwide::Cldr.t("numbers.latn.formats.decimal.patterns.short.standard.1000", count: 1, locale: :ja), Worldwide::Numbers::DEFAULT_COMPACT_PATTERN)
      assert_equal(Worldwide::Cldr.t("numbers.latn.formats.decimal.patterns.short.standard.100000", count: 1, locale: :it), Worldwide::Numbers::DEFAULT_COMPACT_PATTERN)

      data = [
        [:de, 1_234, "1.234"],
        [:ja, 1_234, "1,234"],
        [:it, 123456, "123.456"],
      ]

      data.each do |locale, input, expected|
        number_formatter = Worldwide::Numbers.new(locale: locale)
        actual = number_formatter.format(input, humanize: :short)

        assert_equal expected, actual
      end
    end

    test "number format for zh-HK uses zh-Hant formatting" do
      expected = "100萬"
      actual = Worldwide::Numbers.new(locale: :"zh-HK").format(1_000_000, humanize: :long)

      assert_equal expected, actual
    end

    test "number format with no decimal places" do
      data = [
        [1, "1", "1", "1"],
        [123, "123", "123", "123"],
        [1234, "1,234", "1,234", "1.234"],
        [1234567, "1,234,567", "12,34,567", "1.234.567"],
        [-1, "-1", "-1", "-1"],
        [-123, "-123", "-123", "-123"],
        [-1234, "-1,234", "-1,234", "-1.234"],
        [-1234567, "-1,234,567", "-12,34,567", "-1.234.567"],
      ]

      data.each do |input, expected_us, expected_in, expected_de|
        actual = Worldwide::Numbers.new(locale: :"en-US").format(input, decimal_places: 0)

        assert_equal expected_us, actual

        actual = Worldwide::Numbers.new(locale: :"en-IN").format(input, decimal_places: 0)

        assert_equal expected_in, actual

        actual = Worldwide::Numbers.new(locale: :"de-DE").format(input, decimal_places: 0)

        assert_equal expected_de, actual
      end
    end

    test "default locale is used when no locale specified" do
      data = [
        [1234567.89, "1,234,567.89", :"en-US"],
        [1234567.89, "12,34,567.89", :"en-IN"],
        [1234567.89, "1.234.567,89", :"de-DE"],
      ]

      data.each do |input, expected, locale|
        I18n.with_locale(locale) do
          number_formatter = Worldwide::Numbers.new
          actual = number_formatter.format(input, decimal_places: 2)

          assert_equal expected, actual
        end
      end
    end

    test "negative numbers format correctly in all locales" do
      data = ["af", "af-NA", "af-ZA", "ak", "ak-GH", "am", "am-ET", "ar", "ar-001", "ar-AE", "ar-BH", "ar-DJ", "ar-DZ", "ar-EG", "ar-EH", "ar-ER", "ar-IL", "ar-IQ", "ar-JO", "ar-KM", "ar-KW", "ar-LB", "ar-LY", "ar-MA", "ar-MR", "ar-OM", "ar-PS", "ar-QA", "ar-SA", "ar-SD", "ar-SO", "ar-SS", "ar-SY", "ar-TD", "ar-TN", "ar-YE", "as", "as-IN", "az", "az-Cyrl", "az-Cyrl-AZ", "az-Latn", "az-Latn-AZ", "be", "be-BY", "bg", "bg-BG", "bm", "bm-ML", "bn", "bn-BD", "bn-IN", "bo", "bo-CN", "bo-IN", "br", "br-FR", "bs", "bs-Cyrl", "bs-Cyrl-BA", "bs-Latn", "bs-Latn-BA", "ca", "ca-AD", "ca-ES", "ca-FR", "ca-IT", "ce", "ce-RU", "ckb", "ckb-IQ", "ckb-IR", "cs", "cs-CZ", "cy", "cy-GB", "da", "da-DK", "da-GL", "de", "de-AT", "de-BE", "de-CH", "de-DE", "de-IT", "de-LI", "de-LU", "dz", "dz-BT", "ee", "ee-GH", "ee-TG", "el", "el-CY", "el-GR", "en", "en-001", "en-150", "en-AG", "en-AI", "en-AS", "en-AT", "en-AU", "en-BB", "en-BE", "en-BI", "en-BM", "en-BS", "en-BW", "en-BZ", "en-CA", "en-CC", "en-CH", "en-CK", "en-CM", "en-CX", "en-CY", "en-DE", "en-DG", "en-DK", "en-DM", "en-ER", "en-FI", "en-FJ", "en-FK", "en-FM", "en-GB", "en-GD", "en-GG", "en-GH", "en-GI", "en-GM", "en-GU", "en-GY", "en-HK", "en-IE", "en-IL", "en-IM", "en-IN", "en-IO", "en-JE", "en-JM", "en-KE", "en-KI", "en-KN", "en-KY", "en-LC", "en-LR", "en-LS", "en-MG", "en-MH", "en-MO", "en-MP", "en-MS", "en-MT", "en-MU", "en-MW", "en-MY", "en-NA", "en-NF", "en-NG", "en-NL", "en-NR", "en-NU", "en-NZ", "en-PG", "en-PH", "en-PK", "en-PN", "en-PR", "en-PW", "en-RW", "en-SB", "en-SC", "en-SD", "en-SE", "en-SG", "en-SH", "en-SI", "en-SL", "en-SS", "en-SX", "en-SZ", "en-TC", "en-TK", "en-TO", "en-TT", "en-TV", "en-TZ", "en-UG", "en-UM", "en-US", "en-VC", "en-VG", "en-VI", "en-VU", "en-WS", "en-ZA", "en-ZM", "en-ZW", "eo", "eo-001", "es", "es-419", "es-AR", "es-BO", "es-BR", "es-BZ", "es-CL", "es-CO", "es-CR", "es-CU", "es-DO", "es-EA", "es-EC", "es-ES", "es-GQ", "es-GT", "es-HN", "es-IC", "es-MX", "es-NI", "es-PA", "es-PE", "es-PH", "es-PR", "es-PY", "es-SV", "es-US", "es-UY", "es-VE", "et", "et-EE", "eu", "eu-ES", "fa", "fa-AF", "fa-IR", "ff", "ff-Latn", "ff-Latn-BF", "ff-Latn-CM", "ff-Latn-GH", "ff-Latn-GM", "ff-Latn-GN", "ff-Latn-GW", "ff-Latn-LR", "ff-Latn-MR", "ff-Latn-NE", "ff-Latn-NG", "ff-Latn-SL", "ff-Latn-SN", "fi", "fi-FI", "fil", "fil-PH", "fo", "fo-DK", "fo-FO", "fr", "fr-BE", "fr-BF", "fr-BI", "fr-BJ", "fr-BL", "fr-CA", "fr-CD", "fr-CF", "fr-CG", "fr-CH", "fr-CI", "fr-CM", "fr-DJ", "fr-DZ", "fr-FR", "fr-GA", "fr-GF", "fr-GN", "fr-GP", "fr-GQ", "fr-HT", "fr-KM", "fr-LU", "fr-MA", "fr-MC", "fr-MF", "fr-MG", "fr-ML", "fr-MQ", "fr-MR", "fr-MU", "fr-NC", "fr-NE", "fr-PF", "fr-PM", "fr-RE", "fr-RW", "fr-SC", "fr-SN", "fr-SY", "fr-TD", "fr-TG", "fr-TN", "fr-VU", "fr-WF", "fr-YT", "fy", "fy-NL", "ga", "ga-IE", "gd", "gd-GB", "gl", "gl-ES", "gu", "gu-IN", "gv", "gv-IM", "ha", "ha-GH", "ha-NG", "he", "he-IL", "hi", "hi-IN", "hr", "hr-BA", "hr-HR", "hu", "hu-HU", "hy", "hy-AM", "ia", "ia-001", "id", "id-ID", "ig", "ig-NG", "ii", "ii-CN", "is", "is-IS", "it", "it-CH", "it-IT", "it-SM", "it-VA", "ja", "ja-JP", "jv", "jv-ID", "ka", "ka-GE", "ki", "ki-KE", "kk", "kk-KZ", "kl", "kl-GL", "km", "km-KH", "kn", "kn-IN", "ko", "ko-KP", "ko-KR", "ks", "ku", "ku-TR", "kw", "kw-GB", "ky", "ky-KG", "lb", "lb-LU", "lg", "lg-UG", "ln", "ln-AO", "ln-CD", "ln-CF", "ln-CG", "lo", "lo-LA", "lt", "lt-LT", "lu", "lu-CD", "lv", "lv-LV", "mg", "mg-MG", "mi", "mi-NZ", "mk", "mk-MK", "ml", "ml-IN", "mn", "mn-MN", "mr", "mr-IN", "ms", "ms-BN", "ms-MY", "ms-SG", "mt", "mt-MT", "my", "my-MM", "nb", "nb-NO", "nb-SJ", "nd", "nd-ZW", "ne", "ne-IN", "ne-NP", "nl", "nl-AW", "nl-BE", "nl-BQ", "nl-CW", "nl-NL", "nl-SR", "nl-SX", "nn", "nn-NO", "om", "om-ET", "om-KE", "or", "or-IN", "os", "os-GE", "os-RU", "pa", "pa-Arab", "pa-Arab-PK", "pa-Guru", "pa-Guru-IN", "pl", "pl-PL", "ps", "ps-AF", "pt", "pt-AO", "pt-BR", "pt-CH", "pt-CV", "pt-GQ", "pt-GW", "pt-LU", "pt-MO", "pt-MZ", "pt-PT", "pt-ST", "pt-TL", "qu", "qu-BO", "qu-EC", "qu-PE", "rm", "rm-CH", "rn", "rn-BI", "ro", "ro-MD", "ro-RO", "root", "ru", "ru-BY", "ru-KG", "ru-KZ", "ru-MD", "ru-RU", "ru-UA", "rw", "rw-RW", "sd", "se", "se-FI", "se-NO", "se-SE", "sg", "sg-CF", "si", "si-LK", "sk", "sk-SK", "sl", "sl-SI", "sn", "sn-ZW", "so", "so-DJ", "so-ET", "so-KE", "so-SO", "sq", "sq-AL", "sq-MK", "sq-XK", "sr", "sr-Cyrl", "sr-Cyrl-BA", "sr-Cyrl-ME", "sr-Cyrl-RS", "sr-Cyrl-XK", "sr-Latn", "sr-Latn-BA", "sr-Latn-ME", "sr-Latn-RS", "sr-Latn-XK", "sv", "sv-AX", "sv-FI", "sv-SE", "sw", "sw-CD", "sw-KE", "sw-TZ", "sw-UG", "ta", "ta-IN", "ta-LK", "ta-MY", "ta-SG", "te", "te-IN", "tg", "tg-TJ", "th", "th-TH", "ti", "ti-ER", "ti-ET", "tk", "tk-TM", "to", "to-TO", "tr", "tr-CY", "tr-TR", "tt", "tt-RU", "ug", "ug-CN", "uk", "uk-UA", "ur", "ur-IN", "ur-PK", "uz", "uz-Arab", "uz-Arab-AF", "uz-Cyrl", "uz-Cyrl-UZ", "uz-Latn", "uz-Latn-UZ", "vi", "vi-VN", "wo", "wo-SN", "xh", "xh-ZA", "yi", "yi-001", "yo", "yo-BJ", "yo-NG", "zh", "zh-Hans", "zh-Hans-CN", "zh-Hans-HK", "zh-Hans-MO", "zh-Hans-SG", "zh-Hant", "zh-Hant-HK", "zh-Hant-MO", "zh-Hant-TW", "zu", "zu-ZA"]

      data.each do |locale|
        actual = Worldwide::Numbers.new(locale: locale).format(-123, decimal_places: 0)

        assert_equal "-123", actual

        I18n.with_locale(locale) do
          actual = Worldwide::Numbers.new.format(-123, decimal_places: 0)

          assert_equal "-123", actual
        end
      end
    end

    test "#format(amount, humanize:) formats as expected" do
      data = [
        [:en, 0.0, "0", "0"],
        [:en, 0.17, "0.17", "0.17"],
        [:en, 12.75, "12.75", "12.75"],
        [:en, 1_000_000, "1.0M", "1.0 million"],
        [:en, 31_500_000, "32M", "32 million"],
        [:en, 30_500_000_000, "30B", "30 billion"],
        [:en, -31_500_000_000, "-32B", "-32 billion"],
        [:fr, 1_500, "1,5 k", "1,5 millier"],
        [:fr, 1_000_000, "1,0 M", "1,0 million"],
        [:fr, 3_200_000, "3,2 M", "3,2 millions"],
        [:fr, 2_400_000_000, "2,4 Md", "2,4 milliards"],
        [:ja, 1_000_000, "100万", "100万"],
        [:ja, 8_500_000_000, "85億", "85億"],
        [:"zh-HK", 1_000_000, "1.0M", "100萬"],
      ]

      data.each do |locale, number, expected_short, expected_long|
        actual = Worldwide::Numbers.new(locale: locale).format(number, humanize: :short)

        assert_equal expected_short, actual

        actual = Worldwide::Numbers.new(locale: locale).format(number, humanize: :long)

        assert_equal expected_long, actual
      end
    end

    test "#format(amount, humanize: :japan) insert Japanese grouping symbols as expected" do
      locales = ["en", "ja", "zh-CN"]

      [
        [0, "0"],
        [0.5, "0.5"],
        [12.75, "12.75"],
        [100, "100"],
        [1234, "1234"],
        [1_0001, "1万1"],
        [1_0010, "1万10"],
        [1_0253, "1万253"],
        [1_2345, "1万2345"],
        [1_2345.67, "1万2345.67"],
        [12_3456, "12万3456"],
        [123_4567, "123万4567"],
        [1234_5678, "1234万5678"],
        [1_0000_0000, "1億"],
        [1_0010_0000, "1億10万"],
        [1_0305_0080, "1億305万80"],
        [1_2345_6789, "1億2345万6789"],
        [2345_6789_1234_5678_9012_3456_7890, "2345秭6789垓1234京5678兆9012億3456万7890"],
      ].each do |amount, expected|
        locales.each do |locale|
          actual = Worldwide::Numbers.new(locale: locale).format(amount, humanize: :japan)

          assert_equal expected, actual
        end
      end
    end

    test "#format with humanize short/long extrapolates successfully beyond the given data" do
      [
        ["en-US", 1_000_000_000_000_000, "1,000 trillion", "1,000T"],
        ["en-US", 12_000_000_000_000_000, "12,000 trillion", "12,000T"],
        ["en-US", 123_000_000_000_000_000, "123,000 trillion", "123,000T"],
        ["en-US", 1_234_000_000_000_000_000, "1,234,000 trillion", "1,234,000T"],
        ["es-US", 1_000_000, "1.0 millón", "1.0 M"],
        ["es-US", 12_000_000, "12 millones", "12 M"],
        ["es-US", 123_000_000, "123 millones", "123 M"],
        ["es-US", 1_000_000_000_000_000, "1,000 billones", "1,000 B"],
        ["es-US", 1_234_000_000_000_000_000, "1,234,000 billones", "1,234,000 B"],
      ].each do |locale, amount, expected_long, expected_short|
        nf = Worldwide::Numbers.new(locale: locale)

        actual = nf.format(amount, humanize: :long)

        assert_equal expected_long, actual

        actual = nf.format(amount, humanize: :short)

        assert_equal expected_short, actual
      end
    end

    test "#format with percent: true formats as expected" do
      [
        ["ar-AE", 0.75, "%75"], # This should actually be "٪٧٥", but that's a problem for another day
        ["en", 1, "100%"],
        ["en-CA", 0.5, "50%"],
        ["en-US", 0.001, "0.1%"],
        ["es", 0.3, "30 %"],
        ["fi", 0.25, "25 %"],
        ["fr", 0.001, "0,1 %"],
        ["he", 0.75, "75%"],
        ["ku", 0.1, "%10"],
        ["tr", 1, "%100"],
        ["ur", 0.02, "2%"],
        ["ur-PK", 0.02, "2%"],
        ["zh-CN", 0.22, "22%"],
      ].each do |locale, amount, expected|
        nf = Worldwide::Numbers.new(locale: locale)
        actual = nf.format(amount, percent: true)

        assert_equal("[#{locale}]:#{expected}", "[#{locale}]:#{actual}")
      end
    end

    test "#format relative percentages" do
      ["en", "id", "ja", "zh-CN", "zh-TW"].each do |locale|
        I18n.with_locale(locale) do
          nf = Numbers.new
          cases = [
            [0.6, "+60%"],
            [-0.45, "-45%"],
            [0, "+0%"],
          ]
          cases.each do |amount, expected|
            actual = nf.format(amount, percent: true, relative: true)

            assert_equal expected, actual
          end
        end
      end
    end

    test "#format humanized numbers with relative indicator" do
      I18n.with_locale(:en) do
        nf = Numbers.new

        assert_equal "+1.0 million", nf.format(1_000_000, humanize: :long, relative: true)
        assert_equal "-20 billion", nf.format(-20_000_000_000, humanize: :long, relative: true)
        assert_equal "+0", nf.format(0, humanize: :long, relative: true)
      end
    end

    test "#format removes single quotes from humanized abbreviation" do
      I18n.with_locale(:de) do
        # if this assertion fails, revisit whether filtering out quoted periods is still necessary
        assert_equal "0 Mrd'.'", I18n.t("numbers.latn.formats.decimal.patterns.short.standard.1000000000", count: 1)

        nf = Numbers.new

        assert_equal "1,0 Mrd.", nf.format(1_000_000_000, humanize: :short)
      end
    end

    # The option sets used by the legacy output matrix below, in column order.
    LEGACY_OPTION_SETS = [
      {},
      { decimal_places: 0 },
      { decimal_places: 2 },
      { decimal_places: 3 },
      { humanize: :short },
      { humanize: :long },
      { humanize: :japan },
      { percent: true },
      { relative: true },
      { percent: true, relative: true },
    ].freeze

    # A value that is not Numeric but converts with to_f, as some money types do.
    class FloatConvertible
      def initialize(value)
        @value = value
      end

      def to_f
        @value
      end
    end

    # A money-like value that also supports arithmetic and converts with to_d.
    class DecimalConvertible < FloatConvertible
      def to_d
        BigDecimal(@value.to_s)
      end

      def *(other)
        DecimalConvertible.new(@value * other)
      end

      def <(other)
        @value < other
      end

      def abs
        DecimalConvertible.new(@value.abs)
      end

      def to_s
        @value.to_s
      end
    end

    test "#format keeps the legacy output for Float, Integer, Rational and String amounts" do
      # Output before rounding_mode: and sign_display: were added, one column per LEGACY_OPTION_SETS entry.
      # nil marks a combination that raised.
      [
        [0.0, "0", "0", "0.00", "0.000", "0", "0", "0", "0%", "+0", "+0%"],
        [-0.0, "-0", "-0", "-0.00", "-0.000", "-0", "-0", "-0", "-0%", "+-0", "+-0%"],
        [0.34, "0.34", "0", "0.34", "0.340", "0.34", "0.34", "0.34", "34%", "+0.34", "+34%"],
        [0.125, "0.125", "0", "0.12", "0.125", "0.125", "0.125", "0.125", "12.5%", "+0.125", "+12.5%"],
        [1.005, "1.005", "1", "1.00", "1.005", "1.005", "1.005", "1.005", "100.49999999999999%", "+1.005", "+100.49999999999999%"],
        [1.015, "1.015", "1", "1.02", "1.015", "1.015", "1.015", "1.015", "101.49999999999999%", "+1.015", "+101.49999999999999%"],
        [2.5, "2.5", "2", "2.50", "2.500", "2.5", "2.5", "2.5", "250%", "+2.5", "+250%"],
        [-0.004, "-0.004", "-0", "-0.00", "-0.004", "-0.004", "-0.004", "-0.004", "-0.4%", "-0.004", "-0.4%"],
        [-0.005, "-0.005", "-0", "-0.01", "-0.005", "-0.005", "-0.005", "-0.005", "-0.5%", "-0.005", "-0.5%"],
        [1234.5, "1,234.5", "1,234", "1,234.50", "1,234.500", "1.2K", "1.2 thousand", "1234.5", "123,450%", "+1,234.5", "+123,450%"],
        [-1234.56, "-1,234.56", "-1,235", "-1,234.56", "-1,234.560", "-1K", "-1 thousand", "-万1234.56", "-123,456%", "-1,234.56", "-123,456%"],
        [1234567.891, "1,234,567.891", "1,234,568", "1,234,567.89", "1,234,567.891", "1.2M", "1.2 million", "123万4567.891", "123,456,789.10000001%", "+1,234,567.891", "+123,456,789.10000001%"],
        [31_500_000.0, "31,500,000", "31,500,000", "31,500,000.00", "31,500,000.000", "32M", "32 million", "3150万", "3,150,000,000%", "+31,500,000", "+3,150,000,000%"],
        [123456789012.21, "123,456,789,012.21", "123,456,789,012", "123,456,789,012.21", "123,456,789,012.210", "123B", "123 billion", "1234億5678万9012.21", "12,345,678,901,221%", "+123,456,789,012.21", "+12,345,678,901,221%"],
        [1.0e20, "100,000,000,000,000,000,000.00000", "100,000,000,000,000,000,000", "100,000,000,000,000,000,000.00", "100,000,000,000,000,000,000.000", "100,000,000T", "100,000,000 trillion", "1垓.00000", "10,000,000,000,000,000,000,000.00000%", "+100,000,000,000,000,000,000.00000", "+10,000,000,000,000,000,000,000.00000%"],
        [99.00101, "99.00101", "99", "99.00", "99.001", "99.00101", "99.00101", "99.00101", "9,900.100999999999%", "+99.00101", "+9,900.100999999999%"],
        [Float::NAN, "NaN", "NaN", "NaN", "NaN", "NaN", "NaN", "NaN", "NaN%", "+NaN", "+NaN%"],
        [Float::INFINITY, "Inf", "Inf", "Inf", "Inf", nil, nil, "Inf", "Inf%", "+Inf", "+Inf%"],
        [-Float::INFINITY, "-Inf", "-Inf", "-Inf", "-Inf", nil, nil, "-Inf", "-Inf%", "-Inf", "-Inf%"],
        [0, "0", "0", "0.00", "0.000", "0", "0", "0", "0%", "+0", "+0%"],
        [7, "7", "7", "7.00", "7.000", "7", "7", "7", "700%", "+7", "+700%"],
        [-1234, "-1,234", "-1,234", "-1,234.00", "-1,234.000", "-1K", "-1 thousand", "-万1234", "-123,400%", "-1,234", "-123,400%"],
        [1_234_567, "1,234,567", "1,234,567", "1,234,567.00", "1,234,567.000", "1.2M", "1.2 million", "123万4567", "123,456,700%", "+1,234,567", "+123,456,700%"],
        [-31_500_000_000, "-31,500,000,000", "-31,500,000,000", "-31,500,000,000.00", "-31,500,000,000.000", "-32B", "-32 billion", "-315億", "-3,150,000,000,000%", "-31,500,000,000", "-3,150,000,000,000%"],
        [12_345_678_901_234_567_890_123, "12,345,678,901,234,567,890,123", "12,345,678,901,234,567,890,123", "12,345,678,901,234,567,890,123.00", "12,345,678,901,234,567,890,123.000", "12,345,678,901T", "12,345,678,901 trillion", "123垓4567京8901兆2345億6789万123", "1,234,567,890,123,456,789,012,300%", "+12,345,678,901,234,567,890,123", "+1,234,567,890,123,456,789,012,300%"],
        [5/2r, "3", "3", "2.50", "2.500", "3", "3", "3", "250%", "+3", "+250%"],
        [-5/2r, "-3", "-3", "-2.50", "-2.500", "-3", "-3", "-3", "-250%", "-3", "-250%"],
        [1/8r, "0", "0", "0.13", "0.125", "0", "0", "0", "13%", "+0", "+13%"],
        [1/3r, "0", "0", "0.33", "0.333", "0", "0", "0", "33%", "+0", "+33%"],
        [1234567/100r, "12,346", "12,346", "12,345.67", "12,345.670", "12K", "12 thousand", "1万2346", "1,234,567%", "+12,346", "+1,234,567%"],
        ["1234.5", "1,234.5", "1,234", "1,234.50", "1,234.500", nil, nil, "1234.5", nil, nil, nil],
        ["-1.0", "-1", "-1", "-1.00", "-1.000", nil, nil, "-1", nil, nil, nil],
        ["12.00", "12", "12", "12.00", "12.000", nil, nil, "12", nil, nil, nil],
      ].each do |amount, *expected_outputs|
        LEGACY_OPTION_SETS.zip(expected_outputs).each do |options, expected|
          next if expected.nil?

          formatter = Worldwide::Numbers.new(locale: :en)

          assert_equal expected, formatter.format(amount, **options), "#{amount.inspect} #{options.inspect}"
          assert_equal expected, formatter.format(amount, **options, rounding_mode: nil, grouping: :always, sign_display: :auto), "#{amount.inspect} #{options.inspect}"
        end
      end
    end

    test "#format keeps the legacy output for each locale's symbols and grouping" do
      locales = [:de, :fr, :"en-IN", :es, :pl, :ar, :"de-CH"]
      [
        [1234.5, { decimal_places: 2 }, "1.234,50", "1\u202F234,50", "1,234.50", "1.234,50", "1\u00A0234,50", "1,234.50", "1\u2019234.50"],
        [1234.5, {}, "1.234,5", "1\u202F234,5", "1,234.5", "1.234,5", "1\u00A0234,5", "1,234.5", "1\u2019234.5"],
        [-1234567.891, { decimal_places: 2 }, "-1.234.567,89", "-1\u202F234\u202F567,89", "-12,34,567.89", "-1.234.567,89", "-1\u00A0234\u00A0567,89", "-1,234,567.89", "-1\u2019234\u2019567.89"],
        [-1234567.891, {}, "-1.234.567,891", "-1\u202F234\u202F567,891", "-12,34,567.891", "-1.234.567,891", "-1\u00A0234\u00A0567,891", "-1,234,567.891", "-1\u2019234\u2019567.891"],
        [1_234_567, { decimal_places: 2 }, "1.234.567,00", "1\u202F234\u202F567,00", "12,34,567.00", "1.234.567,00", "1\u00A0234\u00A0567,00", "1,234,567.00", "1\u2019234\u2019567.00"],
        [1_234_567, {}, "1.234.567", "1\u202F234\u202F567", "12,34,567", "1.234.567", "1\u00A0234\u00A0567", "1,234,567", "1\u2019234\u2019567"],
        [12345.678, { decimal_places: 2 }, "12.345,68", "12\u202F345,68", "12,345.68", "12.345,68", "12\u00A0345,68", "12,345.68", "12\u2019345.68"],
        [12345.678, {}, "12.345,678", "12\u202F345,678", "12,345.678", "12.345,678", "12\u00A0345,678", "12,345.678", "12\u2019345.678"],
        [-0.004, { decimal_places: 2 }, "-0,00", "-0,00", "-0.00", "-0,00", "-0,00", "-0.00", "-0.00"],
        [-0.004, {}, "-0,004", "-0,004", "-0.004", "-0,004", "-0,004", "-0.004", "-0.004"],
        [5/2r, { decimal_places: 2 }, "2,50", "2,50", "2.50", "2,50", "2,50", "2.50", "2.50"],
        [5/2r, {}, "3", "3", "3", "3", "3", "3", "3"],
        ["1234.5", { decimal_places: 2 }, "1.234,50", "1\u202F234,50", "1,234.50", "1.234,50", "1\u00A0234,50", "1,234.50", "1\u2019234.50"],
        ["1234.5", {}, "1.234,5", "1\u202F234,5", "1,234.5", "1.234,5", "1\u00A0234,5", "1,234.5", "1\u2019234.5"],
      ].each do |amount, options, *expected_outputs|
        locales.zip(expected_outputs).each do |locale, expected|
          formatter = Worldwide::Numbers.new(locale: locale)

          assert_equal expected, formatter.format(amount, **options), "#{locale} #{amount.inspect} #{options.inspect}"
          assert_equal expected, formatter.format(amount, **options, grouping: :always), "#{locale} #{amount.inspect} #{options.inspect}"
        end
      end
    end

    test "#format renders BigDecimal amounts with decimal arithmetic" do
      # [amount, options, expected, output before this change if it differed, reason for the difference]
      [
        ["1234.56", { decimal_places: 2 }, "1,234.56"],
        ["0.125", { decimal_places: 2 }, "0.12"],
        ["1.015", { decimal_places: 2 }, "1.02"],
        ["2.5", { decimal_places: 0 }, "2"],
        ["-0.004", { decimal_places: 2 }, "-0.00"],
        ["-0", { decimal_places: 2 }, "-0.00"],
        ["0", {}, "0"],
        ["1500", { humanize: :long }, "1.5 thousand"],
        ["31500000", { humanize: :short }, "31.5M"],
        ["12345.675", { humanize: :japan, decimal_places: 2 }, "1万2345.68"],
        ["NaN", {}, "NaN"],
        ["-Infinity", { decimal_places: 2 }, "-Inf"],
        ["123456789012345.01", { decimal_places: 2 }, "123,456,789,012,345.01", "123,456,789,012,345.02", :beyond_double_precision],
        ["9007199254740992.01", { decimal_places: 2 }, "9,007,199,254,740,992.01", "9,007,199,254,740,992.00", :beyond_double_precision],
        ["0.005", { decimal_places: 2 }, "0.00", "0.01", :decimal_tie],
        ["1234.56", {}, "1,234.56", "1,234.56000000", :natural_decimal_places],
        ["100", {}, "100", "100.000", :natural_decimal_places],
        ["-1.50", {}, "-1.5", "-1.5000", :natural_decimal_places],
        ["1e-7", {}, "0.0000001", "0.0000", :natural_decimal_places],
        ["0.25", { percent: true }, "25%", "25.0000%", :natural_decimal_places],
        ["-0.6", { relative: true }, "-0.6", "-0.600", :natural_decimal_places],
      ].each do |amount, options, expected, _previous_output, _reason|
        actual = Worldwide::Numbers.new(locale: :en).format(BigDecimal(amount), **options)

        assert_equal expected, actual, "#{amount} #{options.inspect}"
      end
    end

    test "#format renders a 50-digit BigDecimal exactly" do
      integer_part = "12345678901234567890123456789012345678901234567890"
      expected = "#{integer_part.reverse.scan(/\d{1,3}/).join(",").reverse}.01"

      assert_equal expected, Worldwide::Numbers.new(locale: :en).format(BigDecimal("#{integer_part}.005"), decimal_places: 2, rounding_mode: :half_up)
      assert_equal expected, Worldwide::Numbers.new(locale: :en).format(BigDecimal("#{integer_part}.01"), decimal_places: 2)
      assert_equal expected, Worldwide::Numbers.new(locale: :en).format(Rational("#{integer_part}.01"), decimal_places: 2, rounding_mode: :half_even)
    end

    test "#format with BigDecimal keeps every digit in de" do
      formatter = Worldwide::Numbers.new(locale: :de)

      assert_equal "123.456.789.012.345,01", formatter.format(BigDecimal("123456789012345.01"), decimal_places: 2)
      assert_equal "9.007.199.254.740.992,01", formatter.format(BigDecimal("9007199254740992.01"), decimal_places: 2)
    end

    test "#format accepts the same decimal_places: values as Kernel.format for a BigDecimal" do
      formatter = Worldwide::Numbers.new(locale: :en)

      [2, "2", "02", "", "2f", 2.0, -1, " 2", "2 "].each do |decimal_places|
        expected = begin
          Kernel.format("%.#{decimal_places}f", 1.25)
        rescue ArgumentError => error
          error.class
        end

        [1.25, BigDecimal("1.25")].each do |amount|
          actual = begin
            formatter.format(amount, decimal_places: decimal_places)
          rescue ArgumentError => error
            error.class
          end

          assert_equal expected, actual, "#{amount.inspect} #{decimal_places.inspect}"
        end
      end
    end

    test "#format with rounding_mode: accepts an Integer or a String of digits as decimal_places:" do
      formatter = Worldwide::Numbers.new(locale: :en)

      assert_equal "1.3", formatter.format(BigDecimal("1.25"), decimal_places: 1, rounding_mode: :half_up)
      assert_equal "1.3", formatter.format(1.25, decimal_places: "1", rounding_mode: :half_up)
      assert_equal "1.30", formatter.format(BigDecimal("1.3"), decimal_places: "02", rounding_mode: :half_up)

      ["", "2f", 2.0, -1, " 2", "2 "].each do |decimal_places|
        assert_raises(ArgumentError, decimal_places.inspect) do
          formatter.format(BigDecimal("1.25"), decimal_places: decimal_places, rounding_mode: :half_up)
        end
      end
    end

    test "#format bounds the digits that decimal arithmetic renders" do
      formatter = Worldwide::Numbers.new(locale: :en)
      huge = BigDecimal("1e100000000")
      tiny = BigDecimal("-1e-100000000")

      assert_equal "Inf", formatter.format(huge)
      assert_equal "Inf", formatter.format(huge, decimal_places: 2)
      assert_equal legacy_format(tiny, nil), formatter.format(tiny)
      assert_equal "-0.00", formatter.format(tiny, decimal_places: 2)
      assert_equal "-0.01", formatter.format(tiny, decimal_places: 2, rounding_mode: :floor)
      assert_equal "9" * 999, formatter.format(BigDecimal("9" * 999), decimal_places: 0).delete(",")
      assert_equal "Inf", formatter.format(BigDecimal("1e999"), decimal_places: 0)
      assert_equal "179,769,313,486,231,570,#{(["000"] * 97).join(",")}", formatter.format(Float::MAX, rounding_mode: :half_even)

      assert_raises(ArgumentError) { formatter.format(huge, rounding_mode: :half_even) }
      assert_raises(ArgumentError) { formatter.format(tiny, rounding_mode: :half_even) }
      assert_raises(ArgumentError) { formatter.format(BigDecimal("1.5"), decimal_places: 1_000, rounding_mode: :half_even) }
      assert_raises(ArgumentError) { formatter.format(Rational(1, 2**1_000), rounding_mode: :half_even) }
      assert_equal 999, formatter.format(Rational(1, 2**999), rounding_mode: :half_even).length - 2
    end

    test "#format rounds in every rounding mode at zero and three decimal places" do
      modes = [:half_even, :half_up, :half_down, :up, :down, :ceiling, :floor]
      [
        ["2.5", 0, ["2", "3", "2", "3", "2", "3", "2"]],
        ["-2.5", 0, ["-2", "-3", "-2", "-3", "-2", "-2", "-3"]],
        ["3.5", 0, ["4", "4", "3", "4", "3", "4", "3"]],
        ["2.4", 0, ["2", "2", "2", "3", "2", "3", "2"]],
        ["-2.6", 0, ["-3", "-3", "-3", "-3", "-2", "-2", "-3"]],
        ["-0.4", 0, ["-0", "-0", "-0", "-1", "-0", "-0", "-1"]],
        ["7", 0, ["7", "7", "7", "7", "7", "7", "7"]],
        ["1.0005", 3, ["1.000", "1.001", "1.000", "1.001", "1.000", "1.001", "1.000"]],
        ["1.0015", 3, ["1.002", "1.002", "1.001", "1.002", "1.001", "1.002", "1.001"]],
        ["-1.0015", 3, ["-1.002", "-1.002", "-1.001", "-1.002", "-1.001", "-1.001", "-1.002"]],
        ["1.23456", 3, ["1.235", "1.235", "1.235", "1.235", "1.234", "1.235", "1.234"]],
        ["-1.23449", 3, ["-1.234", "-1.234", "-1.234", "-1.235", "-1.234", "-1.234", "-1.235"]],
        ["1234.5", 3, ["1,234.500", "1,234.500", "1,234.500", "1,234.500", "1,234.500", "1,234.500", "1,234.500"]],
        ["0.0000000001", 0, ["0", "0", "0", "1", "0", "1", "0"]],
        ["-0.0000000001", 0, ["-0", "-0", "-0", "-1", "-0", "-0", "-1"]],
        ["0.0000000001", 3, ["0.000", "0.000", "0.000", "0.001", "0.000", "0.001", "0.000"]],
        ["-0.0000000001", 3, ["-0.000", "-0.000", "-0.000", "-0.001", "-0.000", "-0.000", "-0.001"]],
        ["2.5000000000001", 0, ["3", "3", "3", "3", "2", "3", "2"]],
        ["-1.0004999999999", 3, ["-1.000", "-1.000", "-1.000", "-1.001", "-1.000", "-1.000", "-1.001"]],
      ].each do |amount, decimal_places, expected_outputs|
        formatter = Worldwide::Numbers.new(locale: :en)
        amounts = [BigDecimal(amount), Rational(amount), Float(amount)]
        amounts << Integer(amount) if amount.match?(/\A-?\d+\z/)

        modes.zip(expected_outputs).each do |mode, expected|
          amounts.each do |typed_amount|
            actual = formatter.format(typed_amount, decimal_places: decimal_places, rounding_mode: mode)

            assert_equal expected, actual, "#{typed_amount.inspect} #{mode}"
          end
        end
      end
    end

    test "#format rounds as exact arithmetic does in every rounding mode, also far below the last decimal place" do
      formatter = Worldwide::Numbers.new(locale: :en)
      modes = [:half_even, :half_up, :half_down, :up, :down, :ceiling, :floor]
      integer_parts = [0, 1, 12_345, 10**20]
      # A nudge of one unit at 1, 9, 10, 18 or 40 places past the last decimal place, up or down.
      nudge_shapes = [1, 9, 10, 18, 40].product([1, -1])
      checked_types = Hash.new(0)

      [0, 2, 3].each do |decimal_places|
        last_place = Rational(1, 10**decimal_places)
        nudges = nudge_shapes.map { |places, direction| direction * last_place / 10**places } << 0

        # Exact amounts and ties, each nudged
        integer_parts.product([0, last_place / 2], nudges).each do |integer_part, fraction, nudge|
          magnitude = integer_part + fraction + nudge
          next if magnitude.negative?

          [magnitude, -magnitude].each do |value|
            text = decimal_text(value)
            amounts = [BigDecimal(text), value]
            amounts << value.to_i if value.denominator == 1
            # A Float is rounded through its shortest decimal form, so it is checked when that form is the value.
            amounts << Float(text) if Rational(Float(text).to_s) == value

            amounts.each do |amount|
              checked_types[amount.class] += 1
              modes.each do |mode|
                actual = formatter.format(amount, decimal_places: decimal_places, rounding_mode: mode).delete(",")

                assert_equal oracle_format(value, decimal_places, mode), actual, "#{amount.inspect} #{decimal_places} #{mode}"
              end
            end
          end
        end
      end

      assert_equal [BigDecimal, Float, Integer, Rational], checked_types.keys.sort_by(&:name)
    end

    test "#format with rounding_mode: rounds a Float through its shortest decimal form" do
      formatter = Worldwide::Numbers.new(locale: :en)

      # 1.015 is stored as 1.01499999999999990230, and 0.07 * 100 as 7.000000000000001.
      assert_equal "1.02", formatter.format(1.015, decimal_places: 2, rounding_mode: :half_up)
      assert_equal "-0.01", formatter.format(-0.005, decimal_places: 2, rounding_mode: :half_up)
      assert_equal "7%", formatter.format(0.07, percent: true, rounding_mode: :half_even)
      assert_equal "100,000,000,000,000,000,000", formatter.format(1.0e20, rounding_mode: :half_even)
      assert_equal "0.0000001", formatter.format(1.0e-7, rounding_mode: :half_even)
      assert_equal "-0.00", formatter.format(-0.0, decimal_places: 2, rounding_mode: :half_even)
      assert_equal "NaN", formatter.format(Float::NAN, decimal_places: 2, rounding_mode: :half_even)
      assert_equal "-Inf", formatter.format(-Float::INFINITY, rounding_mode: :half_even)
    end

    test "#format with rounding_mode: and no decimal_places: uses every decimal of a terminating Rational" do
      formatter = Worldwide::Numbers.new(locale: :en)

      assert_equal "0.125", formatter.format(1/8r, rounding_mode: :half_even)
      assert_equal "-2.5", formatter.format(-5/2r, rounding_mode: :half_even)
      assert_equal "12,345.67", formatter.format(1234567/100r, rounding_mode: :half_even)
      assert_equal "0.33", formatter.format(1/3r, decimal_places: 2, rounding_mode: :half_even)

      error = assert_raises(ArgumentError) { formatter.format(1/3r, rounding_mode: :half_even) }
      assert_match(/decimal_places:/, error.message)
    end

    test "#format with sign_display: :negative drops the minus sign from a zero result" do
      formatter = Worldwide::Numbers.new(locale: :en)

      assert_equal "-0.00", formatter.format(BigDecimal("-0.004"), decimal_places: 2)
      assert_equal "0.00", formatter.format(BigDecimal("-0.004"), decimal_places: 2, sign_display: :negative)
      assert_equal "0.00", formatter.format(-0.004, decimal_places: 2, sign_display: :negative)
      assert_equal "0", formatter.format(-0.0, sign_display: :negative)
      assert_equal "0.00", formatter.format("-0.001", decimal_places: 2, sign_display: :negative)
      assert_equal "0", formatter.format(-1/3r, decimal_places: 0, sign_display: :negative)
      assert_equal "-0.01", formatter.format(BigDecimal("-0.005"), decimal_places: 2, rounding_mode: :half_up, sign_display: :negative)
      assert_equal "-0.01", formatter.format(-0.005, decimal_places: 2, rounding_mode: :half_up)
      assert_equal "-0.004", formatter.format(-0.004, sign_display: :negative)
      assert_equal "-1,234.50", formatter.format(-1234.5, decimal_places: 2, sign_display: :negative)
      assert_equal "-Inf", formatter.format(-Float::INFINITY, sign_display: :negative)
      assert_equal "0,00", Worldwide::Numbers.new(locale: :de).format(-0.004, decimal_places: 2, sign_display: :negative)
    end

    test "#format combines the new options with percent: and humanize:" do
      formatter = Worldwide::Numbers.new(locale: :en)

      assert_equal "13%", formatter.format(0.125, percent: true, decimal_places: 0, rounding_mode: :half_up)
      assert_equal "12%", formatter.format(0.125, percent: true, decimal_places: 0, rounding_mode: :half_even)
      assert_equal "0.00%", formatter.format(-0.00004, percent: true, decimal_places: 2, sign_display: :negative)
      assert_equal "1万2345.67", formatter.format(BigDecimal("12345.675"), humanize: :japan, decimal_places: 2, rounding_mode: :down)
      assert_equal "0", formatter.format(-0.4, humanize: :short, decimal_places: 0, sign_display: :negative)
      assert_equal "-32M", formatter.format(-31_500_000, humanize: :short, sign_display: :negative)
      assert_equal "+0.13", formatter.format(0.125, relative: true, decimal_places: 2, rounding_mode: :half_up)
      assert_equal "-0.13", formatter.format(-0.125, relative: true, decimal_places: 2, rounding_mode: :half_up)
    end

    test "#format with humanize: :japan keeps the earlier output for a BigDecimal with more integer digits than it has units for" do
      formatter = Worldwide::Numbers.new(locale: :ja)

      # The output, or the error, before BigDecimal amounts were rounded with decimal arithmetic.
      [
        [10**27, nil, "1000秭"],
        [10**28, nil, NoMethodError],
        [1.0e28, nil, "9999秭9999垓9999京9999兆5831億1973万6832.00000"],
        [1.0e30, nil, NoMethodError],
        [BigDecimal("1e28"), nil, "9999秭9999垓9999京9999兆5831億1973万6832.0000"],
        [BigDecimal("1e28"), 2, "9999秭9999垓9999京9999兆5831億1973万6832.00"],
        # 28 integer digits that round up to 29
        [BigDecimal("#{"9" * 28}.5"), 0, "9999秭9999垓9999京9999兆5831億1973万6832"],
        # 28 integer digits and a minus sign
        [BigDecimal("-1e27"), 0, NoMethodError],
        [BigDecimal("1e30"), nil, NoMethodError],
        [BigDecimal("1e308"), nil, NoMethodError],
        [BigDecimal("1e309"), nil, "Inf"],
        [BigDecimal("1e400"), 2, "Inf"],
        [BigDecimal("1e1000"), nil, "Inf"],
      ].each do |amount, decimal_places, expected|
        actual = begin
          formatter.format(amount, decimal_places: decimal_places, humanize: :japan)
        rescue NoMethodError => error
          error.class
        end

        assert_equal expected, actual, "#{amount.inspect} #{decimal_places.inspect}"
      end

      # Up to 28 integer digits, or 27 and a minus sign, a BigDecimal is rendered exactly.
      assert_equal "9999秭9999垓9999京9999兆9999億9999万9999", formatter.format(BigDecimal("9" * 28), humanize: :japan)
      assert_equal "-999秭9999垓9999京9999兆9999億9999万9999", formatter.format(BigDecimal("-#{"9" * 27}"), humanize: :japan)
      assert_equal "1000秭", formatter.format(BigDecimal("1e27"), humanize: :japan)
    end

    test "#format with humanize: :japan and rounding_mode: raises ArgumentError for more integer digits than it has units for" do
      formatter = Worldwide::Numbers.new(locale: :ja)

      assert_equal "9999秭9999垓9999京9999兆9999億9999万9999", formatter.format(BigDecimal("#{"9" * 28}.5"), decimal_places: 0, humanize: :japan, rounding_mode: :down)
      assert_equal "-999秭9999垓9999京9999兆9999億9999万9999", formatter.format(-(10**27 - 1), humanize: :japan, rounding_mode: :half_even)

      [
        [BigDecimal("#{"9" * 28}.5"), 0],
        [BigDecimal("1e28"), nil],
        [10**28, nil],
        # 1.0e28 is 9999999999999999583119736832, but its shortest decimal form is 10**28.
        [1.0e28, 0],
        [-(10**27), nil],
        [BigDecimal("1e309"), 2],
      ].each do |amount, decimal_places|
        error = assert_raises(ArgumentError, amount.inspect) do
          formatter.format(amount, decimal_places: decimal_places, humanize: :japan, rounding_mode: :half_up)
        end
        assert_match(/humanize: :japan/, error.message)
      end
    end

    test "#format with rounding_mode: raises ArgumentError for a nil amount, which bigdecimal/util converts to zero" do
      formatter = Worldwide::Numbers.new(locale: :en)

      assert_respond_to nil, :to_d
      [{}, { decimal_places: 2 }, { percent: true }, { humanize: :japan }, { relative: true }].each do |options|
        error = assert_raises(ArgumentError, options.inspect) { formatter.format(nil, **options, rounding_mode: :half_even) }
        assert_match(/nil/, error.message)
      end
      assert_raises(ArgumentError) { formatter.format("0.5", percent: true, rounding_mode: :half_even) }

      # Without rounding_mode:, nil raises as it did before.
      assert_raises(TypeError) { formatter.format(nil, decimal_places: 2) }
      assert_raises(NoMethodError) { formatter.format(nil, percent: true) }
    end

    test "#format raises ArgumentError for unsupported option values and combinations" do
      formatter = Worldwide::Numbers.new(locale: :en)

      assert_raises(ArgumentError) { formatter.format(1, rounding_mode: :banker) }
      assert_raises(ArgumentError) { formatter.format(1, rounding_mode: "half_up") }
      assert_raises(ArgumentError) { formatter.format(1, sign_display: :never) }
      assert_raises(ArgumentError) { formatter.format(1, sign_display: nil) }
      assert_raises(ArgumentError) { formatter.format(1_500_000, humanize: :short, rounding_mode: :half_up) }
      assert_raises(ArgumentError) { formatter.format(1_500_000, humanize: :long, rounding_mode: :half_even) }
      assert_raises(ArgumentError) { formatter.format(-0.004, relative: true, sign_display: :negative) }
      assert_raises(ArgumentError) { formatter.format("1.5", rounding_mode: :half_up) }
      assert_raises(ArgumentError) { formatter.format(FloatConvertible.new(1.5), rounding_mode: :half_up) }
      assert_raises(ArgumentError) { formatter.format(BigDecimal("1.5"), decimal_places: -1) }
      assert_raises(ArgumentError) { formatter.format(1.5, decimal_places: 1.0, rounding_mode: :half_up) }
    end

    test "#format with grouping: :auto groups from the locale's minimum grouping digits" do
      amounts = [1234, 12345, 123456]
      # [locale, CLDR minimum grouping digits, expected with :auto, expected with :always], one string per amount.
      [
        [:en, 1, ["1,234", "12,345", "123,456"], ["1,234", "12,345", "123,456"]],
        [:de, 1, ["1.234", "12.345", "123.456"], ["1.234", "12.345", "123.456"]],
        [:pl, 2, ["1234", "12\u00A0345", "123\u00A0456"], ["1\u00A0234", "12\u00A0345", "123\u00A0456"]],
        [:es, 2, ["1234", "12.345", "123.456"], ["1.234", "12.345", "123.456"]],
        [:ee, 3, ["1234", "12345", "123,456"], ["1,234", "12,345", "123,456"]],
      ].each do |locale, minimum, auto, always|
        formatter = Worldwide::Numbers.new(locale: locale)

        assert_equal minimum, formatter.send(:minimum_grouping_digits), locale
        assert_equal auto, amounts.map { |amount| formatter.format(amount, grouping: :auto) }, locale
        assert_equal always, amounts.map { |amount| formatter.format(amount, grouping: :always) }, locale
        assert_equal always, amounts.map { |amount| formatter.format(amount) }, locale
      end
    end

    test "#format with grouping: :auto uses the minimum grouping digits that a regional locale inherits or overrides" do
      [
        # es-ES inherits 2 from es. es-419 overrides it with 1, and es-MX and es-AR inherit 1 from es-419.
        [:"es-ES", "1234"],
        [:"es-419", "1,234"],
        [:"es-MX", "1,234"],
        [:"es-AR", "1.234"],
        # pt-PT overrides pt's 1 with 2, and pt-MZ inherits it. pt-AO, a child of pt-PT, overrides it with 1.
        [:pt, "1.234"],
        [:"pt-BR", "1.234"],
        [:"pt-PT", "1234"],
        [:"pt-MZ", "1234"],
        [:"pt-AO", "1\u00A0234"],
        # ru-UA overrides ru's 1 with 2.
        [:ru, "1\u00A0234"],
        [:"ru-UA", "1234"],
        [:"pl-PL", "1234"],
      ].each do |locale, expected|
        formatter = Worldwide::Numbers.new(locale: locale)

        assert_equal expected, formatter.format(1234, grouping: :auto), locale
        assert_equal formatter.format(12345), formatter.format(12345, grouping: :auto), locale
      end
    end

    test "#format with grouping: :auto groups every locale from its primary group size plus minimum grouping digits" do
      Worldwide::Locales.known.each do |locale|
        # en-US-POSIX has no grouping separator in its pattern.
        next if locale == :"en-US-POSIX"

        formatter = Worldwide::Numbers.new(locale: locale)
        grouped_digits = formatter.send(:group_positions).first + formatter.send(:minimum_grouping_digits)
        largest_ungrouped = (10**(grouped_digits - 1)) - 1

        assert_equal largest_ungrouped.to_s, formatter.format(largest_ungrouped, grouping: :auto), locale
        assert_equal formatter.format(largest_ungrouped + 1), formatter.format(largest_ungrouped + 1, grouping: :auto), locale
      end
    end

    test "#format with grouping: :auto keeps en-IN's 3/2 grouping" do
      formatter = Worldwide::Numbers.new(locale: :"en-IN")

      [:always, :auto].each do |grouping|
        assert_equal "1,234", formatter.format(1234, grouping: grouping)
        assert_equal "12,34,567.89", formatter.format(1234567.891, decimal_places: 2, grouping: grouping)
        assert_equal "-1,23,45,67,890", formatter.format(BigDecimal("-1234567890"), grouping: grouping)
      end
    end

    test "#format with grouping: :auto counts the integer digits after rounding, on either rounding path" do
      formatter = Worldwide::Numbers.new(locale: :pl)

      [
        [9999, {}, "9999"],
        [10000, {}, "10\u00A0000"],
        [-9999, {}, "-9999"],
        [-10000, {}, "-10\u00A0000"],
        [1234.56, { decimal_places: 2 }, "1234,56"],
        [-12345.675, { decimal_places: 2 }, "-12\u00A0345,68"],
        [1234567.891, {}, "1\u00A0234\u00A0567,891"],
        ["1234.5", {}, "1234,5"],
        [12345/10r, { decimal_places: 1 }, "1234,5"],
        [1234567/100r, {}, "12\u00A0346"],
        [9999.999, { decimal_places: 2 }, "10\u00A0000,00"],
        [999.5, { decimal_places: 0 }, "1000"],
        [-Float::INFINITY, {}, "-Inf"],
        [Float::NAN, {}, "NaN"],
        [BigDecimal("1234.565"), { decimal_places: 2 }, "1234,56"],
        [BigDecimal("-12345.675"), { decimal_places: 2 }, "-12\u00A0345,68"],
        [BigDecimal("9999.999"), { decimal_places: 2 }, "10\u00A0000,00"],
        [BigDecimal("-9999.995"), { decimal_places: 2, rounding_mode: :half_up }, "-10\u00A0000,00"],
        [BigDecimal("-9999.995"), { decimal_places: 2, rounding_mode: :down }, "-9999,99"],
        [1234.565, { decimal_places: 2, rounding_mode: :half_up }, "1234,57"],
        [9999.5, { decimal_places: 0, rounding_mode: :half_even }, "10\u00A0000"],
        [BigDecimal("-0.004"), { decimal_places: 2, sign_display: :negative }, "0,00"],
      ].each do |amount, options, expected|
        assert_equal expected, formatter.format(amount, **options, grouping: :auto), "#{amount.inspect} #{options.inspect}"
      end
    end

    test "#format with grouping: :auto groups the digits shown by humanize:, percent: and relative:" do
      es = Worldwide::Numbers.new(locale: :es)
      pl = Worldwide::Numbers.new(locale: :pl)

      # humanize: :short and :long scale the amount first, so the rule applies to the scaled digits.
      assert_equal "1.235\u00A0M", es.format(1_234_567_890, humanize: :short)
      assert_equal "1235\u00A0M", es.format(1_234_567_890, humanize: :short, grouping: :auto)
      assert_equal "1234 biliona", pl.format(1_234_000_000_000_000, humanize: :long, grouping: :auto)
      assert_equal "12\u00A0345\u00A0bln", pl.format(12_345_000_000_000_000, humanize: :short, grouping: :auto)
      assert_equal "1,2 mil millones", es.format(1_234_567_890, humanize: :long, grouping: :auto)
      assert_equal "999", pl.format(999, humanize: :short, grouping: :auto)

      # percent: groups the percentage, and percent: and relative: add their signs after grouping.
      assert_equal "1234%", pl.format(12.34, percent: true, grouping: :auto)
      assert_equal "12\u00A0345%", pl.format(123.45, percent: true, grouping: :auto)
      assert_equal "1234\u00A0%", es.format(12.34, percent: true, grouping: :auto)
      assert_equal "+1234", pl.format(1234, relative: true, grouping: :auto)
      assert_equal "-1234,5", pl.format(-1234.5, relative: true, grouping: :auto)
      assert_equal "+12\u00A0345", pl.format(12345, relative: true, grouping: :auto)
      assert_equal "+1234%", pl.format(12.34, percent: true, relative: true, grouping: :auto)
    end

    test "#format raises ArgumentError for unsupported grouping values and combinations" do
      formatter = Worldwide::Numbers.new(locale: :en)

      assert_raises(ArgumentError) { formatter.format(1234, grouping: :min2) }
      assert_raises(ArgumentError) { formatter.format(1234, grouping: "auto") }
      assert_raises(ArgumentError) { formatter.format(1234, grouping: nil) }
      assert_raises(ArgumentError) { formatter.format(1234, grouping: false) }

      error = assert_raises(ArgumentError) { formatter.format(12345, humanize: :japan, grouping: :auto) }
      assert_match(/humanize: :japan/, error.message)
      assert_equal "1万2345", formatter.format(12345, humanize: :japan, grouping: :always)
    end

    test "#format with grouping: :always does not look up the minimum grouping digits" do
      formatter = Worldwide::Numbers.new(locale: :pl)
      formatter.expects(:minimum_grouping_digits).never

      assert_equal "1\u00A0234", formatter.format(1234)
      assert_equal "1\u00A0234,57", formatter.format(BigDecimal("1234.565"), decimal_places: 2, rounding_mode: :half_up, grouping: :always)
      assert_equal "1,2\u00A0tys.", formatter.format(1234, humanize: :short, grouping: :always)

      formatter = Worldwide::Numbers.new(locale: :pl)
      formatter.expects(:minimum_grouping_digits).once.returns(2)

      assert_equal "1234", formatter.format(1234, grouping: :auto)
    end

    test "#format keeps the legacy output for objects that only convert to Float" do
      formatter = Worldwide::Numbers.new(locale: :en)

      assert_equal "1,234.56", formatter.format(FloatConvertible.new(1234.565), decimal_places: 2)
      assert_equal "0.01", formatter.format(FloatConvertible.new(0.005), decimal_places: 2)
      assert_equal "0.00", formatter.format(FloatConvertible.new(-0.004), decimal_places: 2, sign_display: :negative)
      assert_equal "0.01", formatter.format(DecimalConvertible.new(0.005), decimal_places: 2)
      assert_equal "1,234.56", formatter.format(DecimalConvertible.new(1234.565), decimal_places: 2)
      assert_equal "12%", formatter.format(DecimalConvertible.new(0.125), percent: true, decimal_places: 0)
      assert_equal "-1.50", formatter.format(DecimalConvertible.new(-1.5), relative: true, decimal_places: 2)
    end

    test "#format with rounding_mode: uses to_d for other objects" do
      formatter = Worldwide::Numbers.new(locale: :en)

      assert_equal "0.00", formatter.format(DecimalConvertible.new(0.005), decimal_places: 2, rounding_mode: :half_even)
      assert_equal "1,234.57", formatter.format(DecimalConvertible.new(1234.565), decimal_places: 2, rounding_mode: :half_up)
      assert_equal "13%", formatter.format(DecimalConvertible.new(0.125), percent: true, decimal_places: 0, rounding_mode: :half_up)
    end

    test "#format matches the legacy %f formula, except where a BigDecimal is now rendered exactly" do
      random = Random.new(20261116)
      formatter = Worldwide::Numbers.new(locale: :en)
      differences = Hash.new(0)

      2_000.times do
        decimal_places = [nil, 0, 1, 2, 3, 4].sample(random: random)
        significant_digits = random.rand(1..22)
        unscaled = random.rand(10**significant_digits)
        decimal = if decimal_places && random.rand(4).zero?
          # A tie halfway between two values at decimal_places
          BigDecimal("#{unscaled / 10}5e-#{decimal_places + 1}")
        else
          BigDecimal("#{unscaled}e-#{random.rand(0..12)}")
        end
        decimal = -decimal if random.rand(2).zero?
        float = decimal.to_f
        rational = Rational(random.rand(-10**8..10**8), random.rand(1..10**4))

        [float, float.to_s, unscaled, rational].each do |amount|
          actual = formatter.format(amount, decimal_places: decimal_places).delete(",")

          assert_equal legacy_format(amount, decimal_places), actual, "#{amount.inspect} #{decimal_places.inspect}"
        end

        actual = formatter.format(decimal, decimal_places: decimal_places).delete(",")

        assert_equal exact_format(decimal, decimal_places), actual, "#{decimal} #{decimal_places.inspect}"

        legacy = legacy_format(decimal, decimal_places)
        next if actual == legacy

        reason = difference_reason(decimal, decimal_places)

        refute_nil reason, "#{decimal} #{decimal_places.inspect}: #{legacy} became #{actual}"
        differences[reason] += 1
      end

      assert_equal [:beyond_double_precision, :decimal_tie, :natural_decimal_places], differences.keys.sort
    end

    test "an instance used inside and outside with_bundled_data reads each mode's symbols and grouping" do
      host_polish = {
        numbers: {
          latn: {
            symbols: { decimal: "D", group: "G", percent_sign: "P" },
            formats: { decimal: { patterns: { default: { standard: "#,##,##0.###" } } } },
          },
          minimum_grouping_digits: 1,
        },
      }

      with_host_overrides(pl: host_polish) do
        polish = Worldwide::Numbers.new(locale: :pl)
        formats = -> { [polish.format(1234567.5, decimal_places: 2, grouping: :auto), polish.format(0.5, percent: true)] }

        assert_equal ["12G34G567D50", "50P"], formats.call
        assert_equal ["1\u00A0234\u00A0567,50", "50%"], Worldwide::Cldr.with_bundled_data { formats.call }
        assert_equal ["12G34G567D50", "50P"], formats.call

        polish = Worldwide::Numbers.new(locale: :pl)

        assert_equal "1234,50", Worldwide::Cldr.with_bundled_data { polish.format(1234.5, decimal_places: 2, grouping: :auto) }
        assert_equal "1G234D50", polish.format(1234.5, decimal_places: 2, grouping: :auto)
      end
    end

    private

    # The formatting before rounding_mode: was added, without grouping, for the en locale.
    def legacy_format(amount, decimal_places)
      decimal_places ||= legacy_natural_decimal_places(amount)
      Kernel.format("%.#{decimal_places}f", amount)
    end

    def legacy_natural_decimal_places(amount)
      natural = amount.to_s.sub(/\.0+\Z/, "")
      position = natural.index(".")
      position ? natural.length - position - 1 : 0
    end

    # Half-even rounding by BigDecimal itself, without grouping.
    def exact_format(decimal, decimal_places)
      decimal_places ||= decimal.scale
      integer, fraction = decimal.round(decimal_places, BigDecimal::ROUND_HALF_EVEN).abs.to_s("F").split(".")
      sign = decimal.sign.negative? ? "-" : ""
      return "#{sign}#{integer}" if decimal_places.zero?

      "#{sign}#{integer}.#{fraction.ljust(decimal_places, "0")}"
    end

    # The exact decimal text of a Rational whose denominator divides a power of 10.
    def decimal_text(value)
      places = 0
      places += 1 until (value * 10**places).denominator == 1
      digits = (value.abs * 10**places).to_i.to_s.rjust(places + 1, "0")
      text = places.zero? ? digits : "#{digits[0...-places]}.#{digits[-places..]}"
      value.negative? ? "-#{text}" : text
    end

    # Rounds value with Integer arithmetic, and renders it without grouping, with the minus sign of a negative value.
    def oracle_format(value, decimal_places, rounding_mode)
      floor, remainder = (value.numerator * 10**decimal_places).divmod(value.denominator)
      rounded = if remainder.zero?
        floor
      else
        oracle_round(floor, value.negative?, (2 * remainder) <=> value.denominator, rounding_mode)
      end

      digits = rounded.abs.to_s.rjust(decimal_places + 1, "0")
      text = decimal_places.zero? ? digits : "#{digits[0...-decimal_places]}.#{digits[-decimal_places..]}"
      value.negative? ? "-#{text}" : text
    end

    # Picks floor or floor + 1 for a scaled value strictly between them. half is -1, 0 or 1 as the value is below,
    # at or above the midpoint.
    def oracle_round(floor, negative, half, rounding_mode)
      ceiling = floor + 1
      toward_zero, away_from_zero = negative ? [ceiling, floor] : [floor, ceiling]
      case rounding_mode
      when :floor then floor
      when :ceiling then ceiling
      when :down then toward_zero
      when :up then away_from_zero
      else
        return half.negative? ? floor : ceiling if half.nonzero?

        { half_even: floor.even? ? floor : ceiling, half_up: away_from_zero, half_down: toward_zero }.fetch(rounding_mode)
      end
    end

    def difference_reason(decimal, decimal_places)
      if decimal_places.nil?
        return :natural_decimal_places if legacy_natural_decimal_places(decimal) != decimal.scale

        decimal_places = decimal.scale
      end

      if ((decimal.abs * (10**decimal_places)) % 1) == BigDecimal("0.5")
        :decimal_tie
      elsif decimal.n_significant_digits > 15 || decimal.exponent + decimal_places > 15
        # A Float holds 15 to 17 significant digits, so "%f" showed binary noise past them.
        :beyond_double_precision
      end
    end
  end
end
