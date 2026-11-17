# frozen_string_literal: true

require "cldr/draft_status"
require "cldr/export/data_file"
require "yaml"

module Worldwide
  module Cldr
    # ruby-cldr does not export <minimumGroupingDigits>, so we read it from the CLDR locale XML.
    # https://www.unicode.org/reports/tr35/tr35-numbers.html#Examples_of_minimumGroupingDigits
    module MinimumGroupingDigits
      ELEMENT = "minimumGroupingDigits"
      KEY = "minimum_grouping_digits"

      class << self
        # Reads <minimumGroupingDigits> from each locale XML file in main_dir, keeping the values whose draft status
        # is at least minimum_draft_status, and writes each one as numbers.minimum_grouping_digits in
        # locales_dir/<locale>/numbers.yml. Locales that don't define a value inherit one through the CLDR fallbacks.
        # Returns the values written, by locale.
        def import(main_dir:, locales_dir:, minimum_draft_status:)
          values = read(main_dir, minimum_draft_status)
          values.each { |locale, value| write(locales_dir, locale, value) }
          values
        end

        private

        def read(main_dir, minimum_draft_status)
          paths = Dir[File.join(main_dir, "*.xml")].sort
          raise "No CLDR locale XML files in #{main_dir}. Run `rake cldr:data:import` first." if paths.empty?

          paths.each_with_object({}) do |path, values|
            xml = File.read(path)
            next unless xml.include?(ELEMENT)

            nodes = ::Cldr::Export::DataFile.parse(xml, minimum_draft_status: minimum_draft_status).xpath("//ldml/numbers/#{ELEMENT}")
            next if nodes.empty?
            raise "Expected at most one <#{ELEMENT}> in #{path}, got #{nodes.size}" if nodes.size > 1

            locale = File.basename(path, ".xml").tr("_", "-")
            values[locale] = Integer(nodes.first.content, 10)
          end
        end

        def write(locales_dir, locale, value)
          locale_dir = File.join(locales_dir, locale)
          raise "No exported CLDR data for #{locale} in #{locales_dir}" unless Dir.exist?(locale_dir)

          path = File.join(locale_dir, "numbers.yml")
          data = File.exist?(path) ? YAML.safe_load_file(path, permitted_classes: [Symbol]) : {}
          locale_data = data[locale] ||= {}
          numbers = locale_data["numbers"] ||= {}
          numbers[KEY] = value
          File.write(path, data.to_yaml)
        end
      end
    end
  end
end
