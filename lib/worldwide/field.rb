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

      message = I18n.t("#{base}.#{key_suffix}", default: nil, **options)
      return message if message.present?

      key = key_suffix.include?("_instructional") ? "#{base}.#{key_suffix.sub("_instructional", "")}" : "#{base}.#{key_suffix}_instructional"
      message = I18n.t(key, default: nil, **options)
      return message if message.present?

      I18n.with_locale(:en) { I18n.t("#{base}.#{key_suffix}", default: nil, **options) }
    end

    def lookup(key_suffix, locale:, options: {})
      I18n.with_locale(locale) do
        unless @country_code.nil?
          message = I18n.t("#{base_key(@country_code)}.#{key_suffix}", default: nil, **options)
          return message if message.present?

          key = if key_suffix.include?("_instructional")
            "#{base_key(@country_code)}.#{key_suffix.sub("_instructional", "")}"
          else
            "#{base_key(@country_code)}.#{key_suffix}_instructional"
          end
          message = I18n.t(key, default: nil, **options)
          return message if message.present?
        end

        default_lookup(key_suffix, options: options)
      end
    end
  end
end
