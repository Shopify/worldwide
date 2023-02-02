# frozen_string_literal: true

module Worldwide
  module Cldr
    class ContextTransforms
      TRANSFORMS = {
        # https://www.unicode.org/reports/tr35/tr35-general.html#Context_Transform_Elements
        # > "titlecase-firstword" designates the case in which raw CLDR text that is in middle-of-sentence form,
        # > typically lowercase, needs to have its first word titlecased
        titlecase_first_word: ->(string) { string.sub(/\S/, &:upcase) },
        # > "no-change" designates the case in which it is known that no change from the raw CLDR
        # > text (middle-of-sentence form) is needed.
        no_change: ->(string) { string },
      }

      class << self
        def transform(string, usage, context, locale: I18n.locale)
          self.for(usage, context, locale: locale).call(string)
        end

        def for(usage, context, locale: I18n.locale)
          transform_name = case context
          when :middle_of_sentence
            :no_change
          when :start_of_sentence
            :titlecase_first_word
          else
            Worldwide::Cldr.t("context_transforms.#{usage}.#{context}", locale: locale, default: "no_change").to_sym
          end

          TRANSFORMS[transform_name] || TRANSFORMS[:no_change]
        end
      end
    end
  end
end
