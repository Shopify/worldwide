# frozen_string_literal: true

require_relative "puller"
require_relative "postal_helpers"
require "csv"
require "worldwide"

# Expected file format is CSV, with at least two columns:
#  - postal code string (first column)
#  - count (number of times that postal code string appears in an address) as the last column
#
# In addition
#  - the CSV must be sorted by count (descending)
#  - the file name must be ${country_code}.csv

module Postal
  class Checker
    def initialize
      @total = 0
    end

    def examine(file_name)
      total = count_total(file_name)
      country = country_for(file_name)

      check_codes(file_name, country, total)
    end

    private

    def check_codes(file_name, country, total)
      cumulative_raw_failures = 0
      cumulative_normalized_failures = 0

      output_file_name = file_name.sub("#{country.iso_code}.csv", "#{country.iso_code}.txt")

      File.open(file_name, "r") do |fd|
        File.open(output_file_name, "w") do |fdout|
          csv = CSV.new(fd)
          csv.each do |row|
            zip = row.first&.strip
            count = row.last&.to_i
            next if zip == "zip"

            # The raw check skips normalization on purpose, and Worldwide only offers it as a private method.
            valid_raw = country.send(:valid_normalized_zip?, zip)
            normalizable_to_valid = country.valid_zip?(zip)
            percent = format("%02.02f%%", count * 100.0 / total)
            cumulative_raw_failures += count unless valid_raw
            cumulative_normalized_failures += count unless normalizable_to_valid
            cumulative_raw_percent = format("%02.02f%%", cumulative_raw_failures * 100.0 / total)
            cumulative_normalized_percent = format("%02.02f%%", cumulative_normalized_failures * 100.0 / total)

            fdout.puts "#{zip.inspect} #{valid_raw.inspect} raw, #{normalizable_to_valid.inspect} normalized, (#{count} occurrences, #{percent}, cumulative failed #{cumulative_raw_percent} raw, #{cumulative_normalized_percent} normalized)"
          end

          cumulative_raw_percent = format("%02.02f%%", cumulative_raw_failures * 100.0 / total)
          cumulative_normalized_percent = format("%02.02f%%", cumulative_normalized_failures * 100.0 / total)
          fdout.puts "SUMMARY: #{total} total values, of which #{cumulative_raw_failures} (#{cumulative_raw_percent}) raw, #{cumulative_normalized_failures} (#{cumulative_normalized_percent}) normalized, were rejected."
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
