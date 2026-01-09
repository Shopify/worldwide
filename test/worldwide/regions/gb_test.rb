# frozen_string_literal: true

require "test_helper"

module Worldwide
  class GbTest < ActiveSupport::TestCase
    setup do
      @region = Worldwide.region(code: "GB")
    end

    # Valid UK outward code formats:
    # A9   (e.g., M1)
    # A99  (e.g., M60)
    # A9A  (e.g., W1A)
    # AA9  (e.g., SW1)
    # AA99 (e.g., SW19)
    # AA9A (e.g., EC1A)

    test "valid A9 format postcodes are accepted" do
      assert @region.valid_zip?("M1 4SQ")
      assert @region.valid_zip?("B1 1AA")
    end

    test "valid A99 format postcodes are accepted" do
      assert @region.valid_zip?("M60 2LA")
      assert @region.valid_zip?("B99 1AA")
    end

    test "valid A9A format postcodes are accepted" do
      assert @region.valid_zip?("W1A 0AX")
      assert @region.valid_zip?("E1W 3SS")
    end

    test "valid AA9 format postcodes are accepted" do
      assert @region.valid_zip?("SW1 4SQ")
      assert @region.valid_zip?("NW1 0AA")
    end

    test "valid AA99 format postcodes are accepted" do
      assert @region.valid_zip?("SW19 1AA")
      assert @region.valid_zip?("SE22 8DL")
      assert @region.valid_zip?("KT11 2JH")
    end

    test "valid AA9A format postcodes are accepted" do
      assert @region.valid_zip?("EC1A 1BB")
      assert @region.valid_zip?("SW1A 1AA")
    end

    test "invalid AA99A format postcodes are rejected" do
      # This is the bug we are fixing: "KT11X" has format AA99A which is not a valid UK outward code
      assert_not @region.valid_zip?("KT11X 2JH")
      assert_not @region.valid_zip?("SW19A 1AA")
      assert_not @region.valid_zip?("AB12C 3DE")
    end

    test "invalid A99A format postcodes are rejected" do
      # A99A format (1 letter + 2 digits + 1 letter in outward code) is not valid
      assert_not @region.valid_zip?("M32X 0AS")
      assert_not @region.valid_zip?("B99X 1AA")
    end

    test "postcodes without space are accepted" do
      assert @region.valid_zip?("SW1A1AA")
      assert @region.valid_zip?("M14SQ")
    end

    test "lowercase postcodes are accepted" do
      assert @region.valid_zip?("sw1a 1aa")
      assert @region.valid_zip?("m1 4sq")
    end
  end
end
