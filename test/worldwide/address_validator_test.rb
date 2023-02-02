# frozen_string_literal: true

require "test_helper"

module Worldwide
  class AddressValidatorTest < ActiveSupport::TestCase
    test "valid addresses are considered valid" do
      [
        Worldwide.address(
          first_name: "Liz",
          last_name: "Jolly",
          company: "British Library",
          address1: "96 Euston Rd",
          address2: nil,
          city: "LONDON",
          zip: "NW1 2DB",
          country_code: "GB",
        ),
        Worldwide.address(
          first_name: "David",
          last_name: "Steel",
          address1: "285 Main Street",
          # NOTE:  city not required for Gibraltar
          # NOTE:  zip should be auto-filled (as GX11 1AA) for Gibraltar
          country_code: "GI",
          phone: "+350 200 45440",
        ),
        Worldwide.address(
          last_name: "岸田",
          first_name: "文雄",
          zip: "１００−００１４",
          country_code: "JP",
          province_code: "JP-13",
          city: "千代田区",
          address1: "永田町２丁目３ー１",
        ),
        Worldwide.address(
          first_name: "Halimah",
          last_name: "Jacob",
          address1: "The Istana",
          address2: "Orchard Rd",
          # NOTE:  city not required for Singapore
          zip: "238823",
          country_code: "SG",
          phone: "+6587206021",
        ),
        Worldwide.address(
          first_name: "Louis",
          last_name: "DeJoy",
          address1: "475 L'Enfant Plaza SW",
          city: "Washington",
          province_code: "DC",
          zip: "20260",
          country_code: "US",
          phone: "+18002758777",
        ),
      ].each do |address|
        assert_equal true, address.valid?, "Expected #{address.inspect} to be valid."
        assert_empty address.errors
      end
    end

    test "city may not be blank if it isn't autofilled" do
      [
        Worldwide.address(
          address1: "55 Milner Road",
          province_code: "NT",
          country_code: "AU",
          zip: "0871",
        ),
        Worldwide.address(
          address1: "2 Sanam Chai Rd",
          address2: "Phra Borom Maha Ratchawang",
          province_code: "TH-10",
          country_code: "TH",
          zip: "10200",
        ),
        Worldwide.address(
          address1: "375 Albert Rd",
          address2: "Woodstock",
          country_code: "ZA",
          zip: "7915",
          phone: "+27 21 447 8194",
        ),
      ].each do |address|
        assert_includes address.errors, [:city, :blank], "Validating #{address.inspect}"
        assert_equal false, address.valid?, "Validating #{address.inspect}"
      end
    end

    test "city may be blank in countries where it's autofilled" do
      [
        Worldwide.address(
          address1: "3 Willis' Road",
          country_code: "GI",
        ),
        Worldwide.address(
          address1: "77 Robinson Road",
          address2: "#13-00",
          zip: "068896",
          country_code: "SG",
        ),
        Worldwide.address(
          address1: "South Georgia Museum",
          country_code: "GS",
        ),
        Worldwide.address(
          address1: "St. Mary's School",
          country_code: "TA",
        ),
      ].each do |address|
        assert_equal true, address.valid?, "Validating #{address.inspect}"
        assert_empty address.errors, "Validating #{address.inspect}"
      end
    end

    test "domestic-format phone numbers are considered valid" do
      [
        Worldwide.address( # Ottawa City Hall
          address1: "110 Laurier Ave W",
          city: "Ottawa",
          province_code: "ON",
          country_code: "CA",
          zip: "K1P 1J1",
          phone: "(613) 580-2400",
        ),
        Worldwide.address( # Tennessee State Capitol
          address1: "600 Dr. M.L.K. Jr. Blvd",
          city: "Nashville",
          province_code: "TN",
          country_code: "US",
          zip: "37243",
          phone: "(615)360-4326",
        ),
        Worldwide.address(
          company: "Museo Soumaya",
          address1: "Blvd. Miguel de Cervantes Saavedra",
          address2: "Granada, Miguel Hidalgo",
          city: "Ciudad de México",
          province_code: "CDMX",
          country_code: "MX",
          zip: "11529",
          phone: "55 1103 9800",
        ),
        Worldwide.address( # Oslo Opera House
          address1: "Kirsten Flagstads Plass 1",
          zip: "0150",
          city: "Oslo",
          country_code: "NO",
          phone: "21 42 21 21",
        ),
      ].each do |address|
        assert_empty address.errors, "Validating #{address.inspect}"
        assert_equal true, address.valid?, "Validating #{address.inspect}"
      end
    end

    test "international-format phone numbers are considered valid" do
      [
        Worldwide.address( # Ottawa City Hall
          address1: "110 Laurier Ave W",
          city: "Ottawa",
          province_code: "ON",
          country_code: "CA",
          zip: "K1P 1J1",
          phone: "+1 (613) 580-2400",
        ),
        Worldwide.address( # Ottawa City Hall
          address1: "110 Laurier Ave W",
          city: "Ottawa",
          province_code: "ON",
          country_code: "CA",
          zip: "K1P 1J1",
          phone: "+47 21 42 21 21", # we should allow numbers in other countries, so long as they are international
        ),
        Worldwide.address( # Tennessee State Capitol
          address1: "600 Dr. M.L.K. Jr. Blvd",
          city: "Nashville",
          province_code: "TN",
          country_code: "US",
          zip: "37243",
          phone: "+1(615)360-4326",
        ),
        Worldwide.address(
          company: "Museo Soumaya",
          address1: "Blvd. Miguel de Cervantes Saavedra",
          address2: "Granada, Miguel Hidalgo",
          city: "Ciudad de México",
          province_code: "CDMX",
          country_code: "MX",
          zip: "11529",
          phone: "+52 55 1103 9800",
        ),
        Worldwide.address( # Oslo Opera House
          address1: "Kirsten Flagstads Plass 1",
          zip: "0150",
          city: "Oslo",
          country_code: "NO",
          phone: "+47 21 42 21 21",
        ),
      ].each do |address|
        assert_equal true, address.valid?, "Validating #{address.inspect}"
        assert_empty address.errors, "Validating #{address.inspect}"
      end
    end

    test "province missing and cannot be inferred fails validation" do
      [
        Worldwide.address(
          address1: "1 Sheikh Mohammed bin Rashid Blvd",
          city: "Dubai",
          # missing province_code: DU
          country_code: "AE",
        ),
        Worldwide.address(
          address1: "R. de Santa Cruz do Castelo",
          city: "Lisbon",
          # missing province_code PT-11
          # missing zip 1100-129
          country_code: "PT",
        ),
      ].each do |address|
        assert_equal false, address.valid?, "#{address.inspect} should not be valid"
        assert_includes address.errors, [:province, :blank]
      end
    end

    test "province invalid and cannot be inferred fails validation" do
      [
        Worldwide.address(
          address1: "200 Front Street West",
          city: "Toronto",
          province_code: "Ontariario", # should be code not name; name is misspelled
          # missing zip: M5V 2K2
          country_code: "CA",
        ),
        Worldwide.address(
          address1: "1/103 North Street",
          city: "Palmerston North",
          province_code: "Palmerston North", # should be MWT
          # missing zip: 4410
          country_code: "NZ",
        ),
      ].each do |address|
        assert_equal false, address.valid?, "#{address.inspect} should not be valid"
        assert_includes address.errors, [:province, :invalid], "Validating #{address.inspect}"
      end
    end

    test "zip invalid for country fails validation" do
      [
        Worldwide.address(
          address1: "24 Sussex Drive",
          city: "Ottawa",
          province_code: "ON",
          country_code: "CA",
          zip: "10018", # Should be K1M 1M4
        ),
        Worldwide.address(
          address1: "20 W 34 St",
          city: "New York",
          province_code: "NY",
          country_code: "US",
          zip: "K1A 1A1", # should be 10001
        ),
        Worldwide.address(
          address1: "Bergstrasse 2",
          city: "Vaduz",
          zip: "8001", # should be 9490
          country_code: "LI",
        ),
        Worldwide.address(
          address1: "Falknenstrasse 1",
          city: "Zürich",
          country_code: "CH",
          zip: "9490", # should be 8001
        ),
      ].each do |address|
        assert_equal false, address.valid?, "#{address.inspect} should not be valid"
        assert_equal [[:zip, :invalid_for_country]], address.errors
      end
    end

    test "province that's ambiguous for zip is accepted each way" do
      [
        Worldwide.address(
          address1: "Piazza A. Pastorelli, 1",
          city: "Briga Alta",
          province_code: "CN",
          country_code: "IT",
          zip: "18025",
        ),
        Worldwide.address(
          address1: "Piazza Roma, 1",
          city: "Mendatica",
          province_code: "IM",
          country_code: "IT",
          zip: "18025",
        ),
        Worldwide.address(
          address1: "71001 Market Garden Rd",
          city: "Fort Campbell",
          province_code: "KY",
          zip: "42223",
          country_code: "US",
        ),
        Worldwide.address(
          address1: "7551 Headquarters Loop Rd",
          city: "Fort Campbell",
          province_code: "TN",
          zip: "42223",
          country_code: "US",
        ),
      ].each do |address|
        assert_empty address.errors, "Expected no errors for #{address.inspect}"
        assert_equal true, address.valid?, "#{address.inspect} should be valid"
      end
    end

    test "zip that's invalid for province generates an error" do
      [
        Worldwide.address(
          address1: "265A Maude St",
          city: "Shepparton",
          province_code: "VIC",
          zip: "2007", # Should be 3630
          country_code: "AU",
          phone: "+61 3 5820 4011",
        ),
        Worldwide.address(
          address1: "700 Harris St",
          city: "Ultimo",
          province_code: "NSW",
          zip: "3630", # Should be 2007
          country_code: "AU",
          phone: "+61 2 8333 1500",
        ),
        Worldwide.address(
          address1: "5451 Portage Ave",
          city: "Winnipeg",
          province_code: "MB",
          country_code: "CA",
          zip: "M5W 1E6", # should be R3C 2H1
        ),
        Worldwide.address(
          address1: "11 W 42nd St Unit 19",
          city: "New York",
          province_code: "NY",
          zip: "90232", # Should be 10036
          country_code: "US",
        ),
        Worldwide.address(
          address1: "9909 Jefferson Blvd",
          city: "Culver City",
          province_code: "CA",
          zip: "10036", # Should be 90232
          country_code: "US",
        ),
      ].each do |address|
        assert_equal false, address.valid?, "Validating #{address.inspect}"
        assert_includes address.errors, [:zip, :invalid_for_country_and_province], address.errors
      end
    end
  end
end
