# frozen_string_literal: true

module Worldwide
  class Punctuation
    class << self
      def to_paragraph(sentences, locale: I18n.locale)
        I18n.with_locale(locale) do
          sentences.map { |sentence| end_sentence(sentence) }.join(terminal_space)
        end
      end

      def end_sentence(input, locale: I18n.locale)
        I18n.with_locale(locale) do
          result = strip_terminal_spaces(input)
          return result if result.end_with?(full_stop)

          "#{result}#{full_stop}"
        end
      end

      private

      FULL_STOP = {
        hi: "।",
        ja: "。",
        sa: "।",
        th: "", # Thai doesn't use a full stop but uses a space to indicate the end of a sentence instead.
        ur: "۔",
        zh: "。",
      }

      TERMINAL_SPACE = {
        ja: "",
        zh: "",
      }
      private_constant :FULL_STOP, :TERMINAL_SPACE

      def base_locale
        I18n.locale.to_s.downcase.tr("_", "-").split("-").first
      end

      # The end-of-sentence marker ("period" in American, "full stop" in British English)
      def full_stop
        FULL_STOP[base_locale.to_sym] || "."
      end

      # Strip any number of trailing `terminal_space` characters
      def strip_terminal_spaces(input)
        if terminal_space.empty?
          input
        else
          input.sub(Regexp.new("#{Regexp.escape(terminal_space)}*$"), "")
        end
      end

      # The space that should appear after a full stop, if any.
      def terminal_space
        TERMINAL_SPACE[base_locale.to_sym] || " "
      end
    end
  end
end
