# frozen_string_literal: true

# Based on https://github.com/ruby-i18n/i18n/blob/5eeaad7fb35f9a30f654e3bdeb6933daa7fd421d/lib/i18n/config.rb
# We have this to serve as an object that has the same interface, but uses instance variables instead of class
# variables, so we can independently override config values. If a value is overridden, it sets the instance
# variable and uses that from then on. If not overridden, it will continue to use the class variables.

require "set"

module Worldwide
  class RubyI18nConfig < I18n::Config
    def locale
      defined?(@locale) && !@locale.nil? ? @locale : super
    end

    def locale=(locale)
      I18n.enforce_available_locales!(locale)
      @locale = locale&.to_sym
    end

    def backend
      return @backend if defined?(@backend)

      super
    end
    attr_writer :backend

    def default_locale
      return @default_locale if defined?(@default_locale)

      super
    end

    def default_locale=(locale)
      I18n.enforce_available_locales!(locale)
      @default_locale = locale&.to_sym
    end

    def available_locales
      return @available_locales if defined?(@available_locales)

      super
    end

    # Caches the available locales list as both strings and symbols in a Set, so
    # that we can have faster lookups to do the available locales enforce check.
    def available_locales_set
      if defined?(@available_locales)
        return @available_locales_set ||= available_locales.inject(Set.new) do |set, locale|
          set << locale.to_s << locale.to_sym
        end
      end

      super
    end

    def available_locales=(locales)
      @available_locales = Array(locales).map(&:to_sym)
      @available_locales = nil if @available_locales.empty?
      @available_locales_set = nil
    end

    def available_locales_initialized?
      return !!@available_locales if defined?(@available_locales)

      super
    end

    # Clears the available locales set so it can be recomputed again after I18n
    # gets reloaded.
    def clear_available_locales_set
      @available_locales_set = nil
    end

    def default_separator
      return @default_separator if defined?(@default_separator)

      super
    end
    attr_writer :default_separator

    def exception_handler
      return @exception_handler if defined?(@exception_handler)

      super
    end
    attr_writer :exception_handler

    # Returns the current handler for situations when interpolation argument
    # is missing. MissingInterpolationArgument will be raised by default.
    def missing_interpolation_argument_handler
      return @missing_interpolation_argument_handler if defined?(@missing_interpolation_argument_handler)

      super
    end

    # Sets the missing interpolation argument handler. It can be any
    # object that responds to #call. The arguments that will be passed to #call
    # are the same as for MissingInterpolationArgument initializer. Use +Proc.new+
    # if you don't care about arity.
    #
    # == Example:
    # You can supress raising an exception and return string instead:
    #
    #   I18n.config.missing_interpolation_argument_handler = Proc.new do |key|
    #     "#{key} is missing"
    #   end
    attr_writer :missing_interpolation_argument_handler

    # Allow clients to register paths providing translation data sources. The
    # backend defines acceptable sources.
    #
    # E.g. the provided SimpleBackend accepts a list of paths to translation
    # files which are either named *.rb and contain plain Ruby Hashes or are
    # named *.yml and contain YAML data. So for the SimpleBackend clients may
    # register translation files like this:
    #   I18n.load_path << 'path/to/locale/en.yml'
    def load_path
      return @load_path if defined?(@load_path)

      super
    end

    # Sets the load path instance. Custom implementations are expected to
    # behave like a Ruby Array.
    def load_path=(load_path)
      @load_path = load_path
      @available_locales_set = nil
      backend.reload!
    end

    # Whether or not to verify if locales are in the list of available locales.
    def enforce_available_locales
      return @enforce_available_locales if defined?(@enforce_available_locales)

      super
    end

    attr_writer :enforce_available_locales

    def interpolation_patterns
      return @interpolation_patterns if defined?(@interpolation_patterns)

      super
    end

    # Sets the current interpolation patterns. Used to set a interpolation
    # patterns.
    #
    # E.g. using {{}} as a placeholder like "{{hello}}, world!":
    #
    #   I18n.config.interpolation_patterns << /\{\{(\w+)\}\}/
    attr_writer :interpolation_patterns
  end
end
