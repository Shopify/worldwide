# frozen_string_literal: true

require "test_helper"

module Worldwide
  class LocalizationKeysTest < ActiveSupport::TestCase
    test "can initialize a localization key and read its values" do
      data = {
        "address1" => "nearest_tree",
        "street_name" => "route",
        "street_number" => "house_number",
        "address2" => "nearest_rock",
        "neighborhood" => "suburb",
        "city" => "town",
        "company" => "society",
        "country" => "kingdom",
        "first_name" => "given_name",
        "last_name" => "family_name",
        "phone" => "pager",
        "postal_code" => "tax_collector",
        "zone" => "duchy",
      }

      localization_keys = LocalizationKeys.new(data)

      assert_equal "nearest_tree", localization_keys.address1
      assert_equal "route", localization_keys.street_name
      assert_equal "house_number", localization_keys.street_number
      assert_equal "nearest_rock", localization_keys.address2
      assert_equal "suburb", localization_keys.neighborhood
      assert_equal "town", localization_keys.city
      assert_equal "society", localization_keys.company
      assert_equal "kingdom", localization_keys.country
      assert_equal "given_name", localization_keys.first_name
      assert_equal "family_name", localization_keys.last_name
      assert_equal "pager", localization_keys.phone
      assert_equal "tax_collector", localization_keys.postal_code
      assert_equal "duchy", localization_keys.zone
      assert_equal data, localization_keys.to_h
    end

    test "omitted parameters default to `nil`" do
      data = { "city" => "town" }

      localization_keys = LocalizationKeys.new(data)

      assert_nil localization_keys.address1
      assert_nil localization_keys.street_name
      assert_nil localization_keys.street_number
      assert_nil localization_keys.address2
      assert_nil localization_keys.neighborhood
      assert_nil localization_keys.company
      assert_nil localization_keys.country
      assert_nil localization_keys.first_name
      assert_nil localization_keys.last_name
      assert_nil localization_keys.phone
      assert_nil localization_keys.postal_code
      assert_nil localization_keys.zone

      assert_equal "town", localization_keys.city
      assert_equal data, localization_keys.to_h
    end
  end
end
