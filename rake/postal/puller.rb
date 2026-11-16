# frozen_string_literal: true

require "fileutils"
require "uri"
require "open-uri"
require "zip"

module Postal
  class Puller
    def download(country, source: nil, target: nil)
      source ||= "https://download.geonames.org/export/zip/#{country}.zip"
      target ||= download_path

      puts "DOWNLOAD #{country}"

      URI.parse(source).open do |io_object|
        FileUtils.mkdir_p(target)
        Zip.on_exists_proc = true
        Zip::File.open_buffer(io_object.read) do |file|
          file.each do |entry|
            path = target + "/" + entry.name
            FileUtils.mkdir_p(File.dirname(path))
            file.extract(entry, path)
          end
        end
      end

      puts "DOWNLOAD completed."
    end

    # Returns an array of arrays, containing the contents of the country's postal code TSV file.
    # Note that you'll want to call download() first, so that the file is available to be parsed.
    def parse(country, source = nil)
      source ||= "#{download_path}/#{country}.txt"

      # Expected format:
      #  - country_code
      #  - postal_code
      #  - place_name (What "location" does this code cover?)
      #  - name1 (e.g., state/province)
      #  - code1 (code corresponding to name1)
      #  - name2 (e.g., county)
      #  - code2 (code corresponding to name2)
      #  - name3 (e.g., city/town)
      #  - code3 (code corresponding to name3)
      #  - latitude
      #  - longitude
      #  - accuracy (of lat/long, one of 1=estimated, 4=geonameid, 6=centroid of addresses or shape)

      result = {}
      File.open(source) do |f|
        f.each do |line|
          columns = line.strip.split("\t")

          next unless columns.size == 12

          postal_code = columns[1]
          result[postal_code.to_sym] = {
            country_code: columns[0],
            place_name: columns[2],
            name1: columns[3],
            code1: columns[4],
            name2: columns[5],
            code2: columns[6],
            name3: columns[7],
            code3: columns[8],
            latitude: columns[9],
            longititude: columns[10],
            accuracy: columns[11],
          }
        end
      end

      result
    end

    private

    def download_path
      File.join(__dir__, "vendor", "geonames")
    end
  end
end
