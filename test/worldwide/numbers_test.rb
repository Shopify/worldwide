# frozen_string_literal: true

require "test_helper"

module Worldwide
  class NumbersTest < ActiveSupport::TestCase
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
  end
end
