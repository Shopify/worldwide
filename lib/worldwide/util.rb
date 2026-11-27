# frozen_string_literal: true

module Worldwide
  class Util
    # Characters in U+00C0..U+017F that have no decomposition into a base letter and a mark,
    # mapped to an ASCII approximation.
    HANDLE_APPROXIMATIONS = {
      "ß" => "ss",
      "æ" => "ae",
      "ð" => "d",
      "ø" => "o",
      "þ" => "th",
      "đ" => "d",
      "ħ" => "h",
      "ı" => "i",
      "ĳ" => "ij",
      "ĸ" => "k",
      "ŀ" => "l",
      "ł" => "l",
      "ŉ" => "'n",
      "ŋ" => "ng",
      "œ" => "oe",
      "ŧ" => "t",
    }.freeze
    private_constant :HANDLE_APPROXIMATIONS

    HANDLE_LATIN_RANGE = /[\u00C0-\u017F]/
    private_constant :HANDLE_LATIN_RANGE

    HANDLE_QUOTES_AND_BRACKETS = "'\"()[]"
    private_constant :HANDLE_QUOTES_AND_BRACKETS

    HANDLE_SEPARATOR = /(?:(?!\p{Word}|\u200D|\p{Extended_Pictographic}|\p{Emoji_Modifier}).)+/m
    private_constant :HANDLE_SEPARATOR

    HANDLE_EDGE_HYPHENS = /\A-+|-+\z/
    private_constant :HANDLE_EDGE_HYPHENS

    class << self
      def blank?(value)
        value.nil? ||
          (value.respond_to?(:empty?) && value.empty?) ||
          (value.is_a?(String) && value.strip.empty?)
      end

      def present?(value)
        !blank?(value)
      end

      # Reduces a name to a simplified, lowercase form that is suitable for comparing names.
      # Latin letters with diacritics become their base letters, quotes and brackets are dropped, and each
      # run of other punctuation or whitespace becomes a single hyphen.
      # Letters of other scripts are kept.
      #
      # @example
      #   Worldwide::Util.utf8_handle("Al Fayyūm") == "al-fayyum"
      #   Worldwide::Util.utf8_handle("Ærøskøbing 日本") == "aeroskobing-日本"
      #
      # @param input [String]
      # @return [String] a new, frozen string
      def utf8_handle(input)
        string = input.to_s
        string = string.dup.force_encoding(Encoding::UTF_8) unless string.encoding == Encoding::UTF_8
        string = ActiveSupport::Multibyte::Unicode.tidy_bytes(string) unless string.valid_encoding?

        result = string.downcase.unicode_normalize(:nfc)
        result = result.gsub(HANDLE_LATIN_RANGE) do |char|
          HANDLE_APPROXIMATIONS[char] || char.unicode_normalize(:nfd).delete("\u0300-\u036F")
        end
        result.delete!(HANDLE_QUOTES_AND_BRACKETS)
        result.gsub!(HANDLE_SEPARATOR, "-")
        result.gsub!(HANDLE_EDGE_HYPHENS, "")
        result.freeze
      end

      # Compares a part of one string with a part of another string, ignoring the case of ASCII letters.
      # This allocates no objects, because it compares bytes with `getbyte`.
      # A comparison that involves a byte outside of ASCII is always false.
      #
      # @param str1 [String]
      # @param str2 [String]
      # @param start1 [Integer] the byte offset of the part of `str1`
      # @param length1 [Integer] the byte length of the part of `str1`; it must be greater than 0
      # @param start2 [Integer] the byte offset of the part of `str2`
      # @param length2 [Integer] the byte length of the part of `str2`; it must be greater than 0
      # @return [Boolean]
      # @raise [ArgumentError] when a string is nil, a length is not positive, or a start is negative
      def ascii_casecmp_substring?(str1, str2, start1:, length1:, start2:, length2:)
        raise ArgumentError, "str1 and str2 must not be nil" if str1.nil? || str2.nil?
        raise ArgumentError, "Length must be greater than 0" if length1 <= 0 || length2 <= 0
        raise ArgumentError, "Start indices must not be negative" if start1 < 0 || start2 < 0

        return false if length1 != length2

        length = length1
        return false if start1 + length > str1.bytesize || start2 + length > str2.bytesize

        # A while loop avoids allocating a Range
        i = 0
        while i < length
          b1 = str1.getbyte(start1 + i)
          b2 = str2.getbyte(start2 + i)

          return false if b1 >= 128 || b2 >= 128

          b1 += 32 if b1.between?(65, 90)
          b2 += 32 if b2.between?(65, 90)

          return false if b1 != b2

          i += 1
        end

        true
      end
    end
  end
end
