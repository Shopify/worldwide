# frozen_string_literal: true

require "test_helper"

module Worldwide
  class AddressTest < ActiveSupport::TestCase
    test "can initialize an Address and read its values" do
      given_name = "John"
      surname = "Smith"
      firm = "ACME Widgets Inc."
      address1 = "123 Main Street"
      address2 = "Suite 4"
      city = "Ottawa"
      province_code = "ON"
      country_code = "CA"
      zip = "K1S 5P4"

      address = Address.new(
        first_name: given_name,
        last_name: surname,
        company: firm,
        address1: address1,
        address2: address2,
        city: city,
        province_code: province_code,
        country_code: country_code,
        zip: zip,
      )

      assert_equal given_name, address.first_name
      assert_equal surname, address.last_name
      assert_equal firm, address.company
      assert_equal address1, address.address1
      assert_equal address2, address.address2
      assert_equal city, address.city
      assert_equal province_code, address.province_code
      assert_equal country_code, address.country_code
      assert_equal zip, address.zip
    end

    test "omitted parameters default to `nil`, except for country_code" do
      address = Address.new

      assert_nil address.first_name
      assert_nil address.last_name
      assert_nil address.company
      assert_nil address.address1
      assert_nil address.address2
      assert_nil address.city
      assert_nil address.province_code
      assert_nil address.zip
      assert_equal "ZZ", address.country_code
    end

    focus
    test "generate_address1 when given street and building number, with decorators, append only" do
      address = Address.new(street: "Main Street", building_number: "123", country_code: "BR")

      assert_equal "Main Street, 123", address.generate_address1
    end
  end
end
