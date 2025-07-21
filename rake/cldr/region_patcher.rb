# frozen_string_literal: true

require "yaml"
require "fileutils"
require "csv"

module Worldwide
  module Cldr
    class RegionPatcher
      attr_reader :country_code, :patches, :content, :yaml_path

      def initialize(country_code)
        @country_code = country_code.upcase
        @patches = []

        yaml_path = File.join(Worldwide::Paths::REGIONS_ROOT, "#{@country_code}.yml")
        unless File.exist?(yaml_path)
          raise ArgumentError, "Region file not found: #{yaml_path}"
        end

        @yaml_path = yaml_path
        @content = YAML.safe_load_file(yaml_path)
      end

      # Add a patch to be applied to the YAML file
      # @param path [Array<String>] The path to the value to patch (e.g., ["tax"], ["zones", 0, "name"])
      # @param value [Object] The new value to set
      # @param operation [Symbol] The operation to perform (:set, :append, :remove, :merge)
      def add_patch(path:, value:, operation: :set)
        @patches << { path: path, value: value, operation: operation }
      end

      def apply!
        # Create a backup before modifying
        backup_path = "#{yaml_path}.backup"
        FileUtils.cp(yaml_path, backup_path)

        begin
          @patches.each do |patch|
            apply_patch_to_content(content, patch)
          end

          File.write(yaml_path, YAML.dump(content))

          # Remove backup on success
          FileUtils.rm(backup_path) if File.exist?(backup_path)

          true
        rescue StandardError => e
          # Restore from backup on error
          FileUtils.mv(backup_path, yaml_path) if File.exist?(backup_path)
          raise e
        end
      end

      # Patch a specific zone/province within a country
      # @param zone_code [String] The zone code to patch (e.g., "JP-13" for Tokyo)
      # @param attribute [String] The attribute to patch within the zone
      # @param value [Object] The new value
      def patch_zone(zone_code:, attribute:, value:)
        zone_index = find_zone_index(content, zone_code)

        if zone_index.nil?
          raise ArgumentError, "Zone not found: #{zone_code}"
        end

        add_patch(
          path: ["zones", zone_index, attribute],
          value: value,
          operation: :set,
        )
      end

      # warning: supports only Array and Hash, and if Array, can have at most one extra index
      def make_path_patch(path:, desired_type:)
        add_patch(
          path: path,
          value: desired_type,
          operation: :make_path,
        )
      end

      def get_zone_index(zone_code)
        find_zone_index(content, zone_code)
      end

      private

      def find_zone_index(content, zone_code)
        zones = content["zones"] || []
        zones.find_index { |zone| zone["code"] == zone_code || zone["iso_code"] == zone_code }
      end

      def apply_patch_to_content(content, patch)
        path = patch[:path]
        value = patch[:value]
        operation = patch[:operation]

        case operation
        when :set
          set_value_at_path(content, path, value)
        when :append
          append_value_at_path(content, path, value)
        when :remove
          remove_value_at_path(content, path)
        when :merge
          merge_value_at_path(content, path, value)
        when :make_path
          create_path_if_not_exists(content, path, value)
        else
          raise ArgumentError, "Unknown operation: #{operation}"
        end
      end

      def get_value_at_path(content, path)
        path.reduce(content) do |current, key|
          return nil if current.nil?

          if current.is_a?(Array) && key.is_a?(Integer)
            current[key]
          elsif current.is_a?(Hash)
            current[key.to_s]
          end
        end
      end

      def create_path_if_not_exists(content, path, desired_type)
        path.reduce(content) do |current, key|
          return nil if current.nil?

          if current.is_a?(Array) && key.is_a?(Integer)
            current[key]
          elsif current.is_a?(Hash)
            if current.has_key?(key.to_s)
              current[key.to_s]
            else
              current[key.to_s] = desired_type.dup
              nil
            end
          else
            raise ArgumentError, "Cannot create path: current is #{current.class}, key is #{key.class}"
          end
        end
      end

      def set_value_at_path(content, path, value)
        # path is an Array of String/Integer keys representing the path to navigate
        parent_path = path[0...-1]
        last_key = path[-1]

        parent = parent_path.empty? ? content : get_parent_at_path(content, parent_path)

        if parent.is_a?(Array) && last_key.is_a?(Integer)
          parent[last_key] = value
        elsif parent.is_a?(Hash)
          parent[last_key.to_s] = value
        else
          raise ArgumentError, "Cannot set value at path: #{path.join(" → ")}"
        end
      end

      def append_value_at_path(content, path, value)
        target = get_value_at_path(content, path)

        if target.is_a?(Array)
          target << value
        else
          raise ArgumentError, "Cannot append to non-array at path: #{path.join(" → ")}"
        end
      end

      def remove_value_at_path(content, path)
        *parent_path, last_key = path

        parent = parent_path.empty? ? content : get_parent_at_path(content, parent_path)

        if parent.is_a?(Array) && last_key.is_a?(Integer)
          parent.delete_at(last_key)
        elsif parent.is_a?(Hash)
          parent.delete(last_key.to_s)
        else
          raise ArgumentError, "Cannot remove value at path: #{path.join(" → ")}"
        end
      end

      def merge_value_at_path(content, path, value)
        target = get_value_at_path(content, path)

        if target.is_a?(Hash) && value.is_a?(Hash)
          target.merge!(value)
        else
          raise ArgumentError, "Cannot merge non-hash values at path: #{path.join(" → ")}"
        end
      end

      def get_parent_at_path(content, path)
        path.reduce(content) do |current, key|
          if current.is_a?(Array) && key.is_a?(Integer)
            current[key]
          elsif current.is_a?(Hash)
            current[key.to_s]
          else
            raise ArgumentError, "Invalid path: #{path.join(" → ")}"
          end
        end
      end
    end

    class JpZipPrefixPatcher
      class << self
        def perform(csv_path, csv_reader, max_length_prefix)
          new(csv_path, csv_reader, max_length_prefix).perform
        end
      end

      def initialize(csv_path, csv_reader, max_length_prefix)
        @csv_path = csv_path
        @csv_reader = csv_reader
        @max_length_prefix = max_length_prefix
        @zone_to_prefixes = Hash.new { |h, k| h[k] = Set.new }
      end

      def perform
        process_csv
        patch_regions
      end

      private

      class TrieNode
        attr_reader :children, :part_of_zone

        def initialize
          @children = {}
          @part_of_zone = Set.new
        end

        def add_word_for_zone(word, zone_code)
          current_node = self
          current_node.part_of_zone << zone_code
          word.each_char do |char|
            current_node.children[char] ||= TrieNode.new
            current_node = current_node.children[char]
            current_node.part_of_zone << zone_code
          end
        end
      end

      def build_memoized_trie(trie_root)
        @csv_reader.get_rows do |row|
          iso2_code = @csv_reader.get_iso2(row)
          postcode = @csv_reader.get_postcode(row)
          if iso2_code.nil? || postcode.nil? || !iso2_code.start_with?("JP-")
            next
          end

          trie_root.add_word_for_zone(postcode, iso2_code)
        end

        trie_root
      end

      def _helper(node, prefixes, prefix, depth)
        # stop at length 3 prefixes
        if depth > @max_length_prefix - 1
          node.part_of_zone.each do |zone_code|
            prefixes[zone_code] << prefix
          end
          return
        end

        if node.part_of_zone.size == 1
          prefixes[node.part_of_zone.first] << prefix
          return
        end

        node.children.each do |char, child|
          _helper(child, prefixes, prefix + char, depth + 1)
        end
      end

      def get_zone_unique_prefixes(trie_root)
        # step 1: map each zone to its unique prefixes
        prefixes = Hash.new { |h, k| h[k] = Set.new }
        _helper(trie_root, prefixes, "", 0)

        # step 2: identify and extract prefixes that are shared by multiple zones
        prefix_to_zone = Hash.new { |h, k| h[k] = Set.new }
        prefixes.each do |zone_code, prefixes|
          prefixes.each do |prefix|
            prefix_to_zone[prefix] << zone_code
          end
        end
        shared_prefixes = prefix_to_zone.filter { |_, zones| zones.size > 1 }

        # step 3: identify neighbouring zones
        zone_to_neighboring_zones = Hash.new { |h, k| h[k] = Set.new }
        shared_prefixes.each do |_prefix, zone_codes|
          zone_codes.each do |zone_code|
            (zone_codes - [zone_code]).each do |neighbor_code|
              zone_to_neighboring_zones[zone_code] << neighbor_code
            end
          end
        end

        [prefixes, shared_prefixes, zone_to_neighboring_zones]
      end

      def process_csv
        trie_root = build_memoized_trie(TrieNode.new)
        @zone_to_prefixes, @shared_prefixes, @zone_to_neighboring_zones = get_zone_unique_prefixes(trie_root)
      end

      def patch_regions
        patcher = Worldwide::Cldr::RegionPatcher.new("JP")

        all_jp_prefixes = Set.new
        @zone_to_prefixes.each do |zone_code, prefixes|
          patcher.patch_zone(
            zone_code: zone_code,
            attribute: "zip_prefixes",
            value: prefixes.to_a.sort,
          )
          all_jp_prefixes.merge(prefixes)
        end

        if @shared_prefixes.any?
          patcher.add_patch(
            path: ["zips_crossing_provinces"],
            value: {}, # init with empty hash to avoid nil errors
            operation: :set,
          )
          @shared_prefixes.each do |prefix, zone_codes|
            # add zips crossing provinces for each prefix
            patcher.add_patch(
              path: ["zips_crossing_provinces", prefix],
              value: zone_codes.to_a.sort,
              operation: :set,
            )
          end
        else
          patcher.add_patch(
            path: ["zips_crossing_provinces"],
            value: nil,
            operation: :remove,
          )
        end

        @zone_to_neighboring_zones.each do |zone_code, neighboring_zones|
          patcher.make_path_patch( # ensure we have an array at the path
            path: ["zones", patcher.get_zone_index(zone_code), "neighboring_zones"],
            desired_type: [],
          )
          patcher.patch_zone(
            zone_code: zone_code,
            attribute: "neighboring_zones",
            value: neighboring_zones.to_a.sort,
          )
        end

        patcher.apply!
      end
    end
  end
end
