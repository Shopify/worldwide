# frozen_string_literal: true

require_relative "checker"
require_relative "india_puller"
require_relative "postal_helpers"
require_relative "puller"
require_relative "zone_checker"
require "set"

module Postal
  class Codes
    include PostalHelpers

    def initialize
      @zones_for_prefix_cache = {}
    end

    def import(country)
      subdivision_level = subdivision_level_for_country(country)
      @zones_for_prefix_cache = {}

      puller = if country == "IN"
        Postal::IndiaPuller.new
      else
        Postal::Puller.new
      end
      puller.download(country)
      codes = puller.parse(country)

      prefixes = compute_prefixes(codes, country, subdivision_level)

      # Hash of arrays of postal codes per zone.
      # Zones are, e.g., "provinces" for Canada, "states" for USA
      zones = {}
      prefixes = map_prefix_data(prefixes, country)

      prefixes.each do |prefix, zone_code|
        postal_code_list = zones.fetch(zone_code.to_sym, [])
        postal_code_list.push(prefix)
        zones[zone_code.to_sym] = postal_code_list
      end

      write_yaml(country, zones: zones)
    end

    private

    def longest_possible_shared_common_prefix(a, b)
      return "" if a[0] != b[0]

      a.to_s.split("").each_with_index do |_, i|
        if a[i] != b[i]
          return a[0..(i - 1)]
        end
      end
      a
    end

    # Compute the shortest unique prefixes of postal codes each of which maps to a unique zone.
    #
    # Input:  hash mapping from postal code to data about the code (including zone e.g. "province")
    # Output:  hash mapping from a prefix of a postal code, to the zone.
    #
    def compute_prefixes(codes, country, subdivision_level)
      prefixes = {}

      status_interval = [codes.size / 100, 1].max
      codes.each_with_index do |(key, _), index|
        puts "(#{(index * 100 / codes.size) + 1}% complete)" if index % status_interval == 1
        prefix = ""
        key.to_s.each_char do |c|
          prefix += c
          break if prefixes.include?(prefix)

          zones = zones_for_prefix(prefix, codes, subdivision_level)
          if zones.size == 1
            prefixes[prefix.to_sym] = zones.to_a.first
            break
          end
        end
      end
      prefixes = patch_prefix_data(prefixes, country)

      prefixes
    end

    def zones_for_prefix(prefix, codes, subdivision_level)
      return @zones_for_prefix_cache[prefix] if @zones_for_prefix_cache.include?(prefix)

      zones = Set.new

      keys = codes.keys.map(&:to_s)

      keys.each do |key|
        if key.start_with?(prefix)
          zone = codes[key.to_sym][subdivision_level]
          zones.add(zone)
        end
      end

      @zones_for_prefix_cache[prefix] = zones

      zones
    end
  end
end
