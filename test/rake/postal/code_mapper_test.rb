# frozen_string_literal: true

require "test_helper"
require_relative "../../../rake/postal/code_mapper"
require_relative "../../../rake/postal/postal_helpers"

class CodeMapperTest < ActiveSupport::TestCase
  include PostalHelpers

  test "#map_to_iso class method returns correct values for JP" do
    geoname_codes = [
      "01",
      "02",
      "03",
      "04",
      "05",
      "06",
      "07",
      "08",
      "09",
      "10",
      "11",
      "12",
      "13",
      "14",
      "15",
      "16",
      "17",
      "18",
      "19",
      "20",
      "21",
      "22",
      "23",
      "24",
      "25",
      "26",
      "27",
      "28",
      "29",
      "30",
      "31",
      "32",
      "33",
      "34",
      "35",
      "36",
      "37",
      "38",
      "39",
      "40",
      "41",
      "42",
      "43",
      "44",
      "45",
      "46",
      "47",
      "not",
      "mapped",
    ]
    expected = [
      "JP-23",
      "JP-05",
      "JP-02",
      "JP-12",
      "JP-38",
      "JP-18",
      "JP-40",
      "JP-07",
      "JP-21",
      "JP-10",
      "JP-34",
      "JP-01",
      "JP-28",
      "JP-08",
      "JP-17",
      "JP-03",
      "JP-37",
      "JP-46",
      "JP-14",
      "JP-39",
      "JP-43",
      "JP-26",
      "JP-24",
      "JP-04",
      "JP-45",
      "JP-20",
      "JP-42",
      "JP-29",
      "JP-15",
      "JP-44",
      "JP-33",
      "JP-27",
      "JP-41",
      "JP-11",
      "JP-25",
      "JP-32",
      "JP-22",
      "JP-09",
      "JP-36",
      "JP-13",
      "JP-31",
      "JP-16",
      "JP-30",
      "JP-06",
      "JP-35",
      "JP-19",
      "JP-47",
      "not",
      "mapped",
    ]
    actual = geoname_codes.map do |n|
      Postal::CodeMapper.new.map_to_iso(country: "JP", geonames_code: n)
    end

    assert_equal expected, actual
  end

  test "#map_to_iso class method returns correct values for NZ" do
    geoname_codes = ["10", "E7", "E8", "E9", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "G1", "G2", "G3", "TAS", "not", "mapped"]
    expected = ["CIT", "AUK", "BOP", "CAN", "GIS", "HKB", "MWT", "MBH", "NSN", "NTL", "OTA", "STL", "TKI", "WKO", "WGN", "WTC", "TAS", "not", "mapped"]
    actual = geoname_codes.map do |n|
      Postal::CodeMapper.new.map_to_iso(country: "NZ", geonames_code: n)
    end

    assert_equal expected, actual
  end

  test "#map_to_iso class method returns correct values for PT" do
    geoname_codes = ["02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "13", "14", "16", "17", "18", "19", "20", "21", "22", "23", "not", "mapped"]
    expected = ["PT-01", "PT-02", "PT-03", "PT-04", "PT-05", "PT-06", "PT-07", "PT-08", "PT-30", "PT-09", "PT-10", "PT-11", "PT-12", "PT-13", "PT-14", "PT-15", "PT-16", "PT-17", "PT-18", "PT-20", "not", "mapped"]
    actual = geoname_codes.map do |n|
      Postal::CodeMapper.new.map_to_iso(country: "PT", geonames_code: n)
    end

    assert_equal expected, actual
  end

  test "#map_to_iso class method returns correct values for BR" do
    geoname_codes = ["01", "02", "03", "04", "05", "06", "07", "08", "29", "13", "14", "11", "15", "16", "17", "18", "30", "20", "22", "23", "21", "24", "25", "26", "27", "28", "31", "not", "mapped"]
    expected = ["AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RN", "RS", "RJ", "RO", "RR", "SC", "SP", "SE", "TO", "not", "mapped"]
    actual = geoname_codes.map do |n|
      Postal::CodeMapper.new.map_to_iso(country: "BR", geonames_code: n)
    end

    assert_equal expected, actual
  end
end
