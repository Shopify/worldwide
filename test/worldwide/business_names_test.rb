# frozen_string_literal: true

require "test_helper"

module Worldwide
  class BusinessNamesTest < ActiveSupport::TestCase
    test "leading or trailing whitespace is ignored when creating abbreviation" do
      assert_equal "AS", Worldwide::BusinessNames.abbreviated(name: " A Better Looking Shop  ")
    end

    test "mixed scripts return nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: "อภัADSยวงศ์")
    end

    test "single but unsupported script returns nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: "Мосэнерго")
      assert_nil Worldwide::BusinessNames.abbreviated(name: "بترول")
    end

    test "whitespace-only name returns nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: "   ")
    end

    test "non-positive or non-integer ideal_max_length returns nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: "Shop", ideal_max_length: 0)
      assert_nil Worldwide::BusinessNames.abbreviated(name: "Shop", ideal_max_length: -1)
      assert_nil Worldwide::BusinessNames.abbreviated(name: "Shop", ideal_max_length: "3")
    end

    test "empty name returns nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: "")
    end

    test "nil name returns nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: nil)
    end

    test "single word Latin name returns up to the first 3 letters when ideal_max_length is not set" do
      assert_equal "Sho", Worldwide::BusinessNames.abbreviated(name: "Shop")
      assert_equal "Sh", Worldwide::BusinessNames.abbreviated(name: "Sh")
    end

    test "single word Latin name returns up to ideal_max_length letters when ideal_max_length is set" do
      assert_equal "Shop", Worldwide::BusinessNames.abbreviated(name: "Shop1", ideal_max_length: 4)
      assert_equal "Shop1", Worldwide::BusinessNames.abbreviated(name: "Shop1", ideal_max_length: 7)
    end

    test "Latin name with more than 3 words returns first letter of first and last word when ideal_max_length is not set" do
      assert_equal "AS", Worldwide::BusinessNames.abbreviated(name: "A Better Looking Shop")
    end

    test "Latin name with word count up to ideal_max_length returns first letter of each word" do
      assert_equal "ABLS", Worldwide::BusinessNames.abbreviated(name: "A Better Looking Shop", ideal_max_length: 4)
    end

    test "Latin name within the default ideal_max_length word window returns first letter of each word" do
      assert_equal "ABS", Worldwide::BusinessNames.abbreviated(name: "A Better Shop")
    end

    test "Thai name with more than one word returns nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: "ปูนซ ปูนซิ")
    end

    test "Thai name returns the first grapheme cluster regardless of ideal_max_length" do
      assert_equal "ปู", Worldwide::BusinessNames.abbreviated(name: "ปูนซิเมนต์ไทย")
      assert_equal "ปู", Worldwide::BusinessNames.abbreviated(name: "ปูนซิเมนต์ไทย", ideal_max_length: 20)
    end

    test "single word Chinese name returns the full name" do
      assert_equal "国家电网", Worldwide::BusinessNames.abbreviated(name: "国家电网")
    end

    test "multi word Chinese name returns nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: "国家电网 国家电网")
    end

    test "single word Japanese name returns the full name" do
      assert_equal "任天堂", Worldwide::BusinessNames.abbreviated(name: "任天堂")
    end

    test "multi word Japanese name returns nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: "任天堂 任天堂")
    end

    test "single word Katakana name returns the full name" do
      assert_equal "ソニー", Worldwide::BusinessNames.abbreviated(name: "ソニー")
    end

    test "multi word Katakana name returns nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: "ソニー ソニー")
    end

    test "single word Hiragana name returns the full name" do
      assert_equal "すし", Worldwide::BusinessNames.abbreviated(name: "すし")
    end

    test "multi word Hiragana name returns nil" do
      assert_nil Worldwide::BusinessNames.abbreviated(name: "すし すし")
    end

    test "Hangul name returns first letters of first word up to 3 letters regardless of word count when ideal_max_length is not set" do
      assert_equal "삼성", Worldwide::BusinessNames.abbreviated(name: "삼성 한국어 성삼 한국어")
      assert_equal "삼성한", Worldwide::BusinessNames.abbreviated(name: "삼성한어 한국어 성삼 한국어")
    end

    test "Hangul name returns first letters of first word up to ideal_max_length regardless of word count when ideal_max_length is set" do
      assert_equal "삼", Worldwide::BusinessNames.abbreviated(name: "삼성 한국어 성삼 한국어", ideal_max_length: 1)
      assert_equal "삼성", Worldwide::BusinessNames.abbreviated(name: "삼성 한국어 성삼 한국어", ideal_max_length: 2)
    end
  end
end
