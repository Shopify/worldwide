# frozen_string_literal: true

require "test_helper"

module Worldwide
  class PostalCodeTest < ActiveSupport::TestCase
    test "numeric_only_zip? returns true if country has numeric only zip code" do
      assert_equal(
        true,
        Zip.numeric_only_zip?(country_code: "US"),
      )
    end

    test "numeric_only_zip? returns false if zip code can contain characters" do
      assert_equal(
        false,
        Zip.numeric_only_zip?(country_code: "CA"),
      )
    end

    test "pure_numeric_only_zip? returns true if country has numeric only zip code without any special chars" do
      assert_equal(
        true,
        Zip.pure_numeric_only_zip?(country_code: "AF"),
      )
    end

    test "pure_numeric_only_zip? returns false if country has numeric only zip code and contains space or dash" do
      assert_equal(
        false,
        Zip.pure_numeric_only_zip?(country_code: "US"),
      )
    end

    test "find_country returns expected countries" do
      [
        [:AD, "25700", :ES], # La Seu d'Urgell

        [:CH, "9490", :LI], # Vaduz

        [:CY, "99628", :TR], # Eastern Mediterranean University, Famagusta, North Cyprus via Mersion 10 Turkey

        [:CZ, "040 01", :SK], # St. Elizabeth's Cathedral, Staré Mesto
        [:CZ, "960 01", :SK], # Forestry and Timber Museum, Zvolen
        [:CZ, "811 01", :SK], # St. Martin's Cathedral, Bratislava

        [:DE, "B3K 5X5", :CA], # Canadian FMO mail handled via Halifax
        [:DE, "K8N 5W6", :CA], # CFPO mail, which includes CFPO 5053 in Gellenkirchen, Germany
        [:DE, "V9A 7N2", :CA], # Canadian FMO mail handled via Victoria

        [:FR, "97114", :GP], # Trois-Rivières, Guadeloupe
        [:FR, "97127", :GP], # La Désirade, Guadeloupe
        [:FR, "97133", :BL], # Saint Barthélemy
        [:FR, "97134", :GP], # Saint-Louis de Marie-Galante, Guadeloupe
        [:FR, "97137", :GP], # Terre-de-Haut, Guadeloupe
        [:FR, "97150", :MF], # Saint Martin
        [:FR, "97160", :GP], # Zévallos, Guadeloupe
        [:FR, "97218", :MQ], # Basse-Pointe, Martinique
        [:FR, "97300", :GF], # Cayenne, French Guiana
        [:FR, "97320", :GF], # Saint-Laurent-du-Maroni, French Guiana
        [:FR, "97419", :RE], # La Posession, Réunion
        [:FR, "97460", :RE], # Saint-Paul, Réunion
        [:FR, "97500", :PM], # Saint-Pierre and Miquelon
        [:FR, "97600", :YT], # Koungou, Mayotte
        [:FR, "97610", :YT], # Labattoir, Mayotte
        [:FR, "98000", :MC], # Monaco
        [:FR, "98080", :MC], # Radio Monte Carlo, Monaco
        [:FR, "98090", :MC], # Télé Monte Carlo, Monaco
        [:FR, "98600", :WF], # Uvea, Wallis and Futuna
        [:FR, "98620", :WF], # Sigave, Wallis and Futuna
        [:FR, "98701", :PF], # Arue, French Polynesia
        [:FR, "98783", :PF], # Tatakoto, French Polynesia
        [:FR, "98800", :NC], # Nouméa, New Caledonia
        [:FR, " 98---80 0", :NC], # Extraneous spaces and hyphens should get normalized out

        [:GB, "ASCN 1ZZ", :AC],
        [:GB, "aSCN1zZ", :AC],
        [:GB, "ASCN 1ZZ", :AC],
        [:GB, "AI2640", :AI],
        [:GB, "FIQQ 1ZZ", :FK],
        [:GB, "GY6 8SS", :GG], # Guernsey
        [:GB, "GY9 3TD", :GG], # Alderney
        [:GB, "GY10 1SF", :GG], # Sark
        [:GB, "GX11 1AA", :GI],
        [:GB, "GX111AA", :GI],
        [:GB, "gx111aa", :GI],
        [:GB, "SIQQ 1ZZ", :GS],
        [:GB, "JE2 4WF", :JE],
        [:GB, "PCRN 1ZZ", :PN],
        [:GB, "STHL 1ZZ", :SH],
        [:GB, "TDCU 1ZZ", :TA],
        [:GB, "TKCA 1ZZ", :TC],
        [:GB, "VG1110", :VG],
        [:GB, "vg1120", :VG],

        # The following case will not work until we turn on regex validation for GE postal codes
        # [:GE, "30320", :US], # ATL airport

        [:JP, "96362", :US], # US Naval Hospital Okinawa's FPO ZIP

        [:KN, "33126", :US], # 1708 NW 82nd Ave, Doral FL
        [:KN, "33126-2366", :US], # 1708 NW 82nd Ave, Doral FL

        [:KR, "96218", :US], # PSC 305 APO AP (Camp Walker, Daegu)
        [:KR, "96264", :US], # PSC 2 APO AP

        [:LC, "33126", :US], # 1708 NW 82nd Ave, Doral FL
        [:LC, "33126-2366", :US], # 1708 NW 82nd Ave, Doral FL
        [:LC, "33206", :US], # 1 Aeropost Way, Miami FL
        [:LC, "33206-3206", :US], # 1 Aeropost Way, Miami FL

        [:LI, "6706", :AT], # Bürs AT
        [:LI, "6710", :AT], # Nenzing AT
        [:LI, "6800", :AT], # Feldkirch
        [:LI, "6802", :AT], # Frastanz AT
        [:LI, "6812", :AT], # Meiningen
        [:LI, "6971", :AT], # Hard AT
        [:LI, "7208", :CH], # Älpli, Landquart CH
        [:LI, "7304", :CH], # Fläsch CH
        [:LI, "7320", :CH], # Festung Schollberg, Sargans CH
        [:LI, "9430", :CH], # St. Margarethen CH
        [:LI, "9444", :CH], # Diepoldsau CH
        [:LI, "9470", :CH], # Buchs SG CH

        [:MC, "06190", :FR], # Roquebrune-Cap-Martin
        [:MC, "06240", :FR], # Beausoleil
        [:MC, "06610", :FR], # La Gaude

        [:NO, "8099", :SJ], # Jan Mayen
        [:NO, "9170", :SJ], # Longyearbyen, Svalbard
        [:NO, "9173", :SJ], # Ny-Ålesund, Svalbard
        [:NO, "9174", :SJ], # Hopen, Svalbard
        [:NO, "9175", :SJ], # Sveagruva, Svalbard
        [:NO, "9176", :SJ], # Bjørnøya (Bear Island), Svalbard
        [:NO, "9178", :SJ], # Barentsburg, Svalbard

        [:SK, "110 00", :CZ], # Národní muzeum, Nové Město, Prague
        [:SK, "280 02", :CZ], # Brandlova, Kolín
        [:SK, "370 01", :CZ], # České Budějovice
        [:SK, "460 59", :CZ], # Lberec Town Hall
        [:SK, "565 01", :CZ], # Choceň
        [:SK, "687 74", :CZ], # Muzeum poslední žítkovské bohyně, Starý Hrozenkov
        [:SK, "739 98", :CZ], # Mosty u Jablunkova

        [:VC, "33126", :US], # 1708 NW 82nd Ave, Doral FL
        [:VC, "33126-2366", :US], # 1708 NW 82nd Ave, Doral FL
      ].each do |alleged_country_code, zip, expected_country_code|
        assert_equal(
          expected_country_code,
          Zip.find_country(country_code: alleged_country_code, zip: zip)&.iso_code&.to_sym,
          "(#{alleged_country_code.inspect}, #{expected_country_code.inspect}, #{zip.inspect}",
        )
      end
    end

    test "find_country returns some suggestions even when no country code is given" do
      [
        ["JE3 7FW", :JE],
        ["STHL 1ZZ", :SH],
      ].each do |zip, expected_country_code|
        assert_equal expected_country_code, Zip.find_country(zip: zip).iso_code.to_sym
      end
    end

    test "find_country returns the alleged country if the postal code is valid there" do
      [
        [:AC, "ASCN 1ZZ"],
        [:CA, "K1A 1A1"],
        [:FR, "75009"],
        [:GB, "SW1 1AA"],
        [:GI, "GX11 1AA"],
        [:JE, "JE3 7FW"],
        [:US, "90210"],
      ].each do |country_code, zip|
        assert_equal(
          country_code,
          Zip.find_country(country_code: country_code, zip: zip).iso_code.to_sym,
        )
      end
    end

    test "find_country returns nil in cases where we do not expect a suggestion" do
      [
        [:CA, "Q1Q 1Q1"],
        [:CA, "90210"],
        [:GB, "ASCN 1AA"],
        [:GB, "IS200"],
        [:GB, "90210"],
        [:US, "K1A 1A1"],
        [nil, "3008"], # Southern Cross Station, VIC, AU
        [nil, "7020"], # Richmond / Nelson, New Zealand
        [nil, "90210"], # Beverly Hills, CA, US
      ].each do |country_code, zip|
        assert_nil(
          Zip.find_country(country_code: country_code, zip: zip),
          "#{country_code.inspect} | #{zip.inspect}",
        )
      end
    end

    test "find_country only returns suggestions that are above or equal to the confidence thershold" do
      [
        [:GE, "31313", 70, :US],
        [:GB, "ASCN 1ZZ", 80, :AC],
        [:FR, "97412", 80, :RE],
        [:NO, "8099", 0, :SJ],
      ].each do |alleged_country_code, zip, min_confidence, expected_country_code|
        assert_equal(
          expected_country_code,
          Zip.find_country(country_code: alleged_country_code, zip: zip, min_confidence: min_confidence)&.iso_code&.to_sym,
        )
      end
    end

    test "find_country returns nil for suggestions that are not above or equal to the confidence thershold" do
      [
        [:GE, "31313", 80],
        [:GB, "VG1150", 100],
        [:FR, "97412", 100],
        [:NO, "8099", 95],
      ].each do |alleged_country_code, zip, min_confidence|
        assert_nil(
          Zip.find_country(country_code: alleged_country_code, zip: zip, min_confidence: min_confidence)&.code&.to_sym,
        )
      end
    end

    test "normalize adjusts BD postal codes as expected" do
      [
        ["DHAKA1000", "1000"],
        ["DHAKA1230", "1230"],
        ["DHAKA1342", "1342"],
        ["GPO4000", "4000"],
        ["GPO6000", "6000"],
        ["GPO9000", "9000"],
        ["GPO:9000", "9000"],
      ].each do |zip, expected|
        actual = Zip.normalize(country_code: :BD, zip: zip)

        assert_equal expected, actual, "#{zip} should be normalized to #{expected} but got #{actual}"
      end
    end

    test "normalize adjusts FO postal codes as expected" do
      [
        ["100", "100"],
        ["0100", "100"],
        ["FO0100", "FO-100"],
      ].each do |zip, expected|
        actual = Zip.normalize(country_code: :FO, zip: zip)

        assert_equal expected, actual, "#{zip} should have normalized to #{expected}"
      end
    end

    test "normalize adjusts HT postal codes as expected" do
      [
        ["6110HT", "HT6110"], # Port-au-Prince
        ["6120HT", "HT6120"], # Delmas
        ["6140HT", "HT6140"], # Petion-Ville
      ].each do |zip, expected|
        actual = Zip.normalize(country_code: :HT, zip: zip)

        assert_equal expected, actual, "#{zip} should have normalized to #{expected}"
      end
    end

    test "normalize adjusts LK postal codes as expected" do
      [
        ["002", "00200"],
        ["05", "00500"],
        ["5", "00500"],
        ["13", "01300"],
        ["4000", "40000"],
        ["8100", "81000"],
      ].each do |zip, expected|
        actual = Zip.normalize(country_code: :LK, zip: zip)

        assert_equal expected, actual, "#{zip} should have normalized to #{expected}"
        assert_equal expected, Zip.normalize(country_code: :LK, zip: expected)
      end
    end

    test "normalize adjusts MD postal codes as expected" do
      [
        ["2005MD", "MD-2005"],
        ["3300MD", "MD-3300"],
      ].each do |zip, expected|
        actual = Zip.normalize(country_code: "MD", zip: zip)

        assert_equal expected, actual, "#{zip} should have normalized to #{expected} but got #{actual}"
      end
    end

    test "normalize adjusts valid MG postal codes as expected" do
      [
        ["00101", "101"],
        ["00105", "105"],
        ["00621", "621"],
      ].each do |zip, expected|
        actual = Zip.normalize(country_code: "MG", zip: zip)

        assert_equal expected, actual, "#{zip} should have normalized to #{expected} but got #{actual}"
      end
    end

    # In Nigeria, the principal postal office for a region uses the regional prefix followed by `001`.
    # This often leads to a 6-digit number with a string of 4 zeroes.  Users frequently mistype
    # this be adding an extra zero or leaving one out from the string.  We can auto-correct this for them.
    # For example, we see addresses in Lagos (100001) entered is either `10001` or `1000001`.
    test "normalize adjusts NG postal codes as expected" do
      [
        # Codes that we will correct
        ["10001", "100001"], # Lagos
        ["1000001", "100001"], # Lagos
        ["50001", "500001"], # Port Harcourt
        ["90001", "900001"], # Abuja

        # Codes that we will not correct:
        # These show up in our real-world data, but for wildly differing addresses, so we cannot guess what was intended.
        ["25001", "25001"],
        ["95001", "95001"],
      ].each do |zip, expected|
        actual = Zip.normalize(country_code: :NG, zip: zip)

        assert_equal expected, actual, "#{zip} should normalize to #{expected}"
      end
    end

    test "normalize adjusts SG postal codes as expected" do
      [
        ["(470767)", "470767"],
        ["529861SINGAPORE", "529861"],
        ["529861SINGAP0RE", "529861"],
        ["SINGAPORE729930", "729930"],
        ["SINGAP0RE729930", "729930"],
        ["S(522489)", "522489"],
        ["S522489", "522489"],
        ["5(123456)", "123456"],
        ["5123456", "123456"],
      ].each do |zip, expected|
        actual = Zip.normalize(country_code: :SG, zip: zip)

        assert_equal expected, actual, "#{zip} should have normalized to #{expected}"
      end
    end

    test "normalize auto-extends MA 4-digit values to 5-digits" do
      [
        ["1000", "10000"], # Rabbat
        ["100000", "10000"], # Rabbat
        ["2000", "20000"], # Casablanca
        ["200000", "20000"], # Casablanca
        ["4000", "40000"], # Marrakech
        ["400000", "40000"], # Marrakech
        ["9000", "90000"], # Tangier
        ["900000", "90000"], # Tangier
      ].each do |zip, expected|
        actual = Zip.normalize(country_code: :MA, zip: zip)

        assert_equal expected, actual
      end
    end

    test "normalize adjusts valid UK postal codes as expected" do
      [
        ["SW11AA", "SW1 1AA"],
        ["SW1 1AA", "SW1 1AA"],
        ["SW1  1AA", "SW1 1AA"],
        ["CH65YJ", "CH6 5YJ"],
        ["CH6 5YJ", "CH6 5YJ"],
        ["CH6  5YJ", "CH6 5YJ"],
        ["CH654BD", "CH65 4BD"],
        ["CH65 4BD", "CH65 4BD"],
        ["CH65  4BD", "CH65 4BD"],
      ].each do |zip, expected|
        spaces_inserted = Zip.normalize(country_code: "GB", zip: zip)

        assert_equal expected, spaces_inserted
      end
    end

    test "normalize adjusts valid BR postal codes as expected" do
      [
        ["4   ", "4"],
        ["4 - ", "4"],
        ["42-4", "424"],
        ["4234", "4234"],
        ["42345", "42345"],
        ["423457", "42345-7"],
        ["4234578", "42345-78"],
        ["42345789", "42345-789"],
        ["   42345  -  789   ", "42345-789"],
      ].each do |zip, expected|
        spaces_inserted = Zip.normalize(country_code: "BR", zip: zip)

        assert_equal expected, spaces_inserted
      end
    end

    test "normalize adjusts incomplete JP postal by adding hyphens as expected" do
      [
        ["4   ", "4"],
        ["4 - ", "4"],
        ["42-4", "424"],
        ["4234", "423-4"],
        ["42345", "423-45"],
        ["〒423457", "423-457"],
        ["    423   -  4578 ", "423-4578"],
        ["４   ", "4"],
        ["４  －", "4"],
        ["4２-４", "424"],
        ["４２３４", "423-4"],
        ["423\u30fc45", "423-45"],
        ["〒４２３４５７", "423-457"],
        ["    ４２３    －４５７８  ", "423-4578"],
      ].each do |zip, expected|
        result = Zip.normalize(country_code: "JP", zip: zip)

        assert_equal expected, result
      end
    end

    test "normalize adjusts incomplete (outcode-only) UK postal codes by appending a space" do
      [
        ["SW1", "SW1 "],
        ["SW1 ", "SW1 "],
        ["SW1  ", "SW1 "],
        ["CH6", "CH6 "],
        ["CH6 ", "CH6 "],
        ["CH6  ", "CH6 "],
        ["CH65", "CH65 "],
        ["CH65 ", "CH65 "],
        ["CH65  ", "CH65 "],
      ].each do |zip, expected|
        spaces_inserted = Zip.normalize(country_code: "GB", zip: zip)

        assert_equal expected, spaces_inserted
      end
    end

    test "normalize of incomplete UK-style postcodes leaves spaces alone if they're in the zip" do
      [
        [:GB, "E2 0", "E2 0"],
        [:GB, "E20", "E20 "],
        [:GG, "GY1 2", "GY1 2"],
        [:GG, "GY10", "GY10 "],
        [:IM, "IM8 2", "IM8 2"],
        [:IM, "IM86", "IM86 "],
        [:JE, "JE2 3", "JE2 3"],
        [:JE, "JE2", "JE2 "],
      ].each do |country_code, zip, expected|
        normalized = Zip.normalize(country_code: country_code, zip: zip)

        assert_equal expected, normalized, "Normalization of #{zip.inspect} returned #{normalized.inspect}"
      end
    end

    test "normalize adds `VG` prefix in VG if (and only if) it's not already present" do
      assert_equal "VG1120", Zip.normalize(country_code: :VG, zip: "1120")
      assert_equal "VG1120", Zip.normalize(country_code: "VG", zip: "1120")
      assert_equal "VG1120", Zip.normalize(country_code: :VG, zip: "VG1120")
      assert_equal "VG1120", Zip.normalize(country_code: "VG", zip: "VG1120")
    end

    test "normalize corrects common typos in XK (Kosovo)" do
      [
        ["10000", "1000"],
        ["60000", "600000"],
      ].each do |expected, zip|
        actual = Zip.normalize(country_code: "XK", zip: zip)

        assert_equal expected, actual
      end
    end

    test "normalize strips leading and trailing whitespace" do
      [
        [:CA, "K1S 1A1 ", "K1S 1A1"],
        [:GB, " SW1 1AA", "SW1 1AA"],
        [:GB, "CH15 1AA ", "CH15 1AA"],
        [:US, " 90210", "90210"],
        [:US, " 10010  ", "10010"],
      ].each do |country, zip, expected|
        assert_equal(
          expected,
          Zip.normalize(country_code: country, zip: zip),
          "Normalizing #{zip.inspect} expected #{expected.inspect}.",
        )
      end
    end

    test "normalize doesn't change zips in Costa Rica" do
      ["12345", " 12345", "1 23 45 ", "San Jose", "SAN JOSE"].each do |value|
        assert_equal value, Zip.normalize(country_code: "CR", zip: value)
        assert_equal value, Zip.normalize(country_code: :CR, zip: value)
      end
    end

    test "normalize strips leading 〒 in Japan" do
      assert_equal("100-8111", Zip.normalize(country_code: "JP", zip: "〒100-8111"))
      assert_equal("100-8111", Zip.normalize(country_code: "JP", zip: "〒１００-８１１１"))
      assert_equal("100-8111", Zip.normalize(country_code: "JP", zip: "〒１００ー８１１１"))
    end

    test "normalize converts full-width characters to half-width versions" do
      [
        [:CA, "K１S　１A１", "K1S 1A1"],
        [:CA, "Ｋ１Ｓ　１Ａ１", "K1S 1A1"],
        [:CA, "Ｋ１Ｓ １Ａ１", "K1S 1A1"],
        [:JP, "１００ー８１１１", "100-8111"],
        [:JP, "１００-８１１１", "100-8111"],
        [:JP, "１００ー8111", "100-8111"],
        [:JP, "100-８１１１", "100-8111"],
      ].each do |country, zip, expected|
        assert_equal(expected, Zip.normalize(country_code: country, zip: zip), zip.inspect)
      end
    end

    test "normalize converts various forms of dash into hyphen-minus" do
      [
        [:JP, "〒３３６\u002d００００", "336-0000"], # U+002D hyphen-minus
        [:JP, "〒３３６\u007e００００", "336-0000"], # U+007E tilde
        [:JP, "〒３３６\u058a００００", "336-0000"], # U+058A Armenian hyphen
        [:JP, "〒３３６\u05be００００", "336-0000"], # U+05BE Hebrew punctuation maqaf
        [:JP, "〒３３６\u1806００００", "336-0000"], # U+1806 Mongolian todo soft hyphen
        [:JP, "〒３３６\u1b60００００", "336-0000"], # U+1B60 Balinese pameneng
        [:JP, "〒３３６\u2010００００", "336-0000"], # U+2010 hyphen
        [:JP, "〒３３６\u2011００００", "336-0000"], # U+2011 non-breaking hyphen
        [:JP, "〒３３６\u2012００００", "336-0000"], # U+2012 figure dash
        [:JP, "〒３３６\u2013００００", "336-0000"], # U+2013 en dash
        [:JP, "〒３３６\u2014００００", "336-0000"], # U+2014 em dash
        [:JP, "〒３３６\u2015００００", "336-0000"], # U+2015 horizontal bar ("quotation dash")
        [:JP, "〒３３６\u2053００００", "336-0000"], # U+2053 swung dash
        [:JP, "〒３３６\u2e17００００", "336-0000"], # U+2E17 double oblique hyphen
        [:JP, "〒３３６\u2e3a００００", "336-0000"], # U+2E3A two-em dash
        [:JP, "〒３３６\u2e3b００００", "336-0000"], # U+2E3B three-em dash
        [:JP, "〒３３６\u2212００００", "336-0000"], # U+2212 minus sign
        [:JP, "〒３３６\u30fb００００", "336-0000"], # U+30FB katakana naka-ten
        [:JP, "〒３３６\u30fc００００", "336-0000"], # U+30FC katakana-hiragana prolonged sound mark
        [:JP, "〒３３６\ufe58００００", "336-0000"], # U+FE58 small em dash
        [:JP, "〒３３６\ufe63００００", "336-0000"], # U+FE63 small hyphen-minus
        [:JP, "〒３３６\uff0d００００", "336-0000"], # U+FF0D full-width hyphen-minus
        [:JP, "〒３３６\uff65００００", "336-0000"], # U+FF65 halfwidth katakana naka-ten
      ].each do |country, zip, expected|
        assert_equal(expected, Zip.normalize(country_code: country, zip: zip), zip.inspect)
      end
    end

    test "normalize converts {' ', '.', '/', '_'} to '-'" do
      [
        [:PT, "1049 001", "1049-001"],
        [:PT, "1049.001", "1049-001"],
        [:PT, "1049/001", "1049-001"],
        [:PT, "1049_001", "1049-001"],
      ].each do |country, zip, expected|
        actual = Zip.normalize(country_code: country, zip: zip)

        assert_equal expected, actual, zip.inspect
      end
    end

    # These U+200B (zero-width space) show up somewhat frequently in Thai postcode zip
    test "normalize deletes zero-width spaces" do
      [
        [:AX, "22120\u200b", "22120"],
        [:CA, "M5W\u200b1E6", "M5W 1E6"],
        [:TH, "10110\u200b", "10110"],
        [:US, "\u200b90210", "90210"],
      ].each do |country_code, zip, expected|
        actual = Zip.normalize(country_code: country_code, zip: zip)

        assert_equal expected, actual
      end
    end

    test "normalize deletes internal spaces in US codes" do
      assert_equal "90210", Zip.normalize(country_code: "US", zip: "90 210")
      assert_equal "20003-3228", Zip.normalize(country_code: "US", zip: "20003-32 28")
      assert_equal "20003-3228", Zip.normalize(country_code: "US", zip: "20 003-3228")
      assert_equal "20003-3228", Zip.normalize(country_code: "US", zip: "20003 - 3228")
    end

    test "normalize removes hyphens from Canadian codes" do
      assert_equal "V6B 4A2", Zip.normalize(country_code: "CA", zip: "V6B-4A2")
      assert_equal "V6B 4A2", Zip.normalize(country_code: "CA", zip: "V6B - 4A2")
    end

    test "normalize autofills when an autofill is available" do
      assert_equal "GX11 1AA", Zip.normalize(country_code: "GI", zip: nil)
      assert_equal "GX11 1AA", Zip.normalize(country_code: "GI", zip: "")
      assert_equal "GX11 1AA", Zip.normalize(country_code: "GI", zip: "bogus")
      assert_equal "GX11 1AA", Zip.normalize(country_code: "GI", zip: "SW1 1AA")
    end

    test "replace ohs and zeros for GB where expected" do
      assert_equal "SO14 0YG", Zip.normalize(country_code: "GB", zip: "S014 OYG")
      assert_equal "CO4 0DT", Zip.normalize(country_code: "GB", zip: "C04 ODT")
      assert_equal "CO4 0HW", Zip.normalize(country_code: "GB", zip: "C04 0HW")
      assert_equal "PO6 3LY", Zip.normalize(country_code: "GB", zip: "P06 3LY")
      assert_equal "OL10 1GA", Zip.normalize(country_code: "GB", zip: "0L1O 1GA")
      assert_equal "OX10 0AB", Zip.normalize(country_code: "GB", zip: "0X 1O oa B")
      assert_equal "YO10 3AA", Zip.normalize(country_code: "GB", zip: "y  01o 3 aa")
      assert_equal "SO1 1AA", Zip.normalize(country_code: "GB", zip: "S01 1 AA")
    end

    test "replace ohs and zeros for GB does not replace where not expected" do
      assert_equal "SO14 0YG", Zip.normalize(country_code: "GB", zip: "SO14 0YG")
      assert_equal "S1 1AA", Zip.normalize(country_code: "GB", zip: "S1 1aa")
      assert_equal "SO1 1AA", Zip.normalize(country_code: "GB", zip: "S O11 A A")
    end

    test "replace letters and numbers for numeric only postal codes where expected" do
      [
        [:IT, "61o32", "61032"],
        [:FR, " 7 so o8", "75008"],
        [:CL, "15-90-o", "15900"],
        [:US, " 1 O 0 o 4 ", "10004"],
        [:DE, "D11o11", "D11011"],
        [:IT, "I-0oi84", "I-00184"],
        [:VA, "VAoo120", "00120"], # Autofill for VA will forcefully set the postcode to "00120"
        ["IT", "it-6io3z", "IT-61032"],
        [:CZ, "C-110 o0", "C-110 o0"], # returns unmodified, because after swapping oh to zero it'd be invalid
        ["CZ", "not a postal code", "not a postal code"],
      ].each do |country_code, zip, expected_zip|
        assert_equal(
          expected_zip,
          Zip.normalize(country_code: country_code, zip: zip),
        )
      end
    end

    test "replace letters and numbers for countries with alphanumeric postal codes where expected" do
      [
        [:AR, "Cl4 zS CAB", "C1425CAB"],
        [:AR, "Cl4 zS CABA", "Cl4 zS CABA"],
        [:BB, "8826OO7", "BB26007"],
        [:BB, "B8- 260 O7", "BB26007"],
        [:BB, "8---B26 O 07", "BB26007"],
        [:BM, "H 5 0 5", "HS 05"],
        [:BM, "5B I0", "SB 10"],
        [:BM, "SN O 3", "SN 03"],
        [:BM, "HM O 3", "HM 03"],
        [:BN, " 8E L 4IO ", "BE1410"],
        [:BN, " 8E L 41O ", "BE1410"],
        [:CA, "JSU OCO", "J5V 0C0"],
        [:CA, "KB8 ZTS", "K8B 2T5"],
        [:CA, " -8SA lE7 ", "B5A 1E7"],
        [:CA, "V IC - -- S5 Z", "V1C 5S2"],
        [:CA, "E5H 9M4", "E5H 9M4"],
        [:CA, "1Z 2 zv7", "L2Z 2V7"],
        [:CA, "JSW DCQ", "J5W 0C0"],
        [:IE, "Do8 V04N", "D08 V04N"],
        [:IE, "Dyb V04N", "Dyb V04N"], # This fails the IE regex, so will not be normalized
        [:IE, "D13 HSP2", "D13 H5P2"],
        [:IE, "r95nxro", "R95 NXR0"],
        [:IE, "h91ddko", "H91 DDK0"],
        [:LC, "LCo4101", "LC04  101"],
        [:MS, "m5r IliO", "MSR1110"],
        [:MT, "8Kr 3oOo", "BKR 3000"],
        [:MT, "tp IL71", "tp IL71"],
        [:MT, "tpa 1L7I", "TPA 1171"],
        [:MT, "tp 1L7I", "tp 1L7I"],
        [:NL, "io7l DJ", "1071 DJ"],
        [:NL, "-  -1 o 68 T 8", "1068 TB"],
        [:SZ, "H   I0L", "H101"],
        [:VC, "vCO 1zO", "VC0120"],
        [:VG, "VG11Z0", "VG1120"],
        [:WS, "W5i4ob", "WS1408"],
        [:WS, "not a PostalCode", "not a PostalCode"], # This fails the WS regex, so will not be normalized
      ].each do |country_code, zip, expected_zip|
        assert_equal(
          expected_zip,
          Zip.normalize(country_code: country_code, zip: zip),
        )
      end
    end

    test "when strip_extraneous_characters is true strip out all special characters" do
      [
        [:JP, "#097-0022", "097-0022"], # Special characters are stripped and left with numeric code with hyphen in correct spot.
        [:JP, "0S87-0D0F49", "087-0049"], # Alphabetic characters are stripped and left with numeric code with hyphen in correct spot.
        [:JP, "#0S40-0D0F63", "040-0063"], # Special characters & Alphabetic characters are stripped and left with numeric code with hyphen in correct spot.
        [:JP, "030〜1711", "030-1711"], # strip double-wide tilde, insert hyphen-minus
        [:JP, "「９８４ー０８２７", "984-0827"], # remove extraneous quotation mark, convert to single-width chars
        [:JP, "100-0001です。", "100-0001"], # remove "it is."
        [:JP, "603ー８３６１です。", "603-8361"], # remove "it is." and convert character widths
        [:JP, "#7210973", "721-0973"], # Special characters are stripped and left with numeric code with hyphen in correct spot.
        [:JP, "ap 904-0203", "904-0203"], # Alphabetic characters are stripped and left with numeric code with hyphen in correct spot.
        [:JP, "720〜1133", "720-1133"], # Strip of the tilda and replace with hyphen.
        [:CA, "!V3J0W9", "V3J 0W9"], # Special characters are stripped and left with just numeric/aplha code with space in correct spot.
      ].each do |country_code, zip, expected_zip|
        assert_equal(
          expected_zip,
          Zip.normalize(country_code: country_code, zip: zip, strip_extraneous_characters: true),
        )
      end
    end

    test "normalize inserts spaces and hyphens where expected" do
      [
        [:AC, "ASCN 1ZZ", "ASCN1ZZ"],
        [:AI, "AI-2640", "AI-2640"],
        [:AT, "AT-1010", "AT1010"], # Vienna
        [:AT, "A-1010", "A1010"], # Vienna
        [:BM, "PG 05", "PG05"], # Appleby Lane, Paget
        [:BR, "70070-300", "70070300"], # Memorial JK, Brasilia
        [:CA, "A1A 1A1", "A1A1A1"],
        [:CH, "CH-9000", "CH9000"], # St. Gallen
        [:CR, "40307", "40307"], # Heredioa, Santo Domingo, Tures
        # TODO(on: date('2022-07-01'), to: '#address-service') Activate this test once we start normalizing in CR
        # [:CR, "11051-2059", "110512059"], # San José, Montes de Oca, San Pedro
        [:CZ, "110 00", "11000"], # Astronomical Clock, Prague
        [:FK, "FIQQ 1ZZ", "FIQQ1ZZ"],
        [:GG, "GY2 4GX", "GY24GX"], # The Pony Inn, St. Sampson, Guernsey
        [:GG, "GY10 1SA", "GY101SA"], # Coin de Grive, Sark
        [:GH, "AK", "AK"],
        [:GH, "AK-039", "AK039"],
        [:GH, "AK-039-5028", "AK0395028"], # Kumasi Main Post Office
        [:GH, "WH", "WH"], # Ahanta West
        [:GH, "WH-1435", "WH1435"],
        [:GH, "WH-1435-6447", "WH14356447"], # Takoradi-Elubo Highway, Ahanta West
        [:GI, "GX11 1AA", "GX111AA"],
        [:GR, "106 82", "10682"], # National Archeological Museum, Athens
        [:IE, "D01 X2P2", "D01X2P2"], # Gibson Hotel, Dublin
        [:IM, "IM2 4NA", "IM24NA"], # Palace Hotel Casino, Douglas
        [:JE, "JE2 4UH", "JE24UH"], # Club Hotel & Spa, St. Helier
        [:JE, "JE2 4UH", "JE2 4 UH"], # Club Hotel & Spa, St. Helier
        [:KR, "123-456", "123456"], # Old-style legacy code; note that I made this up, and it may not (have been) valid
        [:LC, "LC03  101", "LC03101"], # Agard Post Office, Castries
        [:LC, "LC05  201", "LC05 201"], # Marchant Post Office, Castries
        [:LV, "LV-1050", "LV1050"], # Jugla, Riga
        [:MT, "VLT 05", "VLT 05"], # Pre-2007 format:  3 letters and 2 digits
        [:MT, "PTA 1226", "PTA1226"], # Modern format (since 2007): 3 letters and 4 digits
        [:NL, "1071 LN", "1071LN"], # Concertgebouw, Amsterdam
        [:NL, "1071 LN", "1071 LN"], # Concertgebouw, Amsterdam
        [:PL, "81-451", "81451"], # Experyment Science Centre, Gdynia
        [:PN, "PCRN 1ZZ", "PCRN1ZZ"],
        [:PT, "4050-253", "4050253"], # Bolsa Palace, Porto
        [:SA, "12214", "12214"], # Kingdom Tower, Riyadh
        [:SA, "12214-1234", "122141234"], # SA is said to support US-ZIP-style plus-four codes; I made this one up
        [:SE, "115 21", "11521"], # Vasa Museum, Stockholm
        [:SH, "STHL 1ZZ", "STHL1ZZ"],
        [:SK, "040 01", "04001"], # St. Elisabeth's Cathedral, Staré Mesto
        [:TA, "TDCU 1ZZ", "TDCU1ZZ"],
        [:TC, "TKCA 1ZZ", "TKCA1ZZ"],
        [:TH, "10100", "10100"],
        [:TH, "10100", "10 100"],
        [:TH, "10210-0299", "10210-0299"], # According to Wikipedia, TH allows 9-digit codes
        [:TH, "10210-0299", "102100299"], # source: https://en.wikipedia.org/wiki/Thai_addressing_system#Postal_code
        [:US, "91608", " 9   1 608 "], # Universal Studios, Hollywood
        [:US, "91608-1002", "91 608 1 002"], # Universal Studios, Hollywood, plus-four code
        [:VG, "VG1110", "VG-1110"], # Tortola Central
        [:VE, "1060-C", "1060C"],
        [:VE, "1050", "1050"],
      ].each do |country, expected, zip|
        assert_equal(expected, Zip.normalize(country_code: country, zip: zip), "For #{zip}")
      end
    end

    test "normalize does not alter a code if it won't be valid after normalization" do
      [
        [:AU, "abc123"],
        [:CA, "901210"],
        [:CA, "q1q-1q1"],
        [:IT, "xx120"],
        [:US, "123456"],
      ].each do |country_code, zip|
        assert_equal(zip, Zip.normalize(country_code: country_code, zip: zip), "For #{zip}")
      end
    end

    test "strip_optional_country_prefix functions as expected" do
      [
        ["DE", "DE-11011", "11011"],
        [:DE, "DE-11011", "11011"],
        [:DE, "DE11011", "11011"],
        [:DE, "D-11011", "11011"],
        [:DE, "D11011", "11011"],
        [:DE, "11011", "11011"],
        [:VA, "VA-00120", "00120"],
        [:IT, "IT-00184", "00184"],
        [:IT, "IT00184", "00184"],
        [:IT, "I-00184", "00184"],
        [:IT, "I00184", "00184"],
        [:IT, "i00184", "00184"],
        [:PT, " p4901-909  ", "4901-909"],
        [:PT, " pt-4901-909  ", "4901-909"],
        [:GR, "Gr-106 82", "106 82"],
        [:GR, " GR14343", "14343"],
      ].each do |country, zip, expected|
        assert_equal(
          expected,
          Zip.strip_optional_country_prefix(country_code: country, zip: zip),
          "Result for country #{country} zip #{zip} should be #{expected}.",
        )
      end
    end

    test "strip_optional_country_prefix does not strip prefix if country code does not match or result after stipping starts with letter" do
      [
        ["IT", "DE-11011", "DE-11011"],
        [:PT, "DE-01840", "DE-01840"],
        [:VA, "VA-Z0120", "VA-Z0120"],
        [:CZ, "C-00120", "C-00120"],
        [:IT, "Il00184", "Il00184"],
      ].each do |country, zip, expected|
        assert_equal(
          expected,
          Zip.strip_optional_country_prefix(country_code: country, zip: zip),
          "Result for country #{country} zip #{zip} should be #{expected}.",
        )
      end
    end

    test "gb_style? returns true for countries that use the United Kingdom's style of postcodes" do
      ["GB", "GG", "GI", "IM", "JE"].each do |country_code|
        assert_equal true, Zip.gb_style?(country_code: country_code)
      end
    end

    test "gb_style? returns false for countries that don't use the UK's style of postcodes" do
      ["CA", "DE", "ES", "FR", "IE", "US"].each do |country_code|
        assert_equal false, Zip.gb_style?(country_code: country_code)
      end
    end

    test "outcode returns the first portion of a postcode for Canada, Ireland, and UK-style postcode countries" do
      [
        [:CA, "K1A 0A9", "K1A"],
        [:IE, "D08 K092", "D08"],
        [:GB, "EC1A 1AA", "EC1A"],
        [:GB, "SW1 1AA", "SW1"],
        [:GB, "sw11 aa", "SW1"], # Check that normalization is applied, too
        [:JE, "JE2 4TQ", "JE2"],
      ].each do |country_code, postcode, expected|
        actual = Zip.outcode(country_code: country_code, zip: postcode)

        assert_equal expected, actual, "Outcode for #{postcode.inspect} should be #{expected} but was #{actual}"
      end
    end

    test "outcode returns the full zip for countries that don't have a split postcode format" do
      [
        [:FR, "75008"],
        [:US, "90210"],
      ].each do |country_code, postcode|
        assert_equal postcode, Zip.outcode(country_code: country_code, zip: postcode)
      end
    end

    test "every country listed in zips_for_country has a regex defined" do
      Zip.send(:zips_for_country).each do |from, candidates|
        assert_predicate(Worldwide.region(code: from).zip_regex, :present?, "#{from} missing regex")

        candidates.each do |country_code, _|
          # Note that we currently do auto-convert Cyprus to Turkey, despite the fact that rollout of
          # regex postal code validation in Turkey is blocked awaiting resolution of zip field hijacking.
          # If/when we manage to resolve that, this special carve-out should be removed.
          next if :TR == country_code.to_sym

          assert_predicate(Worldwide.region(code: country_code).zip_regex, :present?, "#{country_code} missing regex")
        end
      end
    end
  end
end
