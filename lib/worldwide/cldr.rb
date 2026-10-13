# frozen_string_literal: true

require_relative "cldr/date_format_pattern"
require_relative "cldr/fallbacks"
require_relative "ruby_i18n_config"

module Worldwide
  module Cldr
    BUYER_LOCALE_ALIASES = {
      sr: :"sr-Latn",
    }.freeze

    FALLBACKS = Worldwide::Cldr::Fallbacks.new
    CONFIG = Worldwide::RubyI18nConfig.new.tap do |cldr_config|
      cldr_config.exception_handler = Worldwide::Config.exception_handler
    end

    # Match i18n's config storage behavior, not Ruby's Fiber API.
    module FiberStorage
      class << self
        def config
          Fiber[:i18n_config]
        end

        def config=(value)
          Fiber[:i18n_config] = value
          value.owner = Fiber.current if value.respond_to?(:owner=) && !value.frozen?
        end

        def fallbacks
          Fiber[:i18n_fallbacks]
        end

        def fallbacks=(value)
          Fiber[:i18n_fallbacks] = value
        end
      end
    end

    module ThreadStorage
      class << self
        def config
          Thread.current.thread_variable_get(:i18n_config)
        end

        def config=(value)
          Thread.current.thread_variable_set(:i18n_config, value)
        end

        def fallbacks
          Thread.current[:i18n_fallbacks]
        end

        def fallbacks=(value)
          Thread.current[:i18n_fallbacks] = value
        end
      end
    end

    STORAGE = I18n::Config.method_defined?(:owned_by?) ? FiberStorage : ThreadStorage

    class << self
      def fallbacks
        FALLBACKS
      end

      def config
        CONFIG
      end

      # CLDR maintenance tasks must operate on Unicode's standard locale
      # semantics, where bare `sr` is Cyrillic, rather than Shopify's buyer
      # alias for Serbian Latin.
      def with_standard_locale_semantics
        previous = Thread.current.thread_variable_get(:worldwide_standard_locale_semantics)
        Thread.current.thread_variable_set(:worldwide_standard_locale_semantics, true)
        yield
      ensure
        Thread.current.thread_variable_set(:worldwide_standard_locale_semantics, previous)
      end

      private

      def respond_to_missing?(method_name, include_private = false)
        I18n.respond_to?(method_name, include_private)
      end

      def method_missing(method_name, *args, **kwargs, &block)
        kwargs[:locale] = buyer_cldr_locale(kwargs[:locale]) if kwargs.key?(:locale)

        with_cldr do
          I18n.send(method_name, *args, **kwargs, &block)
        end
      end

      # Translation Platform and buyer surfaces use `sr` for Serbian Latin,
      # while Unicode CLDR assigns bare `sr` to Cyrillic. Keep explicit script
      # locales unchanged, but resolve the buyer locale through Latin CLDR data.
      def buyer_cldr_locale(locale)
        return locale if Thread.current.thread_variable_get(:worldwide_standard_locale_semantics)

        BUYER_LOCALE_ALIASES.fetch(locale&.to_sym, locale)
      end

      def with_cldr(&block)
        # Swap the fallbacks slot directly rather than via I18n.fallbacks= so the
        # change stays fiber/thread-local and never clobbers the host
        # application's global fallbacks.
        original_config = STORAGE.config
        original_fallbacks = STORAGE.fallbacks
        # Some hosts patch I18n.fallbacks to keep reading Thread.current, the slot
        # used before i18n 1.15, so they must also see the CLDR fallbacks.
        original_thread_fallbacks = Thread.current[:i18n_fallbacks]
        locale = buyer_cldr_locale(I18n.locale)

        STORAGE.config = config
        STORAGE.fallbacks = fallbacks
        Thread.current[:i18n_fallbacks] = fallbacks

        I18n.with_locale(locale, &block)
      ensure
        STORAGE.config = original_config
        STORAGE.fallbacks = original_fallbacks
        Thread.current[:i18n_fallbacks] = original_thread_fallbacks
      end
    end
  end
end
