# frozen_string_literal: true

module Worldwide
  class Names
    class << self
      SURNAME_FIRST_LOCALES = ["ja", "km", "ko", "vi", "zh"]
      private_constant :SURNAME_FIRST_LOCALES

      def surname_first?(locale)
        return false if locale.nil?

        SURNAME_FIRST_LOCALES.include?(language_subtag(locale))
      end

      def full(given:, surname:)
        format_name("full", given, surname)
      end

      def greeting(given:, surname:)
        format_name("greeting", given, surname)
      end

      def initials(given:, surname:)
        return if given.nil? && surname.nil?

        names = [given, surname].reject(&:blank?).select do |name|
          I18n.transliterate(name[0]) =~ /[a-zA-Z]/
        end

        names.map { |name| name[0] }
      end

      def abbreviated(given:, surname:, ideal_max_length: 3)
        given_stripped = given&.strip
        surname_stripped = surname&.strip

        combined_name = given_stripped.to_s + surname_stripped.to_s
        return if combined_name.blank? || combined_name.match?(/[\p{Punctuation}\s]/)
        return unless ideal_max_length.is_a?(Integer) && ideal_max_length.positive?

        scripts = Scripts.identify(text: combined_name)
        return unless scripts.length == 1

        given_clusters = given_stripped&.grapheme_clusters
        surname_clusters = surname_stripped&.grapheme_clusters

        # Scripts that Scripts.identify recognizes but that have no abbreviation rule
        # here (e.g. Arabic) intentionally return nil so callers fall back to a greeting.
        case scripts.first
        when :Latin
          [given_stripped, surname_stripped].reject(&:blank?).map { |name| name[0] }.join
        when :Han, :Katakana, :Hiragana
          surname_stripped.presence
        when :Hangul
          if given_stripped.blank?
            surname_stripped
          elsif given_clusters.length > ideal_max_length
            given_clusters[0]
          else
            given_stripped
          end
        when :Thai
          if given_stripped.present?
            given_clusters[0]
          elsif surname_stripped.present?
            surname_clusters[0]
          end
        end
      end

      private

      def format_name(format, given, surname)
        parts = [given, surname].reject(&:blank?)

        case parts.length
        when 2
          Cldr.t("names.#{format}", given: given, surname: surname)
        when 1
          parts[0]
        else
          ""
        end
      end

      def language_subtag(locale)
        locale.to_s.split("-")[0]
      end
    end
  end
end
