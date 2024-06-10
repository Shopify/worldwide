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

        assert_instructional_informative_error_messages(value["errors"], file_name, key)
      end
    end

    def assert_instructional_informative_error_messages(errors, file_name, field_key)
      return if errors.nil?
      return unless file_name.end_with?("en.yml")

      errors.keys.each do |error_key|
        assert_msg = "Translation: " + file_name + " -- field_key: " + field_key + " -- error_key: " + error_key

        # rubocop:disable Minitest/AssertWithExpectedArgument
        assert(error_key.end_with?("_instructional", "_informative"), assert_msg)
        # rubocop:enable Minitest/AssertWithExpectedArgument
      end
    end
  end
end
