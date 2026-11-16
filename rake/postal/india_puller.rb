# frozen_string_literal: true

require_relative "postal_helpers"
require_relative "puller"

require "csv"
require "worldwide"

module Postal
  class IndiaPuller < Puller
    include PostalHelpers

    def download(country, source: nil, target: nil)
      target ||= pincodes_csv_path

      puts "  Not performing automated download for India, because the file is huge."
      puts "  If needed, get pincode.csv from data.gov.in at:"
      puts "    https://data.gov.in/catalog/all-india-pincode-directory"
      puts "  and place it at: #{target}"
    end

    # Returns an array of arrays, containing the contents of the country's postal code TSV file.
    # Note that you'll want to call download() first, so that the file is available to be parsed.
    def parse(country, source = nil)
      source ||= pincodes_csv_path
      entries = load_india_pincodes_csv(source)

      postal_codes_crossing_zones = {}

      entries.each do |key, values|
        zones = values.map { |v| v[:code1] }.uniq
        if zones.length > 1
          postal_codes_crossing_zones[key.to_s] = zones
        end
      end

      postal_codes_crossing_zones = postal_codes_crossing_zones.sort.to_h

      puts "POSTAL CODES CROSSING ZONES:\n#{postal_codes_crossing_zones.inspect}"

      unless postal_codes_crossing_zones.empty?
        write_yaml("IN", codes_crossing_zones: postal_codes_crossing_zones)
      end

      entries.transform_values(&:first)
    end

    private

    def download_path
      File.join(__dir__, "vendor", "geonames")
    end

    def load_india_pincodes_csv(source)
      result = {}

      india = Worldwide.region(code: "IN")
      state_names = {
        "THE DADRA AND NAGAR HAVELI AND DAMAN AND DIU" => "Dadra and Nagar Haveli",
      }

      puts "Parsing #{source}..."
      count = 0

      csv = CSV.parse(File.read(source), headers: true)
      csv.each do |row|
        postal_code = row["Pincode"]
        state_name = state_names.fetch(row["StateName"], row["StateName"])

        entries = result[postal_code.to_sym] || []

        entries += [{
          country_code: "IN",
          place_name: row["OfficeName"],
          name1: state_name,
          code1: india.zone(name: state_name).legacy_code,
          name2: row["District"],
          code2: nil,
          name3: row["DivisionName"],
          code3: nil,
          latitude: row["Latitude"],
          longitude: row["Longitude"],
          accuracy: nil,
        }]

        result[postal_code.to_sym] = entries

        count += 1
        if (count % 10000) == 0
          puts "#{count} records processed..."
        end
      end

      result
    end

    def pincodes_csv_path
      "#{download_path}/pincode.csv"
    end
  end
end
