# frozen_string_literal: true

module Worldwide
  class Locale
    class << self
      def unknown
        # Special CLDR value
        @unknown = Locale.new("und")
      end
    end

    attr_reader :code

    def initialize(code)
      if code.nil? || code.empty?
        raise ArgumentError, "Invalid locale: cannot be nil nor an empty string"
      end

      @code = code.to_sym
      @name_cache = {}
    end

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
      @name_cache[context] ||= I18n.with_locale(locale) do
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

      if @name_cache[context].is_a?(I18n::MissingTranslation)
        raise @name_cache[context] if throw

        return nil
      end

      @name_cache[context]
    end

    # The language's name in that language ("endonym").
    def endonym(context: :middle_of_sentence, throw: true)
      return @endonym if defined?(@endonym)

      begin
        @endonym = lookup(code, locale: code)
      rescue I18n::InvalidLocale => e
        raise e if throw
      end

      @endonym = Worldwide::Cldr::ContextTransforms.transform(@endonym, :languages, context, locale: code) unless @endonym.nil?
      @endonym ||= I18n::MissingTranslation.new(code, "languages.#{code}")

      if @endonym.is_a?(I18n::MissingTranslation)
        raise @endonym if throw

        return nil
      end

      @endonym
    end

    private

    def exonym(target_locale:, context:)
      return @exonym if defined?(@exonym)

      # Try to find a language name as specific as possible in the locale we wanted.
      # We chop the hyphens to get more and more general language names
      # (e.g., "Traditional Chinese as spoken in Hong Kong" (zh-Hant-HK) -> "Traditional Chinese" (zh-Hant) -> "Chinese" (zh))
      # and rely on `territories_suffix` to add in additional details after.
      # It's just a heuristic and definitely not perfect (for the really important ones, we can manually patch the data)
      @exonym = chop(code.to_s, "-").each_with_index do |language, i|
        result = lookup(language, locale: target_locale)
        if result
          transformed = Worldwide::Cldr::ContextTransforms.transform(result, :languages, context, locale: target_locale)
          break "#{transformed}#{i > 0 ? territories_suffix(code.to_s) : ""}"
        end
      end
    end

    def name_in_default_locale(context:)
      return @name_in_default_locale if defined?(@name_in_default_locale)

      @name_in_default_locale = lookup(code, locale: I18n.default_locale)
      @name_in_default_locale = Worldwide::Cldr::ContextTransforms.transform(@name_in_default_locale, :languages, context, locale: I18n.default_locale) unless @name_in_default_locale.nil?
      @name_in_default_locale
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
      return if region_code.blank?

      region = Worldwide::Cldr.t(region_code, scope: :territories, default: nil)
      region = region.nil? ? region_code : Worldwide::Cldr::ContextTransforms.transform(region, :territory, :start_of_sentence)

      " (#{region})"
    end
  end
end
