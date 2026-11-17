# frozen_string_literal: true

require_relative "../ruby_i18n_config"

module Worldwide
  module Cldr
    # The I18n configuration for lookups inside Worldwide::Cldr.with_bundled_data.
    # It pins every value that decides which data a lookup reads, so that none of them
    # comes from the host's I18n configuration. Whether an unknown locale raises
    # (enforce_available_locales) stays the host's choice.
    class BundledConfig < Worldwide::RubyI18nConfig
      def initialize(backend)
        super()
        @backend = backend
        @load_path = [].freeze
        @default_locale = :en
        @default_separator = "."
        @exception_handler = Worldwide::Config.exception_handler
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
