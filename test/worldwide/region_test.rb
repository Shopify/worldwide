# frozen_string_literal: true

require "test_helper"

module Worldwide
  class RegionTest < ActiveSupport::TestCase
    test "#initialize with only iso_code" do
      region = Region.new(iso_code: "ZZ")

      assert_nil region.alpha_three
      assert_equal false, region.continent?
      assert_equal false, region.country?
      assert_equal false, region.deprecated?
      assert_equal false, region.has_zip?
      assert_equal "ZZ", region.iso_code
      assert_nil region.legacy_code
      assert_nil region.legacy_name
      assert_empty(region.format)
      assert_empty(region.format_extended)
      assert_empty(region.name_alternates)
      assert_nil region.numeric_three
      assert_equal false, region.province?
      # short_name currently throws a NoMethodError because it's not yet implemented
      # assert_nil region.short_name
      assert_nil region.tax_name
      assert_equal 0, (region.tax_rate * 100).floor
    end

    test "#initialize with various parameters" do
      region = Region.new(
        alpha_three: "AUT",
        continent: false,
        country: true,
        deprecated: false,
        iso_code: "AT",
        legacy_code: "AT",
        legacy_name: "Austria",
        numeric_three: "040",
        province: false,
        short_name: "Austria",
        tax_name: "MwSt",
        tax_rate: 0.2,
      )

      assert_equal "AUT", region.alpha_three
      assert_equal false, region.continent?
      assert_equal true, region.country?
      assert_equal false, region.deprecated?
      assert_equal "AT", region.iso_code
      assert_equal "AT", region.legacy_code
      assert_equal "Austria", region.legacy_name
      assert_equal "040", region.numeric_three
      assert_equal false, region.province?
      # short_name currently throws a NoMethodError because it's not yet implemented
      # assert_equal "Austria", region.short_name
      assert_equal "MwSt", region.tax_name
      assert_equal 20, (region.tax_rate * 100).floor
    end

    test "#initialize sets expected default attributes" do
      region = Region.new(iso_code: "ZZ")

      assert_empty region.additional_address_fields
      assert_empty(region.combined_address_format)
      refute region.building_number_required
      refute region.building_number_may_be_in_address2
      assert_nil region.currency
      assert_nil region.flag
      assert_empty(region.format)
      assert_empty(region.format_extended)
      assert_empty region.name_alternates
      assert_nil region.group
      assert_nil region.group_name
      assert_empty region.languages
      assert_empty region.neighbours
      assert_nil region.partial_zip_regex
      assert_nil region.phone_number_prefix
      assert_nil region.priority
      assert_empty region.tags
      assert_nil region.timezone
      assert_empty(region.timezones)
      assert_nil region.unit_system
      assert_nil region.week_start_day
      refute region.zip_autofill_enabled
      assert_nil region.zip_example
      assert_empty region.zip_prefixes
      assert_nil region.zip_regex
      assert_nil region.example_address
      assert_nil region.example_city
      assert_nil region.example_city_zip
      assert_empty region.parents
      assert_empty region.zones
      assert_nil region.tax_name
      assert_equal 0, (region.tax_rate * 100).floor
    end

    test "#short_name returns values as expected" do
      data = {
        "AU-NSW": "NSW",
        "CA-ON": "ON",
        "GB-ENG": "England",
        "RO-B": "Bucharest",
        "US-NY": "NY",
      }

      data.each do |code, expected|
        actual = Worldwide.region(code: code).short_name

        assert_equal expected, actual, "code #{code.inspect}"
      end
    end

    test "#add_zone adds a child region (zone)" do
      region = Region.new(iso_code: "XA")
      zone = Region.new(iso_code: "XB")

      region.add_zone(zone)

      assert_includes zone.parents, region
      assert_equal [zone], region.zones
      assert_equal zone, region.zone(code: "XB")
    end

    test "#zone can look up a zone by name" do
      legacy_name = "Prince Edward Island"
      scenarios = {
        en: "Prince Edward Island",
        fr: "Île-du-Prince-Édouard",
        ja: "プリンスエドワードアイランド州",
      }

      ca = Worldwide.region(code: "CA")

      scenarios.each do |locale, localized_name|
        I18n.with_locale(locale) do
          assert_equal "CA-PE", ca.zone(name: localized_name).iso_code, "locale #{locale} name #{localized_name}"
          assert_equal "CA-PE", ca.zone(name: legacy_name).iso_code, "locale #{locale} name #{legacy_name}"
        end
      end
    end

    test "#zone can look up a zone by its alternate names" do
      ["Baleares", "Illes Balears", "Islas Baleares"].each do |name|
        assert_equal "ES-PM", Worldwide.region(code: "ES").zone(name: name).iso_code
      end
    end

    test "#zone can look up a zone by CLDR code" do
      zone = Worldwide.region(code: "MY").zone(code: "my14")

      assert_not_nil zone
      assert_equal "MY-14", zone.iso_code
    end

    test "#zone can look up a zone by zip" do
      zone = Worldwide.region(code: "CA").zone(zip: "V6B 4A2")

      assert_not_nil zone
      assert_equal "CA-BC", zone.iso_code
    end

    test "#zone can look up a zone by partial zip" do
      zone = Worldwide.region(code: "CA").zone(zip: "V6B")

      assert_not_nil zone
      assert_equal "CA-BC", zone.iso_code
    end

    test "#zone can look up zones that go by iso_code" do
      [
        ["MX", "AGU", "MXAGU", "MX-AGU", "Aguascalientes"],
        ["JP", "01", "JP01", "JP-01", "Hokkaidō"],
        ["KR", "26", "KR26", "KR-26", "Busan"],
        ["PE", "AMA", "PEAMA", "PE-AMA", "Amazonas"],
      ].each do |country_code, zone_code, cldr_code, iso_code, expected_name|
        country = Worldwide.region(code: country_code)

        assert_equal expected_name, country.zone(code: zone_code).legacy_name
        assert_equal expected_name, country.zone(code: cldr_code).legacy_name
        assert_equal expected_name, country.zone(code: iso_code).legacy_name
      end
    end

    test "#zone raises when both code and name are provided" do
      ca = Worldwide.region(code: "CA")

      assert_raises ArgumentError do
        ca.zone(code: "PE", name: "Prince Edward Island")
      end
    end

    test "#zone can look up territories using alternate code formats" do
      [
        ["US", "PR", "USPR", "US-PR", "Puerto Rico"],
        ["FR", "BL", "FRBL", "FR-BL", "Saint Barthélemy"],
      ].each do |country_code, zone_code, cldr_code, iso_code, expected_name|
        country = Worldwide.region(code: country_code)

        assert_equal expected_name, country.zone(code: zone_code).legacy_name
        assert_equal expected_name, country.zone(code: cldr_code).legacy_name
        assert_equal expected_name, country.zone(code: iso_code).legacy_name
      end
    end

    test "#zone can look up a zone by alternate code" do
      assert_equal "CA-QC", Worldwide.region(code: "CA").zone(code: "PQ").iso_code
      assert_equal "MX-CMX", Worldwide.region(code: "MX").zone(code: "CDMX").iso_code
    end

    test "#zone raises when both name and zip are provided" do
      ca = Worldwide.region(code: "CA")

      assert_raises ArgumentError do
        ca.zone(name: "Ontario", zip: "M5W 1E6")
      end
    end

    test "#zone raises when both code and zip are provided" do
      ca = Worldwide.region(code: "CA")

      assert_raises ArgumentError do
        ca.zone(code: "ON", zip: "M5W 1E6")
      end
    end

    test "#zone raises when all three of code, name and zip are provided" do
      ca = Worldwide.region(code: "CA")

      assert_raises ArgumentError do
        ca.zone(code: "ON", name: "Ontario", zip: "M5W 1E6")
      end
    end

    test "#zone raises when neither code nor name nor zip is provided" do
      ca = Worldwide.region(code: "CA")

      assert_raises ArgumentError do
        ca.zone
      end
    end

    test "#region can be constructed with various code formats" do
      ["CA", "ca", :ca, :CA, "124", 124].each do |code|
        region = Worldwide.region(code: code)

        context = "Region constructed with code: #{code.inspect}"

        assert_not_nil region, context
        assert_equal "CA", region.iso_code, context
        I18n.with_locale("en-US") { assert_equal "Canada", region.full_name }
        I18n.with_locale("ja") { assert_equal "カナダ", region.full_name }
      end
    end

    test "#full_name falls back to legacy_name when CLDR has no name available" do
      dummy = Worldwide::Region.new(
        legacy_name: "Legacy name",
        cldr_code: "x@",
        iso_code: "X@", # does not exist
      )

      assert_equal "Legacy name", dummy.full_name
    end

    test "#autofill_zip returns values as expected" do
      {
        ac: "ASCN 1ZZ",
        ai: "AI-2640",
        cc: "6799",
        cx: "6798",
        fk: "FIQQ 1ZZ",
        gi: "GX11 1AA",
        gs: "SIQQ 1ZZ",
        nf: "2899",
        nr: "NRU68",
        nu: "9974",
        pn: "PCRN 1ZZ",
        sh: "STHL 1ZZ",
        ta: "TDCU 1ZZ",
        tc: "TKCA 1ZZ",
        va: "00120",
      }.each do |country_code, expected|
        assert_equal expected, Worldwide.region(code: country_code).autofill_zip
      end
    end

    test "#autofill_zip returns nil when no autofill is expected" do
      [:ad, :ca, :de, :es, :fr, :it, :nl, :us, :ve].each do |country_code|
        assert_nil Worldwide.region(code: country_code).autofill_zip
      end
    end

    test "#autofill_city returns nil when no autofill is expected" do
      [:ca, :de, :es, :fr, :it, :nl, :us, :ve].each do |country_code|
        assert_nil Worldwide.region(code: country_code).autofill_city
      end
    end

    test "#autofill_city returns values as expected" do
      [
        [:en, :sg, "Singapore"],
        [:fr, :sg, "Singapour"],
        [:ja, :sg, "シンガポール"],
        [:"zh-CN", :sg, "新加坡"],
        [:en, :gi, "Gibraltar"],
        [:en, :gs, "Grytviken"],
        [:en, :pn, "Adamstown"],
        [:en, :ta, "Edinburgh of the Seven Seas"],
        [:en, :va, "Vatican City"],
      ].each do |locale, country_code, expected|
        I18n.with_locale(locale) do
          assert_equal expected, Worldwide.region(code: country_code).autofill_city(locale: locale), "autofill in #{locale}"
        end
      end
    end

    test "#city_required? returns values as expected" do
      city_not_required_countries = [:gi, :gs, :pn, :sg, :ta, :va]
      city_required_countries = [:ca, :us, :gb]

      city_not_required_countries.each do |country_code|
        refute_predicate Worldwide.region(code: country_code), :city_required?
      end

      city_required_countries.each do |country_code|
        assert_predicate Worldwide.region(code: country_code), :city_required?
      end
    end

    test "#street_name_required? returns values as expected" do
      street_name_not_required_countries = [:ca, :us, :id]
      street_name_required_countries = [:nl, :be, :br, :cl, :es]

      street_name_not_required_countries.each do |country_code|
        assert_equal false, Worldwide.region(code: country_code).street_name_required?
      end

      street_name_required_countries.each do |country_code|
        assert_predicate Worldwide.region(code: country_code), :street_name_required?
      end
    end

    test "#street_number_required? returns values as expected" do
      street_number_not_required_countries = [:ca, :cl, :us, :id]
      street_number_required_countries = [:be, :br, :il, :mx, :nl, :es]

      street_number_not_required_countries.each do |country_code|
        assert_equal false, Worldwide.region(code: country_code).street_number_required?
      end

      street_number_required_countries.each do |country_code|
        assert_predicate Worldwide.region(code: country_code), :street_number_required?
      end
    end

    test "#zip_requirement returns zip requirement" do
      assert_equal "required", Worldwide.region(code: "CN").zip_requirement # set as required
      assert_equal "recommended", Worldwide.region(code: "AM").zip_requirement # set as recommended
      assert_equal "optional", Worldwide.region(code: "AF").zip_requirement # set as optional
      assert_equal "required", Worldwide.region(code: "AC").zip_requirement # not set but has potal code regex
      assert_equal "optional", Worldwide.region(code: "TZ").zip_requirement # not set
    end

    test "#neighborhood_required? returns values as expected" do
      neighborhood_not_required_countries = [:ca, :cl, :mx, :id]
      neighborhood_required_countries = [:ph, :vn, :tr]

      neighborhood_not_required_countries.each do |country_code|
        assert_equal false, Worldwide.region(code: country_code).neighborhood_required?
      end

      neighborhood_required_countries.each do |country_code|
        assert_predicate Worldwide.region(code: country_code), :neighborhood_required?
      end
    end

    test "#associated_country returns the expected country" do
      {
        ca: "CA",
        gb: "GB",
        ic: "ES",
        pr: "US",
        sh: "SH",
        us: "US",
      }.each do |region_code, expected_country|
        assert_equal expected_country, Worldwide.region(code: region_code).associated_country.iso_code
      end
    end

    test "#associated_continent returns the expected continent" do
      [
        # Canada
        [:ca, "North America"],
        # Ontario is a province of Canada, which is in North America
        ["CA-ON", "North America"],
        # Tokyo is a province of Japan, which is in Asia
        ["JP-13", "Asia"],
        # North America itself
        ["003", "North America"],
        # Puerto Rico is a territory of the US, which is in North America too
        ["US-PR", "North America"],
        # Bermuda is a territory of the UK, which is in Europe, but it lies in North America
        ["GB-BM", "North America"],
        # French Polynesia is a territory of France, which is in Europe, but it lies in Oceania
        ["FR-PF", "Oceania"],
      ].each do |region_code, expected_continent|
        assert_equal expected_continent, Worldwide.region(code: region_code).associated_continent.full_name
      end
    end

    test "#associated_continent returns nil for world region" do
      assert_nil Worldwide.region(code: "001").associated_continent
    end

    test "#name_alternates returns values as expected" do
      {
        cz: ["Czechia"],
        sz: ["Swaziland"],
        us: ["United States of America"],
        ca: [],
      }.each do |region_code, expected_alternates|
        assert_equal expected_alternates, Worldwide.region(code: region_code).name_alternates
      end
    end

    test "#name_alternates returns values as expected on zones" do
      [
        [:th, "TH-10", ["Krung Thep Maha Nakhon"]],
        [:jp, "JP-01", ["Hokkaido Prefecture", "北海道"]],
        [:ca, "ON", []],
      ].each do |region_code, zone_code, expected_alternates|
        assert_equal expected_alternates, Worldwide.region(code: region_code).zone(code: zone_code).name_alternates
      end
    end

    test "#building_number_required returns values as expected" do
      [
        [:ca, true],
        [:in, false],
        [:pk, false],
        [:de, true],
        [:us, true],
      ].each do |region_code, expected_value|
        assert_equal expected_value, Worldwide.region(code: region_code).building_number_required
      end
    end

    test "#building_number_may_be_in_address2 returns values as expected" do
      [
        [:ca, false],
        [:de, true],
        [:jp, true],
        [:us, false],
      ].each do |region_code, expected_value|
        assert_equal expected_value, Worldwide.region(code: region_code).building_number_may_be_in_address2
      end
    end

    test "#combined_address_format returns values as expected" do
      [
        [:us, {}],
        [:il, {
          "default" => {
            "address1" => [{ "key" => "streetNumber" }, { "key" => "streetName", "decorator" => " " }],
          },
        },],
        [:br, {
          "default" => {
            "address1" => [{ "key" => "streetName" }, { "key" => "streetNumber", "decorator" => ", " }],
            "address2" => [{ "key" => "line2" }, { "key" => "neighborhood", "decorator" => ", " }],
          },
        },],
        [:cl, {
          "default" => {
            "address1" => [{ "key" => "streetName" }, { "key" => "streetNumber", "decorator" => " " }],
            "address2" => [{ "key" => "line2" }, { "key" => "neighborhood", "decorator" => " " }],
          },
        },],
        [:id, {
          "default" => {
            "address2" => [{ "key" => "line2" }, { "key" => "neighborhood", "decorator" => ", " }],
          },
        },],
        [:tw, {
          "default" => {
            "address2" => [{ "key" => "line2" }, { "key" => "neighborhood" }],
          },
          "Latin" => {
            "address2" => [{ "key" => "line2" }, { "key" => "neighborhood", "decorator" => ", " }],
          },
        },],
      ].each do |region_code, expected_value|
        assert_equal expected_value, Worldwide.region(code: region_code).combined_address_format
      end
    end

    test "#additional_address_fields returns values as expected" do
      [
        [:us, []],
        [:br, [{ "name" => "streetName", "required" => true }, { "name" => "streetNumber", "required" => true }, { "name" => "line2" }, { "name" => "neighborhood", "required" => true }]],
        [:be, [{ "name" => "streetName", "required" => true }, { "name" => "streetNumber", "required" => true }]],
        [:id, [{ "name" => "line2" }, { "name" => "neighborhood" }]],
        [:tr, [{ "name" => "line2" }, { "name" => "neighborhood", "required" => true }]],
      ].each do |region_code, expected_value|
        assert_equal expected_value, Worldwide.region(code: region_code).additional_address_fields
      end
    end

    test "#address1_regex returns values as expected" do
      [
        [:us, []],
        [:nl, ["^(?<streetName>[^\\d]+) (?<streetNumber>\\d+(?: ?[a-z])?)$"]],
        [:be, ["^(?<streetName>[^\\d,]+),? (?<streetNumber>\\d+(?: ?[a-z])?)$", "^(?<streetNumber>\\d+(?: ?[a-z])?),? (?<streetName>[^\\d,]+)$"]],
      ].each do |region_code, expected_value|
        assert_equal expected_value, Worldwide.region(code: region_code).address1_regex
      end
    end

    test "#tax_inclusive returns the configured value or false" do
      assert Worldwide.region(code: "AD").tax_inclusive
      refute Worldwide.region(code: "CA").tax_inclusive
    end

    test "#example_city returns values as expected" do
      assert_equal "Los Angeles", Worldwide.region(code: "US").zone(code: "CA").example_city
    end

    test "#example_city_zip returns values as expected" do
      assert_equal "90011", Worldwide.region(code: "US").zone(code: "CA").example_city_zip
    end

    test "#priority returns values as expected" do
      assert_equal 47, Worldwide.region(code: "JP").zone(code: "JP-01").priority
    end

    test "#tax_type returns values as expected" do
      assert_equal "harmonized", Worldwide.region(code: "CA").zone(code: "ON").tax_type
    end

    test "#tax_name returns values as expected" do
      assert_equal "HST", Worldwide.region(code: "CA").zone(code: "ON").tax_name
    end

    test "#tax_rate returns values as expected" do
      assert_in_delta(0.13, Worldwide.region(code: "CA").zone(code: "ON").tax_rate)
    end
  end
end
