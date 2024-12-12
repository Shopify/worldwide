# frozen_string_literal: true

module Worldwide
  module Cldr
    class Fallbacks < Hash
      def initialize
        super
        @all_ancestors_computed = false
        @map = {}
      end

      def [](locale)
        locale = locale.to_sym
        super || store(locale, ancestry(locale))
      end

      def descendants(locale)
        compute_all_ancestors
        compute_all_descendants
        @all_descendants[locale.to_sym] || []
      end

      def defined_parent_locales
        @defined_parent_locales ||= cldr_defined_parents.values.uniq
      end

      private

      def cldr_defined_parents
        @cldr_defined_parents ||= YAML.load_file(
          File.join(Worldwide::Paths::CLDR_ROOT, "parent_locales.yml"),
          symbolize_names: true,
        ).transform_values(&:to_sym)
      end

      def ancestry(locale)
        ancestors = [locale]
        loop do
          if cldr_defined_parents[ancestors.last]
            ancestors << cldr_defined_parents[ancestors.last]
          elsif I18n::Locale::Tag.tag(ancestors.last).parents.count > 0
            ancestors << I18n::Locale::Tag.tag(ancestors.last).parents.first.to_sym
          else
            break
          end
        end
        ancestors << :root unless ancestors.last == :root
        ancestors
      end

      # Walk through all known locales, calculating their ancestry, and caching the results
      def compute_all_ancestors
        return if @all_ancestors_computed

        Worldwide::Locales.known.each do |locale|
          self[locale]
        end

        @all_ancestors_computed = true
      end

      def compute_all_descendants
        return if @all_descendants

        @all_descendants = {}

        each do |locale, ancestors|
          ancestors.each do |ancestor|
            @all_descendants[ancestor] ||= []
            @all_descendants[ancestor] << locale
          end
        end
      end
    end
  end
end
