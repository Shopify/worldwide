# frozen_string_literal: false

require "cldr/download"
require "cldr/draft_status"
require "cldr/export"
require "fileutils"
require "json"
require "net/http"
require "yaml"

module Worldwide
  module Cldr
    class Puller
      VENDORED_CLDR_DIR = File.join("vendor", "cldr")
      VENDORED_CLDR_VERSION_FILE = File.join("vendor", "cldr", "version.yml")

      EXPORTED_CLDR_DIR = File.join("vendor", "ruby-cldr")
      EXPORTED_CLDR_VERSION_FILE = File.join(EXPORTED_CLDR_DIR, "versions.yml")

      DEFAULT_COMPONENTS = ::Cldr::Export::Data.components - [:Transforms, :Variables]

      class << self
        def perform(version, components)
          version = version ? Integer(version) : default_branch_sha
          components = normalize_components(components)

          download_cldr_data(version)
          puts "✅  Download completed"

          FileUtils.rm_rf(EXPORTED_CLDR_DIR)
          puts(components ? "⏳  Exporting components: #{components.map { |c| "`#{c}`" }.join(", ")}" : "⏳  Exporting all components")
          ::Cldr::Export.export(target: EXPORTED_CLDR_DIR, components: components, minimum_draft_status: ::Cldr::DraftStatus::CONTRIBUTED) { putc("⏳ ") }
          puts "\n✅  Files transformed to YAML in: #{EXPORTED_CLDR_DIR}"

          create_version_file(version)
          puts "🌍  All good!"
        end

        private

        def default_branch_sha
          uri = URI("https://api.github.com/repos/unicode-org/cldr-staging/branches/main")
          response = JSON.parse(Net::HTTP.get(uri))
          response["commit"]["sha"]
        end

        def normalize_components(components)
          components = components.presence
          components = components.split(",").map(&:strip).map(&:to_sym).sort if components

          invalid_selected_components = (components || []) - ::Cldr::Export::Data.components
          raise ArgumentError, "Requested unknown CLDR components: #{invalid_selected_components}" if invalid_selected_components.present?

          components ||= DEFAULT_COMPONENTS

          components
        end

        def delete_download_semaphore
          FileUtils.rm_rf(VENDORED_CLDR_VERSION_FILE)
        end

        def create_download_semaphore(version)
          File.write(VENDORED_CLDR_VERSION_FILE, YAML.dump({ "cldr" => version }))
        end

        def formatted_version(version)
          version.is_a?(Integer) ? "v#{version}" : "@ #{version[0..6]}"
        end

        def download_cldr_data(version)
          existing_version = File.exist?(VENDORED_CLDR_VERSION_FILE) ? YAML.load_file(VENDORED_CLDR_VERSION_FILE)["cldr"] : nil

          if version != existing_version && Dir.exist?(VENDORED_CLDR_DIR)
            previous_version_clause = existing_version ? " (#{formatted_version(existing_version)})" : ""
            puts "🗑️  Cleaning up previously downloaded version of CLDR#{previous_version_clause}."
            FileUtils.rm_rf(VENDORED_CLDR_DIR)
          end

          delete_download_semaphore

          if version == existing_version
            puts "⏩  Skipping download of CLDR #{formatted_version(version)}; we've already downloaded it"
          elsif version.is_a?(Integer)
            puts "🚚  Fetching data for CLDR v#{version}"

            ::Cldr::Download.download("https://unicode.org/Public/cldr/#{version}/core.zip") { putc("⏳ ") }
          else
            puts "🚚  Fetching latest CLDR data from https://github.com/unicode-org/cldr-staging #{formatted_version(version)}"
            ::Cldr::Download.download("https://github.com/unicode-org/cldr-staging/archive/#{version}.zip") { putc("⏳ ") }
            FileUtils.mv(Dir.glob("vendor/cldr/cldr-staging-#{version}/production/*"), "vendor/cldr")
            FileUtils.rm_rf("vendor/cldr/cldr-staging-#{version}")
          end

          create_download_semaphore(version)
        end

        def create_version_file(version)
          File.write(EXPORTED_CLDR_VERSION_FILE, YAML.dump(
            {
              "cldr" => version,
              "ruby-cldr" => Gem.loaded_specs["ruby-cldr"].version.to_s,
            },
          ))
        end
      end
    end
  end
end
