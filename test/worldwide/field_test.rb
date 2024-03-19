# frozen_string_literal: true

require "test_helper"

module Worldwide
  class FieldTest < ActiveSupport::TestCase
    test "valid_key? returns the correct value as expected" do
      [
        [:first_name, true],
        [:last_name, true],
        [:company, true],
        [:address1, true],
        [:address2, true],
        [:city, true],
        [:province, true],
        [:zip, true],
        [:country, true],
        [:phone, true],
        [:address, true],
        ["address", true],
        [:some_symbol, false],
        ["some_string", false],
      ].each do |field, expected|
        assert_equal(
          expected,
          Worldwide::Field.valid_key?(field),
          "Expected #{expected} for field #{field}",
        )
      end
    end

    test "autofills city as expected when there is a country_code" do
      [
        [:en, :ae, "-"],
        [:en, :sg, "Singapore"],
        [:fr, :sg, "Singapour"],
        [:ja, :sg, "シンガポール"],
        [:en, :gi, "Gibraltar"],
        [:en, :ta, "Edinburgh of the Seven Seas"],
        [:en, :pn, "Adamstown"],
      ].each do |locale, country_code, expected|
        assert_equal(
          expected,
          Worldwide.region(code: country_code).field(key: :city).autofill(locale: locale),
          "Expected #{expected} for country #{country_code} using locale #{locale}",
        )
      end
    end

    test "autofill returns nil when there is no country code" do
      value = Worldwide::Field.new(country_code: nil, field_key: :city).autofill

      assert_nil value
    end

    test "autofill returns nil when none applicable" do
      test_locales = [:en, :fr, :de, :ja, :"zh-CN"]
      test_countries = [:ca, :gb, :it, :us]

      test_locales.each do |locale|
        test_countries.each do |country_code|
          assert_nil Worldwide.region(code: country_code).field(key: :city).autofill(locale: locale)
        end
      end
    end

    test "error accepts parameters" do
      [
        [:en, "Enter a valid postal code for Prince Edward Island, Canada"],
        [:fr, "Saisir un code postal valide pour Île-du-Prince-Édouard, Canada"],
        [:ja, "カナダのプリンスエドワードアイランド州の有効な郵便番号を入力してください"],
      ].each do |locale, expected|
        I18n.with_locale(locale) do
          ca = Worldwide.region(code: "CA")
          pei = ca.zone(code: "PE")
          actual = Worldwide.region(code: "CA").field(key: :zip).error(
            code: :invalid_for_country_and_province,
            options: { country: ca.full_name, province: pei.full_name },
          )

          assert_equal expected, actual
        end
      end
    end

    test "error returns expected value when there is no country code" do
      [
        [:en, :us, "Enter a valid postal code"],
        [:fr, nil, "Saisissez un code postal valide."],
      ].each do |locale, country_code, expected|
        I18n.with_locale(locale) do
          actual = Worldwide::Field.new(country_code: country_code, field_key: :zip).error(code: :invalid)

          assert_equal expected, actual
        end
      end
    end

    test "error with an invalid error code returns nil" do
      assert_nil Worldwide.region(code: "CA").field(key: :first_name).error(code: :bogus_code_does_not_exist)
    end

    test "warning accepts parameters" do
      [
        [:en, :ca, "Address line 1 is recommended to have less than 15 words"],
        [:fr, nil, "Il est conseillé que la ligne d’adresse 1 ait moins de 15 mots"],
        [:fr, :fr, "Il est conseillé que la ligne d’adresse 1 ait moins de 15 mots"],
        [:ja, :ja, "住所1は15文字未満が推奨されています"],
      ].each do |locale, country_code, expected|
        I18n.with_locale(locale) do
          actual = Worldwide::Field.new(country_code: country_code, field_key: :address1).warning(
            code: :contains_too_many_words,
            options: { word_count: 15 },
          )

          assert_equal expected, actual
        end
      end
    end

    test "warning with an invalid code returns nil" do
      assert_nil Worldwide.region(code: "CA").field(key: :first_name).warning(code: :bogus_code_does_not_exist)
    end

    test "selected labels meet expectations" do
      [
        [:en, :ca, :zip, "Postal code"],
        [:fr, :ca, :zip, "Code postal"],
        [:en, :gb, :zip, "Postcode"],
        [:en, :in, :zip, "PIN code"],
        [:en, :au, :city, "Suburb"],
        [:en, :nz, :city, "City"],
        [:de, :ae, :province, "Emirat"],
        [:ja, :jp, :province, "都道府県"],
        [:en, :jp, :province, "Prefecture"],
      ].each do |locale, country_code, field_key, expected|
        assert_equal(
          expected,
          Worldwide.region(code: country_code).field(key: field_key).label(locale: locale),
          "Expected #{field_key} label for country #{country_code} locale #{locale} to be #{expected}",
        )
      end
    end

    test "label falls back to English if no translation is available in the current locale" do
      zip_field = Worldwide.region(code: "CA").field(key: :zip)

      actual = I18n.with_locale(:sw) do
        zip_field.label
      end

      expected = I18n.with_locale(:en) do
        zip_field.label
      end

      assert_equal(expected, actual)
    end

    test "label returns expected value when there is no country code" do
      [
        [:en, :ca, :address1, "Address"],
        [:fr, nil, :city, "Ville"],
      ].each do |locale, country_code, field, expected|
        I18n.with_locale(locale) do
          actual = Worldwide::Field.new(country_code: country_code, field_key: field).label

          assert_equal expected, actual
        end
      end
    end

    test "label_marked_optional returns expected value for selected fields, countries, and locales" do
      [
        [:de, :at, :address2, "Zusätzliche Adressangaben (optional)"],
        [:en, nil, :city, "City (optional)"],
        [:de, :at, :address2, "Zusätzliche Adressangaben (optional)"],
        [:en, :au, :city, "Suburb (optional)"],
        [:en, :il, :zip, "Postal code (optional)"],
        [:es, :pa, :zip, "Código postal (opcional)"],
        [:es, :sv, :province, "Departamento (opcional)"],
        [:es, nil, :province, "Región (opcional)"],
        [:fr, :ht, :zip, "Code postal (facultatif)"],
        [:ja, :jp, :city, "市区町村 (任意)"],
      ].each do |locale, country_code, field, expected|
        I18n.with_locale(locale) do
          actual = Worldwide::Field.new(country_code: country_code, field_key: field).label_marked_optional

          assert_equal expected, actual
        end
      end
    end
  end
end
