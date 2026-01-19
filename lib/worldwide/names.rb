# frozen_string_literal: true

module Worldwide
  class Names
    class << self
      SURNAME_FIRST_LOCALES = ["ja", "km", "ko", "vi", "zh"]
      private_constant :SURNAME_FIRST_LOCALES

      TRANSLATION_MISSING_PATTERN = /\ATranslation missing:/
      private_constant :TRANSLATION_MISSING_PATTERN

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

      private

      def format_name(format, given, surname)
        parts = [given, surname].reject(&:blank?)

        case parts.length
        when 2
          result = Cldr.t("names.#{format}", given: given, surname: surname)
          return result unless TRANSLATION_MISSING_PATTERN.match?(result)

          I18n.with_locale(:en) { Cldr.t("names.#{format}", given: given, surname: surname) }
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
