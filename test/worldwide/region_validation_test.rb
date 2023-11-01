# frozen_string_literal: true

require "test_helper"

module Worldwide
  class RegionValidationTest < ActiveSupport::TestCase
    setup do
      @mappings = Dir.glob("test/lib/zips/*").map do |file|
        country = File.basename(file, ".*")
        [country, YAML.safe_load_file(file)]
      end.to_h
    end

    test "validity of valid zips in countries where we don't have province-specific zip prefixes" do
      [
        [:BR, :BA, "41150-100"],
        [:ID, :KS, "70114"],
      ].each do |country_code, province_code, zip|
        assert_equal(
          true,
          Worldwide.region(code: country_code).valid_zip?(zip),
          "Expected zip #{zip.inspect} to be valid for country #{country_code}",
        )
        assert_equal(
          true,
          Worldwide.region(code: country_code).zone(code: province_code).valid_zip?(zip),
          "Expected zip #{zip.inspect} to be valid for province #{country_code}-#{province_code}",
        )
      end
    end

    test "validity of regex-invalid zips in countries where we don't have province-specify zip prefixes" do
      [
        [:BR, :BA, "411500-100"],
        [:BR, :BA, "4115-100"],
        [:ID, :KS, "701144"],
        [:ID, :KS, "7011"],
      ].each do |country_code, province_code, zip|
        assert_equal(
          false,
          Worldwide.region(code: country_code).valid_zip?(zip),
          "Expected zip #{zip.inspect} NOT to be valid for country #{country_code}.",
        )
        assert_equal(
          false,
          Worldwide.region(code: country_code).zone(code: province_code).valid_zip?(zip),
          "Expected zip #{zip.inspect} NOT to be valid for province #{country_code}-#{province_code}.",
        )
      end
    end

    test "validity of valid zips in countries where we do have province-specific zip prefixes" do
      [
        [:CA, :NL, "A1A 1A1"],
        [:CA, :ON, "K1A 1A1"],
        [:CA, :ON, "M5W 1E6"],
        [:CA, :MB, "R2N 2X6"],
        [:CA, :BC, "V6B 4A2"],
        [:CA, :NU, "X0A 0H0"],
        [:CA, :NT, "X1A 1N5"],
        [:GB, :ENG, "SW1A 1AA"],
        [:GB, :SCT, "EH99 1SP"],
        [:GB, :WLS, "CF10 5HB"],
        [:GB, :NIR, "BT3 9EP"],
        [:US, :MA, "02128"],
        [:US, :NY, "10018"],
        [:US, :CA, "90210"],
        [:US, :PR, "00901"],
      ].each do |country_code, province_code, zip|
        assert_equal true, Worldwide.region(code: country_code).valid_zip?(zip)
        assert_equal true, Worldwide.region(code: country_code).zone(code: province_code).valid_zip?(zip)
      end
    end

    test "validity of regex-invalid zips in countries where we do have province-specific zip prefixes" do
      [
        [:CA, :NL, "Q1Q 1A1"],
        [:CA, :ON, "Z1Z 1Z1"],
        [:CA, :BC, "90210"],
        [:GB, :ENG, "ZZ1 0ZZ"],
        [:GB, :SCT, "QQ1 1QQ"],
        [:US, :MA, "2128"],
        [:US, :NY, "100018"],
        [:US, :CA, "902210"],
        [:US, :PR, "006000"],
      ].each do |country_code, province_code, zip|
        assert_equal false, Worldwide.region(code: country_code).valid_zip?(zip)
        assert_equal false, Worldwide.region(code: country_code).zone(code: province_code).valid_zip?(zip)
      end
    end

    test "validity of regex-valid but wrong-zone zips where we have prefixes" do
      [
        [:CA, :ON, "A1A 1A1"],
        [:CA, :NL, "K1A 1A1"],
        [:CA, :BC, "R2N 2X6"],
        [:CA, :NT, "X0A 0H0"],
        [:GB, :SCT, "SW1A 1AA"],
        [:GB, :ENG, "EH99 1SP"],
        [:GB, :NIR, "CF10 5HB"],
        [:GB, :WLS, "BT3 9EP"],
        [:US, :NH, "02128"],
        [:US, :MA, "10018"],
        [:US, :OR, "90210"],
        [:US, :PR, "00899"],
      ].each do |country_code, province_code, zip|
        assert_equal true, Worldwide.region(code: country_code).valid_zip?(zip)
        assert_equal false, Worldwide.region(code: country_code).zone(code: province_code).valid_zip?(zip)
      end
    end

    test "#valid_zip? with valid partial postal codes" do
      [
        [:CA, "T1Y"],
        [:CA, "V5T"],
        [:CA, "R3B"],
        [:CA, "X0E"],
        [:GB, "BF1"],
        [:GB, "sw1"],
        [:GB, "BT30"],
        [:GB, "AB99"],
        [:GB, "Cf3"],
        [:IE, "D12"],
        [:IE, "D13"],
        [:IE, "D6W"],
        [:IE, "F93"],
        [:IE, "H14"],
      ].each do |country, zip|
        assert Worldwide.region(code: country).valid_zip?(zip, partial_match: true), "Partial zip #{zip} should be valid for #{country}"
      end
    end

    test "#valid_zip? with invalid partial zip" do
      [
        [:CA, "A"],
        [:CA, ""],
        [:GB, "s"],
        [:GB, ""],
        [:GB, "K1A"],
        [:IE, "D1"],
        [:IE, "s"],
        [:IE, "V95 K"],
        [:US, "123"],
        [:US, "150225"],
        [:US, "ab123"],
      ].each do |country, zip|
        refute Worldwide.region(code: country).valid_zip?(zip, partial_match: true), "Partial zip #{zip} should be invalid for #{country}"
      end
    end
  end
end
