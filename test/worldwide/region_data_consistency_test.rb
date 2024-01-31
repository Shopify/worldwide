# frozen_string_literal: true

require "test_helper"
require "worldwide/region_data_test_helper"

# Assertions that region data follows expected patterns

module Worldwide
  class RegionDataConsistencyTest < ActiveSupport::TestCase
    test "provinces and territories of Canada are as expected" do
      ca = Worldwide.region(code: "CA")

      assert_equal "Canada", ca.legacy_name
      assert_equal "CA", ca.iso_code
      assert_equal "CA", ca.legacy_code

      legacy_codes = ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"]
      iso_codes = legacy_codes.map { |c| "CA-#{c}" }

      assert_equal legacy_codes, ca.zones.map(&:legacy_code).sort
      assert_equal iso_codes, ca.zones.map(&:iso_code).sort
    end

    test "province_optional? is true for all countries where province_optional is true" do
      Regions.all.select(&:country?).each do |country|
        next unless country.province_optional

        assert_equal true, country.province_optional?
      end
    end

    test "has_zip? is true for all countries where an autofill is defined" do
      Regions.all.select(&:country?).each do |country|
        next unless country.zip_autofill_enabled

        assert_equal true, country.has_zip?
      end
    end

    test "if a value is given for zip_requirement, it is one of the three permitted values" do
      Regions.all.select(&:country?).each do |country|
        next if country.zip_requirement.nil?

        next if Worldwide::Region::OPTIONAL == country.zip_requirement
        next if Worldwide::Region::RECOMMENDED == country.zip_requirement
        next if Worldwide::Region::REQUIRED == country.zip_requirement

        flunk "#{country.iso_code} has invalid zip_requirement: #{country.zip_requirement.inspect}"
      end
    end

    test "all province zip_prefixes are uppercase" do
      Regions.all.select(&:province?).each do |province|
        next if province.zip_prefixes.nil?

        # rubocop:disable Performance/RedundantEqualityComparisonBlock
        assert province.zip_prefixes.all? { |prefix| prefix == prefix.upcase }
        # rubocop:enable Performance/RedundantEqualityComparisonBlock
      end
    end

    test "country codes match expected formats" do
      Regions.all.select(&:country?).each do |country|
        assert country.iso_code.match?(/^([A-Z]{2})$/), "alpha2 for #{country.legacy_name}"
        assert country.alpha_three.match?(/^([A-Z]{3})$/), "alpha3 for #{country.legacy_name}"

        unless country.numeric_three.nil?
          assert country.numeric_three.match?(/^([0-9]{3})$/), "numeric3 for #{country.legacy_name}"
        end
      end
    end

    test "province codes match expected formats" do
      Regions.all.select(&:province?).each do |province|
        assert(province.iso_code.match?(/^[A-Z0-9-]+$/), "Unexpected iso_code for #{province.legacy_name}")
        assert(province.legacy_code.match?(/^[A-Z0-9 -]+$/), "Unexpected legacy for #{province.legacy_name}")
      end
    end

    test "except for countries with special sort orders, provinces are sorted alphabetically in English" do
      not_sorted_alphabetically = ["CL", "JP", "US", "RU"]

      Regions.all.select(&:country?).each do |country|
        next if not_sorted_alphabetically.include?(country.iso_code)

        provinces = country.zones.select(&:province?)

        next if provinces.empty?

        province_codes = provinces.map(&:iso_code)
        sorted_province_codes = provinces.sort_by do |province|
          ActiveSupport::Inflector.transliterate(province.legacy_name.downcase)
        end.map(&:iso_code)

        assert_equal sorted_province_codes, province_codes
      end
    end

    test "in Chile, Japan, USA and Russia, provinces are sorted as expected" do
      expectations = {
        "CL" => ["AP", "TA", "AN", "AT", "CO", "VS", "RM", "LI", "ML", "NB", "BI", "AR", "LR", "LL", "AI", "MA"],
        "JP" => (1..47).map { |x| "JP-#{x.to_s.rjust(2, "0")}" },
        "RU" => ["AD", "AL", "ALT", "AMU", "ARK", "AST", "BA", "BEL", "BRY", "BU", "CE", "CHE", "CHU", "CU", "DA", "IN", "IRK", "IVA", "YEV", "KB", "KGD", "KL", "KLU", "KAM", "KC", "KR", "KEM", "KHA", "KK", "KHM", "KIR", "KO", "KOS", "KDA", "KYA", "KGN", "KRS", "LEN", "LIP", "MAG", "ME", "MO", "MOW", "MOS", "MUR", "NEN", "NIZ", "NGR", "NVS", "OMS", "ORE", "ORL", "PNZ", "PER", "PRI", "PSK", "ROS", "RYA", "SPE", "SA", "SAK", "SAM", "SAR", "SE", "SMO", "STA", "SVE", "TAM", "TA", "TOM", "TUL", "TVE", "TYU", "TY", "UD", "ULY", "VLA", "VGG", "VLG", "VOR", "YAN", "YAR", "ZAB"],
        "US" => ["AL", "AK", "AS", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FM", "FL", "GA", "GU", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MH", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "MP", "OH", "OK", "OR", "PW", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY", "VI", "AA", "AE", "AP"],
      }

      expectations.each do |country_code, expected|
        actual = Worldwide.region(code: country_code).zones.select(&:province?).map(&:legacy_code)

        assert_equal expected, actual, "Expected province order for #{country_code}"
      end
    end

    test "province iso_code values are always of the form XX-YY" do
      Regions.all.select(&:province?).each do |province|
        next if RegionDataTestHelper::ES_AND_US_DUAL_STATUS_PROVINCES.include?(province.iso_code)

        assert province.iso_code.match?(/^[A-Z][A-Z]-[A-Z0-9]{1,3}$/), "#{province.iso_code} unexpected"
      end
    end

    test "EU region includes all EU-member, EU-OMR, EU-OCT and EU-special countries" do
      eu = Worldwide.region(code: "EU")
      eu_tags = ["EU-member", "EU-OCT", "EU-OMR", "EU-special"].to_set
      Regions.all.select(&:country?).each do |country|
        country_tags = country.tags&.to_set
        next if country_tags.nil?
        next if eu_tags.intersection(country_tags).empty?

        assert_includes eu.zones.map(&:iso_code), country.iso_code
      end
    end

    test "country shows provices if it has them, unless hide_provinces_from_addresses is set" do
      Regions.all.select(&:country?).each do |country|
        shows_provinces = country.format["show"].include?("{province}")

        if Worldwide::Util.present?(country.zones.select(&:province?))
          assert_equal !shows_provinces, country.hide_provinces_from_addresses, "country: #{country.iso_code}"
        else
          assert_equal false, shows_provinces
        end
      end
    end

    test "CQ has a name" do
      I18n.with_locale(:en) do
        assert_equal "Sark", Worldwide.region(code: "CQ").full_name
      end
      I18n.with_locale(:fr) do
        assert_equal "Sercq", Worldwide.region(code: "CQ").full_name
      end
    end

    test "TR uses the new English name Türkiye" do
      I18n.with_locale(:en) do
        assert_equal "Türkiye", Worldwide.region(code: "TR").full_name
      end
    end
  end
end
