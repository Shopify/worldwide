# frozen_string_literal: true

require "test_helper"

module Worldwide
  class LuTest < ActiveSupport::TestCase
    setup do
      @region = Worldwide.region(code: "LU")
    end

    test "standard postal codes are valid" do
      assert @region.valid_zip?("4750")
      assert @region.valid_zip?("1728")
    end

    test "postal codes starting with zero are valid" do
      # Postal codes starting with 0 are used for packstations/parcel lockers
      assert @region.valid_zip?("0692")
      assert @region.valid_zip?("0001")
    end

    test "postal codes with L prefix are valid" do
      assert @region.valid_zip?("L-4750")
      assert @region.valid_zip?("L-0692")
      assert @region.valid_zip?("L4750")
    end

    test "postal codes with LU prefix are valid" do
      assert @region.valid_zip?("LU-4750")
      assert @region.valid_zip?("LU-0692")
      assert @region.valid_zip?("LU4750")
    end

    test "postal codes with wrong length are invalid" do
      assert_not @region.valid_zip?("475")
      assert_not @region.valid_zip?("47500")
    end
  end
end
