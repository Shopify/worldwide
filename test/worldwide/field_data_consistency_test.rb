# frozen_string_literal: true

require "test_helper"

# Assertions that field translation data follows expected patterns

module Worldwide
  class FieldDataConsistencyTest < ActiveSupport::TestCase
    test "every file has the expected top-level keys" do
      Dir["#{Worldwide::Paths::REGIONS_ROOT}/??/*.yml"].each do |file_name|
        sanity_check_file(file_name)
      end

      Dir["#{Worldwide::Paths::REGIONS_ROOT}/_default/*.yml"].each do |file_name|
        sanity_check_file(file_name)
      end
    end

    private

    def sanity_check_file(file_name)
      permitted_keys = ["autofill", "label", "label_optional", "errors", "warnings"]

      locale = file_name.split("/").last.split(".").first
      country_code = file_name.split("/")[-2]

      y = YAML.load_file(file_name)

      assert_not_nil(y[locale])
      assert_not_nil(y[locale]["worldwide"])
      assert_not_nil(y[locale]["worldwide"][country_code])
      assert_not_nil(y[locale]["worldwide"][country_code]["addresses"])

      y[locale]["worldwide"][country_code]["addresses"].each do |key, value|
        assert_includes(Field::VALID_KEYS, key.to_sym, "File #{file_name}")

        value.keys.each do |key|
          assert_includes(permitted_keys, key)
        end
      end
    end
  end
end
