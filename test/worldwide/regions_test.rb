# frozen_string_literal: true

require "test_helper"

module Worldwide
  class RegionsTest < ActiveSupport::TestCase
    test "Can look up a region by alpha2 iso_code" do
      ["CA", "ca", :CA, :ca].each do |code|
        ca = Worldwide.region(code: code)

        assert_equal "Canada", ca.legacy_name
        assert_equal 13, ca.zones.count
        assert_equal "Ontario", ca.zone(code: "ON").legacy_name
      end
    end

    test "Can look up a province by iso_code" do
      ["CA-ON", :"CA-ON", "ca-on", :"ca-on"].each do |code|
        ontario = Worldwide.region(code: code)
        context = "Constructed using code #{code.inspect}"

        assert_not_nil ontario, context
        assert_equal "Ontario", ontario.legacy_name, context
        assert_equal "Ontario", ontario.full_name(locale: "en-US"), context
        assert_equal "オンタリオ州", ontario.full_name(locale: "ja"), context
      end
    end

    test "Can look up a region by cldr_code" do
      [
        ["ca", 13, "Canada", "Alberta"],
        [:ca, 13, "Canada", "Alberta"],
        ["are", 0, "Entre Ríos", nil],
        [:are, 0, "Entre Ríos", nil],
      ].each do |code, zones_count, name, zone_name|
        region = Worldwide.region(cldr: code)

        assert_equal name, region.legacy_name
        assert_equal zones_count, region.zones.count

        if zone_name.present?
          assert_equal zone_name, region.zones.first&.legacy_name
        else
          assert_nil region.zones.first&.legacy_name
        end
      end
    end

    test "Can look up a province by cldr_code" do
      [
        ["caon", "Ontario", "オンタリオ州"],
        [:caon, "Ontario", "オンタリオ州"],
        ["jp14", "Kanagawa", "神奈川県"],
        [:jp14, "Kanagawa", "神奈川県"],
        ["are", "Entre Ríos", "エントレ・リオス州"],
        [:are, "Entre Ríos", "エントレ・リオス州"],
      ].each do |code, name, japanese_name|
        region = Worldwide.region(cldr: code)
        context = "Constructed using code #{code.inspect}"

        assert_not_nil region, context
        assert_equal name, region.legacy_name, context
        assert_equal name, region.full_name(locale: "en-US"), context
        assert_equal japanese_name, region.full_name(locale: "ja"), context
      end
    end

    test "Can look up a region by alpha3 code" do
      ad = Worldwide.region(code: "AND")

      assert_equal "Andorra", ad.legacy_name
      assert_equal "AD", ad.iso_code
      assert_empty ad.zones
    end

    test "Can look up a region by numeric3 code" do
      de = Worldwide.region(code: "DE")

      assert_equal "Germany", de.legacy_name
      assert_equal "DE", de.iso_code
      assert_empty de.zones
    end

    test "Can look up a province" do
      ny = Worldwide.region(code: "US-NY")

      assert_equal "New York", ny.legacy_name
      assert_equal "NY", ny.legacy_code
    end

    test "Can look up a region by name" do
      legacy_name = "Canada"
      scenarios = {
        en: "Canada",
        de: "Kanada",
        ja: "カナダ",
      }

      scenarios.each do |locale, localized_name|
        I18n.with_locale(locale) do
          assert_equal "CA", Worldwide.region(name: localized_name).iso_code, "locale #{locale} localized"
          assert_equal "CA", Worldwide.region(name: legacy_name).iso_code, "locale #{locale} legacy"
        end
      end
    end

    test "Look up with both code and name raises" do
      assert_raises ArgumentError do
        Worldwide.region(code: "CA", name: "Canada")
      end
    end

    test "Look up with neither code nor name raises" do
      assert_raises ArgumentError do
        Worldwide.region
      end
    end

    test "Regions.all includes both countries and provinces" do
      iso_codes = Worldwide::Regions.all.map(&:iso_code)

      assert_includes iso_codes, "AD"
      assert_includes iso_codes, "US"
      assert_includes iso_codes, "US-NY"
    end

    test "Looking up a region that does not exist returns the unknown region ZZ" do
      assert_equal "ZZ", Worldwide.region(code: "bogus-does-not-exist").iso_code
      assert_equal "ZZ", Worldwide.region(code: "CA").zone(code: "bogus-does-not-exist").iso_code
    end
  end
end
