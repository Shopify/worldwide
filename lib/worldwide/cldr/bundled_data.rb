# frozen_string_literal: true

require "set"
require_relative "bundled_backend"
require_relative "bundled_config"

module Worldwide
  module Cldr
    # Worldwide's own data for lookups inside Worldwide::Cldr.with_bundled_data, read from the gem's
    # data files instead of through the host's I18n configuration. Nothing is built or read until the
    # first lookup inside a block.
    class BundledData
      # The first key segments that the files of each family hold. A lookup reads only the families that
      # list its first segment. A lookup whose first segment no family lists reads every file of its locale.
      SEGMENTS_BY_FAMILY = {
        "cldr/calendars" => [:calendars],
        "cldr/context_transforms" => [:context_transforms],
        "cldr/currencies" => [:currencies],
        "cldr/languages" => [:languages],
        "cldr/layout" => [:layout],
        "cldr/lists" => [:lists],
        "cldr/numbers" => [:numbers],
        "cldr/plurals" => [:i18n],
        "cldr/subdivisions" => [:subdivisions],
        "cldr/territories" => [:territories],
        "cldr/units" => [:units],
        "other/currency" => [:currencies],
        "other/generated" => [:date, :time],
        "other/hand_translated" => [:date_time_translation],
        "other/lists" => [:lists],
        "other/names" => [:names],
        "other/territories" => [:subdivisions, :territories],
        "other/timezones" => [:timezones],
        "other/units" => [:unit_length, :units],
        "regions" => [:worldwide],
      }.transform_values(&:freeze).freeze

      @instance = nil
      @instance_mutex = Mutex.new

      class << self
        # The data source that Worldwide::Cldr.with_bundled_data reads.
        def instance
          @instance || @instance_mutex.synchronize { @instance ||= new }
        end
      end

      # The files registered with Worldwide::Config.add_bundled_data_paths, in the order they apply.
      attr_reader :paths

      def initialize(segments_by_family: SEGMENTS_BY_FAMILY)
        @segments_by_family = segments_by_family
        @paths = [].freeze
        @mutex = Mutex.new
        @config = nil
      end

      def built?
        !@config.nil?
      end

      # The I18n configuration that each lookup inside the block copies.
      def config
        @config || @mutex.synchronize do
          @config ||= BundledConfig.new(BundledBackend.new(build_index, @paths))
        end
      end

      def backend
        config.backend
      end

      # Adds YAML files to apply after Worldwide's data and after the files registered before them.
      # A path that is already registered is ignored, so it keeps its place.
      def add_paths(paths)
        @mutex.synchronize do
          paths = (@paths + paths).uniq
          next if paths == @paths

          @paths = paths.freeze
          @config&.backend&.overlay_paths = @paths
        end
      end

      private

      def build_index
        Index.new(@segments_by_family)
      end

      # Worldwide's data files for each locale, in the order that Worldwide::Config.configure_i18n loads them.
      class Index
        attr_reader :locales

        def initialize(segments_by_family)
          @families_by_segment = {}
          segments_by_family.each do |family, segments|
            segments.each { |segment| (@families_by_segment[segment] ||= Set.new) << family }
          end

          @entries = {}
          read_indices
          @entries.each_value(&:freeze).freeze

          # A locale with a file of a family that the map does not list is always read whole.
          @whole_locales = @entries.filter_map do |locale, entries|
            locale if entries.any? { |family, _path| !segments_by_family.key?(family) }
          end.to_set.freeze

          @locales = (@entries.keys | Worldwide::Locales.known | [:root]).freeze
        end

        def each_entry
          @entries.each do |locale, entries|
            entries.each { |family, path| yield locale, family, path }
          end
        end

        def paths(locale)
          @entries.fetch(locale, []).map(&:last)
        end

        # The files of locale that can hold the first key segment, or nil when any of its files may hold it.
        def segment_paths(locale, segment)
          families = @families_by_segment[segment]
          return if families.nil? || @whole_locales.include?(locale)

          @entries.fetch(locale, []).filter_map { |family, path| path if families.include?(family) }
        end

        private

        def read_indices
          each_path(Paths::CLDR_LOCALE_PATHS_FILE) do |path|
            match = path.match(Worldwide::Config::CLDR_LOCALE_PATH_REGEX)
            next unless match && Worldwide::Config::REQUIRED_CLDR_DATA.include?(match[:component])

            add(match[:locale], "cldr/#{match[:component]}", path)
          end

          each_path(Paths::OTHER_DATA_PATHS_FILE) do |path|
            match = path.match(Worldwide::Config::OTHER_LOCALE_PATH_REGEX)
            add(match[:locale], "other/#{File.basename(File.dirname(path))}", path) if match
          end

          each_path(Paths::REGION_DATA_PATHS_FILE) do |path|
            match = path.match(Worldwide::Config::REGIONS_LOCALE_PATH_REGEX)
            add(match[:locale], "regions", path) if match
          end
        end

        def each_path(index_file)
          File.foreach(index_file) { |line| yield File.join(Paths::GEM_ROOT, line.strip) }
        end

        def add(locale, family, path)
          (@entries[locale.to_sym] ||= []) << [family, path]
        end
      end
    end
  end
end
