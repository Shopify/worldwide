# frozen_string_literal: true

require "cldr/draft_status"
require "cldr/export/data_file"
require "yaml"

module Worldwide
  module Cldr
    # ruby-cldr does not export the <pattern>, <decimal> and <group> that a <currency> element can give, so we read them
    # from the CLDR locale XML. They replace the locale's currency pattern and separators for amounts in that currency.
    # en_150 gives EUR the pattern "¤#,##0.00", so EUR amounts are written "€1,234.56" in en-DE and en-NL.
    # https://www.unicode.org/reports/tr35/tr35-numbers.html#Currencies
    module CurrencySpecificFormats
      KEY = "currencies"
      FALLBACK_KEYS = {
        "decimal" => "numbers.latn.symbols.decimal",
        "group" => "numbers.latn.symbols.group",
        "pattern" => "numbers.latn.formats.currency.patterns.default.standard",
      }.freeze

      class << self
        # Reads the <pattern>, <decimal> and <group> of each <currency> in each locale XML file in main_dir, keeping the
        # values whose draft status is at least minimum_draft_status, and writes all three as
        # numbers.currencies.<code> in locales_dir/<locale>/numbers.yml. A value that the XML leaves out comes from
        # resolve.call(locale, key), the resolved CLDR data of the locale that defines the currency's format, as ICU
        # does. So locales that inherit the format, such as en-DE from en-150, also inherit its separators.
        # Returns the values written, by locale and currency code.
        def import(main_dir:, locales_dir:, minimum_draft_status:, resolve:)
          formats = read(main_dir, minimum_draft_status)
          formats.each do |locale, currencies|
            currencies.each do |code, values|
              FALLBACK_KEYS.each { |name, key| values[name] ||= resolve.call(locale, key) }
              currencies[code] = values.sort.to_h
            end
            write(locales_dir, locale, currencies)
          end
          formats
        end

        private

        def read(main_dir, minimum_draft_status)
          paths = Dir[File.join(main_dir, "*.xml")].sort
          raise "No CLDR locale XML files in #{main_dir}. Run `rake cldr:data:import` first." if paths.empty?

          paths.each_with_object({}) do |path, formats|
            xml = File.read(path)
            next unless xml.include?("<currencies>")

            currencies = ::Cldr::Export::DataFile.parse(xml, minimum_draft_status: minimum_draft_status).xpath("//ldml/numbers/currencies/currency")
            values = currencies.each_with_object({}) do |currency, by_code|
              currency_values = FALLBACK_KEYS.keys.each_with_object({}) do |name, found|
                nodes = currency.xpath("#{name}[not(@alt)]")
                raise "Expected at most one <#{name}> for #{currency["type"]} in #{path}, got #{nodes.size}" if nodes.size > 1

                found[name] = nodes.first.content unless nodes.empty?
              end
              by_code[currency["type"]] = currency_values unless currency_values.empty?
            end
            formats[File.basename(path, ".xml").tr("_", "-")] = values unless values.empty?
          end
        end

        def write(locales_dir, locale, currencies)
          locale_dir = File.join(locales_dir, locale)
          raise "No exported CLDR data for #{locale} in #{locales_dir}" unless Dir.exist?(locale_dir)

          path = File.join(locale_dir, "numbers.yml")
          data = File.exist?(path) ? YAML.safe_load_file(path, permitted_classes: [Symbol]) : {}
          locale_data = data[locale] ||= {}
          numbers = locale_data["numbers"] ||= {}
          numbers[KEY] = currencies.sort.to_h
          File.write(path, data.to_yaml)
        end
      end
    end
  end
end
