# frozen_string_literal: true

require_relative "../ruby_i18n_config"

module Worldwide
  module Cldr
    # The I18n configuration for lookups inside Worldwide::Cldr.with_bundled_data.
    # It pins every value that decides which data a lookup reads, or how values are
    # interpolated into it, so that none of them comes from the host's I18n configuration.
    # Whether an unknown locale raises (enforce_available_locales) stays the host's choice.
    class BundledConfig < Worldwide::RubyI18nConfig
      MISSING_INTERPOLATION_ARGUMENT_HANDLER = lambda do |missing_key, provided_hash, string|
        raise I18n::MissingInterpolationArgument.new(missing_key, provided_hash, string)
      end
      private_constant :MISSING_INTERPOLATION_ARGUMENT_HANDLER

      def initialize(backend)
        super()
        @backend = backend
        @load_path = [].freeze
        @default_locale = :en
        @default_separator = "."
        @exception_handler = Worldwide::Config.exception_handler
        @interpolation_patterns = I18n::DEFAULT_INTERPOLATION_PATTERNS
        @missing_interpolation_argument_handler = MISSING_INTERPOLATION_ARGUMENT_HANDLER
      end

      # Sets the current locale without checking that bundled data has it, unlike locale=.
      # The host's current locale may be one that only the host has. A lookup that uses it checks it.
      def unchecked_locale=(locale)
        @locale = locale&.to_sym
      end

      def available_locales
        backend.available_locales
      end

      def available_locales_set
        backend.available_locales_set
      end

      def available_locales_initialized?
        true
      end
    end
  end
end
