# frozen_string_literal: true

require "test_helper"

module Worldwide
  class MtTest < ActiveSupport::TestCase
    setup do
      @region = Worldwide.region(code: "MT")
    end

    test "zip codes with country prefix are valid" do
      assert @region.valid_zip?("MT-VLT 1933")
      assert @region.valid_zip?("MT-VLT1933")
    end

    test "zip codes without country prefix are valid" do
      assert @region.valid_zip?("VLT 1933")
      assert @region.valid_zip?("VLT1933")
    end

    test "two-letter zip codes from Tigné Point are valid" do
      assert @region.valid_zip?("TP 1933")
      assert @region.valid_zip?("TP1933")
    end

    test "other two-letter zip codes are invalid" do
      assert_not @region.valid_zip?("AA 1933")
    end

    test "pre-2007 formatted zip codes are invalid" do
      assert_not @region.valid_zip?("VLT 05")
    end

    test "malformed zip codes are invalid" do
      assert_not @region.valid_zip?("VLT 193")
      assert_not @region.valid_zip?("VLT 19333")
    end
  end
end
