# frozen_string_literal: true

require "test_helper"

module Worldwide
  class AddressNormalizationTest < ActiveSupport::TestCase
    test "normalize fixes Canadian address" do
      typo_address = Worldwide.address(
        first_name: "John",
        last_name: "Doe",
        address1: "2410 Southvale Crescent",
        city: "Ottawa",
        # province_code is missing
        zip: "k18sk2", # 8 should be B, s should be 5
        country_code: "CA",
        phone: "6137361058",
      )

      normalized = typo_address.normalize

      [:first_name, :last_name, :address1, :city, :country_code].each do |field|
        assert_equal typo_address.send(field), normalized.send(field)
      end

      assert_equal "ON", normalized.province_code # inferred from the zip
      assert_equal "K1B 5K2", normalized.zip
      assert_equal "(613) 736-1058", normalized.phone # domestic format because it's a domestic number
    end

    test "normalize fixes the country code for a high-confidence case" do
      address = Worldwide.address(
        first_name: "John",
        last_name: "Smith",
        address1: "The Weighbridge",
        city: "St. Helier",
        zip: "JE2 3 NG", # extraneous space
        country_code: "GB", # "United Kingdom", but should be "Jersey"
      )

      normalized = address.normalize

      [:first_name, :last_name, :address1, :city].each do |field|
        assert_equal address.send(field), normalized.send(field)
      end

      assert_nil normalized.province_code
      assert_equal "JE2 3NG", normalized.zip
      assert_equal "JE", normalized.country_code
      assert_nil normalized.phone
    end

    test "normalize fixes the country for a mid-confidence case, but only when autocorrect level is increased" do
      address = Worldwide.address(
        first_name: "Scarlett",
        last_name: "O'Hara",
        address1: "181 Peachtree Street",
        city: "Atlanta",
        country_code: "GE", # should be US-GA, the "other" Georgia
        zip: "30303",
        phone: "404-659-0400",
      )

      tentative = address.normalize
      aggressive = address.normalize(autocorrect_level: 9)

      # first_name, last_name, address1, address2, and city should be untouched either way
      [:first_name, :last_name, :address1, :city].each do |field|
        assert_equal address.send(field), tentative.send(field)
        assert_equal address.send(field), aggressive.send(field)
      end
      assert_nil tentative.address2
      assert_nil aggressive.address2

      # province_code and country_code should be untouched after tentative normalization
      assert_nil tentative.province_code
      assert_equal "GE", tentative.country_code

      # province_code and country_code should be corrected after aggressive normalization
      assert_equal "GA", aggressive.province_code
      assert_equal "US", aggressive.country_code

      # phone should be untouched (because not valid) after tentative normalization
      assert_equal address.phone, tentative.phone

      # phone should be reformatted in US domestic style after aggressive normalization
      assert_equal "(404) 659-0400", aggressive.phone
    end

    test "normalize autofills the city and zip if applicable" do
      address = Worldwide.address(address1: "The Convent", address2: "285 Main Street", country_code: "GI")

      normalized = address.normalize

      assert_equal address.address1, normalized.address1
      assert_equal address.address2, normalized.address2
      assert_equal "Gibraltar", normalized.city
      assert_equal "GX11 1AA", normalized.zip
      assert_nil normalized.province_code
      assert_equal address.country_code, normalized.country_code
    end

    test "normalize formats phone as international if it's in a different country" do
      address = Worldwide.address(
        first_name: "H.S.H.",
        last_name: "Hans-Adam II",
        address1: "Bergstrasse 2",
        zip: "9490",
        city: "Vaduz",
        country_code: "LI",
        phone: "+431795570",
      )

      normalized = address.normalize

      [:first_name, :last_name, :address1, :zip, :city, :country_code].each do |field|
        assert_equal address.send(field), normalized.send(field)
      end

      assert_equal "+43 1 795570", normalized.phone
    end

    test "normalize formats phone as domestic if it's in the same country" do
      address = Worldwide.address(
        address1: "Falkenstrasse 1",
        zip: "8001",
        city: "Zürich",
        country_code: "CH",
        phone: "+41442686666",
      )

      normalized = address.normalize

      [:address1, :zip, :city, :country_code].each do |field|
        assert_equal address.send(field), normalized.send(field)
      end

      assert_equal "044 268 66 66", normalized.phone
    end
  end
end
