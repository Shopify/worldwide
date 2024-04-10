# frozen_string_literal: true

require "set"

require "phonelib"

module Worldwide
  class Phone
    @shared_codes_cache = nil
    class << self
      attr_accessor :shared_codes_cache
    end

    attr_reader :extension

    def initialize(number:, country_code: nil)
      @number = number
      @country_code = country_code&.to_s&.downcase&.to_sym
      @parsed_number, @extension, @country_code = parse_number(number: @number, country_code: country_code)
    end

    # Return the ISO-3166 alpha-2 code of the country in which this phone number is located
    def country_code
      @parsed_number.country
    end

    # Return a formatted number suitable for domestic dialing in the specified country
    def domestic
      @parsed_number.national
    end

    # Return the number in E.164 international format
    def e164
      @parsed_number.e164
    end

    # Return a formatted number including the international country code
    def international
      @parsed_number.international
    end

    # Return the raw "number" string that was specified when creating this Phone object
    def raw
      @number
    end

    def valid?
      @parsed_number.valid?
    end

    # Returns the country prefix for the phone number
    def country_prefix
      @parsed_number.country_code
    end

    private

    # For various reasons, Worldwide considers these territories to be zones inside the USA
    # Because libphonenumber considers them to be "countries" in their own right, we must
    # add them to the list of "countries" that we'll ask libphonenumber to consider for +1.
    NANP_US_TERRITORIES = [
      :as, # American Samoa (684)
      :gu, # Guam (671)
      :mp, # Northern Mariana Islands (670)
      :pr, # Puerto Rico (787, 939)
      :vi, # US Virgin Islands (340)
    ].to_set
    private_constant :NANP_US_TERRITORIES

    # libphonenumber does not support certain countries that Worldwide does support.
    # If we call Phonelib with one of thes countries, it'll raise an exception.
    # Fortunately, both cases are part of the numbering plan of another country, so
    # we can simply map to the other country.
    UNSUPPORTED_COUNTRIES = {
      bv: :no,
      pn: :nz,
      um: :us,
    }
    private_constant :UNSUPPORTED_COUNTRIES

    def parse_number(number:, country_code:)
      base_number, extension = split_extension(transliterate(number))

      return [Phonelib.parse(base_number), extension, nil] if country_code.nil?

      adjusted_code = country_code.to_s.downcase.to_sym
      if UNSUPPORTED_COUNTRIES.include?(adjusted_code)
        adjusted_code = UNSUPPORTED_COUNTRIES[adjusted_code]
      end

      parsed = Phonelib.parse(base_number, adjusted_code)
      return [parsed, extension, adjusted_code] if parsed&.valid?

      # Check for other countries that share the same phone number namespace
      shared_codes.each do |_key, countries|
        next unless countries.include?(adjusted_code)

        countries.each do |code|
          alternate = Phonelib.parse(base_number, code)
          return [alternate, extension, code] if alternate&.valid?
        end
      end

      [parsed, extension, adjusted_code]
    end

    # Some "country codes" are shared by more than one country.
    # A "domestic" number within this code will be dialable between the included countries,
    # because the namespace is shared, but Phonelib will flag it as "invalid" because it's
    # not within the specified country.  We want to consider any number that is dialable to be valid..
    def shared_codes
      Phone.shared_codes_cache ||=
        begin
          mapping = Worldwide::Regions.all.map(&:phone_number_prefix).uniq.map do |calling_code|
            [
              calling_code,
              Worldwide::Regions.all.select(&:country?).select do |country|
                (country.phone_number_prefix == calling_code) &&
                  !UNSUPPORTED_COUNTRIES.include?(country.iso_code.downcase.to_sym)
              end.map do |country|
                country.iso_code.downcase.to_sym
              end.to_set,
            ]
          end.to_h

          # "Countries" that we consider to be zones within the country "US"
          mapping[1] |= NANP_US_TERRITORIES

          mapping
        end
    end

    # Split the number into its base (public) number and extension, if any.
    def split_extension(input)
      return [nil, nil] if input.nil?

      number = input.downcase

      ["ext", "x", ";"].each do |separator|
        if number.include?(separator)
          m = number.match(Regexp.new("(?<base>[0-9a-z +-]*)\\s*#{separator}\\.?\\s*(?<ext>.*)"))
          return [m["base"], m["ext"]] unless m.nil?
        end
      end

      # If we get this far, then we have not found an extension, and assume that the full input is just a public number
      [input, nil]
    end

    # Convert exotic characters to ASCII
    def transliterate(number)
      return if number.nil?

      # Change full-width (zen-kaku) to half-width (han-kaku, in this case ASCII)
      zen_kaku = "ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ１２３４５６７８９０（）ー"
      han_kaku = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890()-"

      # Change Eastern-Arabic and Persian digits to Western-Arabic (ASCII) digits
      eastern = "\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669\u06f0\u06f1\u06f2\u06f3\u06f4\u06f5\u06f6\u06f7\u06f8\u06f9"
      western = "01234567890123456789"

      number.tr(zen_kaku, han_kaku).tr(eastern, western).downcase
    end
  end
end
