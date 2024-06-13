# frozen_string_literal: true

require "test_helper"

# Miscellaneous assertions about our files in db/data/regions/??.yml.
# This is intended to catch errors introduced when editing those files.

module Worldwide
  class WorldYmlConsistencyTest < ActiveSupport::TestCase
    setup do
      @raw_yml = YAML.load_file(File.join(Worldwide::Paths::DB_DATA_ROOT, "world.yml"))
    end

    test "every leaf node under '001' is a valid country code" do
      assert_all_leaf_nodes_are_countries(@raw_yml["001"])
    end

    test "no country appears under '001' more than once" do
      values = all_values(@raw_yml["001"])

      duplicated = values.tally.select { |_value, count| count > 1 }.keys

      assert_empty(duplicated, "Values #{duplicated.inspect} appear multiple times under \"001\".")
    end

    test "every tree under 'alternates' has a root that exists under '001" do
      @raw_yml["alternates"].each do |key, _value|
        next if "001" == key

        assert(hash_contains_key?(@raw_yml["001"], key), "Expected alternate #{key.inspect} to exist under \"001\".")
      end
    end

    private

    def all_values(collection)
      if collection.is_a?(Hash)
        result = []
        collection.each do |_key, value|
          result << all_values(value)
        end
        result.flatten
      elsif collection.is_a?(Array)
        collection
      else
        [collection]
      end
    end

    def assert_all_leaf_nodes_are_countries(hash)
      hash.each do |key, value|
        if value.is_a?(Hash)
          assert_all_leaf_nodes_are_countries(value)
        elsif value.is_a?(Array)
          value.each do |country_code|
            region = Worldwide.region(code: country_code)

            next if RegionDataTestHelper::ES_AND_US_DUAL_STATUS_PROVINCES.include?(country_code)
            next if "AQ" == country_code # we don't consider Antarctica to be a country, even though ISO does
            next if "CQ" == country_code # CQ is exceptionally reserved for Sark by ISO, we consider it part of GG

            assert_not_nil(region, "No region found for country_code #{country_code.inspect}.")
            assert_equal(true, region.country?, "Expected #{country_code.inspect} to be a country")
          end
        else
          assert(false, "key #{key.inspect} has unrecognized value #{value.inspect}")
        end
      end
    end

    def hash_contains_key?(hash, key)
      return false unless hash.is_a?(Hash)

      hash.any? do |k, v|
        k == key ||
          (v.is_a?(Hash) && hash_contains_key?(v, key)) ||
          (v.is_a?(Array) && v.include?(key))
      end
    end
  end
end
