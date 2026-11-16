# frozen_string_literal: true

require_relative "puller"
require_relative "postal_helpers"
require "csv"
require "worldwide"

# Expected file format is CSV, with at least three columns:
#  - postal code string (first column)
#  - zone (province) name string as the second column
#  - count (number of times that (postal code, zone) appears in an address) as the last column
#
# In addition
#  - the CSV must be sorted by count (descending)
#  - the file name must be ${country_code}.csv

module Postal
  class ZoneChecker
    def initialize
      @total = 0
    end

    def examine(file_name)
      total = count_total(file_name)
      country = country_for(file_name)

      check_file(file_name, country, total)
    end

    private

    def check_codes(csv_file, output_file, country, total)
      cumulative_failures = 0

      csv = CSV.new(csv_file)
      csv.each do |row|
        zip = row.first&.strip
        zone_name = row[1]&.strip
        count = row.last&.to_i

        next if zip == "zip"
        next unless country.valid_zip?(zip)
        next unless zone_name

        zone = country.zone(name: zone_name)
        next unless zone.province?

        zone_code = zone.legacy_code
        valid = zone.valid_zip?(zip)
        percent = format("%02.02f%%", count * 100.0 / total)
        cumulative_failures += count unless valid
        cumulative_percent = format("%02.02f%%", cumulative_failures * 100.0 / total)

        output_file.puts "#{zip.inspect} #{zone_code.inspect} #{valid.inspect} (#{count} occurrences, #{percent}, cumulative failed #{cumulative_percent})"
      end
    end

    def check_file(file_name, country, total)
      output_file_name = file_name.sub("#{country.iso_code}.csv", "#{country.iso_code}.txt")

      File.open(file_name, "r") do |fd|
        File.open(output_file_name, "w") do |fdout|
          check_codes(fd, fdout, country, total)
        end
      end
    end

    def count_total(file_name)
      total = 0

      File.open(file_name, "r") do |fd|
        csv = CSV.new(fd)
        csv.each do |row|
          count = row.last.to_i
          total += count
        end
      end

      total
    end

    def country_for(file_name)
      country_code = file_name.match(/(?<country_code>[A-Z][A-Z]).csv$/)["country_code"]
      if country_code.nil?
        raise "Filename #{file_name} must be in the format XX.csv, where XX is an ISO-3166 country code."
      end

      country = Worldwide.region(code: country_code)
      raise "Country #{country_code} not found." unless country.country?

      country
    end
  end
end
