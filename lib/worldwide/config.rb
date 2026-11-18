# frozen_string_literal: true

module Worldwide
  module Config
    # The list of CLDR data components needed by this gem
    # Users can add more data components to this list if they want to use them
    REQUIRED_CLDR_DATA = [
      "calendars",
      "context_transforms",
      "currencies",
      "languages",
      "layout",
      "lists",
      "numbers",
      "plurals",
      "subdivisions",
      "territories",
      "units",
    ].freeze

    CLDR_LOCALE_PATH_REGEX = /locales#{File::SEPARATOR}(?<locale>[\w-]+)#{File::SEPARATOR}(?<component>\w+)\.(?:yml|rb)/
    OTHER_LOCALE_PATH_REGEX = /#{File::SEPARATOR}(?<locale>[\w-]+)\.(?:yml|rb)/
    REGIONS_LOCALE_PATH_REGEX = /#{File::SEPARATOR}(?<locale>[\w-]+)\.yml/

    class << self
      def configure_i18n(i18n_config: nil, additional_components: [], ignore_precomputed_paths: false)
        i18n_config ||= I18n.config

        I18n::Backend::Simple.include(
          I18n::Backend::Fallbacks,
          I18n::Backend::Pluralization,
        )

        # Setting enforce_available_locales to true means that we'll get I18n::InvalidLocale exceptions
        # when trying to do anything in a locale that's not part of the configured I18n.available_locales.
        # We default to setting this because we'd rather raise an exception than have API calls silently
        # return nonsensical results.
        #
        # A quirk of ruby-i18n/i18n is that @@enforce_available_locales is always set to true:
        # https://github.com/ruby-i18n/i18n/blob/5eeaad7fb35f9a30f654e3bdeb6933daa7fd421d/lib/i18n/config.rb#L140
        #
        set_unless_explicitly_set(i18n_config, :enforce_available_locales, true)

        set_unless_explicitly_set(i18n_config, :default_locale, :en)
        set_unless_explicitly_set(i18n_config, :exception_handler, exception_handler)

        i18n_config.available_locales = expanded_locales_from_configuration(i18n_config)

        add_cldr_data(i18n_config, additional_components: additional_components, ignore_precomputed_paths: ignore_precomputed_paths)
        add_other_data(i18n_config, ignore_precomputed_paths: ignore_precomputed_paths)

        i18n_config
      end

      def exception_handler
        Worldwide::I18nExceptionHandler.new
      end

      # Registers YAML files for lookups inside Worldwide::Cldr.with_bundled_data, for libraries that add
      # data on top of Worldwide's. Each file is named after its locale (for example "ja.yml" or
      # "pt-BR.yml") and holds that locale's data under a top-level key of the same name. Other top-level
      # keys are ignored. A file whose name is not a well-formed locale identifier, such as "en.rails.yml",
      # or that spells one of Worldwide's locales in another case, such as "pt-br.yml", raises ArgumentError,
      # and none of the paths given are registered then. A name that matches none of Worldwide's locales is kept
      # as spelled, so a lookup reads the file only when its locale, or one of that locale's fallbacks, is spelled
      # the same way.
      #
      # The files apply after Worldwide's own data, and files registered later apply after files registered
      # earlier. A path that is already registered is ignored. Registering does not change I18n.load_path
      # or any host backend, so lookups outside the block do not see the files.
      #
      # The files are read on the first lookup that needs them. They may hold hashes, arrays, strings,
      # numbers, booleans, nil and symbols, with anchors and aliases. A file that is not valid YAML, or that
      # holds other Ruby objects, raises I18n::InvalidLocaleData naming the file on each lookup that needs it.
      # Register only files that your own code ships. Returns nil.
      def add_bundled_data_paths(paths)
        paths = Array(paths).map { |path| File.expand_path(path) }
        not_yaml = paths.reject { |path| File.extname(path) == ".yml" }
        raise ArgumentError, "Bundled data paths must be .yml files: #{not_yaml.join(", ")}" unless not_yaml.empty?

        not_locales = paths.reject { |path| I18n::Locale::Tag::Rfc4646.tag(File.basename(path, ".yml")) }
        unless not_locales.empty?
          raise ArgumentError, "Bundled data files must be named after a locale, such as ja.yml: #{not_locales.join(", ")}"
        end

        # Worldwide's own lookups and available locales use Worldwide's spelling, so they would not read a file named
        # after one of its locales in another case. The names come from the gem's directory of locales; no data file
        # is read.
        spellings = (Worldwide::Locales.known + [:root]).to_h { |locale| [locale.to_s.downcase, locale.to_s] }
        miscased = paths.filter_map do |path|
          name = File.basename(path, ".yml")
          expected = spellings[name.downcase]
          "#{path}: name it #{expected}.yml" unless expected.nil? || expected == name
        end
        unless miscased.empty?
          raise ArgumentError, "Bundled data files must spell the locale as Worldwide does: #{miscased.join("; ")}"
        end

        missing = paths.reject { |path| File.file?(path) }
        raise ArgumentError, "Bundled data files not found: #{missing.join(", ")}" unless missing.empty?

        Worldwide::Cldr::BundledData.instance.add_paths(paths)
        nil
      end

      private

      def i18n_defined?(i18n_config, key)
        if i18n_config.is_a?(I18n::Config)
          # If they are using I18n::Config:
          #  * an explicitly set value is stored in @@available_locales
          #  * an implicit value is resolved by asking the Backend (defaults to whatever language files it finds)
          # If they are using Worldwide::RubyI18nConfig:
          #  * an explicitly set value is stored in @available_locales
          #  * an implicit value is resolved via falling back to I18n::Config's behaviour
          # In either case, we want to use their values if they have set them explicitly, but
          # we don't want to trigger the backend resolution until after we've determined whether they have set it explicitly.
          class_variable = "@@#{key}".to_sym
          instance_variable = "@#{key}".to_sym
          i18n_config.class.class_variable_defined?(class_variable) || i18n_config.instance_variables.include?(instance_variable)
        else
          i18n_config.key?(key)
        end
      end

      def set_unless_explicitly_set(i18n_config, key, value)
        unless i18n_defined?(i18n_config, key)
          setter = "#{key}=".to_sym
          i18n_config.send(setter, value)
        end
      end

      def expanded_locales_from_configuration(i18n_config)
        locales = ((i18n_config&.available_locales || []) + Array(i18n_config.default_locale)).uniq

        # Add in locales that derive from the selected locale.
        # E.g., if "fr" is selected, then include "fr-CA", "fr-CH", "fr-FR", ...
        locales = locales.flat_map { |locale| Worldwide::Cldr.fallbacks.descendants(locale) }

        # Add in the locales needed for CLDR fallback chains
        locales = locales.flat_map { |locale| Worldwide::Cldr.fallbacks[locale.to_sym].map(&:to_s) }.uniq

        # In case they customize I18n.fallbacks, add in the locales needed for their custom fallback chains
        locales = locales.flat_map { |locale| I18n.fallbacks[locale.to_sym].map(&:to_s) }.uniq if I18n.fallbacks

        locales.uniq.sort
      end

      def add_cldr_data(i18n_config, additional_components:, ignore_precomputed_paths: false)
        locale_set = i18n_config.available_locales.map(&:to_s).to_set
        components = REQUIRED_CLDR_DATA + additional_components

        i18n_config.load_path += if ignore_precomputed_paths
          Dir[File.join(Paths::CLDR_ROOT, "locales", "{#{locale_set.to_a.join(",")}}/{#{components.join(",")}}.{yml,rb}")]
        else
          cldr_precomputed_locale_paths(locale_set, components)
        end
      end

      def cldr_precomputed_locale_paths(locale_set, components)
        File.read(Paths::CLDR_LOCALE_PATHS_FILE)
          .lines
          .map { |path| File.join(Paths::GEM_ROOT, path.strip) }
          .select do |path|
            match = path.match(CLDR_LOCALE_PATH_REGEX)
            match && locale_set.include?(match[:locale]) && components.include?(match[:component])
          end
      end

      def add_other_data(i18n_config, ignore_precomputed_paths: false)
        locale_set = i18n_config.available_locales.map(&:to_s).to_set

        if ignore_precomputed_paths
          locales = locale_set.to_a
          i18n_config.load_path += Dir[File.join(Paths::OTHER_DATA_ROOT, "*", "{#{locales.join(",")}}.{yml,rb}")]
          i18n_config.load_path += Dir[File.join(Paths::REGIONS_ROOT, "{#{locales.join(",")}}.yml")]
        else
          i18n_config.load_path += other_data_path(locale_set)
          i18n_config.load_path += regions_data_path(locale_set)
        end
      end

      def other_data_path(locale_set)
        File.read(Paths::OTHER_DATA_PATHS_FILE)
          .lines
          .map { |path| File.join(Paths::GEM_ROOT, path.strip) }
          .select do |path|
            match = path.match(OTHER_LOCALE_PATH_REGEX)
            match && locale_set.include?(match[:locale])
          end
      end

      def regions_data_path(locale_set)
        File.read(Paths::REGION_DATA_PATHS_FILE)
          .lines
          .map { |path| File.join(Paths::GEM_ROOT, path.strip) }
          .select do |path|
            match = path.match(REGIONS_LOCALE_PATH_REGEX)
            match && locale_set.include?(match[:locale])
          end
      end
    end
  end
end
