# frozen_string_literal: true

require "test_helper"

module Worldwide
  class LocaleTest < ActiveSupport::TestCase
    test "name returns a translated name in each supported locale for French" do
      Worldwide.locales.each do |locale|
        I18n.with_locale(locale.to_sym) do
          assert_not_nil Locale.new("fr").name
        end
      end
    end

    test "name returns correctly when given symbols" do
      expected = "română (România)"

      assert_equal(expected, Locale.new("ro-RO").name(locale: "ro-RO"))
      assert_equal(expected, Locale.new(:"ro-RO").name(locale: "ro-RO"))
      assert_equal(expected, Locale.new("ro-RO").name(locale: :"ro-RO"))
      assert_equal(expected, Locale.new(:"ro-RO").name(locale: :"ro-RO"))
    end

    test 'name returns "Simplified Chinese" for language in `zh-Hans`' do
      I18n.with_locale(:"zh-Hans") do
        assert_equal("简体中文", Locale.new("zh-Hans").name)
      end

      # When there is a fallback to English
      begin
        original_fallbacks = I18n.fallbacks
        I18n.fallbacks = I18n::Locale::Fallbacks.new([:en])

        I18n.with_locale(:"zh-Hans") do
          assert_equal("简体中文", Locale.new("zh-Hans").name)
        end
      ensure
        I18n.fallbacks = original_fallbacks
      end
    end

    test 'name returns "Traditional Chinese" for `zh-Hant` locale' do
      I18n.with_locale(:"zh-Hant") do
        assert_equal "繁體中文", Locale.new("zh-Hant").name
      end

      # When there is a fallback to English
      begin
        original_fallbacks = I18n.fallbacks
        I18n.fallbacks = I18n::Locale::Fallbacks.new([:en])

        I18n.with_locale(:"zh-Hant") do
          assert_equal("繁體中文", Locale.new("zh-Hant").name)
        end
      ensure
        I18n.fallbacks = original_fallbacks
      end
    end

    test 'name returns "Traditional Chinese in Hong Kong SAR" for `zh-Hant-HK`' do
      I18n.with_locale(:"zh-Hant-HK") do
        assert_equal "繁體中文 (中國香港特別行政區)", Locale.new("zh-Hant-HK").name
      end

      # When there is a fallback to English
      begin
        original_fallbacks = I18n.fallbacks
        I18n.fallbacks = I18n::Locale::Fallbacks.new([:en])

        I18n.with_locale(:"zh-Hant-HK") do
          assert_equal("繁體中文 (中國香港特別行政區)", Locale.new("zh-Hant-HK").name)
        end
      ensure
        I18n.fallbacks = original_fallbacks
      end
    end

    test "name accepts a locale as parameter" do
      I18n.with_locale(:en) do
        assert_equal "繁體中文", Locale.new("zh-Hant").name(locale: "zh-Hant")
      end
    end

    test "name can generate locale names with region in parenthesis" do
      assert_equal "French (France)", Locale.new("fr-FR").name
    end

    test "name can generate locale names for long locales" do
      assert_equal "Simplified Chinese (China)", Locale.new("zh-Hans-CN").name
    end

    test "name can generate locale names for locales containing a script and no custom name" do
      assert_equal "ouzbek (Afghanistan)", Locale.new("uz-Arab-AF").name(locale: :fr)
    end

    test "name shows the region even if it's the only (CLDR) variant for that locale" do
      assert_equal "Japanese (Japan)", Locale.new("ja-JP").name
    end

    test "name capitalizes the language name according to the context" do
      I18n.with_locale(:"cs-CZ") do
        assert_equal "čeština (Česko)", Locale.new(:"cs-CZ").name
        assert_equal "čeština (Česko)", Locale.new(:"cs-CZ").name(context: :middle_of_sentence)
        assert_equal "Čeština (Česko)", Locale.new(:"cs-CZ").name(context: :start_of_sentence)
        assert_equal "Čeština (Česko)", Locale.new(:"cs-CZ").name(context: :ui_list_or_menu)
        assert_equal "Čeština (Česko)", Locale.new(:"cs-CZ").name(context: :stand_alone)
      end
    end

    test "name can generate locale names for unknown script" do
      assert_equal "ouzbek (Arab)", Locale.new("uz-Arab").name(locale: :fr)
    end

    test "name raises an exception for invalid locales when enforce_available_locales is true (default)" do
      exc = assert_raise(I18n::InvalidLocale) do
        I18n.with_locale(:en) do
          Locale.new("pirate").name
        end
      end

      assert_equal ":pirate is not a valid locale", exc.message
    end

    test "name raises an exception for invalid locales when enforce_available_locales is false" do
      I18n.enforce_available_locales = false

      exc = assert_raise(I18n::MissingTranslation) do
        I18n.with_locale(:en) do
          Locale.new("pirate").name
        end
      end

      assert_includes(exc.message.downcase, "translation missing")
    ensure
      I18n.enforce_available_locales = true
    end

    test "name does not raise an exception if throw: false is passed and enforce_available_locales is false" do
      I18n.enforce_available_locales = false

      assert_nil(Locale.new("bogus").name(locale: :en, throw: false))
    ensure
      I18n.enforce_available_locales = true
    end

    test "name preserves the regional part of the locale even if it's not recognized" do
      [
        ["he", "Hebrew", "hébreu", "ヘブライ語"],
        ["he-IL", "Hebrew (Israel)", "hébreu (Israël)", "ヘブライ語 (イスラエル)"],
        ["he-Israel", "Hebrew (Israel)", "hébreu (Israel)", "ヘブライ語 (Israel)"],
        ["he-israel", "Hebrew (israel)", "hébreu (israel)", "ヘブライ語 (israel)"],
        ["fr-ca", "French (ca)", "français (ca)", "フランス語 (ca)"],
        ["en-pirate", "English (pirate)", "anglais (pirate)", "英語 (pirate)"],
        ["en-POTATO", "English (POTATO)", "anglais (POTATO)", "英語 (POTATO)"],
      ].each do |locale, expected_english, expected_french, expected_japanese|
        actual = I18n.with_locale(:en) { Locale.new(locale).name }

        assert_equal expected_english, actual

        actual = I18n.with_locale(:fr) { Locale.new(locale).name }

        assert_equal expected_french, actual

        actual = I18n.with_locale(:ja) { Locale.new(locale).name }

        assert_equal expected_japanese, actual
      end
    end

    test "raises an exception for nil locale" do
      exc = assert_raise(ArgumentError) do
        Locale.new(nil)
      end

      assert_equal "Invalid locale: cannot be nil nor an empty string", exc.message
    end

    test "raises an exception for empty string locale" do
      exc = assert_raise(ArgumentError) do
        Locale.new("")
      end

      assert_equal "Invalid locale: cannot be nil nor an empty string", exc.message
    end

    test "Locale.unknown.name returns 'Unknown language' when the locale is English" do
      I18n.with_locale(:en) do
        assert_equal "Unknown language", Locale.unknown.name
      end
    end

    test "language_subtag correctly parses locale code when given a locale without region code" do
      input_locale_string = "ja"
      input_locale_sym = :en

      assert_equal "ja", Worldwide.locale(code: input_locale_string).language_subtag
      assert_equal "en", Worldwide.locale(code: input_locale_sym).language_subtag
    end

    test "language_subtag correctly parses locale code when given a locale that has a region code" do
      input_locale_string = "ja-JP"
      input_locale_sym = :"ko-KR"

      assert_equal "ja", Worldwide.locale(code: input_locale_string).language_subtag
      assert_equal "ko", Worldwide.locale(code: input_locale_sym).language_subtag
    end

    test "script returns expected values for several common languages" do
      {
        en: "Latn",
        "en-IN": "Latn",
        "en-US": "Latn",
        fr: "Latn",
        ja: "Jpan",
        "ja-JP": "Jpan",
        nl: "Latn",
        sr: "Cyrl",
        "sr-Cyrl": "Cyrl",
        "sr-Cyrl-RS": "Cyrl",
        "sr-Latn": "Latn",
        "sr-Latn-RS": "Latn",
        "sr-RS": "Cyrl",
        zh: "Hans",
        "zh-CN": "Hans",
        "zh-HK": "Hant",
        "zh-SG": "Hans",
        "zh-TW": "Hant",
      }.each do |locale, expected|
        actual = Worldwide.locale(code: locale).script

        assert_equal expected, actual
      end
    end

    test "regional forms of French don't include `(international)` in their description" do
      forms = ["fr-BE", "fr-BF", "fr-BI", "fr-BJ", "fr-BL", "fr-CA", "fr-CD", "fr-CF", "fr-CG", "fr-CH", "fr-CI", "fr-CM", "fr-DJ", "fr-DZ", "fr-FR", "fr-GA", "fr-GF", "fr-GN", "fr-GP", "fr-GQ", "fr-HT", "fr-KM", "fr-LU", "fr-MA", "fr-MC", "fr-MF", "fr-MG", "fr-ML", "fr-MQ", "fr-MR", "fr-MU", "fr-NC", "fr-NE", "fr-PF", "fr-PM", "fr-RE", "fr-RW", "fr-SC", "fr-SN", "fr-SY", "fr-TD", "fr-TG", "fr-TN", "fr-VU", "fr-WF", "fr-YT"]

      I18n.with_locale(:fr) do
        forms.each do |code|
          # Confirm that each name does not include the text [i]nternational
          name = Worldwide.locale(code: code).name

          refute_includes name, "nternational"
        end
      end
    end
  end
end
