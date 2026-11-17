# frozen_string_literal: true

require "concurrent/hash"
require "concurrent/map"
require "set"

module Worldwide
  module Cldr
    # The I18n backend for lookups inside Worldwide::Cldr.with_bundled_data.
    #
    # It includes I18n::Backend::Simple's implementation instead of subclassing I18n::Backend::Simple,
    # so modules that a host includes into I18n::Backend::Simple do not change it, and it never reads
    # I18n.load_path. The first lookup of a key in a locale reads the files of that locale that can hold
    # the key's first segment (such as "numbers"), then the registered files of that locale. Only the
    # data under that locale is kept from each file.
    class BundledBackend
      include I18n::Backend::Simple::Implementation
      include I18n::Backend::Pluralization
      include I18n::Backend::Fallbacks

      # The data read so far. Its maps are filled in under the backend's mutex, and a segment is marked
      # as read only after its data is stored. Registering files replaces the whole state at once, so that
      # a lookup never finds a segment marked as read while its translations are missing.
      class State
        attr_reader :translations, :available_locales, :available_locales_set

        def initialize(locales, overlay_paths)
          @translations = Concurrent::Hash.new
          @loaded_segments = Concurrent::Map.new
          @whole_locales = Concurrent::Map.new
          @overlay_paths = overlay_paths.group_by { |path| File.basename(path, ".yml").to_sym }
          @overlay_trees = {}
          @available_locales = (locales | @overlay_paths.keys).sort.freeze
          @available_locales_set = @available_locales.each_with_object(Set.new) do |locale, set|
            set << locale << locale.to_s
          end.freeze
          freeze
        end

        def loaded?(locale, segment)
          segments = @loaded_segments[locale]
          (!segments.nil? && segments.key?(segment)) || @whole_locales.key?(locale)
        end

        def whole_locale_loaded?(locale)
          @whole_locales.key?(locale)
        end

        def loaded_segments
          @loaded_segments.keys.to_h { |locale| [locale, @loaded_segments[locale].keys.sort_by(&:to_s)] }
        end

        # The callers below hold the backend's mutex.

        def mark_loaded(locale, segments, whole_locale: false)
          loaded = (@loaded_segments[locale] ||= Concurrent::Map.new)
          segments.each { |segment| loaded[segment] = true }
          @whole_locales[locale] = true if whole_locale
        end

        def overlay_paths(locale)
          @overlay_paths.fetch(locale, [])
        end

        def overlay_tree(path)
          @overlay_trees.fetch(path) { @overlay_trees[path] = yield }
        end
      end

      def initialize(index, overlay_paths = [])
        @index = index
        @overlay_paths = overlay_paths.dup.freeze
        @mutex = Mutex.new
        @state = new_state
      end

      # Files registered later win over files registered earlier. Data already read is dropped,
      # and later lookups read it again with the new files.
      def overlay_paths=(paths)
        @mutex.synchronize do
          @overlay_paths = paths.dup.freeze
          @state = new_state
        end
      end

      def reload!
        @mutex.synchronize { @state = new_state }
      end

      def initialized?
        true
      end

      def available_locales
        @state.available_locales
      end

      def available_locales_set
        @state.available_locales_set
      end

      # The data read so far.
      def translations(**)
        @state.translations
      end

      def store_translations(_locale, _data, _options = I18n::EMPTY_HASH)
        raise FrozenError.new(
          "Bundled data cannot be changed. Register files with Worldwide::Config.add_bundled_data_paths.",
          receiver: self,
        )
      end

      def loaded_segments
        @state.loaded_segments
      end

      def whole_locale_loaded?(locale)
        @state.whole_locale_loaded?(locale.to_sym)
      end

      protected

      def init_translations
        @initialized = true
      end

      # Looks up a key as I18n::Backend::Simple does, after reading the data that its first segment needs.
      def lookup(locale, key, scope = [], options = I18n::EMPTY_HASH)
        keys = I18n.normalize_keys(locale, key, scope, options[:separator])
        locale = keys.first
        segment = keys[1]
        state = @state
        state = load(locale, segment) unless state.loaded?(locale, segment)

        keys.inject(state.translations) do |result, part|
          break unless result.is_a?(Hash)

          unless result.key?(part)
            part = part.to_s.to_sym
            break unless result.key?(part)
          end

          result = result[part]
          result = resolve_entry(locale, part, result, I18n::Utils.except(options.merge(scope: nil), :count)) if result.is_a?(Symbol)
          result
        end
      end

      private

      def new_state
        State.new(@index.locales, @overlay_paths)
      end

      # Reads the data for segment into the current state, and returns that state.
      def load(locale, segment)
        @mutex.synchronize do
          state = @state
          unless state.loaded?(locale, segment)
            paths = @index.segment_paths(locale, segment)
            if paths.nil?
              load_whole_locale(state, locale)
            else
              load_segment(state, locale, segment, paths)
            end
          end
          state
        end
      end

      def load_segment(state, locale, segment, paths)
        trees = paths.map { |path| read_file(path, locale) } + overlay_trees(state, locale)
        trees.each { |tree| store(state, locale, tree.slice(segment)) }
        state.mark_loaded(locale, [segment])
      end

      # Used when a segment is not in the family map, so any file of the locale may hold it.
      # Segments read earlier are kept as they are, so registered files still win over Worldwide's files.
      def load_whole_locale(state, locale)
        trees = @index.paths(locale).map { |path| read_file(path, locale) } + overlay_trees(state, locale)
        segments = trees.flat_map(&:keys).uniq.reject { |segment| state.loaded?(locale, segment) }
        trees.each { |tree| store(state, locale, tree.slice(*segments)) }
        state.mark_loaded(locale, segments, whole_locale: true)
      end

      # Registered files are always read as YAML, whatever their name.
      def overlay_trees(state, locale)
        state.overlay_paths(locale).map do |path|
          state.overlay_tree(path) { read_file(path, locale, ruby: false) }
        end
      end

      # Returns the data under locale in the file at path. Data under other locales is ignored,
      # because some files are named after one locale and hold another.
      def read_file(path, locale, ruby: path.end_with?(".rb"))
        data, keys_symbolized = ruby ? load_rb(path) : load_yml(path)
        raise I18n::InvalidLocaleData.new(path, "expects it to return a hash, but does not") unless data.is_a?(Hash)

        data = I18n::Utils.deep_symbolize_keys(data) unless keys_symbolized
        tree = data[locale]
        tree.is_a?(Hash) ? tree : {}
      end

      def store(state, locale, data)
        return if data.empty?

        translations = (state.translations[locale] ||= Concurrent::Hash.new)
        I18n::Utils.deep_merge!(translations, data)
      end
    end
  end
end
