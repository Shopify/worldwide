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

    # Protects against multiple calls to configure_i18n with the same I18n::Config object
    @previously_configured_i18ns = []

    class << self
      attr_reader :previously_configured_i18ns

      def configure_i18n(i18n_config: nil, additional_components: [])
        i18n_config ||= I18n.config

        return i18n_config if previously_configured_i18ns.include?(i18n_config)

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

        add_cldr_data(i18n_config, additional_components: additional_components)
        add_other_data(i18n_config)

        previously_configured_i18ns << i18n_config

        i18n_config
      end

      def exception_handler
        Worldwide::I18nExceptionHandler.new
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
          i18n_config.class.class_variables.include?(class_variable) || i18n_config.instance_variables.include?(instance_variable)
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
        locales = locales.flat_map { |locale| Worldwide::Cldr.fallbacks.descendants(locale).presence || [locale] }

        # Add in the locales needed for CLDR fallback chains
        locales = locales.flat_map { |locale| Worldwide::Cldr.fallbacks[locale.to_sym].map(&:to_s) }.uniq

        # In case they customize I18n.fallbacks, add in the locales needed for their custom fallback chains
        locales = locales.flat_map { |locale| I18n.fallbacks[locale.to_sym].map(&:to_s) }.uniq if I18n.fallbacks

        locales.uniq.sort
      end

      def add_cldr_data(i18n_config, additional_components:)
        locale_set = i18n_config.available_locales.map(&:to_s).to_set
        components = REQUIRED_CLDR_DATA + additional_components
        i18n_config.load_path += cldr_locale_paths(locale_set, components)
      end

      def cldr_locale_paths(locale_set, components)
        Dir[File.join(Paths::CLDR_ROOT, "locales", "*", "*.{yml,rb}")].select do |path|
          match = path.match(CLDR_LOCALE_PATH_REGEX)
          match && locale_set.include?(match[:locale]) && components.include?(match[:component])
        end
      end

      def add_other_data(i18n_config)
        locale_set = i18n_config.available_locales.map(&:to_s).to_set
        i18n_config.load_path += other_data_path(locale_set)
        i18n_config.load_path += regions_data_path(locale_set)
      end

      def other_data_path(locale_set)
        Dir[File.join(Worldwide::Paths::OTHER_DATA_ROOT, "*", "*.{yml,rb}")].select do |path|
          match = path.match(OTHER_LOCALE_PATH_REGEX)
          match && locale_set.include?(match[:locale])
        end
      end

      def regions_data_path(locale_set)
        Dir[File.join(Worldwide::Paths::REGIONS_ROOT, "*", "*.{yml}")].select do |path|
          match = path.match(REGIONS_LOCALE_PATH_REGEX)
          match && locale_set.include?(match[:locale])
        end
      end
    end
  end
end
