# frozen_string_literal: true

module Worldwide
  module Scripts
    class << self
      # Based off of the text provided, method will return the scripts identified
      def identify(text:)
        return [] if text.blank?

        discovered_scripts = []

        script_regexes = {
          "Latn": "[A-Za-z\uFF21-\uFF3A\uFF41-\uFF5A]",
          "Han": "\\p{Han}",
          "Katakana": "\\p{Katakana}",
          "Hiragana": "\\p{Hiragana}",
        }

        script_regexes.each do |script, regex|
          if text.match(regex)
            discovered_scripts.push(script)
          end
        end

        discovered_scripts
      end
    end
  end
end
