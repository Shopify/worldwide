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

    test "concatenated_address1 returns empty string when neither address1 nor additional address fields are present" do
      nil_address = Address.new(country_code: "BR")
      blank_address = Address.new(address1: "", street_name: "", street_number: "", country_code: "BR")

      assert_equal "", nil_address.concatenated_address1
      assert_equal "", blank_address.concatenated_address1
    end

    test "concatenated_address1 ignores additional address fields if they are not defined for the country" do
      nil_address1 = Address.new(street_name: "Other Street", street_number: "456", country_code: "US")
      blank_address1 = Address.new(address1: "", street_name: "Other Street", street_number: "456", country_code: "US")

      assert_equal "", nil_address1.concatenated_address1
      assert_equal "", blank_address1.concatenated_address1
    end

    test "concatenated_address1 returns address1 when address1 is present" do
      cl_address = Address.new(address1: "Main Street 123", street_name: "Other Street", street_number: "456", country_code: "CL")
      us_address = Address.new(address1: "123 Main Street", street_name: "Other Street", street_number: "456", country_code: "CL")

      assert_equal "Main Street 123", cl_address.concatenated_address1
      assert_equal "123 Main Street", us_address.concatenated_address1
    end

    test "concatenated_address1 returns street name with no delimiter and no decorator when only street name is present" do
      cl_address = Address.new(street_name: "Main Street", country_code: "CL")
      br_address = Address.new(street_name: "Main Street", country_code: "BR")

      assert_equal "Main Street", cl_address.concatenated_address1
      assert_equal "Main Street", br_address.concatenated_address1
    end

    test "concatenated_address1 returns street number prefixed by a delimiter and no decorator when only street number is present" do
      cl_address = Address.new(street_number: "123", country_code: "CL")
      br_address = Address.new(street_number: "123", country_code: "BR")

      assert_equal " 123", cl_address.concatenated_address1
      assert_equal " 123", br_address.concatenated_address1
    end

    test "concatenated_address1 returns street name concatenated with street number separated by delimiter" do
      address = Address.new(street_name: "Main Street", street_number: "123", country_code: "CL")

      assert_equal "Main Street 123", address.concatenated_address1
    end

    test "concatenated_address1 returns street name concatenated with street number separated by delimiter and decorator" do
      address = Address.new(street_name: "Main Street", street_number: "123", country_code: "BR")

      assert_equal "Main Street, 123", address.concatenated_address1
    end

    test "concatenated_address2 returns empty string when neither address2 nor additional address fields are present" do
      nil_address = Address.new(country_code: "BR")
      blank_address = Address.new(address2: "", neighborhood: "", country_code: "BR")

      assert_equal "", nil_address.concatenated_address2
      assert_equal "", blank_address.concatenated_address2
    end

    test "concatenated_address2 ignores additional address fields if they are not defined for the country" do
      nil_address2 = Address.new(neighborhood: "Centretown", country_code: "US")
      blank_address2 = Address.new(address2: "", neighborhood: "Centretown", country_code: "US")

      assert_equal "", nil_address2.concatenated_address2
      assert_equal "", blank_address2.concatenated_address2
    end

    test "concatenated_address2 returns address2 with no delimiters when only address2 is present" do
      cl_address = Address.new(address2: "dpto 4", country_code: "CL")
      br_address = Address.new(address2: "dpto 4", country_code: "BR")

      assert_equal "dpto 4", cl_address.concatenated_address2
      assert_equal "dpto 4", br_address.concatenated_address2
    end

    test "concatenated_address2 returns neighborhood with delimiter when only neighborhood is present" do
      cl_address = Address.new(neighborhood: "Centro", country_code: "CL")
      br_address = Address.new(neighborhood: "Centro", country_code: "BR")

      assert_equal " Centro", cl_address.concatenated_address2
      assert_equal " Centro", br_address.concatenated_address2
    end

    test "concatenated_address2 returns address2 concatenated with neighborhood separated by delimiter" do
      address = Address.new(address2: "dpto 4", neighborhood: "Centro", country_code: "CL")

      assert_equal "dpto 4 Centro", address.concatenated_address2
    end

    test "concatenated_address2 returns address2 concatenated with neighborhood separated by delimiter and decorator" do
      address = Address.new(address2: "dpto 4", neighborhood: "Centro", country_code: "BR")

      assert_equal "dpto 4, Centro", address.concatenated_address2
    end
  end
end
