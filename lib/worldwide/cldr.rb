# frozen_string_literal: true

require_relative "cldr/bundled_data"
require_relative "cldr/bundled_data_scope"
require_relative "cldr/date_format_pattern"
require_relative "cldr/fallbacks"
require_relative "ruby_i18n_config"

module Worldwide
  module Cldr
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

    # Set by the first with_bundled_data block, so that a process that never enters one
    # skips the scope lookup in bundled_data?.
    @bundled_data_used = false

    class << self
      def fallbacks
        FALLBACKS
      end

      def config
        bundled_data? ? BundledData.instance.config.dup : CONFIG
      end

      # Runs the block with every Worldwide::Cldr lookup in the current fiber reading Worldwide's bundled
      # data and the files registered with Worldwide::Config.add_bundled_data_paths. Those lookups ignore the
      # host's I18n backend, load path, available locales, default locale and key separator. Lookups outside
      # the block are unchanged. Returns the block's value.
      #
      # Threads and fibers created inside the block also read bundled data, until the block and every
      # with_bundled_data block that it runs inside have returned.
      def with_bundled_data
        raise ArgumentError, "with_bundled_data requires a block" unless block_given?

        @bundled_data_used = true
        storage = bundled_data_storage
        previous_scope = storage.scope
        scope = BundledDataScope.new(previous_scope)
        storage.scope = scope
        begin
          yield
        ensure
          scope.close
          storage.scope = previous_scope
        end
      end

      # Whether Worldwide::Cldr lookups in the current fiber read bundled data.
      def bundled_data?
        return false unless @bundled_data_used

        scope = bundled_data_storage.scope
        !scope.nil? && scope.active?
      end

      private

      def bundled_data_storage
        BundledDataScope::STORAGE
      end

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
        # Some hosts patch I18n.fallbacks to keep reading Thread.current, the slot
        # used before i18n 1.15, so they must also see the CLDR fallbacks.
        original_thread_fallbacks = Thread.current[:i18n_fallbacks]
        locale = I18n.locale
        cldr_config = config

        STORAGE.config = cldr_config
        STORAGE.fallbacks = fallbacks
        Thread.current[:i18n_fallbacks] = fallbacks

        if cldr_config.is_a?(BundledConfig)
          # Bundled data may lack the host's current locale. A lookup that uses it still checks it.
          cldr_config.unchecked_locale = locale
          yield
        else
          I18n.with_locale(locale, &block)
        end
      ensure
        STORAGE.config = original_config
        STORAGE.fallbacks = original_fallbacks
        Thread.current[:i18n_fallbacks] = original_thread_fallbacks
      end
    end
  end
end
