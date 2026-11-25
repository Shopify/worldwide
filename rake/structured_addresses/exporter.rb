# frozen_string_literal: true

require "worldwide"
require "json"
require "digest/sha2"
require "set"

module Worldwide
  # Generates the Structured Addresses artifact: a public, machine-readable, country-level
  # description of how an address is shaped, read from this gem's region data and nothing else.
  #
  # The artifact is the public contract; the schema in schema/structured-addresses.schema.json
  # defines it. Two versions travel with every artifact: schemaVersion (semver, the shape of the
  # JSON) and release (a date, the data snapshot). Neither is the gem version, which the
  # manifest records as provenance.
  module StructuredAddresses
    SCHEMA_VERSION = "1.0.0"
    ARTIFACT_FILE = "structured-addresses.json"
    MANIFEST_FILE = "manifest.json"
    SCHEMA_FILE = "structured-addresses.schema.json"

    # Layout tokens to artifact identifiers. Tokens not listed keep their name.
    TOKEN_TO_KEY = {
      "line2" => "additionalInformation",
      "country" => "countryCode",
      "province" => "provinceCode",
      "zip" => "postalCode",
    }.freeze

    KNOWN_TOKENS = [
      "firstName",
      "lastName",
      "company",
      "address1",
      "address2",
      "streetName",
      "streetNumber",
      "line2",
      "district",
      "subdistrict",
      "city",
      "province",
      "zip",
      "country",
      "phone",
    ].to_set.freeze

    COMPONENT_KEYS = ["street_name", "street_number", "line2", "district", "subdistrict"].freeze

    # Requiredness. required/optional are country-level facts, from region data where it
    # varies and constants where it never does. contextual means no single value is honest
    # for a majority of shops: the merchant decides, and a consumer should ask before
    # rendering the field.
    REQUIREMENT_VALUES = ["required", "optional", "contextual"].freeze
    ALWAYS_REQUIRED = ["first_name", "last_name", "address1", "country"].freeze
    ALWAYS_OPTIONAL = ["address2"].freeze
    CONTEXTUAL = ["company", "phone"].freeze

    class LayoutError < StandardError; end

    class Exporter
      def initialize(release:, locale: "en", countries: nil)
        raise ArgumentError, "release must be YYYY-MM-DD or YYYY-MM-DD.N, got #{release.inspect}" unless release.match?(/\A\d{4}-\d{2}-\d{2}(\.\d+)?\z/)
        raise ArgumentError, "only the en locale is supported" unless locale == "en"

        @release = release
        @locale = locale
        @countries = countries || self.class.country_codes
      end

      class << self
        def country_codes
          Worldwide::Regions.all.select(&:country?).reject(&:deprecated?).map(&:iso_code).sort
        end
      end

      def export
        Worldwide::Config.configure_i18n
        countries = I18n.with_locale(@locale) { @countries.sort.map { |code| export_country(code) } }
        { schemaVersion: SCHEMA_VERSION, release: @release, locale: @locale, countries: countries }
      end

      private

      def export_country(code)
        region = Worldwide.region(code: code)
        raise ArgumentError, "Unknown country: #{code}" unless region&.country?
        raise ArgumentError, "Deprecated country excluded: #{code}" if region.deprecated?

        structured = structured?(region)
        {
          code: code,
          name: region.full_name,
          coverage: structured ? "structured" : "flat",
          postalCode: { used: region.has_zip? },
          fields: fields(region),
          layouts: {
            edit: {
              flat: edit_rows(region.format["edit"]),
              structured: structured ? edit_rows(region.format_structured["edit"]) : nil,
            },
            show: {
              flat: show_rows(region.format["show"]),
              structured: structured ? show_rows(region.format_structured["show"]) : nil,
            },
          },
        }
      end

      def structured?(region)
        layout = region.format_structured
        !(layout.nil? || layout.empty? || layout["edit"].to_s.empty?)
      end

      def fields(region)
        tokens = Set.new
        [region.format["edit"], region.format["show"]].each { |s| tokens.merge(tokens_in(s)) }
        if structured?(region)
          [region.format_structured["edit"], region.format_structured["show"]].each { |s| tokens.merge(tokens_in(s)) }
        end
        region.address_line_components.each { |c| tokens << c["name"] }

        tokens.map do |token|
          raise LayoutError, "Unknown field token #{token} for #{region.iso_code}" unless KNOWN_TOKENS.include?(token)

          internal = snake(token)
          label = region.field(key: internal.to_sym).label
          raise LayoutError, "Missing #{@locale} label for #{region.iso_code}.#{token}" if label.to_s.empty?

          {
            key: TOKEN_TO_KEY.fetch(token, token),
            label: label,
            kind: COMPONENT_KEYS.include?(internal) ? "component" : "standard",
            requirement: requirement(region, token, internal),
          }
        end.sort_by { |f| f[:key] }
      end

      def requirement(region, token, internal)
        component = region.address_line_components.find { |c| c["name"] == token }
        return component["required"] ? "required" : "optional" if component

        case internal
        when "zip" then region.has_zip? && region.zip_required? ? "required" : "optional"
        when "province" then region.province_optional? ? "optional" : "required"
        when "city" then region.city_required? ? "required" : "optional"
        when *ALWAYS_REQUIRED then "required"
        when *ALWAYS_OPTIONAL then "optional"
        when *CONTEXTUAL then "contextual"
        else raise LayoutError, "No requirement rule for #{region.iso_code}.#{token}"
        end
      end

      # edit rows: lists of field keys. Lines are separated by "_", fields within a line by nothing.
      def edit_rows(format)
        unless format.is_a?(String) && format.match?(/\A\{[a-zA-Z0-9]+\}(?:_?\{[a-zA-Z0-9]+\})*\z/)
          raise LayoutError, "Malformed edit layout: #{format.inspect}"
        end

        format.split("_").map { |line| tokens_in(line).map { |t| key_for(t, format) } }
      end

      # show rows: lists of field keys and literal text elements ({text:}). A single space
      # between two fields is implicit and not emitted; any other literal text is emitted
      # verbatim, including its surrounding whitespace. A renderer concatenates a row's elements
      # in order and inserts one space only between two adjacent field keys.
      def show_rows(format)
        raise LayoutError, "Malformed show layout: #{format.inspect}" unless format.is_a?(String) && !format.empty?

        format.split("_").map do |line|
          row = line.split(/(\{[a-zA-Z0-9]+\})/).reject(&:empty?).filter_map do |part|
            if (m = part.match(/\A\{([a-zA-Z0-9]+)\}\z/))
              key_for(m[1], format)
            elsif part != " "
              { text: part }
            end
          end
          raise LayoutError, "Show row without fields: #{line.inspect}" if row.none?(String)

          row
        end
      end

      def key_for(token, format)
        raise LayoutError, "Unknown layout token {#{token}} in #{format}" unless KNOWN_TOKENS.include?(token)

        TOKEN_TO_KEY.fetch(token, token)
      end

      def tokens_in(format)
        format.to_s.scan(/\{([a-zA-Z0-9]+)\}/).flatten
      end

      def snake(str)
        str.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      end
    end

    class << self
      def artifact_json(artifact)
        JSON.pretty_generate(artifact) + "\n"
      end

      def manifest(artifact, commit: nil)
        {
          schemaVersion: artifact[:schemaVersion],
          release: artifact[:release],
          sources: { worldwide: { version: Worldwide::VERSION, commit: commit }.compact },
          artifact: { file: ARTIFACT_FILE, sha256: Digest::SHA256.hexdigest(artifact_json(artifact)) },
        }
      end

      def write(output_dir, release:, commit: nil)
        artifact = Exporter.new(release: release).export
        FileUtils.mkdir_p(output_dir)
        File.write(File.join(output_dir, ARTIFACT_FILE), artifact_json(artifact))
        File.write(File.join(output_dir, MANIFEST_FILE), JSON.pretty_generate(manifest(artifact, commit: commit)) + "\n")
        FileUtils.cp(File.join(Paths::GEM_ROOT, "schema", SCHEMA_FILE), File.join(output_dir, SCHEMA_FILE))
        artifact
      end
    end
  end
end
