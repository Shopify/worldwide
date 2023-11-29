# frozen_string_literal: true

require "forwardable"
require "singleton"
require "yaml"

module Worldwide
  class RegionsLoader
    WORLD_CODE = "001" # UN code for the whole world

    def load_regions
      @regions_by_cldr_code = {}
      @regions_by_iso_code = {}

      # Load country/region definitions out of the db/data/regions/??.yml files
      @regions = Dir["#{Worldwide::Paths::REGIONS_ROOT}/*.yml"].map do |filename|
        load_territory(filename)
      end.flatten

      # Load hierarchies out of world.yml, and construct regions to match the specified hierarchies
      apply_hierarchy(parent: nil, code: WORLD_CODE, children: world_yml[WORLD_CODE])
      world_yml["alternates"].each do |code, children|
        apply_hierarchy(parent: nil, code: code, children: children)
      end

      # Construct regions to represent trading blocks like the EU
      construct_trading_blocks

      construct_unknown

      @regions.each do |region|
        construct_lookup_info(region)
      end

      [@regions.freeze, @regions_by_cldr_code, @regions_by_iso_code]
    end

    private

    def construct_lookup_info(region)
      pc = region.send(:parent_country)

      # Remember CLDR code(s) for later use during lookup

      search_code = region.cldr_code.to_s.upcase
      @regions_by_cldr_code[search_code] = region if Util.present?(search_code)

      @regions_by_cldr_code["#{pc.cldr_code.upcase}#{search_code}"] = region if Util.present?(pc&.cldr_code)

      # Remember ISO 3166 code(s) for later use during lookup

      iso_code = region.iso_code
      @regions_by_iso_code[iso_code] = region if Util.present?(iso_code)

      @regions_by_iso_code["#{pc.iso_code}-#{iso_code}"] = region if Util.present?(pc)

      alpha_three = region.alpha_three
      @regions_by_iso_code[alpha_three] = region if Util.present?(alpha_three)

      numeric_three = region.numeric_three
      @regions_by_iso_code[numeric_three] = region if Util.present?(numeric_three)
    end

    def apply_hierarchy(parent:, code:, children:)
      current_region = find_region(code: code)
      if current_region.nil?
        current_region = if /^[0-9]+$/.match?(code)
          Region.new(cldr_code: cldr_code(numeric_three: code), numeric_three: code, continent: continent?(code))
        else
          Region.new(
            cldr_code: cldr_code(iso_code: code, numeric_three: country_codes.dig(code, "numeric")),
            iso_code: code,
            alpha_three: country_codes.dig(code, "alpha3"),
            numeric_three: country_codes.dig(code, "numeric"),
          )
        end
        @regions << current_region
      end

      current_region.parents << parent if Util.present?(parent)
      parent&.add_zone(current_region)
      return current_region if children.nil?

      children.each do |child_code, grandchildren|
        apply_hierarchy(parent: current_region, code: child_code, children: grandchildren)
      end

      current_region
    end

    def apply_territory_attributes(region, spec)
      region.building_number_required = spec["building_number_required"] || false
      region.building_number_may_be_in_address2 = spec["building_number_may_be_in_address2"] || false
      currency_code = spec["currency"]
      region.code_alternates = spec["code_alternates"] || []
      region.currency = Worldwide.currency(code: currency_code) unless currency_code.nil?
      region.flag = spec["emoji"]
      region.format = spec["format"]
      region.group = spec["group"]
      region.group_name = spec["group_name"]
      region.hide_provinces_from_addresses = spec["hide_provinces_from_addresses"] || false
      region.languages = spec["languages"]
      region.partial_zip_regex = spec["partial_zip_regex"]
      region.phone_number_prefix = spec["phone_number_prefix"]
      region.tags = spec["tags"] || []
      region.timezone = spec["timezone"]
      region.timezones = spec["timezones"] || {}
      region.week_start_day = spec["week_start_day"] || "sunday"
      region.unit_system = spec["unit_system"] || "metric"
      region.province_optional = spec["province_optional"] || false
      region.zip_autofill_enabled = spec["zip_autofill_enabled"] || false
      region.zip_example = spec["zip_example"]
      region.zip_prefixes = spec["zip_prefixes"]
      region.zip_requirement = spec["zip_requirement"]
      region.zip_regex = spec["zip_regex"]
      region.zips_crossing_provinces = spec["zips_crossing_provinces"]
      region.name_alternates = spec["name_alternates"] || []
    end

    def apply_zone_attributes(region, zone)
      region.code_alternates = zone["code_alternates"] || []
      region.name_alternates = zone["name_alternates"] || []
      region.example_city = zone["example_city"]
      region.neighbours = zone["neighboring_zones"]
      region.zip_prefixes = zone["zip_prefixes"] || []
    end

    # When looking up names in the CLDR data files, we need to use CLDR's naming convention.
    # ISO code CA is CLDR code ca
    # ISO code CA-ON is CLDR code caon
    def cldr_code(iso_code: nil, numeric_three: nil)
      result = (iso_code || numeric_three).to_s
      if 2 == result.length
        result.upcase
      else
        result.downcase.delete("-")
      end
    end

    def construct_eu
      eu = Region.new(
        alpha_three: "EUE", # https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3
        continent: false,
        country: false,
        deprecated: false,
        cldr_code: cldr_code(iso_code: "EU"),
        iso_code: "EU",
        legacy_code: "EU",
        legacy_name: "European Union",
        numeric_three: nil,
        province: false,
        short_name: "EU",
        tax_name: nil,
        tax_rate: nil,
      )

      member_tags = ["EU-member", "EU-OMR", "EU-OCT", "EU-special"]
      member_tags.each do |tag|
        @regions.select { |r| r.tags&.include?(tag) }.each do |region|
          eu.add_zone(region)
        end
      end

      @regions << eu
    end

    # Create trading block regions.
    # Currently only the EU, but we should expand this in the future to cover others like ASEAN and Mercosur
    def construct_trading_blocks
      construct_eu
    end

    def construct_unknown
      unknown = Region.new(
        alpha_three: nil,
        continent: false,
        country: false,
        deprecated: true,
        cldr_code: cldr_code(iso_code: "ZZ"),
        iso_code: "ZZ",
        legacy_code: "ZZ",
        legacy_name: "Unknown",
        numeric_three: nil,
        province: false,
        short_name: nil,
        tax_name: nil,
        tax_rate: nil,
      )

      @regions << unknown
    end

    def country_codes
      @country_codes ||=
        YAML.safe_load(File.read("#{Worldwide::Paths::DB_DATA_ROOT}/country_codes.yml"))["country_codes"]
    end

    def find_region(code:)
      adjusted_code = code.to_s.upcase
      @regions.find { |r| r.cldr_code.upcase == adjusted_code || r.iso_code == adjusted_code || r.numeric_three == adjusted_code || r.alpha_three == adjusted_code }
    end

    def continent?(code)
      world_yml["continents"].include?(code)
    end

    def load_territory(filename)
      spec = YAML.safe_load(File.read(filename))
      code = spec["code"]

      loaded_regions = []

      region = Region.new(
        alpha_three: country_codes.dig(code, "alpha3"),
        continent: false,
        country: true,
        deprecated: spec["deprecated"] || false,
        cldr_code: cldr_code(iso_code: code, numeric_three: country_codes.dig(code, "numeric")),
        iso_code: code,
        legacy_code: code,
        legacy_name: spec["name"],
        numeric_three: country_codes.dig(code, "numeric"),
        province: false,
        short_name: nil,
        tax_name: spec["tax_name"],
        tax_rate: spec["tax"],
        use_zone_code_as_short_name: spec["use_zone_code_as_short_name"] || false,
      )

      apply_territory_attributes(region, spec)

      loaded_regions = [region]

      return loaded_regions if spec["zones"].nil?

      spec["zones"].each do |zone|
        loaded_regions << load_zone(region, zone)
      end

      loaded_regions
    end

    def load_zone(region, zone)
      iso_code = if zone["iso_code"].nil?
        "#{region.iso_code}-#{zone["code"]}"
      else
        zone["iso_code"]
      end

      short_name = if region.use_zone_code_as_short_name
        zone["code"]
      end

      numeric_three = zone["numeric_three"] || country_codes.dig(iso_code, "numeric")

      subregion = Region.new(
        alpha_three: zone["alpha_three"] || country_codes.dig(iso_code, "alpha3"),
        continent: false,
        country: false,
        deprecated: zone["deprecated"] || false,
        cldr_code: cldr_code(iso_code: iso_code, numeric_three: numeric_three),
        iso_code: iso_code,
        legacy_code: zone["code"],
        legacy_name: zone["name"],
        numeric_three: numeric_three,
        province: true,
        short_name: short_name,
        tax_name: zone["tax_name"],
        tax_rate: zone["tax"],
      )

      apply_zone_attributes(subregion, zone)

      region.add_zone(subregion)
      subregion
    end

    def world_yml
      @world_yml ||= YAML.load_file(File.join(Worldwide::Paths::DB_DATA_ROOT, "world.yml"))
    end
  end
end
