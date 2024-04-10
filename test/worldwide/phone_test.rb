# frozen_string_literal: true

require "test_helper"

module Worldwide
  class PhoneTest < ActiveSupport::TestCase
    test "phone handles valid numbers as expected" do
      # rubocop:disable Metrics/ParameterLists

      [
        [:AE, "٠٤٥٥٧٠٩٨٨", "04 557 0988", "+97145570988", "+971 4 557 0988", "AE"], # GS1 UAE, Dubai - b
        ["at", "01/514442250", "01 514442250", "+431514442250", "+43 1 514442250", "AT"], # Staatsoper, Vienna
        [:au, "131318", "13 13 18", "+61131318", "+61 131318", "AU"], # Canberra Parliament House Post Office
        [:au, "+611300227263", "1300 227 263", "+611300227263", "+61 1300 227 263", "AU"], # GS1 Australia, Melbourne
        [:bl, "590811264", "0590 81 12 64", "+590590811264", "+590 590 81 12 64", "GP"], # Pensionnat de Versailles, GP
        [:ca, "6135551212", "(613) 555-1212", "+16135551212", "+1 613-555-1212", "CA"], # 613 information
        [:ch, "071/242 06 06", "071 242 06 06", "+41712420606", "+41 71 242 06 06", "CH"], # Theater St. Gallen
        [:gb, "+44 303 123 7300", "0303 123 7300", "+443031237300", "+44 303 123 7300", "GB"], # Buckingham Palace
        [:gb, "01624 650000", "01624 650000", "+441624650000", "+44 1624 650000", "IM"], # Noble's Hospital, Strang
        [:gg, "+44 1481 226666", "01481 226666", "+441481226666", "+44 1481 226666", "GG"], # Government House
        [:gp, "590811264", "0590 81 12 64", "+590590811264", "+590 590 81 12 64", "GP"], # Pensionnat de Versailles, GP
        [:it, "06 6830 0230", "06 6830 0230", "+390668300230", "+39 06 6830 0230", "IT"], # Pantheon
        [:it, "06 6982", "06 6982", "+39066982", "+39 06 6982", "VA"], # St. Peter's Basilica - b
        [:it, "+39 070 658626", "070 658626", "+39070658626", "+39 070 658626", "IT"], # Chiesa di San Michele, Cagliari
        [:jp, "＋８１　３−３２１３−１１１１", "03-3213-1111", "+81332131111", "+81 3-3213-1111", "JP"], # Imperial Palace
        [:jp, "092-431-0202", "092-431-0202", "+81924310202", "+81 92-431-0202", "JP"], # Hakata station
        ["li", "238 12 00", "238 12 00", "+4232381200", "+423 238 12 00", "LI"], # Schloss Vaduz
        [:mn, "+97611342539", "011 34 2539", "+97611342539", "+976 11 34 2539", "MN"], # Ulaanbaatar Sanatorium
        [:nf, "322068", "3 22068", "+672322068", "+672 3 22068", "NF"], # Homestead Restaurant
        [:no, "+47 78 99 08 20", "78 99 08 20", "+4778990820", "+47 78 99 08 20", "NO"], # Sollia Lodge, Kirkenes
        [:no, "79 02 43 00", "79 02 43 00", "+4779024300", "+47 79 02 43 00", "SJ"], # Governor of Svalbard
        [:pn, "09/373-7999", "09 373 7999", "+6493737999", "+64 9 373 7999", "NZ"], # University of Auckland, NZ
        [:sj, "+47 78 99 08 20", "78 99 08 20", "+4778990820", "+47 78 99 08 20", "NO"], # Sollia Lodge, Kirkenes
        [:sj, "79 02 43 00", "79 02 43 00", "+4779024300", "+47 79 02 43 00", "SJ"], # Governor of Svalbard
        [:um, "(808) 954-4818", "(808) 954-4818", "+18089544818", "+1 808-954-4818", "US"], # Midway Atoll FWS
        ["US", "(604) 662-6000", "(604) 662-6000", "+16046626000", "+1 604-662-6000", "CA"], # CBC Vancouver
        [:US, "1-212-656-3000", "(212) 656-3000", "+12126563000", "+1 212-656-3000", "US"], # NYSE
        [:va, "06 6988 5318", "06 6988 5318", "+390669885318", "+39 06 6988 5318", "VA"], # Vatican Necropolis
      ].each do |input_country, input_number, domestic, e164, international, reported_country|
        [input_number, domestic, e164, international].each do |number|
          phone = Phone.new(number: number, country_code: input_country)
          validate_phone(phone, number, domestic, e164, international, reported_country)
        end
      end

      # rubocop:enable Metrics/ParameterLists
    end

    test "phone handles invalid numbers as expected" do
      [
        [:at, "020/1234"],
        [:ca, "1613555123"],
        [:ch, "01/123-4567"],
        [:us, "(123)456-7890"],
      ].each do |country_code, number|
        phone = Phone.new(number: number, country_code: country_code)

        assert_equal false, phone.valid?
        assert_equal number, phone.raw
      end
    end

    test "landlines in GP/BL/MF" do
      # libphonenumber is unsure whether these numbers are in GP, BL or MF.
      # Depending on the form in which the number is written, it may return a different one of the above countries.

      [
        ["590279921", "0590 27 99 21", "+590590279921", "+590 590 27 99 21"], # La Plénitude, Friar's Bay, MF
      ].each do |input_number, domestic, e164, international|
        group = ["BL", "GP", "MF"]
        group.each do |input_country|
          phone = Phone.new(number: input_number, country_code: input_country)

          assert_equal true, phone.valid?, "#{input_number} in #{input_country}"
          assert_equal domestic, phone.domestic
          assert_equal e164, phone.e164
          assert_equal international, phone.international
          assert_includes group, phone.country_code
        end
      end
    end

    test "mobile phone numbers in GP/BL/MF" do
      # Guadaloupe, St. Barthélemy, and (the French part of) Saint Martin used to all be "Guadaloupe".
      # The telephone number namespace continues to be commingled.
      # In particular, mobile phones in all three countries are in the range +590 690 xxxxxx,
      # and libphonenumber is unable to distinguish which country is involved (it calls them all "GP").

      group = [:bl, :gp, :mf]

      [
        ["690263468", "0690 26 34 68", "+590690263468", "+590 690 26 34 68"], # St. Barts Coffee Roaster, BL
        ["690527585", "0690 52 75 85", "+590690527585", "+590 690 52 75 85"], # Blue Sail Hotel, Anse Marcel, MF
      ].each do |input_number, domestic, e164, international|
        group.each do |input_country|
          phone = Phone.new(number: input_number, country_code: input_country)
          validate_phone(phone, input_number, domestic, e164, international, input_country.to_s.upcase)
        end
      end
    end

    test "valid numbers with extensions" do
      # rubocop:disable Metrics/ParameterLists
      [
        [:ca, "613-356-6900x123", "(613) 356-6900", "+16133566900", "+1 613-356-6900", "CA", "123"], # IBM Ottawa
        [:de, "+493022732152 ext. 5678", "030 22732152", "+493022732152", "+49 30 22732152", "DE", "5678"], # Reichstag
        [:us, "800-872-7245;256", "(800) 872-7245", "+18008727245", "+1 800-872-7245", "US", "256"], # Penn Station, NY
      ].each do |input_country, input_number, domestic, e164, international, country, extension|
        phone = Phone.new(number: input_number, country_code: input_country)
        validate_phone(phone, input_number, domestic, e164, international, country)

        assert_equal extension, phone.extension
      end
      # rubocop:enable Metrics/ParameterLists
    end

    test "correct country prefix" do
      # rubocop:disable Metrics/ParameterLists
      [
        [:ca, "613-356-6900", "(613) 356-6900", "+16133566900", "+1 613-356-6900", "CA", "1"], # IBM Ottawa

      ].each do |input_country, input_number, domestic, e164, international, country, prefix|
        phone = Phone.new(number: input_number, country_code: input_country)
        validate_phone(phone, input_number, domestic, e164, international, country)

        assert_equal prefix, phone.country_prefix
      end
      # rubocop:enable Metrics/ParameterLists
    end

    private

    # rubocop:disable Metrics/ParameterLists
    def validate_phone(phone, input_number, expected_domestic, expected_e164, expected_international, expected_country)
      assert_equal(true, phone.valid?, "number validity check input_number #{input_number.inspect}")
      assert_equal(expected_domestic, phone.domestic, "domestic check input_number #{input_number.inspect}")
      assert_equal(expected_e164, phone.e164, "e164 check input_number #{input_number.inspect}")
      assert_equal(expected_international, phone.international, "international input_number #{input_number.inspect}")
      assert_equal(expected_country, phone.country_code, "country code check input_number #{input_number.inspect}")
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
