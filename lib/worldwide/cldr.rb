# frozen_string_literal: true

require "set"

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

    class << self
      def fallbacks
        FALLBACKS
      end

      def config
        CONFIG
      end

      # Resolve a structural CLDR node by merging each locale's contribution.
      # Leaf lookups should continue to use `t`, where the first fallback match is correct.
      def resolved_hash(key, locale: I18n.locale)
        with_cldr do
          merge_ancestors(key.to_s, locale.to_sym, Set.new)
        end
      end

      private

      def merge_ancestors(key, locale, resolving)
        path = [key, locale]
        added = resolving.add?(path)
        return {} unless added

        fallbacks[locale].reverse_each.with_object({}) do |ancestor, merged|
          node = unresolved_node(key, ancestor)

          case node
          when ::Symbol
            deep_merge!(merged, merge_ancestors(node.to_s, locale, resolving))
          when ::Hash
            deep_merge!(merged, node)
          end
        end
      ensure
        resolving.delete(path) if added
      end

      def unresolved_node(key, locale)
        I18n.t(key, locale: locale, default: nil, fallback: false, resolve: false)
      rescue ::I18n::InvalidLocale
        nil
      end

      def deep_merge!(target, source)
        source.each do |key, value|
          target[key] = if value.is_a?(::Hash)
            deep_merge!(target[key].is_a?(::Hash) ? target[key] : {}, value)
          else
            value
          end
        end

        target
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
