# frozen_string_literal: true

require "test_helper"

module Worldwide
  class ZipValidationTest < ActiveSupport::TestCase
    setup do
      @mappings = Dir.glob("test/lib/zips/*").map do |file|
        country = File.basename(file, ".*")
        [country, YAML.safe_load_file(file)]
      end.to_h
    end

    test "#valid_zip? check for valid postal codes" do
      @mappings.each do |country, mapping|
        mapping["valid"]["postal_codes"].each do |postal_code|
          assert Worldwide.region(code: country).valid_zip?(postal_code), "#{postal_code} should be valid for #{country}"
          mapping.dig("valid", "prefixes")&.each do |prefix|
            assert Worldwide.region(code: country).valid_zip?("#{prefix}#{postal_code}"), "#{postal_code} should be valid for #{country}"
          end
        end
      end
    end

    test "#valid_zip? check for invalid postal codes" do
      @mappings.each do |country, mapping|
        mapping["invalid"]["postal_codes"].each do |postal_code|
          refute Worldwide.region(code: country).valid_zip?(postal_code), "#{postal_code} should be invalid for #{country}"
        end
      end
    end

    test "#valid_zip? with valid partial postal codes" do
      @mappings.each do |country, mapping|
        mapping["valid"]["partial"]&.each do |postal_code|
          assert Worldwide.region(code: country).valid_zip?(postal_code, partial_match: true), "Partial postal code #{postal_code} should be valid for #{country}"
        end
      end
    end

    test "#valid_zip? with invalid partial postal codes" do
      @mappings.each do |country, mapping|
        mapping["invalid"]["partial"]&.each do |postal_code|
          refute Worldwide.region(code: country).valid_zip?(postal_code, partial_match: true), "Partial postal code #{postal_code} should be invalid for #{country}"
        end
      end
    end

    test "#valid_zip? with partial match in Netherlands" do
      assert_equal true, Worldwide.region(code: "NL").valid_zip?("1000", partial_match: true)

      assert_equal false, Worldwide.region(code: "NL").valid_zip?("10", partial_match: true)
      assert_equal false, Worldwide.region(code: "NL").valid_zip?("", partial_match: true)
    end

    test "#valid_zip? in the Åland Islands" do
      ax = Worldwide.region(code: "AX")

      assert_equal true, ax.zip_required?

      [
        "22240", # Hammarland
        "22250", # Lövö
        "22270", # 37 Fiskeläge, Eckerö
        "22340", # 116 Havsviddsvägen
      ].each do |code|
        [code, "AX-#{code}", "AX#{code}"].each do |value|
          assert_equal true, ax.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "2212", # too short
        "221234", # too long
        "22ABC", # must be numeric
        "AB222", # must be numeric
        "23360", # Kustavi, Finland
        "764 56", # Grisslehamn, Sweden
        "96100", # Rovaniemi, Finland
      ].each do |code|
        [code, "AX-#{code}", "AX#{code}"].each do |value|
          assert_equal false, ax.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Afghanistan" do
      af = Worldwide.region(code: "AF")

      assert_equal false, af.zip_required?

      [
        "1001", # Central post office, Kabul
        "1016", # Dashi barchi post office, Kabul
        "2303", # Ghazni South
        "3260", # Murghab, Ghor
        "4259", # Bato, Daykundi
      ].each do |code|
        assert_equal true, af.valid_zip?(code)
      end

      [
        "DL1 1AU", # Darlington, UK
        "32052", # Jasper, FL, USA
        "PO14 4RB", # Portsmouth, UK
        "PA31 8LB", # Lochgilphead, UK
      ].each do |code|
        assert_equal false, af.valid_zip?(code)
      end
    end

    test "#valid_zip? in Albania" do
      al = Worldwide.region(code: "AL")

      assert_equal false, al.zip_required?

      [
        "1000", # Tiranë
        "4001", # Shkoder
        "7306", # Leshnicë
        "8700", # Rruga Azem Hajdari, Quki i Valbones Valbone, Tropoje
        "9706", # Ksamil
      ].each do |code|
        [code, "AL-#{code}", "AL#{code}"].each do |value|
          assert_equal true, al.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "123", # too short
        "12345", # too long
        "BC12", # must be numeric
        "12CD", # must be numeryc
      ].each do |code|
        [code, "AL-#{code}", "AL#{code}"].each do |value|
          assert_equal false, al.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Andorra" do
      ad = Worldwide.region(code: "AD")

      assert_equal true, ad.zip_required?

      [
        "100", # Canillo
        "200", # Encamp
        "300", # Ordino
        "400", # La Massana
        "500", # Andorra la Vella
        "551", # PO Boxes 1001 to 1050 in Andorra la Vella
        "552", # PO Boxes 1051 to 1100 in Andorra la Vella
        "560", # mail for government departments
        "600", # Sant Julià de Lòria
        "700", # Escaldes-Engordany
      ].each do |code|
        [code, "AD-#{code}", "AD#{code}"].each do |value|
          assert_equal true, ad.valid_zip?(value)
        end
      end

      [
        "10", # too short
        "1000", # too long
        "ABC", # must be numeric
        "000", # first digit can't be 0
        "800", # first digit can't be 8
        "900", # first digit can't be 9
      ].each do |code|
        [code, "AD-#{code}", "AD#{code}"].each do |value|
          assert_equal false, ad.valid_zip?(value)
        end
      end
    end

    test "#valid_zip? in Armenia" do
      am = Worldwide.region(code: "AM")

      assert_equal false, am.zip_required?

      [
        "0009", # Aram Khachaturyan House Museum, Yerevan
        "2703", # Aragnadem
        "3401", # Meghri
        "4101", # Noyemberyan
      ].each do |code|
        assert_equal true, am.valid_zip?(code), "#{code} should be valid"
      end

      [
        "4400", # if first digit is 4, second digit must be in the range 0-2
        "5000", # must start with 0-4
        "9999", # must start with 0-4
        "123", # too short
        "12345", # too long
        "375010", # old-style 6-digit codes are no longer allowed
        "AM12", # must be numeric
        "12AM", # must be numeric
      ].each do |code|
        assert_equal false, am.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Astralia" do
      au = Worldwide.region(code: "AU")

      assert_equal true, au.zip_required?

      [
        ["0820", "NT"], # Darwin
        ["2300", "NSW"], # Newcastle
        ["2601", "ACT"], # Canberra
        ["4876", "QLD"], # Umagico
        ["5723", "SA"], # Coober Pedy
        ["6160", "WA"], # Fremantle
        ["7000", "TAS"], # Hobart
      ].each do |zip, _zone|
        assert_equal true, au.valid_zip?(zip), "#{zip} should be accepted"
      end

      [
        "123", # too short
        "12345", # too long
        "AB12", # must be numeric
        "12AB", # must be numeric

        "2899", # Norfolk Island
        "6798", # Christmas Island
        "6799", # Cocos (Keeling) Islands
      ].each do |zip|
        assert_equal false, au.valid_zip?(zip), "#{zip} should not be accepted"
      end

      # 0872 covers the interior outback, including parts of NT, SA and WA
    end

    test "#valid_zip? in Austria" do
      [
        "1010", # Vienna city centre
        "1300", # VIE airport
        "2413", # Berg
        "5020", # Salzburg
        "6691", # Jungholz
        "6800", # Feldkirch
        "8010", # Graz
        "9020", # Klagenfurt am Wörthersee
        "9500", # Villach
      ].each do |code|
        [code, "AT-#{code}", "AT#{code}", "A-#{code}", "A#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "AT").valid_zip?(value)
        end
      end

      assert_equal false, Worldwide.region(code: "AT").valid_zip?("123") # too short
      assert_equal false, Worldwide.region(code: "AT").valid_zip?("12345") # too long
      assert_equal false, Worldwide.region(code: "AT").valid_zip?("0123") # cannot start with zero
      assert_equal false, Worldwide.region(code: "AT").valid_zip?("ABCD") # only digits allowed
    end

    test "#valid_zip? in Argentina" do
      assert_equal true, Worldwide.region(code: "AR").zip_required?
      [
        # Selected valid codes
        "2000",
        "1425",
        "7600",
        "1900",
        "5000",
        "8300",
        "1426",
        "1406",
        "4000",
        "4400",

        # Selected additional valid codes
        "C1425DJA", # Valid postal code in the format: ANNNNAAA
        "Y4602", # Valid postal code in the format: ANNNN
        "1678LLO", # Valid postal code in the format: NNNNAAA
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "AR").valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        # Selected invalid codes
        "",
        "*",
        "01030",
        "A",
        "456543",
        "500",
        "FYHU",
        "400",
        ".",
        "200",

        # Selected additional invalid codes
        "ASD",
        "BUENOSAIRES",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "AR").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Azerbaijan" do
      az = Worldwide.region(code: "AZ")

      assert_equal false, az.zip_required?

      [
        "0525", # Muğanlı
        "1078", # 18 Yusif Vəzir Çəmənzəminli, Bakı
        "2700", # Khachmaz
        "3401", # Meghri
        "5000", # Sumqayit
        "6200", # Ширвани, Zaqatala
        "6713", # Kultepe
        "6834", # Kərimbəyli
      ].each do |code|
        [code, "AZ#{code}", "AZ #{code}", "AZ-#{code}"].each do |value|
          assert_equal true, az.valid_zip?(value), "#{value} should be accepted"
        end
      end

      [
        "0000", # not allocated
        "7501", # not allocated
        "8123", # not allocated
        "9999", # not allocated
        "123", # too short
        "12345", # too long
        "AB12", # must be numeric
        "12AB", # must be numeric
      ].each do |code|
        [code, "AZ#{code}", "AZ #{code}", "AZ-#{code}"].each do |value|
          assert_equal false, az.valid_zip?(value), "#{value} should be rejected"
        end
      end
    end

    test "#valid_zip? in Bangladesh" do
      bd = Worldwide.region(code: "BD")

      assert_equal false, bd.zip_required?

      [
        # Example codes from https://bdpost.portal.gov.bd/site/page/6aaeabe4-479b-4e5a-a671-e9e5b994bf9a
        "1100", # Dhaka Sadar HO, Sutrapur, Dhaka
        "1215", # Tejgaon TSO, Dhaka
        "1360", # Demra, Dhaka
        "1703", # B.O.F, Gazipur Sadar, Gazipur
        "1992", # Hemnagar, Gopalpur, Tangail
        "2230", # Gaforgaon, Mymensingh
        "3002", # Patharia
        "3322", # Narapati
        "7670", # Alfadanga, Faridpur
        "8101", # Ulpur, Gopalganj Sadar, Golpangj, Barisal

        # Example codes from https://worldpostalcode.com/bangladesh/rajshahi-division
        # Note that this includes some ranges that https://www.grcdi.nl/gsb/bangladesh.html claims aren't used,
        # but various sources (including Google Maps) seem to corroborate that they are valid.
        "5020", # Dabiganj, Rangpur
        "5740", # Gabindhaganj, Rangpur
        "5930", # Kalai
        "6000", # Rajshahi Sadar
        "6100", # Ghuramara
        "8240", # Agailzhara
        "8600", # Patuakhali Sadar, Barisal
        "9221", # Chandni Mahal
      ].each do |code|
        assert_equal true, bd.valid_zip?(code), "#{code} should be accepted"
      end

      [
        "123", # too short
        "12345", # too long
        "AB123", # must be numeric
        "123AB", # must be numeric
      ].each do |code|
        assert_equal false, bd.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in Bahrain" do
      bh = Worldwide.region(code: "BH")

      assert_equal false, bh.zip_required?

      [
        "264", # AlNaseem Medical Center W.L.L., Building 3061, Road 6431, Diyar
        "941", # AlSalam Specialist Hospital, Building 1, Road 39, Riffa 80278
        "999", # Kojo Restaurant, Building 4123, Road 9929, Durrat
        "1003", # Vatel Bahrain, Road 318, Building 441, Al Jasra
      ].each do |code|
        assert_equal true, bh.valid_zip?(code), "#{code} should be valid"
      end

      [
        "2345", # out of the allocated range
        "AB12", # must be numeric
        "12AB", # must be numeric
        "12", # too short
        "12345", # too long
      ].each do |code|
        assert_equal false, bh.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Barbados" do
      assert_equal false, Worldwide.region(code: "BB").zip_required?
      [
        "00000",
        "BB11000",
        "BB00000",
        "BB17091",
        "BB17127",
        "BB14004",
        "BB15156",
        "BB17078",
        "BB23004",
        "33178",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "BB").valid_zip?(value), "#{value} should be valid"
        end
      end
      [
        "246",
        "0000",
        "1246",
        "BB",
        "000000",
        "BB0000",
        "11",
        "BB1000",
        "BB1100",
        "NA",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "BB").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Belarus" do
      by = Worldwide.region(code: "BY")

      assert_equal false, by.zip_required?

      [
        "213245", # Ул. Колхозная д.43, Slawharad
        "213660", # Садовая 11, Хотимск
        "220030", # Belarusian National Arts Museum, Minsk
        "223730", # Минская область, Солигорский район, деревня Тычины, улица 17
        "246145", # Гомельская область, Гомельский район, деревня Залипье, исправительное учереждение от 22
      ].each do |code|
        [code, "BY-#{code}", "BY#{code}"].each do |value|
          assert_equal true, by.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "012345", # cannot start with zero
        "ABC123", # must be numeric
        "234ABC", # must be numeric
        "21234", # too short
        "2123456", # too long

        # Codes in other parts of the former Soviet Union (which shares the postcode namespace)
        "109012", # St. Basil's Cathedral, Red Square, Moscow
        "183017", # Naval Museum of the Northern Fleet, Murmansk
        "299049", # Dalne, Sevastopol
        "689000", # ул. Рультытегина, 5, Анадырь, Чукотский автономный округ
      ].each do |code|
        [code, "BY-#{code}", "BY#{code}"].each do |value|
          assert_equal false, by.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Belgium" do
      # Selected valid codes
      ["9000", "1050", "1000", "1180", "1030", "2800", "2000", "2018", "4000", "1070"].each do |code|
        assert_equal true, Worldwide.region(code: "BE").valid_zip?(code), "#{code} should be valid"
        assert_equal true, Worldwide.region(code: "BE").valid_zip?("B-#{code}"), "B-#{code} should be valid"
        assert_equal true, Worldwide.region(code: "BE").valid_zip?("B#{code}"), "B#{code} should be valid"
        assert_equal true, Worldwide.region(code: "BE").valid_zip?("BE-#{code}"), "BE-#{code} should be valid"
        assert_equal true, Worldwide.region(code: "BE").valid_zip?("BE#{code}"), "BE#{code} should be valid"
      end

      # Selected invalid codes
      [
        nil,
        "",
        "00000", # too long
        "0000", # no codes start with 0
        "1",
        "12345", # too long
        "09705", # too long; can't start with 0
        "-",
        "10000", # too long
        "09000", # too long; can't start with 0
      ].each do |code|
        assert_equal false, Worldwide.region(code: "BE").valid_zip?(code), "#{code.inspect} should be invalid"
      end
    end

    test "#valid_zip? in Bermuda" do
      bm = Worldwide.region(code: "BM")

      [
        "CR 01",
        "DD 03",
        "DV 08",
        "FL 04",
        "GE CX",
        "HM 20",
        "MA 06",
        "PG 01",
        "SB 03",
        "WK 10",
      ].each do |code|
        [code, code.delete(" ")].each do |value|
          assert_equal true, bm.valid_zip?(value)
        end
      end

      [
        "12 34", # cannot be all-numeric
        "HM", # partial
        "HM 1", # too short
        "XX 01", # invalid prefix
        "AB CXX", # too long
      ].each do |code|
        [code, code.delete(" ")].each do |value|
          assert_equal false, bm.valid_zip?(value)
        end
      end
    end

    test "#valid_zip? in Bhutan" do
      bt = Worldwide.region(code: "BT")

      assert_equal false, bt.zip_required?

      [
        # Examples from the Google search referencing bhutanpost.bt
        # That actual website seems to have been hijacked (temporarily?) and is unreachable.
        "11001", # Thimphu
        "31002", # Sarpang, Sarpang
        "31101", # Gelephu, Sarpang

        # Examples from https://www.parcelforce.com/sites/default/files/BT%20Postcodes%20Oct19%20v1%20111019.pdf
        "12001", # Paro
        "16009", # Nyishog, Wangdue Phodrang
        "22001", # Samtse
        "35003", # Drujegang, Dagana
        "41001", # Samdrupjongkhar
        "43008", # Tongmizhangsa, Trashiyangtse
        "46102", # Nganglam, Pemghatshel
      ].each do |code|
        assert_equal true, bt.valid_zip?(code), "#{code} should be accepted"
      end

      [
        "1234", # too short
        "123456", # too long
        "AB123", # must be numeric
        "123AB", # must be numeric
      ].each do |code|
        assert_equal false, bt.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in Brunei" do
      bn = Worldwide.region(code: "BN")

      assert_equal true, bn.zip_required?

      [
        "BD0997", # Muara
        "KA2331", # Lot 1300, Jalan Sungai Kuala Belait
        "PA1351", # Jalan Labu
        "TG1749", # Kampong Benutan, Tutong
      ].each do |code|
        assert_equal true, bn.valid_zip?(code), "#{code} should be valid"
      end

      [
        "AA1234", # first letter must be one of B, K, T, P
        "BAA123", # third character must be numeric
        "BA123", # too short
        "BA12345", # too long
        "123456", # first two characters must be alphabetic
      ].each do |code|
        assert_equal false, bn.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Bulgaria" do
      bg = Worldwide.region(code: "BG")

      assert_equal true, bg.zip_required?

      [
        "1000", # Sofia Center
        "1331", # улица „Сливница 182, 1331 Република, София
        "2888", # Долна Крушица
        "3790", # ul. "Georgi Dimitrov", 3790 Bregovo
        "8281", # Rezovo, Bulgaria
        "9300", # ЕКОНТ, ul. "Gotse Delchev" №15, 9300 ПАЗАРА, Dobrich
      ].each do |code|
        [code, "BG-#{code}", "BG#{code}"].each do |value|
          assert_equal true, bg.valid_zip?(value)
        end
      end

      [
        "123", # too short
        "0000", # cannot start with zero
        "0123", # cannot start with zero
        "12345", # too long
        "AB12", # must be numeric
        "12AB", # must be numeric
      ].each do |code|
        [code, "BG-#{code}", "BG#{code}"].each do |value|
          assert_equal false, bg.valid_zip?(value)
        end
      end
    end

    test "#valid_zip? in the British Virgin Islands" do
      vg = Worldwide.region(code: "VG")

      assert_equal true, vg.zip_required?

      # All 6 valid codes
      [
        "VG1110", # Tortola Central
        "VG1120", # Tortola East
        "VG1130", # Tortola West
        "VG1140", # Anegada
        "VG1150", # Virgin Gorda
        "VG1160", # Jost Van Dyke
      ].each do |code|
        assert_equal true, vg.valid_zip?(code)
      end

      [
        "121110", # must start with VG
        "VGABCD", # must end with 4 digits
        "VG1111", # must end with 0
        "K1A1A1", # must start with VG
        "VG111", # too short
        "VG11100", # too long
      ].each do |code|
        assert_equal false, vg.valid_zip?(code)
      end
    end

    test "#valid_zip? in Burkina Faso" do
      bf = Worldwide.region(code: "BF")

      assert_equal false, bf.zip_required?

      # valid codes
      [
        # Examples taken from https://www.upu.int/UPU/media/upu/PostalEntitiesFiles/addressingUnit/bfaEn.pdf
        "10000", # Ouagadougou
        "10010", # Ouagadougou
        "70000", # Tenkodogo
        "91001", # Bama
      ].each do |code|
        assert_equal true, bf.valid_zip?(code), "#{code} should be valid"
      end

      # invalid codes
      [
        "00000", # no codes start with zero
        "1234", # too short
        "123456", # too long
        "ABC12", # must be numeric
        "123AB", # must be numeric
      ].each do |code|
        assert_equal false, bf.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in China" do
      assert_equal true, Worldwide.region(code: "CN").zip_required?

      # Valid codes
      [
        # Selected valid codes
        "518000",
        "510000",
        "310000",
        "100000",
        "610000",
        "201120",
        "200000",
        "210000",
        "214500",
        "450000",

        # Selected valid codes
        "100006", # Dongcheng, Beijing
        "022291", # Ergun City, Hulunbuir, Inner Mongolia
        "134204", # Wenhua Rd, Ji'An, Tonghua, Jilin
        "844000", # Kashgar, Xinjiang
      ].each do |code|
        assert_equal true, Worldwide.region(code: "CN").valid_zip?(code), "#{code} should be valid"
      end

      # Invalid codes
      [
        # Selected rejected codes
        "0",
        "00000",
        "TEST",
        "1",
        "0000",
        "15000", # too short
        "0000000", # too long
        "10000",
        "10010",
        "20000",
      ].each do |code|
        assert_equal false, Worldwide.region(code: "CN").valid_zip?(code), "#{code} should be invalid"
      end
    end

    test "#valid_zip? in Croatia" do
      assert_equal true, Worldwide.region(code: "HR").zip_required?

      # Valid codes
      # It is customary in modern usage to omit the space, but the space is still permitted.
      # We'll try it both with and without the space below.
      [
        "10 000", # Zagreb
        "20 356", # Klek
        "21 300", # Makarska
        "32 255", # Soljani
        "40 000", # Čakovec
        "44 000", # Dvor
        "48 000", # Kopriyvnica
        "52 460", # Kaštel
      ].each do |datum|
        [datum, datum.tr(" ", "")].each do |code|
          [code, "HR-#{code}", "HR#{code}"].each do |value|
            assert_equal true, Worldwide.region(code: "HR").valid_zip?(value)
          end
        end
      end

      assert_equal false, Worldwide.region(code: "HR").valid_zip?("1234") # too short
      assert_equal false, Worldwide.region(code: "HR").valid_zip?("123456") # too long
      assert_equal false, Worldwide.region(code: "HR").valid_zip?("ABC12") # must be numeric
      assert_equal false, Worldwide.region(code: "HR").valid_zip?("00000") # cannot start with zero
      assert_equal false, Worldwide.region(code: "HR").valid_zip?("01234") # cannot start with zero
      assert_equal false, Worldwide.region(code: "HR").valid_zip?("60000") # cannot start with digits >5
      assert_equal false, Worldwide.region(code: "HR").valid_zip?("99999") # cannot start with digits >5
    end

    test "#valid_zip? in Cyprus" do
      assert_equal true, Worldwide.region(code: "CY").zip_required?
      [
        "8560",
        "7060",
        "2480",
        "7040",
        "4046",
        "8020",
        "7104",
        "2540",
        "2057",
        "7102",
        "CY1087",
        "CY-1087",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "CY").valid_zip?(value), "#{value} should be valid"
        end
      end
      [
        "",
        "0",
        "99010",
        "99300",
        "33100",
        "99450",
        "02184",
        "99350",
        "99150",
        "99100",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "CY").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in the Czech Republic" do
      assert_equal true, Worldwide.region(code: "CZ").zip_required?

      # Czech codes should be valid
      [
        "110 00", # Národní muzeum, Nové Město, Prague
        "280 02", # Brandlova, Kolín
        "370 01", # České Budějovice
        "460 59", # Lberec Town Hall
        "565 01", # Choceň
        "687 74", # Muzeum poslední žítkovské bohyně, Starý Hrozenkov
        "739 98", # Mosty u Jablunkova
      ].each do |code|
        [code, "CZ-#{code}", "CZ#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "CZ").valid_zip?(value), "#{value} should be valid"
        end
      end

      # Slovak codes should not be valid
      [
        "040 01", # St. Elizabeth's Cathedral, Staré Mesto
        "811 01", # St. Martin's Cathedral, Bratislava
        "960 01", # Forestry and Timber Museum, Zvolen
      ].each do |code|
        [code, "CZ-#{code}", "CZ#{code}"].each do |value|
          assert_equal false, Worldwide.region(code: "CZ").valid_zip?(value), "#{value} is in SK not in CZ"
        end
      end

      assert_equal false, Worldwide.region(code: "CZ").valid_zip?("1234") # too short
      assert_equal false, Worldwide.region(code: "CZ").valid_zip?("123456") # too long
      assert_equal false, Worldwide.region(code: "CZ").valid_zip?("ABC 12") # must be numeric
    end

    test "#valid_zip? in Denmark" do
      assert_equal true, Worldwide.region(code: "DK").zip_required?

      [
        # Selected valid codes
        "2300",
        "8000",
        "2100",
        "9000",
        "2200",
        "2000",
        "4000",
        "8600",
        "8700",
        "5000",

        # Selected extra valid cases
        "0800", # Høje Taastrup
        "0877", # København C
        "0900", # København C
        "0918", # Københavns Pakke Brc
        "0960", # Internationalt Postcenter
        "1350", # København
        "3000", # Helsingør
        "7190", # Billund
      ].each do |code|
        [code, "DK-#{code}", "DK#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "DK").valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "100", # Tórshavn, Faroe Islands (country code FO)
        "0100", # falsified "Danish" code intended for Tórshavn 100, Faroe Islands
        "0370", # falsified "Danish" code intended for Miðvágur 370, Faroe Islands
        "JCVD",
        "3900", # Nuuk (Godthåb), Greenland (country code GL)
        "3905", # Nuussuaq (Bydel i Nuuk), Greenland (country code GL)
        "2300S",
        "U",
        "2200N",
        "1",
        "188", # Hoyvik, Faroe Islands (country code FO)

        # Selected extra invalid cases
        "12345", # too long
        "3800", # discontinued, formerly used for Tórshavn, Faroe Islands
        "3897", # discontinued, formerly used for Sumba, Faroe Islands
      ].each do |code|
        [code, "DK-#{code}", "DK#{code}"].each do |value|
          assert_equal false, Worldwide.region(code: "DK").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Estonia" do
      ee = Worldwide.region(code: "EE")

      assert_equal true, ee.zip_required?

      [
        "11314", # Solaris mall, Talinn
        "20304", # The Irish Embassy Pub, Narva
        "41008", # Ida-Viru maakond
        "51003", # Raekoja plats, Tartu
        "65001", # Misso, Võru maakond
        "80036", # Alexander's Pub, Vana-Rääma 8, Pärnu maakond
        "86005", # Ikla, Pärnu maakond
        "93816", # Nooruse 1, Kuressaare, Saare maakond
      ].each do |code|
        [code, "EE-#{code}", "EE#{code}", "EST-#{code}", "EST#{code}"].each do |value|
          assert_equal true, ee.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "01234", # cannot start with zero
        "1234", # too short
        "123456", # too long
        "AB123", # must be numeric
        "123AB", # must be numeric
      ].each do |code|
        [code, "EE-#{code}", "EE#{code}", "EST-#{code}", "EST#{code}"].each do |value|
          assert_equal false, ee.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Ethiopia" do
      et = Worldwide.region(code: "ET")

      assert_equal false, et.zip_required?

      [
        # Examples from https://www.parcelforce.com/sites/default/files/ET%20Postcodes%20Sep19%20v1%20230919.pdf
        "1000", # Central Addis Ababa
        "1150", # Alem Gena, Addis Ababa Zone 2
        "1230", # Ak'ak'i Besek'a, Addis Ababa Zone 6
        "2040", # Adele, Oromia-Arssi
        "2120", # Asasa, Ormia-Arssi
        "3080", # Godder, Somali-Afder
        "4560", # Sorfta, Oromia-Bale
        "5440", # Abobo, Gambela Zone 2
        "6300", # Sali, Amhara-Debub Gondar
        "7000", # Kwiha, Tigray-Debubawi
        "7160", # Agula, Tigray-Misrakawi
        "7240", # Serdo, Afar Zone 1
        "7260", # Manda, Afar Zone 1
      ].each do |code|
        assert_equal true, et.valid_zip?(code), "#{code} should be accepted"
      end

      [
        "123", # too short
        "12345", # too long
        "0000", # unallocated
        "9999", # unallocated
        "AB12", # must be numeric
        "12AB", # must be numeric
      ].each do |code|
        assert_equal false, et.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in the Faroe Islands" do
      fo = Worldwide.region(code: "FO")

      assert_equal true, fo.zip_required?

      [
        "100", # Tórshavn
        "188", # Hoyvik
        "380", # Sørvágur
        "766", # Kirkja
        "970", # Sumba
      ].each do |code|
        [code, "FO-#{code}", "FO#{code}"].each do |value|
          assert_equal true, fo.valid_zip?(value)
        end
      end

      [
        "12", # too short
        "1234", # too long
        "012", # first digit cannot be zero
        "3800", # former code for Tórshavn, no longer accepted by the postal service
      ].each do |code|
        [code, "FO-#{code}", "FO#{code}"].each do |value|
          assert_equal false, fo.valid_zip?(value)
        end
      end
    end

    test "#valid_zip? in Finland" do
      assert_equal true, Worldwide.region(code: "FI").zip_required?

      # Valid codes
      [
        "00170", # Helsinki Cathedral
        "23360", # Kustavi
        "33210", # Tampere
        "82980", # Möhköntie
        "99490", # Kilpisjärvi
        "99980", # Utsjoki
      ].each do |code|
        [code, "FI-#{code}", "FI#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "FI").valid_zip?(value), "#{value} should be valid"
        end
      end

      # Invalid codes
      [
        "1234", # too short
        "123456", # too long
        "22270", # Eckerö, Åland Islands
        "22940", # Åva, Åland Islands
      ].each do |code|
        [code, "FI-#{code}", "FI#{code}"].each do |value|
          assert_equal false, Worldwide.region(code: "FI").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in France" do
      # Selected codes (mostly in Paris)
      ["75015", "75017", "75019", "75011", "75018", "75008", "75013", "75012", "75012", "75020", "92100"].each do |code|
        assert_equal true, Worldwide.region(code: "FR").valid_zip?(code), "#{code} should be valid"
      end

      # Selected rejects (mostly "overseas" dependencies)
      [
        nil,
        "",
        "98000", # Monaco
        "M5G 1S4", # Toronto, Canada
        "97200", # Fort-de-France, Martinique
        "97490", # Le Chaudron, Réunion
        "97400", # Saint-Denis, Réunion
        "-",
        "A renseigner", # "To be determined"
        "97430", # Le Tampon, Réunion
      ].each do |code|
        assert_equal false, Worldwide.region(code: "FR").valid_zip?(code), "#{code} should not be valid"
      end

      # A sample of valid codes from across the country
      [
        "13898", # military code
        "20146", # Sotta, Corsica
        "34280", # La Grande-Motte, l'Hérault
        "53370", # Ravigny
        "58180", # Marzay, Nièvre
        "59400", # Cambrai
        "75998", # military code
        "92056", # Paris la Défense
        "99123", # Paris Concours
        "99999", # La Poste (customer service)
      ].each do |code|
        assert_equal true, Worldwide.region(code: "FR").valid_zip?(code), "#{code} should be valid"
      end
    end

    test "#valid_zip? in French Guiana" do
      gf = Worldwide.region(code: "GF")

      assert_equal true, gf.zip_required?

      [
        "97300", # Cayenne
        "97310", # Kourou
        "97313", # Saint-Georges
        "97320", # Saint-Laurent du Maroni
        "97360", # Hydro-base ULM
      ].each do |code|
        [code, "GF-#{code}", "GF#{code}"].each do |value|
          assert_equal true, gf.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "9731", # too short
        "973123", # too long
        "973AB", # must be numeric
        "973GF", # must be numeric
        "75001", # Paris, France
      ].each do |code|
        [code, "GF-#{code}", "GF#{code}"].each do |value|
          assert_equal false, gf.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in French Polynesia" do
      pf = Worldwide.region(code: "PF")

      assert_equal true, pf.zip_required?

      [
        "98702", # Fa'a'ā International Airport
        "98741", # Tahauku
        "98742", # Nuku Hiva
        "98754", # Tubuai Islands
      ].each do |code|
        [code, "PF-#{code}", "PF#{code}"].each do |value|
          assert_equal true, pf.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "75001", # Paris, France
        "978AB", # must be numeric
        "AB978", # must be numeric
        "9781", # too short
        "978123", # too long
      ].each do |code|
        [code, "PF-#{code}", "PF#{code}"].each do |value|
          assert_equal false, pf.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in French Southern Territories" do
      assert_equal false, Worldwide.region(code: "TF").zip_required?
      [
        "", # Accept empty values since postal code is optional.
        "98470",
        "98499",
        "98421",
        "98480",
        "98452",
      ].each do |code|
        assert_equal true, Worldwide.region(code: "TF").valid_zip?(code), "#{code} should be valid"
      end
      [
        "05000",
        "20200",
        "80132",
        "90230",
        "75016",
        "75019",
        "97400",
        "94270",
        "97229",
        "DFN",
      ].each do |code|
        assert_equal false, Worldwide.region(code: "TF").valid_zip?(code), "#{code} should be invalid"
      end
    end

    test "#valid_zip? in Guadeloupe" do
      assert_equal true, Worldwide.region(code: "GP").zip_required?
      [
        # Selected valid codes
        "97139",
        "97122",
        "97190",
        "97170",
        "97180",
        "97129",
        "97160",
        "97110",
        "97115",
        "97118",

        # Selected additional valid codes
        "GP-97181",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "GP").valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        # Selected invalid codes
        "",
        "97133",
        "97150",
        "78108",
        "30008",
        "97232",
        "75015",
        "97220",
        "93100",
        "97300",
        "97060",

        # Selected additional invalid codes
        "971", # too short but contains valid prefix
        "971110", # too many digits
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "GP").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Indonesia" do
      assert_equal true, Worldwide.region(code: "ID").zip_required?

      assert_equal true, Worldwide.region(code: "ID").valid_zip?("30267")
      assert_equal true, Worldwide.region(code: "ID").valid_zip?("17116")
      assert_equal true, Worldwide.region(code: "ID").valid_zip?("73111")
      assert_equal true, Worldwide.region(code: "ID").valid_zip?("95112")

      assert_equal false, Worldwide.region(code: "ID").valid_zip?("3026") # too short
      assert_equal false, Worldwide.region(code: "ID").valid_zip?("302678") # too long
      assert_equal false, Worldwide.region(code: "ID").valid_zip?("00000") # can't start with zero
    end

    test "#valid_zip? in the Isle of Man" do
      im = Worldwide.region(code: "IM")

      assert_equal true, im.zip_required?

      [
        "IM2 4NA", # Douglas
        "IM7 4AT", # Bride
        "IM9 5PX", # Cregneash
        "IM86 1AA", # made-up code, but IM86 is in use according to Wikipedia
        "IM99 1ZZ", # made-up code, but IM99 is in use according to Wikipedia
        "im24na", # Check that normalization is in place
      ].each do |code|
        [code, code.delete(" "), code.gsub(" ", "  "), code.downcase].each do |value|
          assert_equal true, im.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "IM0 1AA", # There is no district 0
        "JE2 3NG", # St. Helier, Jersey
        "SW1 1AA", # Buckingham Palace, London
        "K1S 1A1", # Ottawa, Canada
        "D01 W3X5", # Dublin, Ireland
        "90210", # California, USA
      ].each do |code|
        [code, code.delete(" "), code.gsub(" ", "  "), code.downcase].each do |value|
          assert_equal false, im.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Georgia" do
      assert_equal true, Worldwide.region(code: "GE").zip_required?

      assert_equal true, Worldwide.region(code: "GE").valid_zip?("1010") # Tbilisi
      assert_equal true, Worldwide.region(code: "GE").valid_zip?("2100") # Zugdidid
      assert_equal true, Worldwide.region(code: "GE").valid_zip?("384900") # Sukhum

      assert_equal false, Worldwide.region(code: "GE").valid_zip?("101") # too short
      assert_equal false, Worldwide.region(code: "GE").valid_zip?("12345") # invalid length
      assert_equal false, Worldwide.region(code: "GE").valid_zip?("1234567") # too long
    end

    test "#valid_zip? for Georgia, USA" do
      assert_equal false, Worldwide.region(code: "GE").valid_zip?("30320") # ATL airport
      assert_equal true, Worldwide.region(code: "US").valid_zip?("30320")

      assert_equal false, Worldwide.region(code: "GE").valid_zip?("31401") # 501 Whitaker St., Savannah
      assert_equal true, Worldwide.region(code: "US").valid_zip?("31401")
    end

    test "#valid_zip? for Germany" do
      assert_equal true, Worldwide.region(code: "DE").zip_required?

      assert_equal true, Worldwide.region(code: "DE").valid_zip?("11011") # Reichstag, Berlin
      assert_equal true, Worldwide.region(code: "DE").valid_zip?("24943") # Flensburg
      assert_equal true, Worldwide.region(code: "DE").valid_zip?("80331") # Munich

      # Permit optional prefixes
      assert_equal true, Worldwide.region(code: "DE").valid_zip?("D-11011")
      assert_equal true, Worldwide.region(code: "DE").valid_zip?("D11011")
      assert_equal true, Worldwide.region(code: "DE").valid_zip?("DE-11011")
      assert_equal true, Worldwide.region(code: "DE").valid_zip?("DE11011")
      assert_equal true, Worldwide.region(code: "DE").valid_zip?("D11011")

      assert_equal false, Worldwide.region(code: "DE").valid_zip?("1234") # too short
      assert_equal false, Worldwide.region(code: "DE").valid_zip?("123456") # too long
      assert_equal false, Worldwide.region(code: "DE").valid_zip?("1B3D5") # only digits allowed

      # Buesingen am Hochrein is an enclave of German territory inside Switzerland.
      # Mail to Buesingen can be addressed as if it is in Germany (using D-78266) or
      # as if it were in Switzerland (using CH-8238).  We intentionally only accept
      # the German postal code if the country is entered as "Germany", and the Swiss
      # postal code if the country is entered as "Switzerland".
      assert_equal true, Worldwide.region(code: "DE").valid_zip?("78266")
      assert_equal false, Worldwide.region(code: "DE").valid_zip?("8238")
      assert_equal true, Worldwide.region(code: "CH").valid_zip?("8238")

      assert_equal false, Worldwide.region(code: "CH").valid_zip?("78266")
    end

    test "#valid_zip? in Ghana" do
      gh = Worldwide.region(code: "GH")

      assert_equal false, gh.zip_required?

      [
        # Some codes looked up on ghanapostgps.com
        "AK-039-5028", # Kumasi Main Post Office
        "GA-183-8164", # Ghana Post Head Office, G.P.O., Asafoatse Netty Read, Accra, Central
        "GS-0757-3391", # example from screenshot on front page
        "WH1435", # Takoradi
        "WH-1435-6447", # Takoradi-Elubo Highway, Ahanta West
      ].each do |code|
        assert_equal true, gh.valid_zip?(code)
      end

      [
        # Code must start with a letter
        "123",
        "1234",
        "123-1234",

        # Code cannot start with Z
        "ZA-123",
        "ZA-123-4567",
      ].each do |code|
        assert_equal false, gh.valid_zip?(code)
      end
    end

    test "#valid_zip? in Greece" do
      assert_equal true, Worldwide.region(code: "GR").zip_required?

      [
        "105 58", # Acropolis, Athens
        "270 65", # Temple of Apollo at Bassae
        "330 54", # Delphi
        "412 21", # Theatre of Larisa
        "520 50", # Moni Agias Paraskevis, Kastraki
        "630 85", # Old Square, Pefkochori
        "712 02", # Heraklion Archaeological Museum
        "851 00", # Acropolis, Rhodes
      ].each do |code|
        [code, "GR-#{code}", "GR#{code}", code.tr(" ", ""), code.tr(" ", "-")].each do |value|
          assert_equal true, Worldwide.region(code: "GR").valid_zip?(value)
        end
      end

      assert_equal false, Worldwide.region(code: "GR").valid_zip?("123 4") # too short
      assert_equal false, Worldwide.region(code: "GR").valid_zip?("123 456") # too long
      assert_equal false, Worldwide.region(code: "GR").valid_zip?("012 34") # first digit can't be 0
      assert_equal false, Worldwide.region(code: "GR").valid_zip?("999 99") # first digit can't be 9
      assert_equal false, Worldwide.region(code: "GR").valid_zip?("ABC 12") # must be numeric
    end

    test "#valid_zip? in Greenland" do
      gl = Worldwide.region(code: "GL")

      [
        "3900", # Nuuk
        "3905", # Nuussuaq
        "3910", # Kangerlussuaq
        "3924", # Ikerasassuaq
        "3932", # Arsuk
        "3940", # Paamiut
        "3950", # Aasiaat
        "3961", # Uummannaq
        "3970", # Pituffik
        "3985", # Constable Pynt
        "3992", # SIRIUS Sled Patrol
      ].each do |code|
        [code, "GL-#{code}", "GL#{code}"].each do |value|
          assert_equal true, gl.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "1234", # must start with 39
        "39AB", # must be numeric
        "391", # too short
        "39123", # too long
      ].each do |code|
        [code, "GL-#{code}", "GL#{code}"].each do |value|
          assert_equal false, gl.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Guernsey" do
      assert_equal true, Worldwide.region(code: "GG").zip_required?

      [
        # Selected valid codes
        "GY8 0DJ",
        "GY1 1JB",
        "GY1 2EX",
        "GY1 1DR",
        "GY1 1NZ",
        "GY1 1NG",
        "GY1 1RQ",
        "GY1 1XB",
        "GY1 1PG",
        "GY1 1SS",

        # Selected additional valid codes
        "GY2 4AA", # Pont Vaillant Lane, Guernsey
        "GY3 5AA", # Ville Baudu, Guernsey
        "GY4 6DA", # Les Camps du Moulin, Guernsey
        "GY5 7ZX", # Apartment 6, Villa Rosemount, Rue des Houmets, Castel, Guernsey
        "GY6 8ZD", # Harper Drive, Cranleigh
        "GY7 9DA", # Rue du Campere, St. Pierre du Bois, Guernsey
        "GY8 0AN", # La Vigne, Le Bourg, Forest, Guernsey
        "GY9 3RS", # Clover Cottage, Courtil Liage, Alderney
        "GY10 1PB", # Sark Post Office
      ].each do |code|
        assert_equal true, Worldwide.region(code: "GG").valid_zip?(code), "#{code} should be valid"
      end

      # NOTE: We currently permit GY1 0ZZ, but we should not.  According to royalmail.com, it's invalid.
      # It shows up a fair amount, in what seem to be obvious phony addresses.

      [
        # Selected invalid codes
        "",
        "GY",
        "SW1W 9TQ", # Buckingham Palace Rd, London, England
        "GUERNSEY",
        "CR0 6RG", # Lower Adiscombe Road, Croydon, England
        "GY1ZQ", # must contain at least two digits
        "GY4", # partial code for Saint Martin
        "GY5", # partial code for Castel
        "M1 5AN", # Oxford Street, Manchester, England
        "CT15 5HD", # Napchester Road, Dover, England

        # Selected additional invalid codes
        "GY0 1AA", # only GY1 through GY10 permitted
        "GY11 1AA", # only GY1 through GY10 permitted
        "GY22 1AA", # only GY1 through GY10 permitted
        "JE1 1AA", # Jersey
        "K1A 1A1", # Ottawa, Canada
        "12345", # must be alphanumeric
      ].each do |code|
        assert_equal false, Worldwide.region(code: "GG").valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in Haiti" do
      ht = Worldwide.region(code: "HT")

      assert_equal false, ht.zip_required?

      [
        # Examples from https://en.youbianku.com/Haiti
        "1110", # Cap Haïtien
        "1710", # Plaisance
        "2110", # Fort-Liberté
        "3210", # Saint-Louis du Nord
        "4510", # Marmelade
        "5110", # Hinche
        "6510", # La Gonâve
        "7310", # Corail
        "8110", # Cayes
        "9310", # Belle-Anse
      ].each do |code|
        [code, "HT#{code}", "HT #{code}"].each do |value|
          assert_equal true, ht.valid_zip?(value)
        end
      end

      [
        "0000", # unallocated
        "1800", # unallocated
        "9999", # unallocated
        "123", # too short
        "12345", # too long
        "AB12", # last four characters must be numeric
        "12AB", # last four characters must be numeric
      ].each do |code|
        [code, "HT#{code}", "HT #{code}"].each do |value|
          assert_equal false, ht.valid_zip?(value)
        end
      end
    end

    test "#valid_zip? in Hungary" do
      assert_equal true, Worldwide.region(code: "HU").zip_required?

      # Valid codes
      [
        "1014", # Buda Castle
        "4976", # Garbolc
        "9962", # Magyarlak
      ].each do |code|
        [code, "HU-#{code}", "H-#{code}", "HU#{code}", "H#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "HU").valid_zip?(value), "#{value} should be valid"
        end
      end

      # Invalid codes
      [
        "0000", # unallocated
        "101", # too short
        "10140", # too long
      ].each do |code|
        [code, "HU-#{code}", "H-#{code}", "HU#{code}", "H#{code}"].each do |value|
          assert_equal false, Worldwide.region(code: "HU").valid_zip?(value), "#{value} should be invalid"
        end
      end
    end

    test "#valid_zip? in Iceland" do
      assert_equal true, Worldwide.region(code: "IS").zip_required?
      [
        # Selected valid codes
        "210",
        "200",
        "112",
        "220",
        "105",
        "110",
        "221",
        "101",
        "270",
        "600",

        # Selected additional valid codes
        "108",
      ].each do |code|
        [code, "IS-#{code}", "IS#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "IS").valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        # Selected invalid codes
        "",
        "0112",
        "0105",
        "15107",
        "15200",
        "15105",
        "NN3 5EJ",
        "H",
        "A",
        "0110",

        # Selected additional invalid codes
        "098", # 3 digit postal code with leading 0
        "1010", # 4 digit postal code
        "IS-010",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "IS").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in India" do
      assert_predicate Worldwide.region(code: "IN"), :zip_required?

      # Test various codes that should be considered valid for multiple states
      [
        ["160003", ["CH", "PB"]],  # Raipur Khurd, CH and Raipur Khurd, PB share this pincode
        ["160014", ["CH", "PB"]],  # Jhampur, PB and Jhampur, CH share this pincode
        ["247662", ["UK", "UP"]],
        ["246763", ["UP", "UK"]],  # Bandari caloni, UK and Mohmmad Taharpur, UP share this pincode
        ["396230", ["DN", "GJ"]],
        ["396235", ["GJ", "DN"]],
        ["533464", ["AP", "PY"]],
        ["605007", ["TN", "PY"]],
        ["605014", ["PY", "TN"]],
        ["605102", ["PY", "TN"]],
        ["605105", ["TN", "PY"]],
        ["605106", ["PY", "TN"]],
        ["605110", ["TN", "PY"]],
        ["605111", ["TN", "PY"]],
        ["605501", ["TN", "PY"]],
        ["607402", ["PY", "TN"]],
        ["609601", ["PY", "TN"]],  # Nallambal, TN and Nallambal, PY share this pincode
        # We previously considered 673310 to be in both PY and KL, but seems to be solidly in PY
        ["783123", ["AS", "ML"]],  # Athiabari, ML and Mariampur, AS share this pincode
        ["783134", ["AS", "ML"]],  # Kharkutta, AS and Karkhutta, ML share this pincode
      ].each do |pin_code, _states|
        assert_equal true, Worldwide.region(code: "IN").valid_zip?(pin_code), "#{pin_code} should be valid"
      end

      # Some pincodes are listed in more than one state in the data.gov.in release. Each must be valid country-wide.
      ["503145", "503188", "503225", "503230", "505325", "506003", "509132", "509324", "531149"].each do |pincode|
        assert_equal true, Worldwide.region(code: "IN").valid_zip?(pincode), "PINcode #{pincode} should be valid"
      end

      # 262407 (Nawabganj, Bareilly) exists, but is absent from pincodes.csv.
      assert_equal true, Worldwide.region(code: "IN").valid_zip?("262407")

      # This code is included as a "test" value in pincodes.csv, but it's not a valid PINcode, so we should reject.
      assert_equal false, Worldwide.region(code: "IN").valid_zip?("999999")

      assert_equal false, Worldwide.region(code: "IN").valid_zip?("12345") # too short
      assert_equal false, Worldwide.region(code: "IN").valid_zip?("1234567") # too long
    end

    test "#valid_zip? in Iraq" do
      iq = Worldwide.region(code: "IQ")

      assert_equal false, iq.zip_required?

      [
        # Examples from https://irq.postcodebase.com/
        "10081", # Abu Ghraib, Baghdad
        "31020", # Abu Ghraib, Al Anbar
        "32012", # Hubhib, Deyala
        "34014", # Al Baris (Bamerni), Salah Al Deen
        "36007", # Al Haweejah, Al Ta'amim
        "41005", # Al Shuraa, Mousl (Nainawa)
        "42012", # Al Shekhan, Dahouk
        "44021", # Quwair, Arbil
        "46022", # Kifri, Al Sulaymaniah
        "51017", # Al Nile, Babil
        "52009", # Al Muwafaqiya, Wasit
        "54007", # Al Herra, Al Najaf
        "56003", # Al Husanyniya, Karbala
        "58011", # Sumer, Al Quadisiya
        "61029", # Al Meethag, Al Basrah
        "62010", # Al Azair, Maysan
        "64006", # Al Fajr, Thi Qar
        "66004", # Al Salman, Al Muthanna
      ].each do |code|
        assert_equal true, iq.valid_zip?(code)
      end

      [
        "1034", # too short
        "103456", # too long
        "AB123", # must be numeric
        "123AB", # must be numeric
      ].each do |code|
        assert_equal false, iq.valid_zip?(code)
      end
    end

    test "#valid_zip? in Israel" do
      il = Worldwide.region(code: "IL")

      assert_equal false, il.zip_required?

      # valid codes
      [
        "1224500", # Beit Ussishkin Nature Museum, Dan
        "6133201", # Tel Aviv Museum of Art, Shaul Hamalech Blvd 27, Tel Aviv-Yafo
        "9107802", # The Jerusalem Great Synagogue
      ].each do |code|
        assert_equal true, il.valid_zip?(code), "#{code} should be valid"
      end

      # invalid codes
      [
        "1234", # too short
        "12345", # old-style 5-digit codes are not acceptable
        "123456", # invalid length
        "12345678", # too long
        "ABC1234", # must be numeric
        "1234ABC", # must be numeric
      ].each do |code|
        assert_equal false, il.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Italy" do
      assert_predicate Worldwide.region(code: "IT"), :zip_required?

      italy = Worldwide.region(code: "IT")

      [
        ["BZ", "39012"], # Merano (Bozen)
        ["CA", "09123"], # Cagliari
        ["CN", "12025"], # Dronero
        ["CO", "22060"], # Campione d'Italia, an enclave inside Switzerland
        ["CO", "22100"], # Como
        ["IM", "18024"], # Colle di Nava, Imperia
        ["LE", "73100"], # Lecce
        ["ME", "98164"], # Torre Faro
        ["NA", "80045"], # Pompeii
        ["PA", "90133"], # Palermo
        ["RC", "89018"], # Villa San Giovanni
        ["RM", "00184"], # Colosseo, Roma
        ["RM", "00186"], # Pantheon, Rome
        ["SO", "23024"], # Montespluga, Sondrio
        ["OT", "07028"], # Santa Teresa Gallura
        ["TS", "34131"], # Trieste
      ].each do |_zone, code|
        ["IT-#{code}", "IT#{code}", "I-#{code}", "I#{code}", code].each do |value|
          assert_equal true, italy.valid_zip?(value), "Postal code #{value} should be valid for Italy."
        end
      end

      # Variations of the country prefix should be accepted
      assert_equal true, italy.valid_zip?("IT-00184")
      assert_equal true, italy.valid_zip?("I-00184")
      assert_equal true, italy.valid_zip?("IT00184")
      assert_equal true, italy.valid_zip?("I00184")

      # 18025 is used both for Briga Alta CN and for Mendatica IM
      ["IT-18025", "IT18025", "I-18025", "I18025", "18025"].each do |code|
        assert_equal true, italy.valid_zip?(code), "#{code} should be valid"
      end

      # I have manually confirmed that the following codes are valid on poste.it.
      # They were edge cases that were not permitted in earlier versions of our prefix lists.
      # Thus, I'm asserting about them here to guard against accidentally removing them in the future.
      assert_equal true, italy.valid_zip?("09060") # Settimo San Pietro, CA

      # I have confirmed on poste.it that the following postcodes are NOT valid for Italy.  Here's an example URL:
      # https://www.poste.it/cerca/index.html#/risultati-cerca-cap/00233
      # Let's make sure that we reject them, as we should.
      [
        "00233",
        "00234",
        "00987",
        "08034",
        "08520",
        "09046",
        "09603",
        "09606",
        "09613",
        "09618",
        "09620",
        "09621",
        "09622",
        "09627",
        "09630",
        "09876",
        "20200",
        "20214",
        "20219",
        "20700",
        "23321",
        "23423",
        "23456",
        "23524",
        "33333",
        "33351",
        "34060",
        "34342",
        "34343",
        "34567",
        "49100",
        "77777",
        "78000",
        "89768",
        "99999",
      ].each do |code|
        assert_equal false, italy.valid_zip?(code), "#{code} should be rejected"
      end

      # Note that the following codes are also invalid according to poste.it, but we permit them as "valid"
      # This is an intentional trade-off, sacrificing rejecting some invalid codes in return for shorter
      # prefix tables and, thus, better run-time efficiency.
      # 08043

      # 00120 is in the range of postcodes assigned to Rome, but is used for the Vatican.
      # Thus, it is not valid for IT, but is valid for VA
      assert_equal false, italy.valid_zip?("00120")
      assert_equal true, Worldwide.region(code: "VA").valid_zip?("00120")

      assert_equal false, italy.valid_zip?("1234") # too short
      assert_equal false, italy.valid_zip?("123456") # too long
      assert_equal false, italy.valid_zip?("1B3D5") # only digits allowed
    end

    test "#valid_zip? in Liberia" do
      lr = Worldwide.region(code: "LR")

      assert_equal false, lr.zip_required?

      [
        # This is the only code that seems to be clearly documented on the web
        "1000", # Main post office, Monrovia
      ].each do |code|
        assert_equal true, lr.valid_zip?(code), "#{code} should be accepted"
      end

      [
        "123", # too short
        "12345", # too long
        "AB12", # must be numeric
        "12AB", # must be numeric
      ].each do |code|
        assert_equal false, lr.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in Kazakhstan" do
      kz = Worldwide.region(code: "KZ")

      assert_equal false, kz.zip_required?

      [
        # Codes from api.post.kz, e.g. with this URL:
        # https://api.post.kz/api/byAddress/%D0%B0%D1%81%D1%82%D0%B0%D0%BD%D0%B0%20%D0%BA%D1%83%D0%BD%D0%B0%D0%B5%D0%B2%D0%B0%208?from=0
        ["B46D7X1", "041000"], # ОБЛЫСЫ Алматы,Үштөбе,ДАҢҒЫЛЫ Динмухамеда Ахмедовича Кунаева,үй  8
        ["N31E8H4", "120715"], # ОБЛЫСЫ Қызылорда,Сұлутөбе,Сұлутөбе,КӨШЕCI Астана,үй  8
        ["R22T2X5", "130600"], # Батыр,Батыр,ШАҒЫН АУДАНЫ Астана,КӨШЕCI №8,үй  4
        ["S22A7H2", "140400"], # ОБЛЫСЫ Павлодар,Веселорощин,Славяновка,КӨШЕCI Дунаев,үй  8
      ].each do |new_code, old_code|
        assert_equal true, kz.valid_zip?(new_code), "#{new_code} should be accepted"
        assert_equal true, kz.valid_zip?(old_code), "#{old_code} should be accepted"
      end

      [
        "12345", # too short
        "1234567", # too long for numeric old-style
        "A12B3C", # too short for alpha-numeric new-style
        "A12B3C45", # too long for alpha-numeric new-style
      ].each do |code|
        assert_equal false, kz.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in Kenya" do
      ke = Worldwide.region(code: "KE")

      assert_equal false, ke.zip_required?

      [
        # Source:  https://www.kenyans.co.ke/news/38212-postal-codes-list-all-postal-codes-kenya
        "50413", # Adungosi
        "80101", # Bamburi
        "10401", # Dol Dol
        "20103", # Eldama Ravine
        "40504", # Itibo
        "10203", # Kigumo
        "00905", # Lusingeti
        "00100", # Nairobi GPO
        "90131", # Tala
        "30214", # Zombe
      ].each do |code|
        assert_equal true, ke.valid_zip?(code)
      end
    end

    test "#valid_zip? in Kosovo" do
      xk = Worldwide.region(code: "XK")

      assert_equal false, xk.zip_required?

      [
        "10000", # Pristina
        "22070", # Dragash
        "30000", # Pejë
        "43500", # Rudarska, Leposavić
        "60000", # Giljan
      ].each do |code|
        [code, "RKS-#{code}", "RKS#{code}", "XK-#{code}", "XK#{code}"].each do |value|
          assert_equal true, xk.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "01234", # cannot start with 0
        "AB123", # must be numeric
        "AB12345", # must be numeric
        "123AB", # must be numeric
      ].each do |code|
        [code, "RKS-#{code}", "RKS#{code}", "XK-#{code}", "XK#{code}"].each do |value|
          assert_equal false, xk.valid_zip?(value), "#{value} sohuld not be valid"
        end
      end
    end

    test "#valid_zip? in Laos" do
      la = Worldwide.region(code: "LA")

      assert_equal false, la.zip_required?

      [
        # Examples from https://www.parcelforce.com/sites/default/files/LA%20Postcodes%20Sep19%20v1%20260919_0.pdf
        "01000", # Chanthabuly, Vientiane
        "01170", # Xaythany, Vientane
        "02000", # Boon Neua, Phongsali
        "03000", # Long, Louang Namtha
        "04000", # Beng, Oudomxai
        "05000", # Paktha, Bokeo
        "06000", # Nan, Louangphrabang
        "07000", # Kuan, Houaphan
        "08000", # Khop, Xaignabouli
        "09000", # Pek, Xiangkhoang
        "10000", # Mad, Vientiane Province
        "11000", # Pakxane, Bolikhamxai
        "12000", # Thakhek, Khammouan
        "13000", # Nong, Savannakhet
        "14000", # Ta Oi, Salavan
        "15000", # Kaleum, Xekong
        "16000", # Paksé, Champasak
        "17000", # Sanxay, Altapeu
      ].each do |code|
        assert_equal true, la.valid_zip?(code), "#{code} should be accepted"
      end

      [
        "00000", # unallocated
        "19000", # unallocated
        "21345", # unallocated
        "99999", # unallocated
        "1234", # too short
        "123456", # too long
        "AB123", # must be numeric
        "123AB", # must be numeric
      ].each do |code|
        assert_equal false, la.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in Lithuania" do
      lt = Worldwide.region(code: "LT")

      assert_equal true, lt.zip_required?

      [
        "00143", # Gediminas Castle Tower, Vilnius
        "44279", # Kaunas Town Hall
        "91122", # Rumpiškės g., Klaipėda
      ].each do |code|
        [code, "LT-#{code}", "LT#{code}"].each do |value|
          assert_equal true, lt.valid_zip?(value)
        end
      end

      [
        "1234", # too short
        "123456", # too long
        "ABC12", # must be numeric
        "123AB", # must be numeric
      ].each do |code|
        [code, "LT-#{code}", "LT#{code}"].each do |value|
          assert_equal false, lt.valid_zip?(value)
        end
      end
    end

    test "#valid_zip? in Latvia" do
      assert_equal true, Worldwide.region(code: "LV").zip_required?

      [
        # Selected valid codes
        "LV-2167",
        "LV-1013",
        "LV-1010",
        "LV-1084",
        "LV-1058",
        "LV-1011",
        "LV-1009",
        "LV-1021",
        "LV-1082",
        "LV-1046",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "LV").valid_zip?(value), "#{value} should be valid"
        end
      end
      [
        # Selected invalid codes
        "",
        "45-7356",
        "7272892",
        "7282829",
        "27288283",
        "LV",
        "728292992",
        "7272828",
        "60611",
        "7383829",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "LV").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Luxembourg" do
      assert_predicate Worldwide.region(code: "LU"), :zip_required?

      [
        # Selected valid codes
        "3364",
        "1855",
        "1433",
        "8077",
        "1471",
        "8140",
        "1420",
        "1750",
        "1150",
        "7540",

        # Selected additional valid codes
        "1728", # Palais Grand-Ducal, 17 Rue du Marché-aux-Herbes, Luxembourg
        "3598", # 180 Rte. de Zoufftgen, Dudelange
        "4965", # 18 Rue de l'Église, Käerjeng
        "5555", # 5 Pl. du marché, Remich
        "9647", # 25 Bohey, Wanseler
        "9999", # Colruyt, Weiswampach

        # Packstation addresses can start with 0 (worldwide v1.21.1+)
        "0692",
        "0836",
        "0381",
      ].each do |code|
        [code, "L-#{code}", "L#{code}", "LU-#{code}", "LU#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "LU").valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        # Invalid codes
        "",
        "66706",
        "54294",

        # Selected additional invalid codes
        "123", # too short
        "12345", # too long
        "ABCD", # must be numeric
      ].each do |code|
        [code, "L-#{code}", "L#{code}", "LU-#{code}", "LU#{code}"].each do |value|
          assert_equal false, Worldwide.region(code: "LU").valid_zip?(value), "#{value} should be rejected"
        end
      end
    end

    test "#valid_zip? in Madagascar" do
      assert_equal true, Worldwide.region(code: "MG").zip_required?
      [
        "101",
        "105",
        "102",
        "110",
        "501",
        "103",
        "207",
        "301",
        "503",
        "208",
        "00101", # Normalization should automatically remove the leading `00`
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "MG").valid_zip?(value), "#{value} should be valid"
        end
      end
      [
        "",
        "TANA101",
        "06230",
        "97436",
        "18556",
        "YRORYRORYORYJN",
        "63336",
        "49240",
        "93200",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "MG").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Malawi" do
      mw = Worldwide.region(code: "MW")

      assert_equal false, mw.zip_required?

      # valid codes
      [
        # Source:  https://macra.mw/malawi-post-codes/
        "101100", # Chitipa BOMA
        "106104", # STA Nyaluwanga
        "201104", # TA Chulu
        "203107", # TA Chikho
        "207239", # Lilongwe Urban Area 39
        "313105", # TA Mlauli
      ].each do |code|
        assert_equal true, mw.valid_zip?(code), "#{code} should be valid"
      end

      # invalid codes
      [
        "000000", # no codes start with zero
        "400000", # codes must start with 1, 2 or 3
        "12345", # too short
        "1234567", # too long
        "123ABC", # numeric only
      ].each do |code|
        assert_equal false, mw.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Mauritius" do
      mu = Worldwide.region(code: "MU")

      assert_equal false, mu.zip_required?

      # Codes from https://www.mauritiuspost.mu/products-and-services/post-code-and-zip-code-finder#postcode
      [
        "11106", # Cite La Lumiere, Port Louis
        "20204", # Old Flacq, Calebasses
        "52601", # Cite Anoushka, 16eme Mille
        "61707", # Rioux, La Flora
        "80203", # NHDC Dagotiere
        "A2101", # Ste Rita Village, Agalega
        "R1309", # Chateau de Fleurs, Rodrigues
      ].each do |code|
        assert_equal true, mu.valid_zip?(code), "#{code} should be valid"
      end

      [
        "B1010", # Cannot start with B
        "1110", # too short
        "111006", # too long
        "M1234", # Cannot start with M
      ].each do |code|
        assert_equal false, mu.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Maldives" do
      mv = Worldwide.region(code: "MV")

      assert_equal false, mv.zip_required?

      # Codes from maldivespost.com/post-code
      [
        "00110", # ADh, Angaga
        "00150", # ADh, Kudarah
        "05010", # R, Alifushi
        "05130", # R, Fainu
        "17010", # GDh, Madaveli
        "20123", # Aanu, Buruzu Magu, K, Male
        "22000", # Velana International Airport
        "23000", # Male', Hulhumale
      ].each do |code|
        assert_equal true, mv.valid_zip?(code), "#{code} should be valid"
      end

      [
        "24123", # not allocated
        "31234", # not allocated
        "1234", # too short
        "123456", # too long
        "AB123", # must be numeric
        "123AB", # must be numeric
      ].each do |code|
        assert_equal false, mv.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Mayotte" do
      assert_equal true, Worldwide.region(code: "YT").zip_required?
      [
        "97600",
        "97615",
        "97620",
        "97670",
        "97660",
        "97650",
        "97630",
        "97640",
        "97625",
        "97680",
        "97690",
        "YT-97690",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "YT").valid_zip?(value), "#{value} should be valid"
        end
      end
      [
        "",
        "03100",
        "976000",
        "123456",
        "38100",
        "21237",
        "31077",
        "02310",
        "97650BANDRABOUA",
        "63000",
        "45110",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "YT").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Mexico" do
      assert_predicate Worldwide.region(code: "MX"), :zip_required?

      [
        # Selected valid codes
        "03100",
        "11000",
        "03020",
        "06700",
        "44370",
        "11320",
        "57000",
        "45645",
        "66220",
        "08500",

        # Selected additional valid codes
        "06000", # Catedral Metropolitana, Mexico City
        "22000", # Tijuana
        "77509", # Cancún
      ].each do |code|
        assert_equal true, Worldwide.region(code: "MX").valid_zip?(code), "#{code} should be valid"
      end

      [
        # Selected invalid codes
        "",
        "X",
        ".",
        "0",
        "1900",
        "2",
        "CENTR0",
        "1000000",
        "4310",
        "3100",

        # Selected additional invalid codes
        "7750", # too short
        "775099", # too long
        "ABCDE", # only digits allowed
      ].each do |code|
        assert_equal false, Worldwide.region(code: "MX").valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Moldova" do
      md = Worldwide.region(code: "MD")

      assert_equal false, md.zip_required?

      [
        "2001", # Chișinău (from Wikipedia)

        # Various examples from https://www.posta.md/en/postal_code.html
        "2068", # bd. Moscova, 14/1, or. Chișinău, reg. Chișinău mun.
        "3100", # s. Strîi, 17A, or. Bălți, mun. Bălți
        "3519", # s. Ciocîlteni, Orhei
        "4227", # s. Palanca, Ștefan Vodă
        "4729", # s. Halahora de Sus, Briceni
        "5217", # s. Hăsnăşenii Mari, s. Hăsnășenii Mari, Drochia
        "5434", # s. Solonceni, Rezina
        "6424", # s. Cristeşti, s. Cristești, Nisporeni
        "6518", # str. Ștefan cel Mare, 15, s. Cobusca Veche, Anenii Noi
        "6702", # str. K Marx, 29, or. Basarabeasca, reg. Basarabeasca
        "7416", # s. Budăi, район Taraclia
        "7730", # str. Serghei Lazo, 24, s. Taraclia, Căușeni
      ].each do |code|
        [code, "MD#{code}", "MD-#{code}"].each do |value|
          assert_equal true, md.valid_zip?(value), "#{value} should be accepted"
        end
      end

      [
        "0000", # not allocated
        "1000", # not allocated
        "7800", # not allocated
        "8123", # not allocated
        "9999", # not allocated

        "234", # too short
        "23456", # too long
        "AB23", # must be 4 digits
        "23AB", # must be 4 digits
      ].each do |code|
        [code, "MD#{code}", "MD-#{code}"].each do |value|
          assert_equal false, md.valid_zip?(value), "#{value} should be rejected"
        end
      end
    end

    test "#valid_zip? in Monaco" do
      mc = Worldwide.region(code: "MC")

      assert_equal true, mc.zip_required?

      [
        "98000", # All physical addresses
      ].each do |code|
        [code, "MC-#{code}", "MC#{code}"].each do |value|
          assert_equal true, mc.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "9800", # too short
        "980000", # too long
        "99000", # wrong prefix
        "75010", # Paris, France
        "97133", # Saint Barthélemy
        "97150", # Saint Martin (French part)
        "98400", # Territoires Australes Françaises
      ].each do |code|
        [code, "MC-#{code}", "MC#{code}"].each do |value|
          assert_equal false, mc.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Montenegro" do
      me = Worldwide.region(code: "ME")

      assert_equal true, me.zip_required?

      [
        "81000", # Podgorica
        "85330", # Dobrota
        "84210", # Vijenac 17
        "85346", # Herceg-Novik
      ].each do |code|
        [code, "ME-#{code}", "ME#{code}", "MNE-#{code}", "MNE#{code}"].each do |value|
          assert_equal true, me.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "11000", # Belgrade, Serbia
        "21000", # Novi Sad, Serbia
        "33000", # Prijepolje, Serbia
        "44000", # Sisak, Croatia
        "63000", # Celje, Slovenia
        "72000", # Zenica, Bosnia
        "83550", # typo for 85330
        "91000", # Skopje, North Macedonia
        "8123", # too short
        "812345", # too long
        "ABC12", # must be numeric
        "812AB", # must be numeric
      ].each do |code|
        [code, "ME-#{code}", "ME#{code}", "MNE-#{code}", "MNE#{code}"].each do |value|
          assert_equal false, me.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Montserrat" do
      ms = Worldwide.region(code: "MS")

      assert_equal true, ms.zip_required?

      [
        "MSR1110", # GPO (Brades) and PO boxes
        "MSR1120", # Little Bay
        "MSR1210", # Davy Hill
        "MSR1230", # St John's
        "MSR1250", # Look Out
        "MSR1310", # Cudjoe Head
        "MSR1330", # St. Peter's
        "MSR1350", # Salem
      ].each do |code|
        assert_equal true, ms.valid_zip?(code), "#{code} should be valid"
      end

      [
        "MSR0000", # Digits must start with 1
        "MSR0110", # Digits must start with 1
        "MSR9999", # Digits must start with 1
        "MSR1990", # Middle digits cannot be 9
        "ABC1110", # Must start with MSR
        "1110", # Must start with MSR
        "1231110", # Must be alpha-numeric
      ].each do |code|
        assert_equal false, ms.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Niger" do
      ne = Worldwide.region(code: "NE")

      assert_equal false, ne.zip_required?

      [
        # Examples from https://nigerposte.ne/page/Codes-Bureaux
        "1000", # Agadez
        "1003", # Tchirozerine
        "2001", # Maine-Soroa
        "3003", # Birni N'Gaoure
        "4004", # Madaroufna
        "5007", # Tchintabaraden
        "6000", # Tillabery
        "7005", # Tanout
        "8007", # Niamey-RP
      ].each do |code|
        assert_equal true, ne.valid_zip?(code), "#{code} should be accepted"
      end

      [
        "0000", # unallocated
        "9999", # unallocated
        "1101", # 2nd digit must be zero
        "1021", # 3rd digit must be zero or one
        "100", # too short
        "10000", # too long
        "A001", # must be numeric
        "100A", # must be numeric
      ].each do |code|
        assert_equal false, ne.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in Namibia" do
      na = Worldwide.region(code: "NA")

      assert_equal false, na.zip_required?

      [
        # Examples from Namibian Post
        # https://www.nampost.com.na/uploads/documents/cd93d1d6a58287b5b1e5739815c6c628baa1e657.pdf
        "10000", # Windhoek Office of the Exchange
        "10034", # Wanaheda
        "11001", # Gobabis
        "11008", # Otjinene
        "12001", # Otjiwarongo
        "12013", # Otavi
        "13012", # Okombahe
        "14004", # Onandjokwe
        "15006", # Ongwediva
        "16010", # Ogongo
        "17007", # Ongenga
        "18002", # Mpungu
        "19001", # Rundu
        "20005", # Chincimane
        "21002", # Khorixas
        "22009", # Klein Aub
        "23012", # Noordoewer
      ].each do |code|
        assert_equal true, na.valid_zip?(code)
      end

      [
        "1234", # too short
        "123456", # too long
        "12345", # middle digit must be zero
        "00000", # first digit must be 1 or 2
        "24000", # first two digits must be <= 23
        "45012", # first digit must be 1 or 2
        "99099", # first digit must be 1 or 2
        "99999", # first digit must be 1 or 2
        "AB012", # must be numeric
        "120AB", # must be numeric

        # pre-independence South African codes have not been valid since 1990
        "9000", # catch-all for all of Namibia
        "9100", # Windhoek
        "9180", # Swakopmund
        "9190", # Walvis Bay (this was in use until 1994)
      ].each do |code|
        assert_equal false, na.valid_zip?(code)
      end
    end

    test "#valid_zip? in Nigeria" do
      ng = Worldwide.region(code: "NG")

      assert_equal false, ng.zip_required?

      [
        ["106104", "LA"], # Tiger Bar, Murtala Muhammed Dr., Ikoyi, Lagos
        ["240212", "CR"], # 73, Ndidem Usang Iso Road, Calabar, Cross River
        ["600282", "BO"], # Maiduguri, Borno
        ["841101", "SO"], # Tangaza, Sokoto
      ].each do |zip, _zone_code|
        assert_equal true, ng.valid_zip?(zip), "#{zip} should be valid"
        # Uncomment the next line if/when we add postal code prefixes
        # assert_equal zone_code, ng.zone(postal_code: zip), "Lookup of zone for #{zip} should return #{zone_code}"
      end

      [
        "012345", # must not start with 0
        "000000", # must not start with 0
        "12345", # too short
        "1234567", # too long
        "NG1234", # must be numeric
        "NG123456", # must be numeric
        "1234AB", # must be numeric
      ].each do |zip|
        assert_equal false, ng.valid_zip?(zip), "#{zip} should not be valid"
      end
    end

    test "#valid_zip? in Morocco" do
      ma = Worldwide.region(code: "MA")

      assert_equal false, ma.zip_required?

      [
        "10000", # Rabat
        "20550", # 12 Rue Moulay Ismail, Casablanca
        "40000", # Marrakesh
        "44000", # Essaouira
        "62602", # Cap de l'eau, Рашка
      ].each do |code|
        assert_equal true, ma.valid_zip?(code), "#{code} should be valid"
      end

      [
        "00000", # cannot start with zero
        "01234", # cannot start with zero
        "1234", # too short
        "123456", # too long
        "MA123", # must be numeric
      ].each do |code|
        assert_equal false, ma.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in North Macedonia" do
      mk = Worldwide.region(code: "MK")

      assert_equal true, mk.zip_required?

      [
        "1000", # Skopje
        "1250", # Debar
        "1300", # Kumanovo
        "1480", # Gevgelija
        "2320", # Delçevo
        "6335", # Vevchani
        "7000", # Bitola
        "7500", # Prilep
      ].each do |code|
        [code, "MK-#{code}", "MK#{code}", "NMK-#{code}", "NMK#{code}"].each do |value|
          assert_equal true, mk.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "123", # too short
        "12345", # too long
        "0000", # first digit cannot be 0
        "3000", # first digit cannot be 3
        "4000", # first digit cannot be 4
        "5000", # first digit cannot be 5
        "8000", # first digit cannot be 8
        "9000", # first digit cannot be 9
        "ABCD", # must be numeric
        "123J", # must be numeric
      ].each do |code|
        [code, "MK-#{code}", "MK#{code}", "NMK-#{code}", "NMK#{code}"].each do |value|
          assert_equal false, mk.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Norway" do
      assert_predicate Worldwide.region(code: "NO"), :zip_required?

      [
        "0001", # Oslo
        "1607", # Fredrikstad
        "2677", # Heidal
        "3226", # Sandefjord
        "4737", # Hornnes
        "5527", # Haugesund
        "6770", # Nordfjordeid
        "7870", # Grong
        "8063", # Værøy
        "8590", # Kjøpsvik
        "8009", # Bodø
        "8098", # Bodø
        "9103", # Kvaløya
        "9143", # Skibotn
        "9525", # Masi
        "9740", # Lebesby
        "9900", # Kirkenes
        "9991", # Båtsfjord
      ].each do |code|
        [code, "NO-#{code}", "NO#{code}", "N-#{code}", "N#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "NO").valid_zip?(value), "#{value} should be valid"
        end
      end

      # Svalbard and Jan Mayen should not be considered valid for country NO; they should use country SJ.
      [
        "8099", # Olonkin City, Jan Mayen
        "9170", # Longyearbyen, Svalbard
        "9173", # Ny-Ålesund, Svalbard
        "9174", # Hopen, Svalbard
        "9175", # Sveagruva, Svalbard
        "9176", # Bjørnøya (Bear Island), Svalbard
        "9178", # Barentsburg, Svalbard
      ].each do |code|
        [code, "NO-#{code}", "NO#{code}", "N-#{code}", "N#{code}", "SJ-#{code}", "SJ#{code}"].each do |value|
          assert_equal false, Worldwide.region(code: "NO").valid_zip?(value), "#{value} is in SJ, not NO"
        end
      end

      assert_equal false, Worldwide.region(code: "NO").valid_zip?("123") # too short
      assert_equal false, Worldwide.region(code: "NO").valid_zip?("12345") # too long
      assert_equal false, Worldwide.region(code: "NO").valid_zip?("ABCD") # must be numeric
    end

    test "#valid_zip? in Liechtenstein" do
      assert_predicate Worldwide.region(code: "LI"), :zip_required?

      # AFAIK, these are all currently-allocated codes for Liechtenstein
      [
        "9485", # Nendeln
        "9486", # Schaanwald
        "9487", # Gamprin-Bendern
        "9488", # Schellenberg
        "9490", # Vaduz
        "9491", # Ruggell
        "9492", # Eschen
        "9493", # Mauren
        "9494", # Schaan
        "9495", # Triesen
        "9496", # Balzers
        "9497", # Triesenberg
        "9498", # Planken
      ].each do |code|
        [code, "LI-#{code}", "LI#{code}", "FL-#{code}", "FL#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "LI").valid_zip?(value), "#{value} should be valid"
        end
      end

      assert_equal false, Worldwide.region(code: "LI").valid_zip?("1211") # United Nations, Geneva
      assert_equal false, Worldwide.region(code: "LI").valid_zip?("8001") # Zürich
      assert_equal false, Worldwide.region(code: "LI").valid_zip?("9470") # Buchs SG
    end

    test "#valid_zip? in Panama" do
      pa = Worldwide.region(code: "PA")

      assert_equal false, pa.zip_required?

      # valid codes
      [
        # Source: https://codigopostal.pa/
        "0101", # Bocas del Toro
        "0432", # Dolega, Chiriquí
        "0515", # Jaqué, Darién
        "0754", # Purio, Pedasí, Los Santos
        "0833", # Plaza Panamá, Panamá City
        "0921", # Santa Fe, Veraguas
        "1017", # San Carlos, Panamá Oeste
        "0815", # Correos y Telégrafos, Avenida Central y Calle 34
        # Ten-character codes. Source: https://www.codigospostalespanama.gob.pa/
        "ADC96-M8H44", # Municipio de Panamá, Avenida Justo Arosemena
        "ADC96M8H44", # without the hyphen
        "adc96 m8h44", # lowercase, with a space
        "ACC9B-EJS3W", # Biomuseo, Amador
      ].each do |code|
        assert_equal true, pa.valid_zip?(code), "#{code} should be valid"
      end

      # invalid codes
      [
        "123", # too short
        "12345", # too long
        "12AB", # four characters must be digits
        "AB12", # four characters must be digits
        "C96M8H44", # without the 2-character prefix
        "ADC96-M8H4", # too short
        "ADC96-M8H442", # too long
        "AD096-M8H44", # 0 is not in the code alphabet
        "ADC96-I8H44", # I is not in the code alphabet
        "ADC96-M8O44", # O is not in the code alphabet
        "ADC96-M8H4U", # U is not in the code alphabet
        "ADC96-Y8H44", # Y is not in the code alphabet
      ].each do |code|
        assert_equal false, pa.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Martinique" do
      assert_equal true, Worldwide.region(code: "MQ").zip_required?
      [
        "97200",
        "97232",
        "97233",
        "97224",
        "97231",
        "97240",
        "97212",
        "97230",
        "97215",
        "97220",

        # Selected additional valid codes
        "MQ-97220",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "MQ").valid_zip?(value), "#{value} should be valid"
        end
      end
      [
        "",
        "9200",
        "97300",
        "93000",
        "972",
        "97355",
        "97232LAMENTIN",
        "83200",
        "0000",
        "97321",
        "93400",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "MQ").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in New Caledonia" do
      nc = Worldwide.region(code: "NC")

      assert_equal true, nc.zip_required?

      [
        "98800", # Nouméa
        "98811", # Walla
        "98819", # Moindou
        "98824", # Pouébo
      ].each do |code|
        assert_equal true, nc.valid_zip?(code), "#{code} should be valid"
      end

      [
        "75010", # Paris, France
        "97150", # Saint Martin
        "988AB", # must be numeric
        "9881", # too short
        "988123", # too long
        "A88BB", # must be numeric
      ].each do |code|
        assert_equal false, nc.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Poland" do
      assert_predicate Worldwide.region(code: "PL"), :zip_required?

      assert_equal true, Worldwide.region(code: "PL").valid_zip?("60-534")
      assert_equal true, Worldwide.region(code: "PL").valid_zip?("87-100")
      assert_equal true, Worldwide.region(code: "PL").valid_zip?("05-500")
      assert_equal true, Worldwide.region(code: "PL").valid_zip?("04-536")
      assert_equal true, Worldwide.region(code: "PL").valid_zip?("26 600")
      assert_equal true, Worldwide.region(code: "PL").valid_zip?("PL-60-534")
      assert_equal true, Worldwide.region(code: "PL").valid_zip?("PL-60534")
      assert_equal true, Worldwide.region(code: "PL").valid_zip?("PL60-534")
      assert_equal true, Worldwide.region(code: "PL").valid_zip?("PL60534")
      assert_equal true, Worldwide.region(code: "PL").valid_zip?("PL-60 534")

      assert_equal false, Worldwide.region(code: "PL").valid_zip?(nil)
      assert_equal false, Worldwide.region(code: "PL").valid_zip?("")
      assert_equal false, Worldwide.region(code: "PL").valid_zip?("-")
      assert_equal false, Worldwide.region(code: "PL").valid_zip?("123")
      assert_equal false, Worldwide.region(code: "PL").valid_zip?("1200") # too short
      assert_equal false, Worldwide.region(code: "PL").valid_zip?("123456") # too long
    end

    test "#valid_zip? in Russia" do
      assert Worldwide.region(code: "RU").valid_zip?("103132") # Kremlin
      assert Worldwide.region(code: "RU").valid_zip?("236039") # Brandenburg Gate, Kaliningrad
      assert Worldwide.region(code: "RU").valid_zip?("300041") # Tul'skiy Kreml'
      assert Worldwide.region(code: "RU").valid_zip?("428000") # Cheboksary, Chuvashia Republic
      assert Worldwide.region(code: "RU").valid_zip?("693000") # Yuzhno-Sakhalinsk, Sakhalin Oblast

      refute Worldwide.region(code: "RU").valid_zip?("500000") # No domestic codes begin with 5
      refute Worldwide.region(code: "RU").valid_zip?("700000") # No domestic codes begin with 7
      refute Worldwide.region(code: "RU").valid_zip?("800000") # No domestic codes begin with 8
      refute Worldwide.region(code: "RU").valid_zip?("900000") # No domestic codes begin with 9

      refute Worldwide.region(code: "RU").valid_zip?("12345") # Codes must have 6 digits
      refute Worldwide.region(code: "RU").valid_zip?("97400") # This is the Ukranian code for the Russian 297400
    end

    test "#valid_zip? in Philippines" do
      # Test normal formatting passes
      assert Worldwide.region(code: "PH").valid_zip?("4200")
      assert Worldwide.region(code: "PH").valid_zip?("1124")

      # Test edge cases: too long, too short, not numeric
      assert_equal false, Worldwide.region(code: "PH").valid_zip?("500")
      assert_equal false, Worldwide.region(code: "PH").valid_zip?("700000")
      assert_equal false, Worldwide.region(code: "PH").valid_zip?("7d4a")
    end

    test "#valid_zip? in Réunion" do
      re = Worldwide.region(code: "RE")

      [
        "97413", # Cilaos
        "97420", # Le Port
        "97440", # Saint-André
        "97442", # Saint-Philippe
        "97450", # Saint-Louis
      ].each do |code|
        [code, "RE-#{code}", "RE#{code}"].each do |value|
          assert_equal true, re.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "9741", # too short
        "974123", # too long
        "75010", # 10e arrondissement, Paris, France
        "97150", # Saint Martin
        "98800", # Nouméa, Nouvelle-Caledonie
      ].each do |code|
        [code, "RE-#{code}", "RE#{code}"].each do |value|
          assert_equal false, re.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Romania" do
      ro = Worldwide.region(code: "RO")

      assert_equal false, ro.zip_required?

      # valid codes
      [
        "030167", # Romanian Athenaeum, 1, Strada Benjamin Franklin 1-3, Bucharest
        "300028", # Direcția de Evidență a Persoanelor Timișoara
        "440280", # Strada Mihai Viteazul 2, Satu Mare
        "717315", # DN29A, Rădăuţi-Prut
        "907163", # Sandalandala, Strada Delfinului nr. 9, Vama Veche
      ].each do |zip|
        [zip, "RO-#{zip}", "RO#{zip}"].each do |value|
          assert_equal true, ro.valid_zip?(value)
        end
      end

      # codes that are invalid country-wide
      [
        "12345", # too short
        "1234567", # too long
        "RS123456", # wrong prefix
        "RS1234", # must be numeric
        "ABCDEF", # must be numeric
      ].each do |zip|
        [zip, "RO-#{zip}", "RO#{zip}"].each do |value|
          assert_equal false, ro.valid_zip?(value)
        end
      end
    end

    test "#valid_zip? in Saint Lucia" do
      lc = Worldwide.region(code: "LC")

      assert_equal false, lc.zip_required?

      # Examples taken from https://stluciapostal.com/postal-codes-2/
      [
        "LC01  101", # Gros Islet Post Office, Gros Islet
        "LC02  201", # Balata Post Office, Castries
        "LC03  101", # Agard Post Office, Castries
        "LC05  201", # Marchand Post Office, Castries
        "LC10  101", # Choiseul Post Office, Choiseul
        "LC17  201", # Aux Lyons Post Office, Dennery
        "LC18  101", # Canaries Post Office, Canaries
      ].each do |code|
        assert_equal true, lc.valid_zip?(code), "#{code} should be valid"
      end

      [
        "01  101", # must start with LC
        "LCAB  101", # must be numeric after the LC
        "90210", # must start with LC
      ].each do |code|
        assert_equal false, lc.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in San Marino" do
      sm = Worldwide.region(code: "SM")

      assert_equal true, sm.zip_required?

      (47890..47899).each do |code|
        [code.to_s, "SM-#{code}", "SM#{code}", "RSM-#{code}", "RSM#{code}"].each do |value|
          assert_equal true, sm.valid_zip?(value), "#{value.inspect} should be valid"
        end
      end

      [
        # Selected invalid codes
        "",
        "47853", # Coriano, RN, Italy
        "47923", # Rimini, RN, Italy
        "47900", # seems to be a generic CAP for Rimini, Italy?
        "97150", # Out of range for SM; not recognized by poste.it either
        "28643", # Out of range for SM; not recognized by poste.it either
        "47924", # Rimin, RN, Italy
        "70043", # Monopoli, BA, Italy
        "88304", # Out of range for SM; not recognized by poste.it either
        "47981", # Out of range for SM; not recognized by poste.it either

        # Selected additional invalid codes
        "1234", # too short
        "123456", # too long
        "ABCDE", # only digits are allowed
      ].each do |code|
        [code, "SM-#{code}", "SM#{code}", "RSM-#{code}", "RSM#{code}"].each do |value|
          assert_equal false, sm.valid_zip?(value), "#{value.inspect} should not be valid"
        end
      end
    end

    test "#valid_zip? in Saint Martin" do
      assert_equal true, Worldwide.region(code: "MF").zip_required?
      [
        # Saint Martin has just one postal code for the whole region.
        "97150",

        # Selected additional valid codes
        "MF-97150",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "MF").valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        # Selected invalid codes
        "",
        "97133",
        "33126",
        "78108",
        "00000",
        "0000",
        "1721",
        "34344",
        "001721",
        "32164",
        "03589",

        # Selected additional invalid codes
        "097150", # too many digits
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "MF").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Saint Barthélemy" do
      assert_equal true, Worldwide.region(code: "BL").zip_required?
      [
        # Saint Barthélemy has just one postal code for the whole region.
        "97133",

        # Selected additional valid codes
        "BL-97133",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "BL").valid_zip?(value), "#{value} should be valid"
        end
      end
      [
        "02090",
        "97150",
        "97130",
        "971333",
        "48323",
        "342323469",
        "38000",
        "97133STBARTHELEMY",
        "KDKSKHZUNSCAN",
        "WKMI",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "BL").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Saint Kitts and Nevis" do
      kn = Worldwide.region(code: "KN")

      assert_equal false, kn.zip_required?

      # All allocated codes, based on https://nia.gov.kn/skn-introduces-official-postal-code/
      [
        # Saint Kitts
        "0101", # General post office, district 1
        "0102", # General post office, district 2
        "0103", # General post office, district 3
        "0104", # General post office, district 4
        "0105", # General post office, district 5
        "0106", # General post office, district 6
        "0107", # General post office, district 7
        "0108", # General post office, district 8
        "0109", # General post office, district 9
        "0110", # General post office, district 10
        "0111", # General post office, district 11
        "0201", # Old Road post office, district 1
        "0202", # Old Road post office, discrict 2
        "0301", # Sandy Point post office, district 1
        "0302", # Sandy Point post office, district 2
        "0401", # Dieppe Bay post office, district 1
        "0402", # Dieppe Bay post office, district 2
        "0403", # Dieppe Bay post office, district 3
        "0501", # Tabernacle post office, district 1
        "0601", # Cayon post office, district 1
        "0602", # Cayon post office, district 2

        "0700", # Areas that do not fall into the above, e.g. Bird Rock, Potato Bay, Frigate Bay (general delivery)

        # Nevis
        "0801", # St. Paul's Parish, district 1
        "0802", # St. Paul's Praish, district 2
        "0901", # St. Johns Parish, district 1
        "0902", # St. Johns Parish, district 2
        "1001", # St. Georges Parish, district 1
        "1002", # St. Georges Parish, district 2
        "1101", # St. James Parish, district 2
        "1102", # St. James Parish, district 2
        "1201", # St. Thomas Parish, district 1
        "1202", # St. Thomas Parish, district 2
      ].each do |code|
        [code, "KN#{code}"].each do |value|
          assert_equal true, kn.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "0191", # not allocated
        "101", # too short
        "01010", # too long
        "ABCD", # must be numeric
        "01B1", # must be numeric
      ].each do |code|
        [code, "KN#{code}"].each do |value|
          assert_equal false, kn.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Saint Pierre And Miquelon" do
      assert_equal true, Worldwide.region(code: "PM").zip_required?
      [
        "97500",

        # Selected additional valid codes
        "97513",
        "PM-97550",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "PM").valid_zip?(value), "#{value} should be valid"
        end
      end
      [
        "FF",
        "07631",
        "22540",
        "NE455JR",
        "35000",
        "KJ",
        "",
        "B2T1K2",
        "6072",
        "7626",

        # Selected additional invalid codes
        "9755", # Too few digits
        "975500", # Too many digits
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "PM").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Saint Vincent and the Grenadines" do
      vc = Worldwide.region(code: "VC")

      assert_equal false, vc.zip_required?

      # postal code values from https://www.getpostalcodes.com/saint-vincent-and-the-grenadines/
      [
        "VC0100", # Kingstown, Saint George
        "VC0170", # Edinboro, Saint Andrew
        "VC0214", # Byera Hill
        "VC0260", # Biabou
        "VC0316", # Coulls Hill, Saint Patrick
        "VC0378", # Clare Valley
        "VC0472", # Ashton
      ].each do |code|
        assert_equal true, vc.valid_zip?(code), "#{code} should be valid"
      end

      [
        "VC0501", # unallocated
        "VC1010", # unallocated
        "VC9999", # unallocated
        "VC010", # too short
        "VC01010", # too long
        "VC01AB", # last four chars must be numeric
        "VCAB01", # last four chars must be numeric
        "0100", # must start with VC
      ].each do |code|
        assert_equal false, vc.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in (Western) Samoa" do
      ws = Worldwide.region(code: "WS")

      assert_equal false, ws.zip_required?

      # Postal codes selected from https://www.samoapost.ws/index.php/special-services/post-code-for-samoa
      # which lists every allocated code in WS.
      # Codes on Upolu, and the minor islands Apolima and Manono, start with 1.
      # Codes on Savai start with 2.
      [
        "WS1270", # Fasitoo Uta
        "WS1190", # Manono Tai
        "WS1424", # Siufaga, Upolu
        "WS2173", # Asau, Savaii
        "WS2581", # Puleia, Savaii
      ].each do |code|
        assert_equal true, ws.valid_zip?(code), "#{code} should be valid"
      end

      [
        "WS123", # too short
        "WS12345", # too long
        "1270", # must start with WS
        "123456", # must start with WS
        "WS3124", # must be between WS1000 and WS2999
        "WS4567", # must be between WS1000 and WS2999
      ].each do |code|
        assert_equal false, ws.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in Serbia" do
      rs = Worldwide.region(code: "RS")

      assert_equal true, rs.zip_required?

      [
        # Old-style 5-digit codes
        "11070", # Štark Arena, Belgrade
        "18320", # Caribrodskih umetnika 1, Dimitrovgrad
        "24411", # Granični prelaz, Horgoš
        "25270", # Košut Lajoša bb, Bezdan
        "36350", # Казновиће 33, Kaznoviće

        # New-style 6-digit codes (PAK)
        "190558", # Štark Arena, Belgrade
        "281531", # According to GRCDI, this code is in (old-style) 11000 Belgrade
        "426014", # Košut Lajoša bb, Bezdan
        "445210", # Granični prelaz, Horgoš
        "569619", # Казновиће 33, Kaznoviće
        "625113", # Caribrodskih umetnika 1, Dimitrovgrad
      ].each do |code|
        [code, "RS-#{code}", "RS#{code}", "SRB-#{code}", "SRB#{code}"].each do |value|
          assert_equal true, rs.valid_zip?(value)
        end
      end

      [
        "1234", # too short
        "1234567", # too long
        "41234", # 5-digit codes must start with 1, 2 or 3
        "AB123", # must be numeric
        "123ABC", # must be numeric
      ].each do |code|
        [code, "RS-#{code}", "RS#{code}", "SRB-#{code}", "SRB#{code}"].each do |value|
          assert_equal false, rs.valid_zip?(value)
        end
      end
    end

    test "#valid_zip? in Singapore" do
      sg = Worldwide.region(code: "SG")

      assert_equal true, sg.zip_required?

      [
        "058840", # Buddha Tooth Relic Temple, 288 South Bridge Rd
        "068896", # 77 Robinson Rd #13-00
        "178897", # National Museum, 93 Stamford Rd
        "637607", # Tuas Power Generation, 60 Tuas South Ave 9
        "819664", # Changi Airport Control Tower, 75 Airport Blvd
      ].each do |code|
        assert_equal true, sg.valid_zip?(code), "#{code} should be valid"
      end

      [
        "12345", # too short
        "1234567", # too long
        "SG1234", # must be numeric
        "1234SG", # must be numeric
      ].each do |code|
        assert_equal false, sg.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Slovakia" do
      assert_equal true, Worldwide.region(code: "SK").zip_required?

      # Slovak codes should be accepted
      [
        "040 01", # St. Elizabeth's Cathedral, Staré Mesto
        "960 01", # Forestry and Timber Museum, Zvolen
        "811 01", # St. Martin's Cathedral, Bratislava
      ].each do |code|
        [code, "SK-#{code}", "SK#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "SK").valid_zip?(value), "#{value} should be valid for SK"
        end
      end

      # Czech codes should be rejected
      [
        "110 00", # Národní muzeum, Nové Město, Prague
        "280 02", # Brandlova, Kolín
        "370 01", # České Budějovice
        "460 59", # Lberec Town Hall
        "565 01", # Choceň
        "687 74", # Muzeum poslední žítkovské bohyně, Starý Hrozenkov
        "739 98", # Mosty u Jablunkova
      ].each do |code|
        [code, "SK-#{code}", "SK#{code}"].each do |value|
          assert_equal false, Worldwide.region(code: "SK").valid_zip?(value), "#{value} is in CZ, not in SK"
        end
      end

      assert_equal false, Worldwide.region(code: "SK").valid_zip?("123 4") # too short
      assert_equal false, Worldwide.region(code: "SK").valid_zip?("123 456") # too long
      assert_equal false, Worldwide.region(code: "SK").valid_zip?("ABC 12") # must be numeric
    end

    test "#valid_zip? in Slovenia" do
      si = Worldwide.region(code: "SI")

      assert_equal true, si.zip_required?

      [
        "1000", # Ljubljana
        "2370", # Dravograd
        "4280", # Kranjska Gora
        "6000", # Koper
        "6333", # Parecag
        "8250", # Topliška c. 35, Čatež ob Savi
        "8342", # Srednji Radenci 2, Stari trg ob Kolpi
        "9000", # Murska Sobota
      ].each do |code|
        [code, "SI-#{code}", "SI#{code}", "SLO-#{code}", "SLO#{code}"].each do |value|
          assert_equal true, si.valid_zip?(value), "#{value} should be valid"
        end
      end

      [
        "0123", # cannot start with zero
        "AB12", # must be numeric
        "61AB", # must be numeric
        "7123", # cannot start with seven
        "123", # too short
        "12345", # too long
      ].each do |code|
        [code, "SI-#{code}", "SI#{code}", "SLO-#{code}", "SLO#{code}"].each do |value|
          assert_equal false, si.valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in South Africa" do
      za = Worldwide.region(code: "ZA")

      assert_equal true, za.zip_required?

      [
        # Selected valid codes
        "7441",
        "0157",
        "2191",
        "2196",
        "0081",
        "4001",
        "3610",
        "8001",
        "1459",
        "3201",

        # Selected additional valid codes
        "0028", # Pretoria
        "4001", # Durban
        "7915", # Cape Town
      ].each do |code|
        assert_equal true, za.valid_zip?(code), "#{code.inspect} should be valid"
      end

      [
        # Selected invalid codes
        "",
        "GAUTENG",
        "012",
        "SPRINGS",
        "1",
        "9000",
        "N/A",
        "J0HANNESBURG",
        "CAPET0WN",
        "WESTERNCAPE",

        # Selected additional invalid codes
        "123", # too short
        "12345", # too long
        "9200", # former South West Africa code, discontinued after NA separated
      ].each do |code|
        assert_equal false, za.valid_zip?(code), "#{code.inspect} should not be valid"
      end
    end

    test "#valid_zip? in South Sudan" do
      ss = Worldwide.region(code: "SS")

      assert_equal false, ss.zip_required?

      [
        "81000", # Terekeka
        "81111", # Juba
        "82000", # Charet
      ].each do |code|
        assert_equal true, ss.valid_zip?(code), "#{code} should be valid"
      end

      [
        "1234", # too short
        "123456", # too long
        "123AB", # must be numeric
      ].each do |code|
        assert_equal false, ss.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Spain" do
      assert_equal true, Worldwide.region(code: "ES").zip_required?

      assert_equal true, Worldwide.region(code: "ES").valid_zip?("11203") # Algeciras
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("ES-11203") # Algeciras
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("ES11203") # Algeciras
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("E-11203") # Algeciras
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("E11203") # Algeciras
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("17600") # Figueres
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("28001") # Madrid
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("36203") # Vigo

      # Postal codes in Madrid
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("28050")
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("28850")
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("28014")
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("28015")
      assert_equal true, Worldwide.region(code: "ES").valid_zip?("28045")

      assert_equal false, Worldwide.region(code: "ES").valid_zip?("99999") # unallocated
      assert_equal false, Worldwide.region(code: "ES").valid_zip?("1234") # too short
      assert_equal false, Worldwide.region(code: "ES").valid_zip?("123456") # too long
    end

    test "#valid_zip? in Sri Lanka" do
      lk = Worldwide.region(code: "LK")

      assert_equal false, lk.zip_required?

      # Codes from https://worldpostalcode.com/sri-lanka/
      [
        "00300", # Colpetty, Colombo
        "12204", # Veyangalla, Western Province
        "22094", # Agarapathana, Central Province
        "32508", # Panama, Eastern Province
        "40000", # Jaffna, Northern Province
        "51092", # Dalukana, North Central Province
        "60600", # Maho, North Western Province
        "71315", # Lewangama, Sabaragamuwa
        "80142", # Opatha, Southern Province
        "91022", # Wilaoya, Uva
      ].each do |code|
        assert_equal true, lk.valid_zip?(code), "#{code} should be valid"
      end

      [
        "1234", # too short
        "123456", # too long
        "AB123", # must be numeric
        "123AB", # must be numeric
      ].each do |code|
        assert_equal false, lk.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Sudan" do
      sd = Worldwide.region(code: "SD")

      assert_equal false, sd.zip_required?

      [
        # The SudaPost website doesn't seem to provide a way to validate/list postcodes.
        # ParcelForce, however, has a list here:
        # https://www.parcelforce.com/sites/default/files/SD%20Postcodes%20Oct19%20v1%20041019.pdf
        # The following entries are selected from that list.
        "11111", # Khartoum
        "12217", # Khartoum
        "14419", # Khartoum
        "21111", # Wad Medani, Al-Jazirah
        "24414", # Sinja, Sennar
        "28812", # Rabak, White Nile
        "31118", # Kassala
        "33321", # Port Sudan, Red Sea
        "45516", # Ad-Damir, River Nile
        "52221", # El-Obeid, North Kordofan
        "61111", # Al-Fashir, North Darfur
        "63314", # Geneina, West Darfur
      ].each do |code|
        assert_equal true, sd.valid_zip?(code), "#{code} should be accepted"
      end

      [
        # The following codes are in South Sudan, which is now a separate country
        "81000", # Terekeka
        "81111", # Juba
        "82000", # Charet
      ].each do |code|
        assert_equal false, sd.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in Svalbard and Jan Mayen" do
      assert_equal true, Worldwide.region(code: "SJ").zip_required?

      # AFACT, these are all the allocated postal codes for SJ
      [
        "8099", # Olonkin City, Jan Mayen
        "9170", # Longyearbyen, Svalbard
        "9173", # Ny-Ålesund, Svalbard
        "9174", # Hopen, Svalbard
        "9175", # Sveagruva, Svalbard
        "9176", # Bjørnøya (Bear Island), Svalbard
        "9178", # Barentsburg, Svalbard
      ].each do |code|
        [code, "SJ-#{code}", "SJ#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "SJ").valid_zip?(value), "#{value} should be valid"
        end
      end

      # Postal codes in (the rest of) Norway should not be accepted for SJ
      [
        "0001", # Oslo
        "1607", # Fredrikstad
        "2677", # Heidal
        "3226", # Sandefjord
        "4737", # Hornnes
        "5527", # Haugesund
        "6770", # Nordfjordeid
        "7870", # Grong
        "8063", # Værøy
        "8590", # Kjøpsvik
        "8009", # Bodø
        "8098", # Bodø
        "9103", # Kvaløya
        "9143", # Skibotn
        "9525", # Masi
        "9740", # Lebesby
        "9900", # Kirkenes
        "9991", # Båtsfjord
      ].each do |code|
        [code, "NO-#{code}", "NO#{code}", "N-#{code}", "N#{code}", "SJ-#{code}", "SJ#{code}"].each do |value|
          assert_equal false, Worldwide.region(code: "SJ").valid_zip?(value), "#{value} is in NO, not in SJ"
        end
      end

      assert_equal false, Worldwide.region(code: "SJ").valid_zip?("123") # too short
      assert_equal false, Worldwide.region(code: "SJ").valid_zip?("12345") # too long
      assert_equal false, Worldwide.region(code: "SJ").valid_zip?("ABCD") # must be numeric
    end

    test "#valid_zip? in Switzerland" do
      [
        "1007", # IOC, Lausanne
        "1211", # Palais des Nations, Genève
        "2502", # Biel/Bienne
        "3011", # Einsteinhaus, Bern
        "8001", # Swiss National Museum, Zürich
        "9000", # St. Gallen
        "9400", # Rorschach
        "9470", # Buchs
        "9476", # Wartau
        "9602", # Bazenheid
      ].each do |code|
        [code, "CH-#{code}", "CH#{code}"].each do |value|
          assert_equal true, Worldwide.region(code: "CH").valid_zip?(value), "#{value.inspect} should be valid"
        end
      end

      # Codes in Liechtenstein
      [
        "9485", # Nendeln
        "9486", # Schaanwald
        "9487", # Gamprin-Bendern
        "9488", # Schellenberg
        "9490", # Vaduz
        "9491", # Ruggell
        "9492", # Eschen
        "9493", # Mauren
        "9494", # Schaan
        "9495", # Triesen
        "9496", # Balzers
        "9497", # Triesenberg
        "9498", # Planken
      ].each do |code|
        [code, "CH-#{code}", "CH#{code}", "LI-#{code}", "LI#{code}"].each do |value|
          assert_equal false, Worldwide.region(code: "CH").valid_zip?(value), "#{value} is in Liechtenstein"
        end
      end

      # We will accept Büsingen am Hochrein as a postal code for Switzerland, despite the fact that it's actually
      # part of Germany.  This is because, as an enclave within Switzerland, it uses the Swiss postal service,
      # and is part of the Swiss customs area.
      assert_equal true, Worldwide.region(code: "CH").valid_zip?("8238")
      assert_equal true, Worldwide.region(code: "CH").valid_zip?("CH-8238")
    end

    test "#valid_zip? in New Zealand" do
      # Test normal formatting passes
      assert Worldwide.region(code: "NZ").valid_zip?("4200")
      assert Worldwide.region(code: "NZ").valid_zip?("1142")

      # Test overlapping codes work

      # Test edge cases: too long, too short, not numeric
      assert_equal false, Worldwide.region(code: "NZ").valid_zip?("500")
      assert_equal false, Worldwide.region(code: "NZ").valid_zip?("700000")
      assert_equal false, Worldwide.region(code: "NZ").valid_zip?("7d4a")

      # Valid zone code

      # Valid code, wrong zone

      # Valid code, invalid zone

      # Meets the regex, but does not map to any zone
      assert_equal false, Worldwide.region(code: "NZ").valid_zip?("9901")
    end

    test "#valid_zip? in Turkmenistan" do
      assert_equal false, Worldwide.region(code: "TM").zip_required?
      [
        "744000",
        "745100",
        "745000",
        "789998",
        "705111",
        "744015",
        "746300",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "TM").valid_zip?(value), "#{value} should be valid"
        end
      end
      [
        "ISJUORPGTHIUT90O",
        "4432",
        "48386",
        "93908",
        "M4E2P3",
        "34325",
        "83130",
        "06580",
        "115563",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "TM").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? in Thailand" do
      th = Worldwide.region(code: "TH")

      assert_equal true, th.zip_required?

      # valid codes
      [
        ["10100", "TH-10"], # Bangkok
        ["10110", "TH-10"], # Bangkok
        ["10120", "TH-10"], # Bangkok
        ["10210-0299", "TH-10"], # According to Wikipedia, this is Thailand Post's head office
        ["102100299", "TH-10"], # Also permit the hyphen to be omitted
        ["10280", "TH-11"], # Ancient City, Sukhumvit Rd, Bang Pu Mai, Maueang Samut Prakan
        ["20150", "TH-S"], # Pattaya special governed district
        ["20160", "TH-20"], # Chon Buri
        ["32110", "TH-32"], # Ranang Subdistrict, Sikhoraphum District, Surin
        ["38000", "TH-38"], # Bueng Kan
        ["40000", "TH-40"], # Khon Kaen
        ["57000", "TH-57"], # Chiang Rai
        ["74000", "TH-74"], # Samut Sakhon
        ["83110", "TH-83"], # Phuket
      ].each do |code, _zone_code|
        assert_equal true, th.valid_zip?(code), "#{code} should be valid"
      end

      # invalid codes
      [
        "00000", # unallocated
        "1234", # too short
        "123456", # too long
        "ABCDE", # must be numeric
      ].each do |code|
        assert_equal false, th.valid_zip?(code), "#{code} should be invalid"
      end
    end

    test "#valid_zip? in Trinidad and Tobago" do
      tt = Worldwide.region(code: "TT")

      assert_equal false, tt.zip_required?

      # valid codes
      [
        "120110", # example given in http://archives.newsday.co.tt/2012/03/29/postal-code-coming-soon/
        "350462", # TT Postal Corporation, Piarco
      ].each do |code|
        assert_equal true, tt.valid_zip?(code), "#{code} should be valid"
      end

      # invalid codes
      [
        "12345", # too short
        "1234567", # too long
        "123ABC", # must be numeric
        "ABC123", # must be numeric
      ].each do |code|
        assert_equal false, tt.valid_zip?(code), "#{code} should not be valid"
      end
    end

    test "#valid_zip? in Tunisia" do
      tn = Worldwide.region(code: "TN")

      assert_equal false, tn.zip_required?

      [
        "1194", # Dhraa Ben Jouder
        "1200", # Kasserine
        "2083", # Avenue Fethi Zouhir, Cebalat Ben Ammar
        "2263", # Degach
        "4192", # Ben Guerdane
        "5000", # Khniss
        "7042", # Menzel Bourgiba
        "8030", # Grombalia
        "8136", # Ain Draham
        "9084", # Amdoun
      ].each do |code|
        assert_equal true, tn.valid_zip?(code), "#{code} should be accepted"
      end

      [
        "0000", # Unallocated
        "0123", # Unallocated
        "1345", # Unallocated
        "1999", # Unallocated
        "2345", # Unallocated
        "4312", # Unallocated
        "5712", # Unallocated
        "7322", # Unallocated
        "9234", # Unallocated
        "9999", # Unallocated
        "AB12", # Must be numeric
        "12AB", # Must be numeric
        "123", # too short
        "12345", # too long
      ].each do |code|
        assert_equal false, tn.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in the United States" do
      us = Worldwide.region(code: "US")

      assert_equal true, us.zip_required?

      [
        ["00912", :PR], # San Juan
        ["09005", :AE],
        ["10001", :NY], # Empire State Building
        ["20050", :DC], # White House
        ["20050-0005", :DC], # White House
        ["90210", :CA], # Beverly Hills
        ["96799", :AS], # All of American Samoa
        ["96913", :GU], # GUM airport
        ["96929", :GU], # 159 Redondo Luchan, Dededo
        ["96931", :GU], # Tamuning (P.O. boxes)
        ["96932", :GU], # Hagatna (P.O. boxes)
        ["96939", :PW], # Ngerulmud
        ["96940", :PW], # All parts of Palau outside of Ngerulmud
      ].each do |zip, _zone_code|
        assert_equal true, us.valid_zip?(zip), "#{zip} should be valid"
      end

      [
        "K1A 1A1", # Ottawa, ON Canada
        "SO14 3QT", # 5 Maritime Walk, Southampton UK
        "1234", # too short
        "123456", # invalid length
        "1234567", # invalid length
        "12345678", # invalid length
        "12345567890", # too long
      ].each do |zip|
        assert_equal false, us.valid_zip?(zip)
      end

      [
        "42223", # Fort Campbell, on the KY/TN border
        "45275", # CVG airport, Cincinnati "Ohio" PO Box, but located in KY
      ].each do |zip|
        assert_equal true, us.valid_zip?(zip), "#{zip} should be valid"
      end
    end

    test "#valid_zip? in Uzbekistan" do
      uz = Worldwide.region(code: "UZ")

      assert_equal false, uz.zip_required?

      [
        # Examples from https://postal-codes.cybo.com/uzbekistan/
        "100000", # Tashkent
        "110604", # Navoiy Region
        "111215", # Saolor, Tashkent Region
        "121005", # Yangiyer, Sirdaryo Region
        "130100", # Jizzakh
        "140150", # Samarkand
        "151103", # Margilan, Fergana Region
        "160130", # Namangan
        "170134", # Andijan
        "180100", # Qarshi
        "190115", # Termez
        "200125", # Bukhara
        "220900", # Khiva, Xarazm Region
      ].each do |code|
        assert_equal true, uz.valid_zip?(code), "#{code} should be accepted"
      end

      [
        "000000", # not allocated
        "109000", # not allocated
        "199999", # not allocated
        "999999", # not allocated

        "10045", # too short
        "1004567", # too long
        "AB1234", # must be numeric
        "100ABC", # must be numeric
      ].each do |code|
        assert_equal false, uz.valid_zip?(code), "#{code} should be rejected"
      end
    end

    test "#valid_zip? in Wallis And Futuna" do
      assert_equal true, Worldwide.region(code: "WF").zip_required?
      [
        "98600",
        "98620",
        "98672",
        "98661",
        "98606",
        "98664",
        "98684",
        "98671",
        "98632",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal true, Worldwide.region(code: "WF").valid_zip?(value), "#{value} should be valid"
        end
      end
      [
        "74132",
        "",
        "98109",
        "98272",
        "83014",
        "53092",
        "98102",
        "98026",
        "98020",
        "98862",
        "98004",
      ].each do |code|
        [code, code.delete("-")].each do |value|
          assert_equal false, Worldwide.region(code: "WF").valid_zip?(value), "#{value} should not be valid"
        end
      end
    end

    test "#valid_zip? is case-insensitive" do
      assert Worldwide.region(code: "CA").valid_zip?("k1s 1A1")
      assert Worldwide.region(code: "CA").valid_zip?("k1s1A1")
      assert Worldwide.region(code: "CA").valid_zip?("K1s 1a1")
      assert Worldwide.region(code: "CA").valid_zip?("K1s1a1")
      assert_equal false, Worldwide.region(code: "CA").valid_zip?("d0g e3e")
      assert_equal false, Worldwide.region(code: "CA").valid_zip?("d0ge3e")
      assert_equal false, Worldwide.region(code: "CA").valid_zip?("D0ge3e")

      assert Worldwide.region(code: "GB").valid_zip?("sw1 1aa")
      assert Worldwide.region(code: "GB").valid_zip?("sw1 1AA")
      assert Worldwide.region(code: "GB").valid_zip?("Sw1 1AA")
      assert Worldwide.region(code: "GB").valid_zip?("sW1 1AA")
      assert_equal false, Worldwide.region(code: "GB").valid_zip?("qK1 1ZZ")
      assert_equal false, Worldwide.region(code: "GB").valid_zip?("tdcu 1zz")
      assert_equal false, Worldwide.region(code: "GB").valid_zip?("AsCn 1Zz")
    end
  end
end
