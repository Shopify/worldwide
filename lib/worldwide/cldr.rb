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

      # Look up a structural (hash-valued) CLDR key with CLDR's own inheritance rules.
      #
      # CLDR resolves locale data item by item: the effective data for a locale is the
      # union of its own data with each of its ancestors', the more specific locale
      # winning per item, and `<alias>` elements resolved against the locale originally
      # requested (UTS #35 §4.1 "Multiple Inheritance" and §4.4 "Alias Elements").
      #
      # `I18n`'s fallback backend instead returns the first non-nil node it finds in the
      # chain, which is correct for leaves but wrong for whole nodes: a locale that
      # overrides a single entry hides every sibling entry it should inherit. `en-CA`
      # only overrides September ("Sept" rather than "Sep"), so a plain `t` of the
      # abbreviated month names returns a one-entry hash instead of all twelve.
      #
      # Leaf lookups should keep using `t`; only whole-node lookups need this.
      def resolved_hash(key, locale: I18n.locale)
        with_cldr do
          merge_ancestors(key.to_s, locale.to_sym, Set.new)
        end
      end

      private

      # Walks the CLDR fallback chain from the least specific ancestor to the most
      # specific, so that descendants overwrite what they inherit.
      def merge_ancestors(key, locale, seen)
        # Guards against a cycle between two aliases pointing at each other.
        return {} unless seen.add?([key, locale])

        fallbacks[locale].reverse_each.with_object({}) do |ancestor, merged|
          case (node = unresolved_node(key, ancestor))
          when ::Symbol # A CLDR `<alias>`, resolved against the requested locale rather than the ancestor.
            deep_merge!(merged, merge_ancestors(node.to_s, locale, seen))
          when ::Hash
            deep_merge!(merged, node)
          end
        end
      end

      # A single locale's own contribution: no fallbacks, no alias resolution, and no
      # exception handler (`default: nil` makes a miss return nil instead of degrading).
      def unresolved_node(key, locale)
        I18n.t(key, locale: locale, default: nil, fallback: false, resolve: false)
      rescue ::I18n::InvalidLocale
        nil
      end

      def deep_merge!(target, source)
        source.each do |key, value|
          target[key] = if target[key].is_a?(::Hash) && value.is_a?(::Hash)
            deep_merge!(target[key], value)
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
