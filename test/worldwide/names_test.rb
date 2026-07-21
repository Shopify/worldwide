# frozen_string_literal: true

require "test_helper"

module Worldwide
  class NamesTest < ActiveSupport::TestCase
    setup do
      @given   = "Mary"
      @surname = "Dillon"
    end

    test ".full returns the expected format for en" do
      I18n.with_locale("en") do
        assert_equal "Mary Dillon", Worldwide::Names.full(given: @given, surname: @surname)
      end
    end

    test ".full returns a localized format when one exists" do
      I18n.with_locale("ja") do
        assert_equal "DillonMary", Worldwide::Names.full(given: @given, surname: @surname)
      end
    end

    test ".full returns 'surname given' when locale is vi" do
      I18n.with_locale("vi") do
        assert_equal "Dillon Mary", Worldwide::Names.full(given: @given, surname: @surname)
      end
    end

    test ".greeting returns the expected format for en" do
      I18n.with_locale("en") do
        assert_equal "Mary", Worldwide::Names.greeting(given: @given, surname: @surname)
      end
    end

    test ".greeting returns a localized format when one exists" do
      I18n.with_locale("ja") do
        assert_equal "Dillon様", Worldwide::Names.greeting(given: @given, surname: @surname)
      end
    end

    test ".initials returns an array of the user's given and surname initials" do
      assert_equal ["M", "D"], Worldwide::Names.initials(given: @given, surname: @surname)
    end

    test ".initials returns an array of length 1 when there is no surname" do
      @surname = ""

      assert_equal ["M"], Worldwide::Names.initials(given: @given, surname: @surname)
    end

    test ".initials returns an empty array when given and surname are empty strings" do
      @given   = ""
      @surname = ""

      assert_empty Worldwide::Names.initials(given: "", surname: "")
    end

    test ".initials returns nil when there is no given or surname" do
      @given   = nil
      @surname = nil

      assert_nil Worldwide::Names.initials(given: nil, surname: nil)
    end

    test ".initials works with transliterable characters" do
      @given   = "Étienne"
      @surname = "Ãarun"

      assert_equal ["É", "Ã"], Worldwide::Names.initials(given: @given, surname: @surname)
    end

    test ".initials returns empty when language doesn't support initials" do
      @given   = "部ブ連"
      @surname = "Dillon"

      assert_equal ["D"], Worldwide::Names.initials(given: @given, surname: @surname)

      @given   = "Mary"
      @surname = "部ブ連"

      assert_equal ["M"], Worldwide::Names.initials(given: @given, surname: @surname)

      @given   = "部ブ連"
      @surname = "部ブ連"

      assert_empty Worldwide::Names.initials(given: @given, surname: @surname)
    end

    test ".surname_first? returns true if locale is a surname first locale and does not have a region code" do
      input_locale_string = "ja"
      input_locale_sym    = :zh

      assert Worldwide::Names.surname_first?(input_locale_string)
      assert Worldwide::Names.surname_first?(input_locale_sym)
    end

    test ".surname_first? returns true if locale is a surname first locale and has a region code" do
      input_locale_string = "ja-JP"
      input_locale_sym    = :"zh-Hans-HK"

      assert Worldwide::Names.surname_first?(input_locale_string)
      assert Worldwide::Names.surname_first?(input_locale_sym)
    end

    test ".surname_first? returns false if locale is not a surname first locale and does not have a region code" do
      input_locale_string = "fr"
      input_locale_sym    = :en

      refute Worldwide::Names.surname_first?(input_locale_string)
      refute Worldwide::Names.surname_first?(input_locale_sym)
    end

    test ".surname_first? returns false if locale is not a surname first locale and has a region code" do
      input_locale_string = "fr-FR"
      input_locale_sym    = :"pt-BR"

      refute Worldwide::Names.surname_first?(input_locale_string)
      refute Worldwide::Names.surname_first?(input_locale_sym)
    end

    test ".surname_first? returns false if input locale is nil" do
      refute Worldwide::Names.surname_first?(nil)
    end

    test ".full returns one parameter with no extra spaces if the other parameter is blank" do
      I18n.with_locale(:en) do
        assert_equal "Mary", Worldwide::Names.full(given: @given, surname: "")
        assert_equal "Dillon", Worldwide::Names.full(given: "", surname: @surname)
      end
    end

    test ".greeting returns one parameter with no extra spaces if the other parameter is blank" do
      I18n.with_locale(:en) do
        assert_equal "Mary", Worldwide::Names.greeting(given: @given, surname: "")
        assert_equal "Dillon", Worldwide::Names.greeting(given: "", surname: @surname)
      end
    end

    test ".greeting doesn't add 様 if name is empty" do
      I18n.with_locale(:ja) do
        assert_equal "Mary", Worldwide::Names.greeting(given: @given, surname: "")
        assert_equal "Dillon", Worldwide::Names.greeting(given: "", surname: @surname)
      end
    end

    test ".abbreviated ignores leading and trailing whitespace" do
      assert_equal "MG", Worldwide::Names.abbreviated(given: " Michael ", surname: " Garfinkle ")
    end

    test ".abbreviated returns nil when given or surname contains punctuation or whitespace" do
      assert_nil Worldwide::Names.abbreviated(given: "Michael", surname: "Garfinkle-Smith")
      assert_nil Worldwide::Names.abbreviated(given: "Mr.", surname: "Garfinkle")
      assert_nil Worldwide::Names.abbreviated(given: "Michael", surname: "van der Garfinkle")
    end

    test ".abbreviated returns nil for mixed scripts" do
      assert_nil Worldwide::Names.abbreviated(given: "คEวง", surname: "อภัADSยวงศ์")
      assert_nil Worldwide::Names.abbreviated(given: "アイ", surname: "Garfinkle")
    end

    test ".abbreviated returns nil when both given and surname are blank" do
      assert_nil Worldwide::Names.abbreviated(given: "", surname: "")
      assert_nil Worldwide::Names.abbreviated(given: nil, surname: nil)
    end

    test ".abbreviated Latin script returns first letter of surname when given is blank" do
      assert_equal "G", Worldwide::Names.abbreviated(given: "", surname: "Garfinkle")
      assert_equal "G", Worldwide::Names.abbreviated(given: nil, surname: "Garfinkle")
    end

    test ".abbreviated Latin script returns first letter of given when surname is blank" do
      assert_equal "M", Worldwide::Names.abbreviated(given: "Michael", surname: "")
      assert_equal "M", Worldwide::Names.abbreviated(given: "Michael", surname: nil)
    end

    test ".abbreviated Latin script returns first letter of given and surname when both present" do
      assert_equal "MG", Worldwide::Names.abbreviated(given: "Michael", surname: "Garfinkle")
    end

    test ".abbreviated Han/Katakana/Hiragana returns surname regardless of given" do
      assert_equal "愛莉", Worldwide::Names.abbreviated(given: "", surname: "愛莉")
      assert_equal "アイ", Worldwide::Names.abbreviated(given: nil, surname: "アイ")
      assert_equal "エリ", Worldwide::Names.abbreviated(given: "エ", surname: "エリ")
    end

    test ".abbreviated Han/Katakana/Hiragana returns nil when surname is blank" do
      assert_nil Worldwide::Names.abbreviated(given: "愛莉", surname: "")
      assert_nil Worldwide::Names.abbreviated(given: "アイ", surname: nil)
    end

    test ".abbreviated Hangul returns given when within ideal_max_length" do
      assert_equal "이슬", Worldwide::Names.abbreviated(given: "이슬", surname: "재현")
      assert_equal "하야나", Worldwide::Names.abbreviated(given: "하야나", surname: "재현")
    end

    test ".abbreviated Hangul returns first cluster of given when it exceeds default ideal_max_length" do
      assert_equal "이", Worldwide::Names.abbreviated(given: "이슬슬슬", surname: "재현")
    end

    test ".abbreviated Hangul returns first cluster of given when it exceeds supplied ideal_max_length" do
      assert_equal "이", Worldwide::Names.abbreviated(given: "이슬", surname: "재현", ideal_max_length: 1)
    end

    test ".abbreviated Hangul returns surname when given is blank" do
      assert_equal "재현", Worldwide::Names.abbreviated(given: nil, surname: "재현")
      assert_equal "재현", Worldwide::Names.abbreviated(given: "", surname: "재현")
    end

    test ".abbreviated Thai returns first cluster of given" do
      assert_equal "ค", Worldwide::Names.abbreviated(given: "ควง", surname: "อภัยวงศ์")
    end

    test ".abbreviated Thai returns first cluster of surname when given is blank" do
      assert_equal "อ", Worldwide::Names.abbreviated(given: "", surname: "อภัยวงศ์")
      assert_equal "อ", Worldwide::Names.abbreviated(given: nil, surname: "อภัยวงศ์")
    end
  end
end
