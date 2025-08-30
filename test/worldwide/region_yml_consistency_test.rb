# frozen_string_literal: true

require "test_helper"

# Miscellaneous assertions about our files in data/regions/??.yml.
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
        "example_address",
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

    test "all regions that allow a building number on address2 set building_number_required to true" do
      Regions.all.select(&:country?).each do |country|
        next unless country.building_number_may_be_in_address2

        assert_predicate country,
          :building_number_required,
          "#{country.iso_code} allows building number in address2 but building_number_required is not true"
      end
    end

    test "country currencies are all 3-character strings and exist" do
      expected_format = /\A[A-Z]{3}\z/

      Regions.all.select(&:country?).each do |country|
        currency = country.currency

        assert_predicate currency, :present?, "#{country.iso_code} currency is empty"
        assert_kind_of Currency, currency, "#{country.iso_code} currency was not a Currency"
        assert_match expected_format, currency.currency_code, "#{country.iso_code} currency.curency_code was not a 3-character capitalized alphabetical code"
      end
    end

    test "country phone_number_prefix attributes are all numeric and exist" do
      expected_format = /\A0|[1-9][0-9]{0,2}\z/

      Regions.all.select(&:country?).each do |country|
        phone_number_prefix = country.phone_number_prefix

        assert_predicate phone_number_prefix, :present?, "#{country.iso_code} phone_number_prefix is empty"
        assert_match expected_format, phone_number_prefix.to_s, "#{country.iso_code} phone_number_prefix was not a 1-3 digit code"
      end
    end

    test "country group attribute is always present and is a string" do
      Regions.all.select(&:country?).each do |country|
        group = country.group

        assert_predicate group, :present?, "#{country.iso_code} group is empty"
        assert_kind_of String, group, "#{country.iso_code} group was not a String"
      end
    end

    test "format keys must belong to a limited set of required and allowed keys" do
      allowed_keys = ["edit", "show"]
      required_format_keys = ["{firstName}", "{lastName}", "{company}", "{address1}", "{address2}", "{country}", "{phone}"]
      allowed_format_keys = ["{city}", "{zip}", "{province}"]

      Regions.all.select(&:country?).each do |country|
        formats = country.format

        allowed_keys.each do |allowed_key|
          format = formats[allowed_key]
          keys = format.scan(/{[^}]+}/)
          missing_required_keys = required_format_keys - keys

          assert_empty missing_required_keys, "#{country.iso_code} #{allowed_key} format is missing required keys #{missing_required_keys}"

          unknown_keys = keys - required_format_keys - allowed_format_keys

          assert_empty unknown_keys, "#{country.iso_code} #{allowed_key} format has unknown keys: #{unknown_keys}"
        end
      end
    end

    test "format_extended keys must belong to a limited set of required and allowed keys" do
      required_format_keys = ["{firstName}", "{lastName}", "{company}", "{country}", "{phone}"]
      allowed_format_keys = ["{address1}", "{address2}", "{streetName}", "{streetNumber}", "{line2}", "{neighborhood}", "{city}", "{zip}", "{province}"]

      Regions.all.select(&:country?).each do |country|
        next if country.format_extended.blank?

        format = country.format_extended["edit"]
        keys = format.scan(/{[^}]+}/)
        missing_required_keys = required_format_keys - keys

        assert_empty missing_required_keys, "#{country.iso_code} edit format_extended is missing required keys #{missing_required_keys}"

        unknown_keys = keys - required_format_keys - allowed_format_keys

        assert_empty unknown_keys, "#{country.iso_code} edit format_extended has unknown keys: #{unknown_keys}"
      end
    end

    test "additional_address_fields names must belong to a limited set of allowed names" do
      allowed_names = ["streetName", "streetNumber", "line2", "neighborhood"]

      Regions.all.select(&:country?).each do |country|
        next if country.additional_address_fields.blank?

        country.additional_address_fields.each do |field|
          field_name = field["name"]

          assert_includes allowed_names, field_name, "#{country.iso_code} additional_address_field #{field_name} is not an allowed name"
        end
      end
    end

    test "additional_address_fields names are present as keys in the combined_address_format" do
      Regions.all.select(&:country?).each do |country|
        next if country.additional_address_fields.blank?

        country.additional_address_fields.each do |field|
          field_name = field["name"]
          present = country.combined_address_format.any? do |_, script_combined_address_format|
            script_combined_address_format.each do |_, fields|
              fields.any? { |f| f["key"] == field_name }
            end
          end

          assert present, "#{country.iso_code} additional_address_field #{field_name} is not present in combined_address_format"
        end
      end
    end

    test "combined_address_format defines default property" do
      Regions.all.select(&:country?).each do |country|
        next if country.combined_address_format.blank?

        keys_found = country.combined_address_format.keys
        includes_default = keys_found.include?("default")

        assert includes_default, "#{country.iso_code} combined_address_format must define default, only defines scripts #{keys_found}"
      end
    end

    test "combined_address_format keys are present in additional_address_fields" do
      Regions.all.select(&:country?).each do |country|
        next if country.combined_address_format.blank?

        country.combined_address_format.each do |_script, script_combined_address_format|
          script_combined_address_format.each do |_key, fields|
            fields.each do |field|
              field_name = field["key"]
              present = country.additional_address_fields.any? { |f| f["name"] == field_name }

              assert present, "#{country.iso_code} combined_address_format key #{field_name} is not present in additional_address_fields"
            end
          end
        end
      end
    end

    test "combined_address_format decorators are non-empty strings when set" do
      Regions.all.select(&:country?).each do |country|
        next if country.combined_address_format.blank?

        country.combined_address_format.each do |_script, script_combined_address_format|
          script_combined_address_format.each do |_key, fields|
            fields.each do |field|
              decorator = field["decorator"]

              next if decorator.nil?

              refute_predicate(
                decorator,
                :empty?,
                "#{country.iso_code} combined_address_format decorator for #{field["key"]} can't be an empty string",
              )
            end
          end
        end
      end
    end

    test "address1_regex capture groups must belong to a limited set of allowed names" do
      Regions.all.select(&:country?).each do |country|
        next if country.address1_regex.empty?

        allowed_names = country.combined_address_format["default"]["address1"].map { |field| field["key"] }
        country.address1_regex.each do |regex|
          address1_regex = Regexp.new(regex)

          address1_regex.names do |capture_group|
            assert_includes allowed_names, capture_group, "#{country.iso_code} regex capture group #{capture_group} is not a supported additional address field"
          end
        end
      end
    end

    test "example_address contains the word joiner when additional_address_fields are present" do
      word_joiner = "\u2060"

      Regions.all.select(&:country?).each do |country|
        next if country.additional_address_fields.blank?

        example_address = country.example_address

        next if example_address.blank?

        country.combined_address_format["default"].keys.each do |key|
          included = example_address[key].include?(word_joiner)

          assert included, "#{country.iso_code} example_address #{key} should contain the unicode word joiner"
        end
      end
    end

    test "If zones key does not exists, should not have {province} in format key" do
      Regions.all.select do |region|
        region.country? && region.zones.blank?
      end.each do |country|
        next if country.format.blank?

        assert_not_includes country.format["edit"], "{province}", "#{country.iso_code} does not have zones so should not have {province} key in format"
        assert_not_includes country.format["show"], "{province}", "#{country.iso_code} does not have zones so should not have {province} key in format"

        next if country.format_extended["edit"].blank?

        assert_not_includes country.format_extended["edit"], "{province}", "#{country.iso_code} does not have zones so should not have {province} key in format_extended"
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

        format_extended = country.format_extended.dig("edit")

        next if format_extended.blank?

        assert_includes format_extended, "{zip}", "#{country.iso_code} format_extended requires zip but doesn't prompt for it."
      end
    end

    test "edit format does not include zip field if zip_autofill is enabled" do
      Regions.all.select(&:country?).each do |country|
        next unless country.zip_autofill_enabled

        format = country.format.dig("edit")

        refute_includes format, "{zip}", "#{country.iso_code} has zip autofill but prompts for zip"

        format_extended = country.format_extended.dig("edit")

        next if format_extended.blank?

        refute_includes format_extended, "{zip}", "#{country.iso_code} format_extended has zip autofill but prompts for zip"
      end
    end

    test "if format key is missing {city}, then autofill_city must be active" do
      formats = ["edit", "show"]

      Regions.all.select(&:country?).each do |country|
        formats.each do |format|
          unless country.format[format].include?("{city}")
            assert_not_nil country.autofill_city, "#{country.iso_code} has no {city} in #{format} but autofill_city is not active"
          end
        end

        next if country.format_extended["edit"].blank?

        unless country.format_extended["edit"].include?("{city}")
          assert_not_nil country.autofill_city, "#{country.iso_code} has no {city} in format_extended but autofill_city is not active"
        end
      end
    end

    test "if autofill_city is active, then edit format must not have a city field" do
      Regions.all.select(&:country?).each do |country|
        next unless country.autofill_city

        refute_includes country.format["edit"], "{city}", "#{country.iso_code} has both autofill and {city} in edit format"

        next if country.format_extended["edit"].blank?

        refute_includes country.format_extended["edit"], "{city}", "#{country.iso_code} has both autofill and {city} in edit format_extended"
      end
    end

    test "in show format, each field must be separated from other fields by at least one character" do
      Regions.all.select(&:country?).each do |country|
        refute_includes country.format["show"], "}{", "#{country.iso_code} show format has fields without separation"
      end
    end

    test "all neighbors are uppercase" do
      Regions.all.select(&:province?).each do |province|
        next if province.neighbors.blank?

        assert province.neighbors.all?(&:upcase)
      end
    end

    test "If A is a neighbor for B, then B must be a neighbor for A" do
      Regions.all.select(&:country?).each do |country|
        next if country.zones.blank?
        next unless country.zones.any? { |zone| zone.neighbours.present? }

        # Fix `neighboring_zones` data in India and Thailand
        next if country.legacy_code == "IN" || country.legacy_code == "TH"

        country.zones.each do |zone_a|
          # Just because some zones in a country have neighbours defined doesn't mean that they all do.
          # For example, AU-TAS is an island, so it shares no land borders with any other zone.
          next if zone_a.neighbours.blank?

          zone_a.neighbours.each do |zone_code_b|
            zone_b = country.zone(code: zone_code_b)
            assertion_message =
              "Region #{country.legacy_code} zone A #{zone_a.legacy_code} zone B #{zone_b.legacy_code}"

            assert_predicate zone_b.neighbours, :present?, assertion_message
            assert_includes zone_b.neighbours, zone_a.legacy_code, assertion_message
          end
        end
      end
    end

    test "week_start_day is a valid value" do
      Regions.all.select(&:country?).each do |country|
        week_start_day = country.week_start_day

        valid_values = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

        assert_includes valid_values, week_start_day
      end
    end

    test "unit_system is a valid value" do
      Regions.all.select(&:country?).each do |country|
        unit_system = country.unit_system

        valid_values = ["metric", "imperial"]

        assert_includes valid_values, unit_system
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

    test "priority is an Integer" do
      Regions.all.select(&:province?).each do |province|
        next unless province.priority

        assert_kind_of Integer, province.priority, "Province priority should be an Integer for #{province.inspect}"
      end
    end

    test "example_city is available for each US state" do
      Worldwide.region(code: "US").zones.each do |state|
        # Skip territories that legitimately don't have cities
        next if state.iso_code == "UM" # United States Minor Outlying Islands

        assert_kind_of String, state.example_city, "example_city should be a String for #{state.iso_code}"
        refute_predicate state.example_city, :empty?, "example_city should not be empty for #{state.iso_code}"
      end
    end

    test "example_city_zip is available for each US state" do
      Worldwide.region(code: "US").zones.each do |state|
        # Skip territories that legitimately don't have zip codes
        next if state.iso_code == "UM" # United States Minor Outlying Islands

        assert_kind_of String, state.example_city_zip, "example_city_zip should be a String for #{state.iso_code}"
        refute_predicate state.example_city_zip, :empty?, "example_city_zip should not be empty for #{state.iso_code}"
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
