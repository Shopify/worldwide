# frozen_string_literal: true

require "yaml"

module Worldwide
  module Locales
    class << self
      include Enumerable

      alias_method :known, :to_a

      def each(&block)
        cldr_locales.each(&block)
      end

      def likely_subtags
        @likely_subtags ||= YAML.safe_load_file(
          File.join(Worldwide::Paths::CLDR_ROOT, "likely_subtags.yml"),
        ).fetch("subtags")
      end

      def top_25
        @top25 ||= YAML.safe_load_file(
          File.join(Worldwide::Paths::DATA_ROOT, "top_locales.yml"),
        ).fetch("by_speakers")[0..25]
      end

      def sub_locales
        return @sub_locales if defined?(@sub_locales)

        @sub_locales = {}
        Worldwide::Locales.known.each do |locale|
          Worldwide::Cldr::FALLBACKS[locale].drop(1).each do |fallback|
            @sub_locales[fallback] ||= []
            @sub_locales[fallback] << locale
          end
        end
        @sub_locales
      end

      private

      def cldr_locales
        @cldr_locales ||= begin
          entries = Dir.entries(File.join(Worldwide::Paths::CLDR_ROOT, "locales"))
          entries.reject { |entry| entry.start_with?(".") || entry == "root" }
        end.map(&:to_sym).sort
      end
    end
  end
end
