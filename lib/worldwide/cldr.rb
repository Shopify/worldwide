# frozen_string_literal: true

require_relative "cldr/date_format_pattern"
require_relative "cldr/fallbacks"
require_relative "ruby_i18n_config"

module Worldwide
  module Cldr
    FALLBACKS = Worldwide::Cldr::Fallbacks.new
    CONFIG = Worldwide::RubyI18nConfig.new.tap do |cldr_config|
      cldr_config.exception_handler = Worldwide::Config.exception_handler
    end

    class << self
      def fallbacks
        FALLBACKS
      end

      def config
        CONFIG
      end

      private

      def respond_to_missing?(method_name, include_private = false)
        I18n.respond_to?(method_name, include_private)
      end

      def method_missing(method_name, *args, **kwargs, &block)
        with_cldr do
          I18n.send(method_name, *args, **kwargs, &block)
        end
      end

      def with_cldr(&block)
        original_fallbacks = Thread.current[:i18n_fallbacks]
        Thread.current[:i18n_fallbacks] = fallbacks

        locale = I18n.locale
        original_config = Thread.current[:i18n_config]
        Thread.current[:i18n_config] = config

        I18n.with_locale(locale, &block)
      ensure
        Thread.current[:i18n_fallbacks] = original_fallbacks
        Thread.current[:i18n_config] = original_config
      end
    end
  end
end
