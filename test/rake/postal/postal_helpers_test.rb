# frozen_string_literal: true

require "test_helper"
require_relative "../../../rake/postal/postal_helpers"

class PostalHelpersTest < ActiveSupport::TestCase
  include PostalHelpers

  test "#patch_prefix_data returns correct values for CA" do
    assert_equal({ K1A: "QC" }, patch_prefix_data({}, "CA"))
  end

  test "#patch_prefix_data returns correct values for US" do
    expected_hash_us = {
      "006": "PR",
      "007": "PR",
      "009": "PR",
      "008": "VI",
      "09": "AE",
      "340": "AA",
      "962": "AP",
      "963": "AP",
      "964": "AP",
      "965": "AP",
      "966": "AP",
      "96799": "AS",
      "96939": "PW",
      "96940": "PW",
      "96941": "FM",
      "96942": "FM",
      "96943": "FM",
      "96944": "FM",
      "9691": "GU",
      "9692": "GU",
      "96931": "GU",
      "96932": "GU",
      "9695": "MP",
    }

    assert_equal(expected_hash_us, patch_prefix_data({}, "US"))
  end

  test "#patch_prefix_data returns input prefixes param for invalid country" do
    assert_empty(patch_prefix_data({}, "NIL"))
  end

  # code_mapper_test.rb tests full implementation of CodeMappings.
  # Following two tests quickly ensure that the CodeMapper class is being called correctly
  test "#map_prefix_data modifies values if necessary" do
    assert_equal({ "490" => "JP-23" }, map_prefix_data({ "490" => "01" }, "JP"))
  end

  test "#map_prefix_data returns input prefixes param for country not in CodeMapper" do
    assert_equal({ "006" => "PR" }, map_prefix_data({ "006" => "PR" }, "US"))
  end

  test "#subdivision_level_for_country returns :code1 for valid countries" do
    level_1_countries = ["CA", "JP", "NZ", "PT", "US", "IN", "BR", "AU"]

    level_1_countries.each do |country|
      assert_equal :code1, subdivision_level_for_country(country)
    end
  end

  test "#subdivision_level_for_country returns :code2 for valid countries" do
    level_2_countries = ["IT", "ES"]

    level_2_countries.each do |country|
      assert_equal :code2, subdivision_level_for_country(country)
    end
  end

  test "#subdivision_level_for_country raises exception for a yet to be mapped country" do
    assert_raises RuntimeError do
      subdivision_level_for_country("NOPE")
    end
  end

  test "#write_yaml writes zip_prefixes and zips_crossing_provinces" do
    path = write_yaml("CA", zones: { BC: [:"999", :"998"] }, codes_crossing_zones: { K1A: ["ON", "QC"] }, only_show_diff: true)

    yaml = YAML.load_file(path)
    bc = yaml["zones"].find { |zone| zone["code"] == "BC" }

    assert_equal(["998", "999"], bc["zip_prefixes"])
    assert_equal(["ON", "QC"], yaml["zips_crossing_provinces"]["K1A"])
  ensure
    FileUtils.rm_f(path) if path
  end

  test "#write_yaml changes nothing but the postal code data, and leaves the data file alone" do
    data_file = File.join(Worldwide::Paths::REGIONS_ROOT, "CA.yml")
    original = File.read(data_file)
    path = write_yaml("CA", zones: { BC: ["999"] }, only_show_diff: true)

    expected = YAML.safe_load(original)
    expected["zones"].find { |zone| zone["code"] == "BC" }["zip_prefixes"] = ["999"]

    assert_equal(expected, YAML.safe_load_file(path))
    assert_equal(original, File.read(data_file))
  ensure
    FileUtils.rm_f(path) if path
  end

  test "#write_yaml keeps the comments and the key order of the rest of the file" do
    path = write_yaml("CA", zones: { BC: ["999"] }, only_show_diff: true)

    original = File.read(File.join(Worldwide::Paths::REGIONS_ROOT, "CA.yml"))
    updated = File.read(path)

    refute_empty(original.lines.grep(/\A\s*#/))
    assert_equal(original.lines.grep(/\A\s*#/), updated.lines.grep(/\A\s*#/))
    assert_equal(YAML.safe_load(original).keys, YAML.safe_load(updated).keys)
    assert_equal(YAML.safe_load(original)["zones"].map(&:keys), YAML.safe_load(updated)["zones"].map(&:keys))
  ensure
    FileUtils.rm_f(path) if path
  end

  test "#write_yaml adds zip_prefixes to a zone that has none, and zips_crossing_provinces to a country that has none" do
    path = write_yaml("AR", zones: { B: ["1"] }, codes_crossing_zones: { "1000": ["B", "C"] }, only_show_diff: true)

    yaml = YAML.safe_load_file(path)

    assert_equal(["1"], yaml["zones"].find { |zone| zone["code"] == "B" }["zip_prefixes"])
    assert_equal(["B", "C"], yaml["zips_crossing_provinces"]["1000"])
  ensure
    FileUtils.rm_f(path) if path
  end

  test "#write_yaml replaces zip_prefixes that are indented by four spaces, as in ES.yml" do
    path = write_yaml("ES", zones: { C: ["15", "27"] }, only_show_diff: true)

    yaml = YAML.safe_load_file(path)

    assert_equal(["15", "27"], yaml["zones"].find { |zone| zone["code"] == "C" }["zip_prefixes"])
    assert_includes(File.read(path), "  zip_prefixes:\n    - '15'\n    - '27'\n")
    assert_equal(YAML.safe_load_file(File.join(Worldwide::Paths::REGIONS_ROOT, "ES.yml")).except("zones"), yaml.except("zones"))
  ensure
    FileUtils.rm_f(path) if path
  end
end
