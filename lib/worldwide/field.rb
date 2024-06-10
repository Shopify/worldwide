# frozen_string_literal: true

# Encapsulates the translation information for all locales, for a single field in a single country

require "yaml"

module Worldwide
  class Field
    VALID_KEYS = [
      :first_name,
      :last_name,
      :company,
      :address1,
      :street_name,
      :street_number,
      :address2,
      :line2,
      :neighborhood,
      :city,
      :province,
      :zip,
      :country,
      :phone,
      :address,
    ]

    class << self
      def valid_key?(key)
        VALID_KEYS.include?(key.to_sym)
      end
    end

    def initialize(country_code: nil, field_key:)
      @country_code = country_code&.upcase&.to_sym
      @field_key = field_key.downcase.to_sym
    end

    def autofill(locale: I18n.locale)
      lookup("autofill", locale: locale)
    end

    def label(locale: I18n.locale)
      lookup("label.default", locale: locale)
    end

    def label_marked_optional(locale: I18n.locale)
      lookup("label.optional", locale: locale)
    end

    def error(locale: I18n.locale, code:, options: {})
      unless code.end_with?("_instructional", "_informative")
        code = "#{code}_instructional"
      end
      lookup("errors.#{code}", locale: locale, options: options)
    end

    def warning(locale: I18n.locale, code:, options: {})
      lookup("warnings.#{code}", locale: locale, options: options)
    end

    private

    def base_key(country_key)
      "worldwide.#{country_key}.addresses.#{@field_key}"
    end

    def default_lookup(key_suffix, options: {})
      base = base_key("_default")
      I18n.t("#{base}.#{key_suffix}", default: nil, **options) ||
        I18n.with_locale(:en) { I18n.t("#{base}.#{key_suffix}", default: nil, **options) }
    end

    def lookup(key_suffix, locale:, options: {})
      I18n.with_locale(locale) do
        if @country_code.nil?
          default_lookup(key_suffix, options: options)
        else
          I18n.t("#{base_key(@country_code)}.#{key_suffix}", default: nil, **options) ||
            default_lookup(key_suffix, options: options)
        end
      end
    end
  end
end
