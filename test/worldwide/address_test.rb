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

    test "concatenate_address1 returns address1 when additional fields are unset" do
      nil_address = Address.new(country_code: "BR")
      address_with_no_additional_fields = Address.new(address1: "123 Main Street", country_code: "BR")
      address_with_nil_additional_fields = Address.new(address1: "123 Main Street", street_name: nil, street_number: nil, country_code: "BR")

      assert_nil nil_address.concatenate_address1
      assert_equal "123 Main Street", address_with_no_additional_fields.concatenate_address1
      assert_equal "123 Main Street", address_with_nil_additional_fields.concatenate_address1
    end

    test "concatenate_address1 ignores additional fields if they are not defined for the country" do
      nil_address1 = Address.new(street_name: "Other Street", street_number: "456", country_code: "US")
      blank_address1 = Address.new(address1: "", street_name: "Other Street", street_number: "456", country_code: "US")

      assert_nil nil_address1.concatenate_address1
      assert_equal "", blank_address1.concatenate_address1
    end

    test "concatenate_address1 ignores address1 when some additional fields are not nil" do
      empty_street_name = Address.new(address1: "123 Main Street", street_name: "", country_code: "BR")

      assert_equal "", empty_street_name.concatenate_address1
    end

    test "concatenate_address1 does not return delimiters for empty additional fields" do
      empty_street_name = Address.new(street_name: "", street_number: "", country_code: "BR")

      assert_equal "", empty_street_name.concatenate_address1
    end

    test "concatenate_address1 returns street name with no delimiter and no decorator when only street name is present" do
      cl_address = Address.new(street_name: "Main Street", country_code: "CL")
      br_address = Address.new(street_name: "Main Street", country_code: "BR")

      assert_equal "Main Street", cl_address.concatenate_address1
      assert_equal "Main Street", br_address.concatenate_address1
    end

    test "concatenate_address1 returns street number prefixed by a delimiter and no decorator when only street number is present" do
      cl_address = Address.new(street_number: "123", country_code: "CL")
      br_address = Address.new(street_number: "123", country_code: "BR")

      assert_equal "⁠123", cl_address.concatenate_address1
      assert_equal "⁠123", br_address.concatenate_address1
    end

    test "concatenate_address1 returns street name concatenated with street number separated by delimiter" do
      Worldwide::Region.any_instance.stubs(:combined_address_format).returns(
        { "default" => { "address1" => [{ "key" => "street_name" }, { "key" => "street_number" }] } },
      )
      address = Address.new(street_name: "文林路", street_number: "88號", country_code: "TW")

      assert_equal "文林路⁠88號", address.concatenate_address1
    end

    test "concatenate_address1 returns street name concatenated with street number separated by delimiter and decorator" do
      address = Address.new(street_name: "Main Street", street_number: "123", country_code: "BR")

      assert_equal "Main Street, ⁠123", address.concatenate_address1
    end

    # mock conctenation rules as we don't currently have a country that fits this use case
    test "concatenate_address1 returns a concatenated string with default script-specific formatting" do
      mock_address1_concat_rules
      address = Address.new(street_number: "30號", street_name: "水杉道", country_code: "TW")

      assert_equal "水杉道⁠30號", address.concatenate_address1
    end

    test "concatenate_address1 returns a concatenated string with script-specific formatting when alt script is detected" do
      mock_address1_concat_rules
      address = Address.new(street_number: "No. 3", street_name: "Water Fir Ave", country_code: "TW")

      assert_equal "Water Fir Ave ⁠No. 3", address.concatenate_address1
    end

    test "concatenate_address1 returns a concatenated string with default script-specific formatting when no script is detected" do
      mock_address1_concat_rules
      address = Address.new(street_number: "5", street_name: "", country_code: "TW")

      assert_equal "⁠5", address.concatenate_address1
    end

    test "concatenate_address1 returns a concatenated string with default script-specific formatting when multiple scripts are detected" do
      mock_address1_concat_rules
      address = Address.new(street_number: "No. 3", street_name: "水杉道", country_code: "TW")

      assert_equal "水杉道⁠No. 3", address.concatenate_address1
    end

    test "concatenate_address2 returns address2 when additional fields are unset" do
      nil_address = Address.new(country_code: "BR")
      address_with_no_additional_fields = Address.new(address2: "Centretown", country_code: "BR")
      address_with_nil_additional_fields = Address.new(address2: "Centretown", line2: nil, neighborhood: nil, country_code: "BR")

      assert_nil nil_address.concatenate_address2
      assert_equal "Centretown", address_with_no_additional_fields.concatenate_address2
      assert_equal "Centretown", address_with_nil_additional_fields.concatenate_address2
    end

    test "concatenate_address2 ignores additional address fields if they are not defined for the country" do
      nil_address2 = Address.new(neighborhood: "Centretown", country_code: "US")
      blank_address2 = Address.new(address2: "", line2: "#2", neighborhood: "Centretown", country_code: "US")

      assert_nil nil_address2.concatenate_address2
      assert_equal "", blank_address2.concatenate_address2
    end

    test "concatenate_address2 ignores address2 when some additional fields are not nil" do
      empty_street_name = Address.new(address2: "Centertown", line2: "", country_code: "BR")

      assert_equal "", empty_street_name.concatenate_address2
    end

    test "concatenate_address2 does not return delimiters for empty additional fields" do
      empty_street_name = Address.new(line2: "", neighborhood: "", country_code: "BR")

      assert_equal "", empty_street_name.concatenate_address2
    end

    test "concatenate_address2 returns address2 with no delimiters when only line2 is present" do
      cl_address = Address.new(line2: "dpto 4", country_code: "CL")
      br_address = Address.new(line2: "dpto 4", country_code: "BR")

      assert_equal "dpto 4", cl_address.concatenate_address2
      assert_equal "dpto 4", br_address.concatenate_address2
    end

    test "concatenate_address2 returns neighborhood with delimiter when only neighborhood is present" do
      cl_address = Address.new(neighborhood: "Centro", country_code: "CL")
      br_address = Address.new(neighborhood: "Centro", country_code: "BR")

      assert_equal "⁠Centro", cl_address.concatenate_address2
      assert_equal "⁠Centro", br_address.concatenate_address2
    end

    test "concatenate_address2 returns line2 concatenated with neighborhood separated by delimiter" do
      address = Address.new(line2: "1樓", neighborhood: "士林區", country_code: "TW")

      assert_equal "1樓⁠士林區", address.concatenate_address2
    end

    test "concatenate_address2 returns line2 concatenated with neighborhood separated by delimiter and decorator" do
      br_address = Address.new(line2: "dpto 4", neighborhood: "Centro", country_code: "BR")
      ph_address = Address.new(line2: "apt 4", neighborhood: "294", country_code: "PH")
      vn_address = Address.new(line2: "apt 4", neighborhood: "Cầu Giấy", country_code: "VN")

      assert_equal "dpto 4, ⁠Centro", br_address.concatenate_address2
      assert_equal "apt 4 ⁠294", ph_address.concatenate_address2
      assert_equal "apt 4, ⁠Cầu Giấy", vn_address.concatenate_address2
    end

    test "concatenate_address2 returns a concatenated string with default script-specific formatting" do
      address = Address.new(line2: "30號", neighborhood: "大甲區", country_code: "TW")

      assert_equal "30號⁠大甲區", address.concatenate_address2
    end

    test "concatenate_address2 returns a concatenated string with script-specific formatting when alt script is detected" do
      address = Address.new(line2: "No. 3", neighborhood: "Daija District", country_code: "TW")

      assert_equal "No. 3, ⁠Daija District", address.concatenate_address2
    end

    test "concatenate_address2 returns a concatenated string with default script-specific formatting when no script is detected" do
      address = Address.new(line2: "5", neighborhood: "", country_code: "TW")

      assert_equal "5", address.concatenate_address2
    end

    test "concatenate_address2 returns a concatenated string with default script-specific formatting when multiple scripts are detected" do
      address = Address.new(line2: "No. 3", neighborhood: "大甲區", country_code: "TW")

      assert_equal "No. 3⁠大甲區", address.concatenate_address2
    end

    test "split_address1 returns nil when additional address fields are not defined for the country" do
      address = Address.new(address1: "123 Main Street", country_code: "US")

      assert_nil address.split_address1
    end

    test "split_address1 returns blank fields when address1 is blank" do
      blank_address1 = Address.new(address1: "", country_code: "CL") # regular space
      nil_address1 = Address.new(address1: nil, country_code: "CL") # regular space

      expected_hash = {}

      assert_equal expected_hash, blank_address1.split_address1
      assert_equal expected_hash, nil_address1.split_address1
    end

    test "split_address1 returns entire address1 as street when address1 does not contain a delimiter" do
      address = Address.new(address1: "Main Street 123", country_code: "CL") # regular space
      expected_hash = { "street_name" => "Main Street 123" }

      assert_equal expected_hash, address.split_address1
    end

    test "split_address1 splits on the first delimiter" do
      address = Address.new(address1: "Main Street⁠123⁠ n° 145", country_code: "BR")
      expected_hash = { "street_name" => "Main Street", "street_number" => "123⁠ n° 145" }

      assert_equal expected_hash, address.split_address1
    end

    test "split_address1 returns only street number if no string is present before the delimiter" do
      cl_address = Address.new(address1: "⁠123", country_code: "CL")
      br_address = Address.new(address1: "⁠123", country_code: "BR")
      expected_hash = { "street_number" => "123" }

      assert_equal expected_hash, cl_address.split_address1
      assert_equal expected_hash, br_address.split_address1
    end

    test "split_address1 returns street name and street number when both values are present and separated by a delimiter" do
      Worldwide::Region.any_instance.stubs(:combined_address_format).returns(
        { "default" => { "address1" => [{ "key" => "street_name" }, { "key" => "street_number" }] } },
      )
      address = Address.new(address1: "文林路⁠88號", country_code: "TW")
      expected_hash = { "street_name" => "文林路", "street_number" => "88號" }

      assert_equal expected_hash, address.split_address1
    end

    test "split_address1 returns street name and street number when both values are present and separated by a delimiter and decorator" do
      address = Address.new(address1: "Main Street, ⁠123", country_code: "BR")
      expected_hash = { "street_name" => "Main Street", "street_number" => "123" }

      assert_equal expected_hash, address.split_address1
    end

    test "split_address1 returns street name and street number when delimiter is present but decorator is missing" do
      address = Address.new(address1: "Main Street⁠123", country_code: "BR")
      expected_hash = { "street_name" => "Main Street", "street_number" => "123" }

      assert_equal expected_hash, address.split_address1
    end

    # mock conctenation rules as we don't currently have a country that fits this use case
    test "split_address1 returns street name and street number based on default script-specific formatting" do
      mock_address1_concat_rules
      address = Address.new(address1: "水杉道⁠30號", country_code: "TW")
      expected_hash = { "street_name" => "水杉道", "street_number" => "30號" }

      assert_equal expected_hash, address.split_address1
    end

    test "split_address1 returns street name and street number based on default script-specific formatting when multiple scripts are detected" do
      mock_address1_concat_rules
      address = Address.new(address1: "水杉道⁠No. 3", country_code: "TW")
      expected_hash = { "street_name" => "水杉道", "street_number" => "No. 3" }

      assert_equal expected_hash, address.split_address1
    end

    test "split_address1 returns returns fields based on default script-specific formatting when no script is detected" do
      mock_address1_concat_rules
      address = Address.new(address1: "⁠5", country_code: "TW")
      expected_hash = { "street_number" => "5" }

      assert_equal expected_hash, address.split_address1
    end

    test "split_address1 returns street name and street number based on script-specific formatting when alt script is detected" do
      mock_address1_concat_rules
      address = Address.new(address1: "Water Fir Ave ⁠No. 3", country_code: "TW")
      expected_hash = { "street_number" => "No. 3", "street_name" => "Water Fir Ave" }

      assert_equal expected_hash, address.split_address1
    end

    test "split_address2 returns nil when additional address fields are not defined for the country" do
      address = Address.new(address2: "apt 4, Centretown", country_code: "US")

      assert_nil address.split_address2
    end

    test "split_address2 returns blank fields when when address2 is blank" do
      blank_address2 = Address.new(address2: "", country_code: "CL") # regular space
      nil_address2 = Address.new(address2: nil, country_code: "CL") # regular space

      expected_hash = {}

      assert_equal expected_hash, blank_address2.split_address2
      assert_equal expected_hash, nil_address2.split_address2
    end

    test "split_address2 returns only line2 when address2 does not contain a delimiter" do
      address = Address.new(address2: "dpto 4", country_code: "CL") # regular space
      expected_hash = { "line2" => "dpto 4" }

      assert_equal expected_hash, address.split_address2
    end

    test "split_address2 returns only neighborhood if no string is present before the delimiter" do
      cl_address = Address.new(address2: "⁠Centro", country_code: "CL")
      br_address = Address.new(address2: "⁠Centro", country_code: "BR")
      expected_hash = { "neighborhood" => "Centro" }

      assert_equal expected_hash, cl_address.split_address2
      assert_equal expected_hash, br_address.split_address2
    end

    test "split_address2 splits on the first delimiter" do
      address = Address.new(address2: "1樓⁠士林區⁠123", country_code: "TW")
      expected_hash = { "line2" => "1樓", "neighborhood" => "士林區⁠123" }

      assert_equal expected_hash, address.split_address2
    end

    test "split_address2 returns line2 and neighborhood when both values are present and separated by a delimiter" do
      cl_address = Address.new(address2: "1樓⁠士林區", country_code: "TW")
      expected_hash = { "line2" => "1樓", "neighborhood" => "士林區" }

      assert_equal expected_hash, cl_address.split_address2
    end

    test "split_address2 returns line2 and neighborhood when both values are present and separated by a delimiter and a decorator" do
      br_address = Address.new(address2: "dpto 4, ⁠Centro", country_code: "BR")
      ph_address = Address.new(address2: "dpto 4 ⁠294", country_code: "PH")
      expected_hash_br = { "line2" => "dpto 4", "neighborhood" => "Centro" }
      expected_hash_ph = { "line2" => "dpto 4", "neighborhood" => "294" }

      assert_equal expected_hash_br, br_address.split_address2
      assert_equal expected_hash_ph, ph_address.split_address2
    end

    test "split_address2 returns line2 and neighborhood when delimiter is present but decorator is missing" do
      address = Address.new(address2: "dpto 4⁠Centro", country_code: "BR")
      expected_hash = { "line2" => "dpto 4", "neighborhood" => "Centro" }

      assert_equal expected_hash, address.split_address2
    end

    test "split_address2 returns line2 and neighborhood based on default script-specific formatting" do
      address = Address.new(address2: "30號⁠大甲區", country_code: "TW")
      expected_hash = { "line2" => "30號", "neighborhood" => "大甲區" }

      assert_equal expected_hash, address.split_address2
    end

    test "split_address2 returns line2 and neighborhood based on default script-specific formatting when multiple scripts are detected" do
      address = Address.new(address2: "No. 3⁠大甲區", country_code: "TW")
      expected_hash = { "line2" => "No. 3", "neighborhood" => "大甲區" }

      assert_equal expected_hash, address.split_address2
    end

    test "split_address2 returns returns fields based on default script-specific formatting when no script is detected" do
      address = Address.new(address2: "5", country_code: "TW")
      expected_hash = { "line2" => "5" }

      assert_equal expected_hash, address.split_address2
    end

    test "split_address2 returns line2 and neighborhood based on script-specific formatting when alt script is detected" do
      address = Address.new(address2: "No. 3, ⁠Daija District", country_code: "TW")
      expected_hash = { "line2" => "No. 3", "neighborhood" => "Daija District" }

      assert_equal expected_hash, address.split_address2
    end

    private

    def mock_address1_concat_rules
      Region.any_instance.stubs(:combined_address_format).returns({
        "default" => {
          "address1" => [
            { "key" => "streetName" },
            { "key" => "streetNumber" },
          ],
        },
        "Latin" => {
          "address1" => [
            { "key" => "streetName" },
            { "key" => "streetNumber", "decorator" => " " },
          ],
        },
      })
    end
  end
end
