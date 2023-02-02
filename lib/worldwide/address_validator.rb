# frozen_string_literal: true

require "forwardable"
require "singleton"

module Worldwide
  class AddressValidator
    include Singleton

    class << self
      extend Forwardable
      def_delegators :instance, :errors, :valid?
    end

    # Return an array of diagnostics about the validity of this address.
    # If no problems are found, then the result will be an empty array.
    def errors(address)
      return [:address, :nil] if address.nil?

      result = []
      normalized_address = address.normalize(autocorrect_level: 0)

      result << country_errors(normalized_address)
      result << province_errors(normalized_address)
      result << zip_errors(normalized_address)
      result << phone_errors(normalized_address)
      result << city_errors(normalized_address)

      result.reject(&:empty?)
    end

    # Return true if (as far as we know) the address is valid.
    # Return false if we know of at least one error with the address.
    def valid?(address)
      return false if address.nil?

      errors(address).empty?
    end

    private

    def city_errors(address)
      if Util.blank?(address.city)
        [:city, :blank]
      else
        []
      end
    end

    def country_errors(address)
      if Util.blank?(address.country_code)
        [:country, :blank]
      else
        country = Worldwide.region(code: address.country_code) unless address.country_code.nil?
        if country.nil?
          [:country, :invalid]
        else
          []
        end
      end
    end

    def phone_errors(address)
      if Util.blank?(address.phone) || Phone.new(number: address.phone, country_code: address.country_code).valid?
        []
      else
        [:phone, :invalid]
      end
    end

    def province_errors(address)
      country = Worldwide.region(code: address.country_code)

      return [] if country.nil?
      return [] if country.zones.nil?
      return [] if country.zones.select(&:province?).empty?
      return [] if country.hide_provinces_from_addresses

      if Util.blank?(address.province_code)
        [:province, :blank]
      else
        province = country.zone(code: address.province_code)
        if province.nil? || Worldwide.unknown_region == province
          [:province, :invalid]
        else
          []
        end
      end
    end

    def zip_errors(address)
      country = Worldwide.region(code: address.country_code)
      return [] if country.nil?

      return [] if country.autofill_zip

      if Util.blank?(address.zip) && country.zip_required?
        return [:zip, :blank]
      end

      if country.valid_zip?(address.zip)
        if Util.blank?(address.province_code)
          []
        else
          province = country.zone(code: address.province_code)
          if province.nil? || province == Worldwide.unknown_region || province.valid_zip?(address.zip)
            []
          else
            [:zip, :invalid_for_country_and_province]
          end
        end
      else
        [:zip, :invalid_for_country]
      end
    end
  end
end
