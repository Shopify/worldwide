# frozen_string_literal: true

module Worldwide
  class BusinessNames
    class << self
      # Returns a script aware abbreviation, or nil when the name cannot be abbreviated.
      def abbreviate(name:, ideal_max_length: 3)
        name_stripped = name&.strip

        return if Util.blank?(name_stripped)
        return unless ideal_max_length.is_a?(Integer) && ideal_max_length.positive?

        scripts = Scripts.identify(text: name_stripped)
        return unless scripts.one?

        case scripts.first
        when :Latin
          latin_abbreviation(name_stripped, ideal_max_length)
        when :Hangul
          name_stripped.split(" ", 2).first.grapheme_clusters[0, ideal_max_length].join
        when :Thai
          # Thai does not use spaces between words.
          return if name_stripped.include?(" ")

          name_stripped.grapheme_clusters.first
        when :Han, :Katakana, :Hiragana
          return if name_stripped.include?(" ")

          name_stripped
        end
      end

      private

      def latin_abbreviation(name, ideal_max_length)
        words = name.split(" ")

        if words.length == 1
          words.first.grapheme_clusters[0, ideal_max_length].join
        elsif words.length <= ideal_max_length
          words.map { |word| word.grapheme_clusters.first }.join
        else
          words.first.grapheme_clusters.first + words.last.grapheme_clusters.first
        end
      end
    end
  end
end
