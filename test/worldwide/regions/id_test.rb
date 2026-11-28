# frozen_string_literal: true

require "test_helper"

module Worldwide
  class IdTest < ActiveSupport::TestCase
    setup do
      @region = Worldwide.region(code: "ID")
    end

    test "Indonesia has 38 provinces" do
      assert_equal 38, @region.zones.count(&:province?)
    end

    test "the provinces created in 2022 can be looked up by code" do
      {
        "PD" => "Papua Barat Daya",
        "PE" => "Papua Pegunungan",
        "PS" => "Papua Selatan",
        "PT" => "Papua Tengah",
      }.each do |code, name|
        zone = @region.zone(code: code)

        assert_equal "ID-#{code}", zone.iso_code
        assert_equal name, zone.legacy_name
      end
    end

    test "the provinces created in 2022 can be looked up by ISO code and by name" do
      assert_equal "PS", @region.zone(code: "ID-PS").legacy_code
      assert_equal "PT", @region.zone(name: "Papua Tengah").legacy_code
    end
  end
end
