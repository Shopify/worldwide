# frozen_string_literal: true

require "test_helper"

module Worldwide
  class PtTest < ActiveSupport::TestCase
    setup do
      @region = Worldwide.region(code: "PT")
    end

    test "seven digit postal codes are valid" do
      assert @region.valid_zip?("1234-567")
    end

    test "hypen is optional in valid postal codes" do
      assert @region.valid_zip?("1234567")
    end

    test "leading country code in postal code is valid" do
      assert @region.valid_zip?("PT-1234-567")
    end

    test "four digit postal codes are invalid" do
      assert_not @region.valid_zip?("1234")
    end
  end
end
