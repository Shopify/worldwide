# frozen_string_literal: true

require "test_helper"

module Worldwide
  # Behaviours that a Region has when it is a zone (province, state, ...) of a country.
  class RegionZoneTest < ActiveSupport::TestCase
    def region(code)
      Worldwide.region(code: code)
    end

    def allocated_objects
      yield
      GC.start
      GC.disable
      before = GC.stat(:total_allocated_objects)
      yield
      GC.stat(:total_allocated_objects) - before
    ensure
      GC.enable
    end

    # #has_code?

    test "#has_code? accepts any of the legacy code, a code alternate, or the ISO 3166-2 code" do
      [
        ["CA", "nl", "CA-NL"],
        ["CA", "CA-NL", "CA-NL"],
        ["CA", "qc", "CA-QC"],
        ["CA", "pq", "CA-QC"],
        ["CA", "CA-QC", "CA-QC"],
        ["CA", "ca-qc", "CA-QC"],
        ["ZA", "kzn", "ZA-KZN"],
        ["ZA", "nl", "ZA-KZN"],
        ["ZA", "ZA-KZN", "ZA-KZN"],
        ["ZA", "ZA-NL", "ZA-KZN"],
        ["CR", "CR-C", "CR-C"],
        ["IT", "su", "IT-CI"],
        ["IT", "ci", "IT-CI"],
        ["IT", "IT-SU", "IT-CI"],
      ].each do |country_code, input, expected_iso_code|
        zone = region(country_code).zones.find { |candidate| candidate.has_code?(input) }

        assert_equal expected_iso_code, zone&.iso_code, "Lookup iso code did not match expected"
        assert zone.has_code?(input), "Zone #{zone.iso_code} should has_code?(#{input.inspect})"
        assert zone.has_code?(expected_iso_code), "Zone #{zone.iso_code} should has_code?(#{expected_iso_code.inspect})"
      end
    end

    test "#has_code? finds Sulcis Iglesiente by SU or CI, with or without the country code" do
      italy = region("IT")

      ["SU", "CI", "IT-SU", "IT-CI"].each do |code|
        assert_equal "SU", italy.zones.find { |zone| zone.has_code?(code) }&.legacy_code, "has_code?(#{code.inspect})"
      end
      assert_includes italy.zones.map(&:legacy_code), "SU"
      refute_includes italy.zones.map(&:legacy_code), "CI"
    end

    test "#has_code? accepts a code that is the part of the legacy code after the hyphen" do
      tokyo = region("JP-13")

      assert_equal "JP-13", tokyo.iso_code
      assert tokyo.has_code?("13")
      assert tokyo.has_code?("JP-13")
      assert tokyo.has_code?("jp-13")
      refute tokyo.has_code?("14")
      refute region("JP-14").has_code?("13")
    end

    test "#has_code? accepts a symbol" do
      assert region("CA-QC").has_code?(:qc)
      assert region("CA-QC").has_code?(:pq)
      refute region("CA-QC").has_code?(:on)
    end

    test "#has_code? returns false for a blank code" do
      [nil, "", " ", "\t"].each do |code|
        refute region("CA-QC").has_code?(code), "has_code?(#{code.inspect})"
      end
    end

    test "#has_code? handles the case where a code without a country is passed in" do
      refute region("CA-QC").has_code?("-ON")
      refute region("CA-QC").has_code?("-QC")
      refute region("CA-QC").has_code?("CA-")
      refute region("CA-QC").has_code?("-")
    end

    test "#has_code? does not accept the code of a different zone or country" do
      refute region("CA-QC").has_code?("ON")
      refute region("CA-QC").has_code?("CA-ON")
      refute region("CA-QC").has_code?("US-QC")
      refute region("CA-QC").has_code?("QCX")
      refute region("CA-QC").has_code?("XQC")
    end

    test "#has_code? does not accept ISO codes for a different country" do
      [
        ["AR", "CR-A"],
        ["CR", "AR-A"],
      ].each do |country_code, zone_code|
        assert_nil(
          region(country_code).zones.find { |zone| zone.has_code?(zone_code) },
          "Country #{country_code} code #{zone_code}",
        )
      end
    end

    test "#has_code? matches the legacy code, code alternates and ISO code of a country, but never a prefixed code" do
      canada = region("CA")

      assert canada.has_code?("CA")
      assert canada.has_code?("ca")
      refute canada.has_code?("CA-ON")
    end

    test "#has_code? does not allocate" do
      allocated_objects { nil }

      [
        ["CA-QC", "qc"],
        ["CA-QC", "PQ"],
        ["CA-QC", "CA-QC"],
        ["CA-QC", "ca-pq"],
        ["CA-QC", "CA-ON"],
        ["CA-QC", "unknown"],
        ["JP-13", "13"],
        ["JP-13", "14"],
        ["CA", "CA-ON"],
      ].each do |iso_code, input|
        zone = region(iso_code)
        zone.has_code?(input)

        assert_equal 0, allocated_objects { 10.times { zone.has_code?(input) } }, "#{iso_code} has_code?(#{input.inspect})"
      end
    end

    # #has_name? and #has_handle?

    test "#has_name? returns true if the zone has the given name" do
      assert region("EG-FYM").has_name?("Faiyum")
      assert region("EG-FYM").has_name?("FAIYUM")
      assert region("EG-FYM").has_name?("Al Fayyūm")
    end

    test "#has_name? ignores diacritics, case and punctuation" do
      assert region("EG-FYM").has_name?("Al Fayyum")
      assert region("EG-FYM").has_name?("al-fayyum")
      assert region("EG-FYM").has_name?(" (Al) Fayyūm ")
      assert region("CA-QC").has_name?("Québec")
      assert region("CA-QC").has_name?("Quebec")
    end

    test "#has_name? returns false when the zone does not have the given name" do
      refute region("EG-FYM").has_name?("Fayyūm")
      refute region("EG-FYM").has_name?("Quebec")
      refute region("EG-FYM").has_name?(nil)
      refute region("EG-FYM").has_name?("")
    end

    test "#has_name? does not change the string that it is given" do
      name = +"Al Fayyūm"
      region("EG-FYM").has_name?(name)

      assert_equal "Al Fayyūm", name
    end

    test "#has_handle? returns true if the zone has the given handle" do
      assert region("EG-FYM").has_handle?("faiyum")
      assert region("EG-FYM").has_handle?("al-fayyum")
    end

    test "#has_handle? returns false when the zone does not have the given handle" do
      refute region("EG-FYM").has_handle?("fayyum")
      refute region("EG-FYM").has_handle?(nil)
      refute Region.new(iso_code: "ZZ").has_handle?(nil)
    end

    test "#name_alternates= replaces the handles that #has_handle? compares" do
      zone = Region.new(iso_code: "XX-YY", legacy_name: "Yy")
      zone.name_alternates = ["Zeta"]

      assert zone.has_handle?("zeta")

      zone.name_alternates = ["Éta"]

      refute zone.has_handle?("zeta")
      assert zone.has_handle?("eta")
    end

    # #neighbor?

    test "#neighbor? returns true for matching neighbours" do
      assert_equal true, region("CA-ON").neighbor?("QC")
    end

    test "#neighbor? returns false for non-matching neighbours" do
      assert_equal false, region("CA-ON").neighbor?("BC")
    end

    test "#neighbor? returns false when a zone does not have neighbours" do
      assert_equal false, region("US-AK").neighbor?("BC")
      assert_equal false, Region.new(iso_code: "XX-YY").tap { |zone| zone.neighbours = nil }.neighbor?("BC")
    end

    # #valid_zone_zip?

    test "#valid_zone_zip? returns false for nil" do
      refute region("CA-ON").valid_zone_zip?(nil)
    end

    test "#valid_zone_zip? returns expected results" do
      ["X0E1A1", "X0G2A2", "X1A3A3"].each do |zip|
        assert region("CA-NT").valid_zone_zip?(zip)
      end
      refute region("CA-NT").valid_zone_zip?("K1A444")
    end

    test "#valid_zone_zip? returns expected results for AL, USA" do
      al = region("US-AL")

      assert_equal false, al.valid_zone_zip?("00000")
      assert_equal true, al.valid_zone_zip?("35004")
      assert_equal false, al.valid_zone_zip?("h3w2h5")
    end

    test "#valid_zone_zip? returns expected results for the weird forward sortation area K1A" do
      assert region("CA-ON").valid_zone_zip?("K1A9A6")
      assert region("CA-QC").valid_zone_zip?("K1A0H4")
    end

    test "#valid_zone_zip? is case-insensitive" do
      ["k1s 1a1", "K1s 1a1", "k1S 1A1", "k1s1a1", "k1S1a1"].each do |zip|
        assert region("CA-ON").valid_zone_zip?(zip)
      end

      ["d0g 3e3", "d0g3e3", "degfcb", "a1aa1a"].each do |zip|
        assert_equal false, region("CA-NL").valid_zone_zip?(zip)
      end
    end

    test "#valid_zone_zip? accepts certain popular English postcodes" do
      other_uk_zones = ["GB-BFP", "GB-NIR", "GB-SCT", "GB-WLS"]
      ["DE12 6DT", "FY1 4JH", "N3 2QS", "PR9 7HA", "S5 9GA"].each do |zip|
        assert_equal true, region("GB-ENG").valid_zone_zip?(zip)

        other_uk_zones.each do |zone_code|
          assert_equal false, region(zone_code).valid_zone_zip?(zip), "'#{zip}' should not be a valid postcode for #{zone_code}"
        end
      end
    end

    test "#valid_zone_zip? accepts certain Scottish postcodes" do
      other_uk_zones = ["GB-BFP", "GB-ENG", "GB-NIR", "GB-WLS"]
      ["AB35 5TB", "DD1 3JA", "EH16 5BQ", "G4 0QZ", "ZE1 0HB"].each do |zip|
        assert_equal true, region("GB-SCT").valid_zone_zip?(zip)

        other_uk_zones.each do |zone_code|
          assert_equal false, region(zone_code).valid_zone_zip?(zip), "'#{zip}' should not be a valid postcode for #{zone_code}"
        end
      end
    end

    test "#valid_zone_zip? is flexible about spaces and capitalization in GB" do
      ["Ab355tb", "dD1  3Ja", "eh16 5bq", "g40Qz", "ZE10HB"].each do |zip|
        assert_equal true, region("GB-SCT").valid_zone_zip?(zip)
      end
    end

    test "#valid_zone_zip? accepts the first part of a zip only when partial_match is true" do
      assert_equal false, region("CA-ON").valid_zone_zip?("K2A")
      assert_equal true, region("CA-ON").valid_zone_zip?("K2A", partial_match: true)
      assert_equal false, region("CA-ON").valid_zone_zip?("V6B", partial_match: true)
    end

    test "#valid_zone_zip? accepts a zip with an optional country prefix" do
      ["15001", "ES-15001", "E-15001", "es 15001"].each do |zip|
        assert_equal true, region("ES-C").valid_zone_zip?(zip), zip
        assert_equal false, region("ES-M").valid_zone_zip?(zip), zip
      end
    end

    test "#valid_zone_zip? treats a blank zip like valid_zip? in a country that does not require one" do
      zone = region("HK-HK")

      refute_predicate zone.associated_country, :zip_required?
      [nil, "", " "].each do |zip|
        assert_equal true, zone.valid_zone_zip?(zip), "valid_zone_zip?(#{zip.inspect})"
        assert_equal true, zone.valid_zip?(zip), "valid_zip?(#{zip.inspect})"
      end
    end

    test "#valid_zone_zip? returns false for a blank zip in a country that requires one" do
      [nil, "", " "].each do |zip|
        assert_equal false, region("CA-ON").valid_zone_zip?(zip)
      end
    end

    test "#valid_zone_zip? accepts a zip for a zone without prefixes when the country has a zone for the zip" do
      zone = region("CA-ON")
      zone.stubs(:zip_prefixes).returns([])

      assert_equal true, zone.valid_zone_zip?("V6B 4A2")
      assert_equal false, zone.valid_zip?("V6B 4A2")
      assert_equal false, zone.valid_zone_zip?("0000000")
    end

    test "#valid_zone_zip? accepts a zip whose zone shares a prefix with another zone" do
      # "K1A" is a prefix of both CA-ON and CA-QC, and valid_zip? infers only one of them
      assert_equal true, region("CA-ON").valid_zone_zip?("K1A ", partial_match: true)
      assert_equal true, region("CA-QC").valid_zone_zip?("K1A ", partial_match: true)
      assert_equal false, region("CA-QC").valid_zip?("K1A ", partial_match: true)
    end

    test "#valid_zone_zip? accepts a zip that is shorter than the prefix of the zone" do
      zone = region("TR-02")

      assert_includes zone.zip_prefixes, "02"
      assert_equal true, zone.valid_zone_zip?("0")
      assert_equal false, zone.valid_zip?("0")
    end

    test "#valid_zone_zip? gives the same result as valid_zip? for a region that is not a province" do
      ["V6B 4A2", "K1A", "nonsense", "", nil].each do |zip|
        assert_equal region("CA").valid_zip?(zip), region("CA").valid_zone_zip?(zip), "CA #{zip.inspect}"
      end
    end

    test "#valid_zone_zip? does not change valid_zip?" do
      assert_equal true, region("CA-ON").valid_zip?("K1A9A6")
      assert_equal true, region("CA-QC").valid_zip?("K1A0H4")
      assert_equal true, region("CA-NT").valid_zip?("X0E1A1")
      assert_equal false, region("CA-NT").valid_zip?("K1A444")
    end

    # Zone attributes and lookups

    test "zones have the expected attribute values" do
      assert_equal ["PQ"], region("CA-QC").code_alternates
      assert_equal "Ontario", region("CA-ON").legacy_name
      assert_equal ["Al Fayyūm"], region("EG-FYM").name_alternates
      assert_equal ["QC", "MB"], region("CA-ON").neighbours
      assert_equal ["T"], region("CA-AB").zip_prefixes
      assert_empty region("AE-AZ").zip_prefixes
      assert_equal 47, region("JP-01").priority
      assert_in_delta(0.13, region("CA-ON").tax_rate)
      assert_equal "HST", region("CA-ON").tax_name
      assert_equal "harmonized", region("CA-ON").tax_type
      assert_equal "Huntsville", region("US-AL").example_city
      assert_equal "35801", region("US-AL").example_city_zip
      assert_nil region("NZ").zones.first.example_city
      assert_nil region("NZ").zones.first.example_city_zip
      assert_equal "England", region("GB-ENG").full_name(locale: :en)
      assert_equal "Angleterre", region("GB-ENG").full_name(locale: :fr)
    end

    test "#zone finds a province by zip" do
      assert_equal "Quebec", region("CA").zone(zip: "K1A 1C9").legacy_name
      assert_equal "Ontario", region("CA").zone(zip: "K1A0H2").legacy_name
      assert_same Worldwide.unknown_region, region("CA").zone(zip: "123 456")
    end

    test "#zone finds a province in GB even with extra spaces in the zip" do
      assert_equal "England", region("GB").zone(zip: "SW1  1AA").legacy_name
      assert_equal "England", region("GB").zone(zip: "Sw1  1aa").legacy_name
    end

    test "#zone does not find a province by an invalid zip" do
      assert_same Worldwide.unknown_region, region("CA").zone(zip: "BOGUS")
      assert_same Worldwide.unknown_region, region("CA").zone(zip: "A1A A1A")
    end

    test "#zone finds a province by a partial zip if the country hides provinces" do
      assert_equal "England", region("GB").zone(zip: "SW1").legacy_name
      assert_equal "England", region("GB").zone(zip: "CH4").legacy_name
      assert_equal "Wales", region("GB").zone(zip: "CH6").legacy_name
      assert_equal "Scotland", region("GB").zone(zip: "AB1").legacy_name
      assert_equal "Scotland", region("GB").zone(zip: "TD1").legacy_name
      assert_equal "England", region("GB").zone(zip: "TD12").legacy_name
      assert_equal "Northern Ireland", region("GB").zone(zip: "BT1").legacy_name
    end

    test "#zone does not find a province by a partial zip if the country does not hide provinces" do
      assert_same Worldwide.unknown_region, region("CA").zone(zip: "K1S")
      assert_same Worldwide.unknown_region, region("JE").zone(zip: "JE1")
      assert_same Worldwide.unknown_region, region("SH").zone(zip: "STHL")
      assert_same Worldwide.unknown_region, region("US").zone(zip: "90")
    end

    test "#zone finds the same province by an alternate code as by the code" do
      assert_same region("CA").zone(code: "QC"), region("CA").zone(code: "PQ")
      assert_same region("CA").zone(code: "NL"), region("CA").zone(code: "NF")
    end

    test "#iso_code of a zone is the ISO code, including where the legacy code differs" do
      assert_equal "COR", region("CO").zone(code: "COR").legacy_code
      assert_equal "CO-COR", region("CO").zone(code: "COR").iso_code
      assert_equal "CA-ON", region("CA").zone(code: "ON").iso_code
      assert_equal "JP-13", region("JP").zone(code: "JP-13").iso_code
      assert_equal "JP-13", region("JP").zone(code: "13").iso_code
    end
  end
end
