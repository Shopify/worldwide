# frozen_string_literal: true

module Worldwide
  module PluralizationHelper
    # Translates pluralization string, returning the first
    # translation found in the `Worldwide::Cldr.fallbacks` chain.
    # Raises I18n::InvalidPluralizationData exception if
    # pluralization data is invalid for all fallbacks.
    def translate_plural(key, locale: I18n.locale, count:)
      Worldwide::Cldr.fallbacks[locale].find.with_index do |fallback_locale, index|
        raise = index == Worldwide::Cldr.fallbacks[locale].size - 1 # raise on last fallback
        value = try_translate_plural(key, locale: fallback_locale, count: count, raise: raise)
        break value if value
      end
    end

    private

    # Translates pluralization string.
    # Raises I18n::InvalidPluralizationData exception if `raise` is true
    # and pluralization data is invalid.
    def try_translate_plural(key, locale:, count:, raise: true)
      Worldwide::Cldr.t(key, locale: locale, count: count)
    rescue I18n::InvalidPluralizationData => exception
      raise exception if raise
    end
  end
end
