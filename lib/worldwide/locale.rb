# frozen_string_literal: true

module Worldwide
  class Locale
    attr_reader :code

    def initialize(code)
      if code.nil? || code.empty?
        raise ArgumentError, "Invalid locale: cannot be nil nor an empty string"
      end

      @code = code.to_sym
      @name_cache = {}
      @endonym_cache = {}
    end

    # Special CLDR value
    @unknown = new("und")
    singleton_class.attr_reader(:unknown)

    def language_subtag
      code.to_s.split("-", 2).first
    end

    def script
      locale_string = code.to_s.tr("-", "_")

      parts = locale_string.downcase.split("_")

      # If the locale includes a script specification, then return that script
      return parts[1].capitalize if parts.size >= 2 && parts[1].size == 4

      # If the full locale has an entry in the likely_subtags list, the use that
      parts = locale_string.split("_")
      adjusted_locale = [parts.first.downcase, parts.last.upcase].join("_")
      subtags = Worldwide::Locales.likely_subtags[adjusted_locale]
      return subtags.split("_")[1] unless subtags.nil?

      # If the locale's language code has an entry in the likely_subtags list, then use that
      subtags = Worldwide::Locales.likely_subtags[parts.first]
      return subtags.split("_")[1] unless subtags.nil?

      nil
    end

    def sub_locales
      Worldwide::Locales.sub_locales[code] || []
    end

    def name(locale: I18n.locale, context: :middle_of_sentence, throw: true)
      cache_key = [locale&.to_sym, context]
      @name_cache[cache_key] ||= I18n.with_locale(locale) do
        # Try to find a language name as specific as possible in the locale we wanted.
        exonym(target_locale: locale, context: context) ||

          # We didn't find a language name in the locale we wanted.
          # In cases like this, try to look up the language's native name ("endonym").
          endonym(context: context, throw: throw) ||

          # CLDR does not define language names (`languages.yml`) in some languages
          # (example: 'cu' Church Slavic does not have a `languages.yml`, so every
          # language name lookup in that locale will fail, since `cu` lookups only
          # fall back to `root`, which also does not have a `languages.yml`).
          # This means that we cannot provide the endonym for `cu`.

          # If we have a translation in the default locale, we'll return that.
          name_in_default_locale(context: context) ||

          # We still don't know anything about the language, and we're out of options.
          I18n::MissingTranslation.new(locale, "languages.#{code}")
      end

      if @name_cache[cache_key].is_a?(I18n::MissingTranslation)
        raise @name_cache[cache_key] if throw

        return
      end

      @name_cache[cache_key]
    end

    # The language's name in that language ("endonym").
    def endonym(context: :middle_of_sentence, throw: true)
      @endonym_cache[context] ||= begin
        result = begin
          lookup(code, locale: code)
        rescue I18n::InvalidLocale => e
          raise e if throw
        end

        result = Worldwide::Cldr::ContextTransforms.transform(result, :languages, context, locale: code) unless result.nil?
        result || I18n::MissingTranslation.new(code, "languages.#{code}")
      end

      if @endonym_cache[context].is_a?(I18n::MissingTranslation)
        raise @endonym_cache[context] if throw

        return
      end

      @endonym_cache[context]
    end

    private

    def exonym(target_locale:, context:)
      # Try to find a language name as specific as possible in the locale we wanted.
      # We chop the hyphens to get more and more general language names
      # (e.g., "Traditional Chinese as spoken in Hong Kong" (zh-Hant-HK) -> "Traditional Chinese" (zh-Hant) -> "Chinese" (zh))
      # and rely on `territories_suffix` to add in additional details after.
      # It's just a heuristic and definitely not perfect (for the really important ones, we can manually patch the data)
      chop(code.to_s, "-").each_with_index do |language, i|
        result = lookup(language, locale: target_locale)
        if result
          transformed = Worldwide::Cldr::ContextTransforms.transform(result, :languages, context, locale: target_locale)
          break "#{transformed}#{territories_suffix(code.to_s) if i > 0}"
        end
      end
    end

    def name_in_default_locale(context:)
      result = lookup(code, locale: I18n.default_locale)
      Worldwide::Cldr::ContextTransforms.transform(result, :languages, context, locale: I18n.default_locale) unless result.nil?
    end

    def lookup(key, locale:)
      I18n.with_locale(locale) do
        if Worldwide::Cldr.exists?("languages.#{key}", locale: locale) # Avoid the exception handler
          Worldwide::Cldr.t("languages.#{key}", locale: locale)
        end
      end
    end

    def chop(string, separator)
      Enumerator.new do |enum|
        remaining = string
        loop do
          enum.yield remaining
          chopped, sep, _tail = remaining.rpartition(separator)
          break if chopped.empty? && sep.empty? # https://ruby-doc.org/core/String.html#method-i-rpartition

          remaining = chopped
        end
      end
    end

    def territories_suffix(target_code)
      parts = target_code.split("-")
      return if parts.size <= 1

      region_code = parts.last
      return if Util.blank?(region_code)

      region = Worldwide::Cldr.t(region_code, scope: :territories, default: nil)
      region = region.nil? ? region_code : Worldwide::Cldr::ContextTransforms.transform(region, :territory, :start_of_sentence)

      " (#{region})"
    end
  end
end
