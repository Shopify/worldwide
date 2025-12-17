# frozen_string_literal: true

require "fileutils"
require "json"
require "yaml"

module Worldwide
  module Icu4x
    # Converts worldwide's patched CLDR YAML data to CLDR JSON format
    # compatible with icu_datagen.
    #
    # The conversion follows the CLDR JSON schema:
    # https://cldr.unicode.org/index/cldr-spec/cldr-json-bindings
    #
    # Output structure:
    #   vendor/cldr-json/
    #   ├── cldr-numbers-full/main/{locale}/numbers.json
    #   ├── cldr-numbers-full/main/{locale}/currencies.json
    #   ├── cldr-dates-full/main/{locale}/ca-gregorian.json
    #   ├── cldr-localenames-full/main/{locale}/territories.json
    #   ├── cldr-localenames-full/subdivisions/{locale}/territories.json
    #   └── cldr-core/supplemental/plurals.json
    class JsonExporter
      OUTPUT_DIR = File.join("vendor", "cldr-json")
      CLDR_ROOT = File.join("data", "cldr")

      def self.perform
        new.perform
      end

      def perform
        puts "🚀 Starting YAML→JSON conversion for ICU4X"
        
        FileUtils.rm_rf(OUTPUT_DIR)
        FileUtils.mkdir_p(OUTPUT_DIR)

        export_numbers
        export_currencies
        export_dates
        export_territories
        export_subdivisions
        export_plurals
        export_core_data

        puts "✅ YAML→JSON conversion complete: #{OUTPUT_DIR}"
      end

      private

      # Export numbers data from locales/*/numbers.yml
      def export_numbers
        puts "📊 Exporting numbers data..."
        
        numbers_dir = File.join(OUTPUT_DIR, "cldr-numbers-full", "main")
        FileUtils.mkdir_p(numbers_dir)

        each_locale_file("numbers.yml") do |locale, content|
          data = content[locale.to_s] || {}
          
          # Wrap in CLDR JSON structure
          json_data = {
            "main" => {
              locale.to_s => {
                "identity" => { "language" => extract_language(locale) },
                "numbers" => data
              }
            }
          }

          output_file = File.join(numbers_dir, locale.to_s, "numbers.json")
          FileUtils.mkdir_p(File.dirname(output_file))
          File.write(output_file, JSON.pretty_generate(json_data))
        end
      end

      # Export currencies data from locales/*/currencies.yml
      def export_currencies
        puts "💱 Exporting currencies data..."
        
        currencies_dir = File.join(OUTPUT_DIR, "cldr-numbers-full", "main")
        FileUtils.mkdir_p(currencies_dir)

        each_locale_file("currencies.yml") do |locale, content|
          data = content[locale.to_s] || {}
          
          json_data = {
            "main" => {
              locale.to_s => {
                "identity" => { "language" => extract_language(locale) },
                "numbers" => { "currencies" => data }
              }
            }
          }

          output_file = File.join(currencies_dir, locale.to_s, "currencies.json")
          FileUtils.mkdir_p(File.dirname(output_file))
          File.write(output_file, JSON.pretty_generate(json_data))
        end
      end

      # Export calendar/date data from locales/*/calendars.yml
      def export_dates
        puts "📅 Exporting dates data..."
        
        dates_dir = File.join(OUTPUT_DIR, "cldr-dates-full", "main")
        FileUtils.mkdir_p(dates_dir)

        each_locale_file("calendars.yml") do |locale, content|
          data = content[locale.to_s] || {}
          
          json_data = {
            "main" => {
              locale.to_s => {
                "identity" => { "language" => extract_language(locale) },
                "dates" => data
              }
            }
          }

          output_file = File.join(dates_dir, locale.to_s, "ca-gregorian.json")
          FileUtils.mkdir_p(File.dirname(output_file))
          File.write(output_file, JSON.pretty_generate(json_data))
        end
      end

      # Export territory names from locales/*/territories.yml
      def export_territories
        puts "🌍 Exporting territories data..."
        
        territories_dir = File.join(OUTPUT_DIR, "cldr-localenames-full", "main")
        FileUtils.mkdir_p(territories_dir)

        each_locale_file("territories.yml") do |locale, content|
          data = content[locale.to_s] || {}
          
          json_data = {
            "main" => {
              locale.to_s => {
                "identity" => { "language" => extract_language(locale) },
                "localeDisplayNames" => { "territories" => data }
              }
            }
          }

          output_file = File.join(territories_dir, locale.to_s, "territories.json")
          FileUtils.mkdir_p(File.dirname(output_file))
          File.write(output_file, JSON.pretty_generate(json_data))
        end
      end

      # Export subdivision names from locales/*/subdivisions.yml
      def export_subdivisions
        puts "🗺️  Exporting subdivisions data..."
        
        subdivisions_dir = File.join(OUTPUT_DIR, "cldr-localenames-full", "subdivisions")
        FileUtils.mkdir_p(subdivisions_dir)

        each_locale_file("subdivisions.yml") do |locale, content|
          data = content[locale.to_s] || {}
          
          json_data = {
            "subdivisions" => {
              locale.to_s => data
            }
          }

          output_file = File.join(subdivisions_dir, locale.to_s, "territories.json")
          FileUtils.mkdir_p(File.dirname(output_file))
          File.write(output_file, JSON.pretty_generate(json_data))
        end
      end

      # Export plural rules from locales/*/plural_rules.yml
      def export_plurals
        puts "🔢 Exporting plurals data..."
        
        plurals_dir = File.join(OUTPUT_DIR, "cldr-core", "supplemental")
        FileUtils.mkdir_p(plurals_dir)

        plurals_data = {}

        each_locale_file("plural_rules.yml") do |locale, content|
          locale_str = locale.to_s
          if content[locale_str]
            plurals_data[locale_str] = content[locale_str]
          end
        end

        json_data = { "supplemental" => { "plurals" => plurals_data } }
        output_file = File.join(plurals_dir, "plurals.json")
        File.write(output_file, JSON.pretty_generate(json_data))
      end

      # Export core supplemental data
      def export_core_data
        puts "📦 Exporting core supplemental data..."
        
        core_dir = File.join(OUTPUT_DIR, "cldr-core", "supplemental")
        FileUtils.mkdir_p(core_dir)

        # Export likely subtags
        if File.exist?(File.join(CLDR_ROOT, "likely_subtags.yml"))
          data = YAML.safe_load_file(File.join(CLDR_ROOT, "likely_subtags.yml"))
          json_data = { "supplemental" => { "likelySubtags" => data } }
          File.write(File.join(core_dir, "likelySubtags.json"), JSON.pretty_generate(json_data))
        end

        # Export parent locales
        if File.exist?(File.join(CLDR_ROOT, "parent_locales.yml"))
          data = YAML.safe_load_file(File.join(CLDR_ROOT, "parent_locales.yml"))
          json_data = { "supplemental" => { "parentLocales" => data } }
          File.write(File.join(core_dir, "parentLocales.json"), JSON.pretty_generate(json_data))
        end
      end

      # Iterate over all locale files of a given type
      def each_locale_file(filename)
        locales_dir = File.join(CLDR_ROOT, "locales")
        Dir.glob(File.join(locales_dir, "*", filename)).each do |filepath|
          locale = File.basename(File.dirname(filepath))
          content = YAML.safe_load_file(filepath, permitted_classes: [Symbol])
          yield locale, content
        end
      end

      # Extract language code from locale (e.g., "en-US" -> "en")
      def extract_language(locale)
        locale.to_s.split("-").first
      end
    end
  end
end
