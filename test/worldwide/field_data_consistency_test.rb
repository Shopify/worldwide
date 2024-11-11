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

    test "All label overrides have a matching \"optional\" version" do
      override_file_paths = Dir.glob(File.join(["data", "regions", "*", "*.yml"])).sort

      override_file_paths.each do |file_path|
        overrides = flatten_hash(YAML.safe_load_file(file_path))

        default_labels = overrides.select { |key, _value| key[-2..] == ["label", "default"] }
        optional_labels = overrides.select { |key, _value| key[-2..] == ["label", "optional"] }

        default_label_keys = default_labels.keys.map { |key| key[0...-2] }
        optional_label_keys = optional_labels.keys.map { |key| key[0...-2] }

        missing_optional_versions = default_label_keys - optional_label_keys

        assert_empty(missing_optional_versions, "Missing `optional` version of #{missing_optional_versions}")

        missing_default_versions = optional_label_keys - default_label_keys

        assert_empty(missing_optional_versions, "Missing `default` version of #{missing_default_versions}")

        default_labels.each do |key, value|
          optional_key = key[0...-1] + ["optional"]

          # TODO: https://github.com/Shopify/worldwide/issues/305
          next if file_path.include?("JP") && file_path.include?("th.yml")

          assert_not_equal(value, optional_labels[optional_key], "Expected that the label for `#{key[-3]}` and its optional version in `#{file_path}` would differ. Instead found that they both are: `#{value}`")
          # TODO: https://github.com/Shopify/worldwide/issues/304
          next if file_path.include?("AE") && file_path.include?("ko.yml")

          # TODO: https://github.com/Shopify/worldwide/issues/306
          next if file_path.include?("AR") && file_path.include?("el.yml")

          # TODO: https://github.com/Shopify/worldwide/issues/307
          next if file_path.include?("AU") && file_path.include?("el.yml")

          # TODO: https://github.com/Shopify/worldwide/issues/308
          next if file_path.include?("AU") && file_path.include?("hr.yml")

          assert(
            differ_only_in_contents_of_parens(value, optional_labels[optional_key]) ||
            differ_only_in_optionality(value, optional_labels[optional_key]),
            "Expected that the label for `#{key[-3]}` and its optional version in `#{file_path}` would only differ by the contents of the parentheses. Instead found:\n\t default: #{value}\n\toptional: #{optional_labels[optional_key]}",
          )
        end
      rescue StandardError => e
        raise StandardError, "Had a problem while analyzing `#{file_path}`: #{e}"
      end
    end

    private

    def flatten_hash(hash, output = {}, parent_key = [])
      raise ArgumentError("Expected a hash") unless hash.is_a?(Hash)

      hash.keys.each do |key|
        current_key = parent_key + [key]

        if hash[key].is_a?(Hash)
          flatten_hash(hash[key], output, current_key)
        else
          output[current_key] = hash[key]
        end
      end

      output
    end

    def differ_only_in_contents_of_parens(default, optional)
      default.casecmp(optional.gsub(/ ?[\(（].*?[\)）]/, ""))
    end

    # For one label, our Korean translator has opted for a phrasing that already has paretheses in the core text.
    # This means that the (optional) phrasing shares the same parentheses, after a comma.
    # In order to avoid failing the test on that label, we need to explicitly search for ", optional" in Korean.
    def differ_only_in_optionality(default, optional)
      default == optional.gsub(/, 선택 사항/, "")
    end

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
