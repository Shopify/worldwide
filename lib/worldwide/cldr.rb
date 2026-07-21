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

    # i18n 1.15 keeps the active config and fallbacks in Fiber storage on Ruby
    # 3.2+ and in thread-local storage otherwise. We must write the same slots
    # i18n reads back, so a Thread.current[:i18n_config] write is not silently
    # ignored on Ruby 3.2+. These strategies mirror i18n's own storage; the one
    # matching the runtime is selected once into STORAGE.
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

    STORAGE = Fiber.respond_to?(:[]) ? FiberStorage : ThreadStorage

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
        # Swap the fallbacks slot directly rather than via I18n.fallbacks= so the
        # change stays fiber/thread-local and never clobbers the host
        # application's global fallbacks.
        original_config = STORAGE.config
        original_fallbacks = STORAGE.fallbacks
        locale = I18n.locale

        STORAGE.config = config
        STORAGE.fallbacks = fallbacks

        I18n.with_locale(locale, &block)
      ensure
        STORAGE.config = original_config
        STORAGE.fallbacks = original_fallbacks
      end
    end
  end
end
