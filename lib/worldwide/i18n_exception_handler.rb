# frozen_string_literal: true

module Worldwide
  class I18nExceptionHandler < ::I18n::ExceptionHandler
    # I18n.exception_handler is needed in cases where the lookup has
    # gone through the fallback chain. In that case, we want to do the
    # lookup in the default locale.
    #
    # It's a common misconception that we should add the default locale
    # to the fallbacks chain. Instead, you catch the exception and do
    # the lookup in the source locale.
    def call(exception, locale, key, options, context = I18n)
      if exception.is_a?(I18n::MissingTranslation)

        # We've already tried the default locale, so we don't want to try it again.
        if locale.to_s == context.default_locale.to_s
          handle_missing_translation(exception, locale, key, options)
        else
          handle_default_locale_fallback(exception, locale, key, options, context)
        end
      else
        super(exception, locale, key, options)
      end
    end

    private

    def handle_missing_translation(exception, _locale, key, options)
      # From Rails guide (https://guides.rubyonrails.org/i18n.html#using-different-exception-handlers):
      #
      # > However, if you are using `I18n::Backend::Pluralization` this handler will also raise
      # > `I18n::MissingTranslationData: translation missing: en.i18n.plural.rule` exception that
      # > should normally be ignored to fall back to the default pluralization rule for English locale.
      if key == :"i18n.plural.rule"
        return degraded_translation(key, options)
      end

      log_missing(exception)
      report_error(exception)
      degraded_translation(key, options)
    end

    def handle_default_locale_fallback(exception, _locale, key, options, context)
      log_missing(exception)

      context.t(key, **options, locale: I18n.default_locale)
    end

    # Rails i18n view logic uses `titleize`.
    # In order to avoid a dependency over Rails, implementing a minimal version.
    def degraded_translation(key, options)
      separator = options[:separator] || I18n.default_separator
      last_entry = key.to_s.split(separator).last
      last_entry
        .gsub(/[^\w]/, "_") # Non word to underscore
        .gsub(/[_]+/, " ") # Underscore to space
    end

    def log_missing(exception)
      # pass
    end

    def report_error(exception)
      # pass
    end
  end
end
