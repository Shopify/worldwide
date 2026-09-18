# frozen_string_literal: true

require "test_helper"

class WorldwideTest < ActiveSupport::TestCase
  test "it has a version number" do
    refute_nil(::Worldwide::VERSION)
  end

  test ".locale caches known locales without retaining unknown codes" do
    original_cache = Worldwide.instance_variable_get(:@locales_cache)
    cache = {}
    Worldwide.instance_variable_set(:@locales_cache, cache)

    ["en", :en, "fr-CA", :"fr-CA"].each do |code|
      locale = Worldwide.locale(code: code)

      assert_equal(code.to_sym, locale.code)
      assert_same(locale, Worldwide.locale(code: code))
    end

    known_keys = cache.keys
    ["en-pirate", :"en-POTATO", "he-Israel", :"he-israel", "bogus-one", :"bogus-two"].each do |code|
      assert_equal(code.to_sym, Worldwide.locale(code: code).code)
      assert_equal(code.to_sym, Worldwide.locale(code: code).code)
    end

    assert_equal(known_keys, cache.keys)
  ensure
    Worldwide.instance_variable_set(:@locales_cache, original_cache)
  end

  test ".locale preserves unknown locale names and fallback" do
    {
      "en-pirate" => "English (pirate)",
      :"en-POTATO" => "English (POTATO)",
      "he-Israel" => "Hebrew (Israel)",
      :"he-israel" => "Hebrew (israel)",
    }.each do |code, expected|
      assert_equal expected, Worldwide.locale(code: code).name(locale: :en)
    end

    unknown_name = Worldwide.locale(code: "bogus-does-not-exist").name(throw: false)

    assert_nil unknown_name
    assert_equal "Unknown language", unknown_name || Worldwide::Locale.unknown.name
  end

  test ".locale rejects nil and empty codes" do
    [nil, "", :""].each do |code|
      assert_raises(ArgumentError) { Worldwide.locale(code: code) }
    end
  end

  test ".lists class method returns the Lists singleton" do
    assert_equal Worldwide::Lists, Worldwide.lists
  end

  test ".names class method returns the Names singleton" do
    assert_equal Worldwide::Names, Worldwide.names
  end

  test ".numbers class method returns the Numbers singleton" do
    assert_equal Worldwide::Numbers, Worldwide.numbers
  end

  test ".punctuation class method returns the Punctuation singleton" do
    assert_equal Worldwide::Punctuation, Worldwide.punctuation
  end

  test ".scripts class method returns the Scripts singleton" do
    assert_equal Worldwide::Scripts, Worldwide.scripts
  end
end
