# frozen_string_literal: true

require "test_helper"

module Worldwide
  class PluralsTest < ActiveSupport::TestCase
    test "#cardinal_key_for returns expected values for selected locales and numbers" do
      data = [
        ["cs-CZ", 1, :one],
        [:cs, 2, :few],
        [:cs, 5, :other],
        [:en, 0, :other],
        [:en, 1, :one],
        [:en, 2, :other],
        [:fr, 0, :one],
        [:fr, 1, :one],
        [:fr, 2, :other],
        [:pl, 1, :one],
        [:pl, 18, :many],
        [:pl, 32, :few],
        [:pt, 0, :other],
        [:pt, 1, :one],
        [:"pt-BR", 0, :other],
        [:"pt-BR", 1, :one],
        [:"pt-PT", 0, :other],
        [:"pt-PT", 1, :one],
      ]

      data.each do |input_locale, count, expected_key|
        [input_locale.to_s, input_locale.to_sym].each do |locale|
          actual_key = Worldwide::Plurals.send(:cardinal_key_for, locale, count)

          assert_equal "[#{locale.inspect}] #{expected_key}", "[#{locale.inspect}] #{actual_key}"
        end
      end
    end

    test "#keys returns expected cardinal values for certain locales" do
      data = {
        "bg-BG": [:one, :other],
        cs: [:one, :few, :many, :other],
        da: [:one, :other],
        de: [:one, :other],
        el: [:one, :other],
        en: [:one, :other],
        es: [:many, :one, :other],
        fi: [:one, :other],
        fr: [:many, :one, :other],
        it: [:many, :one, :other],
        hi: [:one, :other],
        "hr-HR": [:one, :few, :other],
        hu: [:one, :other],
        id: [:other],
        ja: [:other],
        ko: [:other],
        "lt-LT": [:one, :few, :many, :other],
        nb: [:one, :other],
        nl: [:one, :other],
        pl: [:one, :few, :many, :other],
        "pt-BR": [:many, :one, :other],
        "pt-PT": [:many, :one, :other],
        "ro-RO": [:one, :few, :other],
        ru: [:one, :few, :many, :other],
        "sk-SK": [:one, :few, :many, :other],
        "sl-SI": [:one, :two, :few, :other],
        sv: [:one, :other],
        th: [:other],
        tr: [:one, :other],
        vi: [:other],
        "zh-CN": [:other],
        "zh-Hans": [:other],
        "zh-Hant": [:other],
        "zh-HK": [:other],
        "zh-TW": [:other],
      }

      data.each do |locale, expected_keys|
        expected = "[#{locale}]: #{expected_keys.sort.inspect}"

        actual_keys = Worldwide::Plurals.keys(locale.to_s)
        actual = "[#{locale}]: #{actual_keys.sort.inspect}"

        assert_equal expected, actual

        actual_keys = Worldwide::Plurals.keys(locale.to_sym)
        actual = "[#{locale}]: #{actual_keys.sort.inspect}"

        assert_equal expected, actual
      end
    end

    test "#keys returns expected ordinal values for certain locales" do
      data = {
        "bg-BG": [:other],
        cs: [:other],
        da: [:other],
        de: [:other],
        el: [:other],
        en: [:few, :one, :other, :two],
        es: [:other],
        fi: [:other],
        fr: [:one, :other],
        it: [:many, :other],
        hi: [:few, :many, :one, :other, :two],
        "hr-HR": [:other],
        hu: [:one, :other],
        id: [:other],
        ja: [:other],
        ko: [:other],
        "lt-LT": [:other],
        nb: [:other],
        nl: [:other],
        pl: [:other],
        "pt-BR": [:other],
        "pt-PT": [:other],
        "ro-RO": [:one, :other],
        ru: [:other],
        "sk-SK": [:other],
        "sl-SI": [:other],
        sv: [:one, :other],
        th: [:other],
        tr: [:other],
        vi: [:one, :other],
        "zh-CN": [:other],
        "zh-Hans": [:other],
        "zh-Hant": [:other],
        "zh-HK": [:other],
        "zh-TW": [:other],
      }

      data.each do |locale, expected_keys|
        expected = "#{locale}: #{expected_keys.sort.inspect}"

        actual_keys = Worldwide::Plurals.keys(locale.to_s, type: :ordinal)
        actual = "#{locale}: #{actual_keys.sort.inspect}"

        assert_equal expected, actual

        actual_keys = Worldwide::Plurals.keys(locale.to_sym, type: :ordinal)
        actual = "#{locale}: #{actual_keys.sort.inspect}"

        assert_equal expected, actual
      end
    end

    test "#keys explodes for invalid locales" do
      e = assert_raises(Worldwide::Plurals::UnknownLocaleError) do
        Worldwide::Plurals.keys("NON-EXISTENT")
      end

      assert_equal "Unknown locale code: `NON-EXISTENT`.", e.message
    end

    test "#keys explodes for invalid plurlization type" do
      e = assert_raises(Worldwide::Plurals::UnknownPluralizationTypeError) do
        Worldwide::Plurals.keys(:en, type: :"NON-EXISTENT")
      end

      assert_equal "Unknown pluralization type: `NON-EXISTENT`. Valid values are :cardinal or :ordinal", e.message
    end

    test "#CARDINAL_PLURALIZATION_KEYS children are all frozen" do
      not_frozen_values = Worldwide::Plurals.send(:cardinal_pluralization_keys).reject { |_k, v| v.frozen? }.keys.sort

      assert_empty not_frozen_values, "Found #{not_frozen_values.size} non-frozen values that should have been frozen. Examples: #{not_frozen_values[0..5]}"
    end

    test "#ORDINAL_PLURALIZATION_KEYS children are all frozen" do
      not_frozen_values = Worldwide::Plurals.send(:ordinal_pluralization_keys).reject { |_k, v| v.frozen? }.keys.sort

      assert_empty not_frozen_values, "Found #{not_frozen_values.size} non-frozen values that should have been frozen. Examples: #{not_frozen_values[0..5]}"
    end
  end
end
