# frozen_string_literal: true

require "test_helper"
require_relative "../../../rake/postal/codes"
require_relative "../../../rake/postal/postal_helpers"

class CodesTest < ActiveSupport::TestCase
  include PostalHelpers

  test "#longest_possible_shared_common_prefix returns expected value" do
    data = [
      ["abcdef", "abcfeg", "abc"],
      ["K1S 1A1", "M5W 1E6", ""],
      ["123456", "1792831", "1"],
      ["xyzzy", "xzzzy", "x"],
      ["aberdeen", "able", "ab"],
    ]

    codes = Postal::Codes.new

    data.each do |a, b, expected|
      actual = codes.send(:longest_possible_shared_common_prefix, a, b)

      assert_equal expected, actual
    end
  end

  test "#compute_prefixes handles three codes that reduce to two prefixes" do
    prefix_level = subdivision_level_for_country("CA")
    data = {
      "123": { prefix_level => "AB" },
      "121": { prefix_level => "AB" },
      "327": { prefix_level => "BC" },
    }

    expected = {
      "1": "AB",
      "3": "BC",
      "K1A": "QC",
    }

    codes = Postal::Codes.new
    actual = codes.send(:compute_prefixes, data, "CA", subdivision_level_for_country("CA"))

    assert_equal expected, actual
  end

  test "#compute_prefixes handles a subset of codes from Ontario and Nova Scotia" do
    prefix_level = subdivision_level_for_country("CA")
    data = {
      "BOC": { prefix_level => "NS" },
      "BOE": { prefix_level => "NS" },
      "B1A": { prefix_level => "NS" },
      "B2T": { prefix_level => "NS" },
      "B3R": { prefix_level => "NS" },
      "B4C": { prefix_level => "NS" },
      "P0R": { prefix_level => "ON" },
      "N3P": { prefix_level => "ON" },
      "N3R": { prefix_level => "ON" },
      "L0N": { prefix_level => "ON" },
      "L8H": { prefix_level => "ON" },
      "K0L": { prefix_level => "ON" },
      "K1S": { prefix_level => "ON" },
      "P1A": { prefix_level => "ON" },
    }

    expected = {
      "B": "NS",
      "K": "ON",
      "L": "ON",
      "N": "ON",
      "P": "ON",
      "K1A": "QC",
    }

    codes = Postal::Codes.new
    actual = codes.send(:compute_prefixes, data, "CA", subdivision_level_for_country("CA"))

    assert_equal expected, actual
  end

  test "#compute_prefixes handles a subset of codes from YT, NT, and NU" do
    prefix_level = subdivision_level_for_country("CA")
    data = {
      "X0C 0G0": { prefix_level => "NU" },
      "Y1A 3V5": { prefix_level => "YT" },
      "X0E 0A0": { prefix_level => "NT" },
      "X0E 0Z0": { prefix_level => "NT" },
      "X1A 3T5": { prefix_level => "NT" },
      "X0A 0J0": { prefix_level => "NU" },
      "X0A 0R0": { prefix_level => "NU" },
      "X0A 0H0": { prefix_level => "NU" },
      "Y0B 1L0": { prefix_level => "YT" },
      "Y0A 1B0": { prefix_level => "YT" },
      "X0E 0P0": { prefix_level => "NT" },
    }

    expected = {
      "X0C": "NU",
      "Y": "YT",
      "X0E": "NT",
      "X1": "NT",
      "X0A": "NU",
      "K1A": "QC",
    }

    codes = Postal::Codes.new
    actual = codes.send(:compute_prefixes, data, "CA", subdivision_level_for_country("CA"))

    assert_equal expected, actual
  end

  test "#compute_prefixes handles specialization of codes further down the list" do
    prefix_level = subdivision_level_for_country("CA")
    data = {
      "abcdef": { prefix_level => "ON" },
      "abcfgh": { prefix_level => "ON" },
      "abcdfg": { prefix_level => "QC" },
    }

    expected = {
      "abcde": "ON",
      "abcf": "ON",
      "abcdf": "QC",
      "K1A": "QC",
    }

    codes = Postal::Codes.new
    begin
      actual = codes.send(:compute_prefixes, data, "CA", subdivision_level_for_country("CA"))
    rescue => e
      puts "########"
      puts e.backtrace
    end

    assert_equal expected, actual
  end

  test "#compute_prefixes correctly changes subdivision level for Italy" do
    prefix_level = subdivision_level_for_country("IT")
    data = {
      "92010": { prefix_level => "AG" },
      "15010": { prefix_level => "AL" },
      "60010": { prefix_level => "AN" },
    }

    expected = {
      "9": "AG",
      "1": "AL",
      "6": "AN",
    }

    codes = Postal::Codes.new
    actual = codes.send(:compute_prefixes, data, "IT", subdivision_level_for_country("IT"))

    assert_equal expected, actual
  end

  test "#exception is raised when trying to import a country that is not yet mapped." do
    actual = assert_raises(RuntimeError) do
      subdivision_level_for_country("ZW")
    end
    expected = "The country code 'ZW' has not been mapped yet. Data is pulled from geonames.org, whose format differs from how Worldwide's data is structured internally."

    assert_equal(expected, actual.message)
  end
end
