# frozen_string_literal: true

module Worldwide
  module Scripts
    class << self
      # Based off of the text provided, method will return the scripts identified
      def identify(text:)
        return [] if Util.blank?(text)

        discovered_scripts = []

        script_regexes = {
          "Arabic": "\\p{Arabic}",
          "Han": "\\p{Han}",
          "Hangul": "\\p{Hangul}",
          "Hiragana": "\\p{Hiragana}",
          "Katakana": "\\p{Katakana}",
          "Latn": "\\p{Latin}",
          "Thai": "\\p{Thai}",
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
