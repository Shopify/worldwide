# frozen_string_literal: true

require "test_helper"

# Miscellaneous assertions about our files in db/data/regions/??.yml.
# This is intended to catch errors introduced when editing those files.

module Worldwide
  class RegionYmlConsistencyTest < ActiveSupport::TestCase
    setup do
      @raw_yml = Dir["#{Worldwide::Paths::REGIONS_ROOT}/*.yml"].map do |filename|
        YAML.safe_load_file(filename).freeze
      end
    end

    test "zones keys must belong to a limited set of allowed keys" do
      allowed_keys = [
        "code",
        "code_alternates",
        "deprecated",
        "iso_code",
        "name",
        "name_alternates",
        "neighboring_zones",
        "zip_prefixes",
        "priority",
        "tax",
        "tax_name",
        "tax_type",
        "tags",
        "example_city",
        "example_city_zip",
      ]

      @raw_yml.each do |yml|
        zones = yml["zones"] || []

        zones.each do |zone|
          difference = zone.keys - allowed_keys

          assert_predicate difference, :empty?, "#{zone} has keys that are not allowed: #{difference}"
        end
      end
    end

    test "country legacy_names are all non-empty strings" do
      Regions.all.select(&:country?).each do |country|
        assert_not country.legacy_name.nil?, "Country legacy_name should not be nil for #{country.inspect}"
        assert_not country.legacy_name&.empty?, "Country legacy_name should not be empty for #{country.inspect}"
        assert_kind_of String, country.legacy_name, "Country legacy_name should be a string for #{country.inspect}"
      end
    end

    test "province legacy_names are all non-empty strings" do
      Regions.all.select(&:province?).each do |province|
        assert_not province.legacy_name.nil?, "Province legacy_name should not be nil for #{province.inspect}"
        assert_not province.legacy_name&.empty?, "Province legacy_name should not be empty for #{province.inspect}"
        assert_kind_of String, province.legacy_name, "Province legacy_name should be a string for #{province.inspect}"
      end
    end

    test "address1 formats include {building_num} and {street} tags" do
      expected_fields = ["building_num", "street"]
      Regions.all.select(&:country?).each do |country|
        format = country.format.dig("address1")
        next unless format

        expected_fields.each do |field|
          assert_includes format, "{#{field}}", "#{country.iso_code} address1 format missing {#{field}}"
        end
      end
    end

    test "address1_with_unit formats include {building_num}, {street} and {unit} tags" do
      expected_fields = ["building_num", "street", "unit"]
      Regions.all.select(&:country?).each do |country|
        format = country.format.dig("address1_with_unit")
        next unless format

        expected_fields.each do |field|
          assert_includes format, "{#{field}}", "#{country.iso_code} address1_with_unit missing {#{field}}"
        end
      end
    end

    test "edit format includes zip for all countries where the postal code is required and not autofilled" do
      Regions.all.select(&:country?).each do |country|
        next if country.zip_autofill_enabled
        next unless country.zip_required?

        format = country.format.dig("edit")

        assert_includes format, "{zip}", "#{country.iso_code} requires zip but doesn't prompt for it."
      end
    end

    test "edit format does not include zip field if zip_autofill is enabled" do
      Regions.all.select(&:country?).each do |country|
        next unless country.zip_autofill_enabled

        format = country.format.dig("edit")

        refute_includes format, "{zip}", "#{country.iso_code} has zip autofill but prompts for zip"
      end
    end

    test "week_start_day is a valid value" do
      Regions.all.select(&:country?).each do |country|
        week_start_day = country.week_start_day

        valid_values = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

        assert_includes valid_values, week_start_day
      end
    end

    test "all countries and provinces have tax information" do
      Regions.all.select do |region|
        region.country? || region.province?
      end.each do |region|
        assert_kind_of Float, region.tax_rate, "#{region.iso_code} tax rate should be a Float"
        assert (0..1).cover?(region.tax_rate), "#{region.iso_code} tax rate should be between 0 and 100%"

        next if (region.tax_rate * 100).to_i == 0

        assert_kind_of String, region.tax_name, "#{region.iso_code} tax name should be a String"
        assert !region.tax_name&.empty?, "#{region.iso_code} tax name should be non-empty"
      end
    end

    test "zip_prefixes are sorted" do
      Regions.all.select(&:province?).each do |province|
        next if province.zip_prefixes.nil?

        assert_equal province.zip_prefixes, province.zip_prefixes.sort, "prefixes for #{province.iso_code}"
      end
    end

    test "zip_prefixes are unambiguous" do
      Regions.all.select(&:country?).each do |country|
        next if country.zones&.empty? || country.zones.first.zip_prefixes&.empty?

        mappings = {}
        country.zones.each do |province|
          next if province.zip_prefixes.nil?

          province.zip_prefixes.each do |prefix|
            mappings.each do |k, v|
              refute prefix.start_with?(k), "#{country.iso_code} prefix #{prefix} ambigous between #{v} and #{province.legacy_code}"
              refute k.start_with?(prefix), "#{country.iso_code} prefix #{prefix} ambigous between #{v} and #{province.legacy_code}"
            end
            mappings[prefix] = province.legacy_code
          end
        end
      end
    end

    test "if a country has zip_prefixes, then every province has at least one prefix" do
      Regions.all.select(&:country?).each do |country|
        provinces = country.zones.select(&:province?)

        next unless provinces.any? { |p| !p.zip_prefixes&.empty? }

        provinces_without_prefixes = provinces
          .select { |p| p.zip_prefixes&.empty? }
          .reject(&:deprecated?)

        assert_empty(
          provinces_without_prefixes,
          "#{country.iso_code} has no prefix(es) for #{provinces_without_prefixes.map(&:iso_code).join(", ")}",
        )
      end
    end

    test "example_city is available for each US state" do
      assert_predicate Worldwide.region(code: "US").zones, :all? do |state|
        !state.example_city&.empty?
      end
    end

    test "timezone info is in the expected format" do
      Regions.all.select(&:country?).each do |country|
        unless country.timezone.nil?
          assert_kind_of String, country.timezone
          assert_empty country.timezones
        end

        unless country.timezones&.empty?
          assert_kind_of Hash, country.timezones
          assert_nil country.timezone
        end
      end
    end

    test "all tznames are valid when looked up" do
      Regions.all.select(&:country?).each do |country|
        unless country.timezone.nil?
          assert_not_nil TZInfo::Timezone.get(country.timezone)
        end

        country.timezones.each do |timezone, _prefixes|
          assert_not_nil TZInfo::Timezone.get(timezone)
        end
      end
    end
  end
end
