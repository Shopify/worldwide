# frozen_string_literal: true

require "test_helper"

module Worldwide
  class NgTest < ActiveSupport::TestCase
    setup do
      @region = Worldwide.region(code: "NG")
    end

    test "6-digit zip codes are valid" do
      assert @region.valid_zip?("930283")
      assert @region.valid_zip?("100001")
    end

    test "11-character zip codes are valid in all three input styles" do
      assert @region.valid_zip?("EK-01-A03-FK-01")
      assert @region.valid_zip?("EK 01 A03 FK 01")
      assert @region.valid_zip?("EK01A03FK01")
      assert @region.valid_zip?("ek01a03fk01")
    end

    test "11-character zip codes with digits in the district segment are valid" do
      assert @region.valid_zip?("LA-12-345-AB-99")
    end

    test "11-character zip codes with 00 in the LGA or unit segment are invalid" do
      assert_not @region.valid_zip?("EK-00-A03-FK-01")
      assert_not @region.valid_zip?("EK-01-A03-FK-00")
    end

    test "malformed zip codes are invalid" do
      assert_not @region.valid_zip?("EK-01-A03-FK-1")
      assert_not @region.valid_zip?("EK-01-A03-FK-011")
      assert_not @region.valid_zip?("EK-1-A03-FK-01")
      assert_not @region.valid_zip?("E1-01-A03-FK-01")
      assert_not @region.valid_zip?("EK-01-A03-F1-01")
      assert_not @region.valid_zip?("93028")
      assert_not @region.valid_zip?("9302831")
    end

    test "the zip example is still valid" do
      assert @region.valid_zip?(@region.zip_example)
    end
  end
end
