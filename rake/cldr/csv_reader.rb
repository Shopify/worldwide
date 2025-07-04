# frozen_string_literal: true

require "csv"

module Worldwide
  module Cldr
    class CsvReader
      def initialize(csv_path)
        @csv_path = csv_path
      end

      def get_rows(&block)
        raise NotImplementedError, "#{self.class.name} must implement #get_rows"
      end

      def get_postcode(row)
        raise NotImplementedError, "#{self.class.name} must implement #get_postcode"
      end

      def get_iso2(row)
        raise NotImplementedError, "#{self.class.name} must implement #get_iso2"
      end
    end

    class CustomCSVReaderReader < CsvReader
      def get_rows(&block)
        CSV.foreach(@csv_path, headers: true, col_sep: ";", &block)
      end

      def get_postcode(row)
        row["postcode"]
      end

      def get_iso2(row)
        row["iso2"]
      end
    end

    class CsvReaderFactory
      class << self
        def create(reader_type, csv_path)
          case reader_type
          when "custom_csv"
            CustomCSVReaderReader.new(csv_path)
          else
            raise "Unknown reader type: #{reader_type}"
          end
        end
      end
    end
  end
end
