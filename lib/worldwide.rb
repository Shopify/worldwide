# frozen_string_literal: true

require "i18n"
require "active_support"
require "yaml"

require "worldwide/config"
require "worldwide/i18n_exception_handler"
require "worldwide/locale"
require "worldwide/locales"
require "worldwide/paths"
require "worldwide/version"
require "worldwide/extant_outcodes"

require "worldwide/address"
require "worldwide/address_validator"
require "worldwide/calendar"
require "worldwide/cldr"
require "worldwide/cldr/context_transforms"
require "worldwide/currencies"
require "worldwide/currency"
require "worldwide/deprecated_time_zone_mapper"
require "worldwide/discounts"
require "worldwide/fields"
require "worldwide/lists"
require "worldwide/names"
require "worldwide/numbers"
require "worldwide/paths"
require "worldwide/phone"
require "worldwide/plurals"
require "worldwide/punctuation"
require "worldwide/region"
require "worldwide/regions"
require "worldwide/ruby_i18n_config"
require "worldwide/scripts"
require "worldwide/time_formatter"
require "worldwide/time_zone"
require "worldwide/units"
require "worldwide/util"
require "worldwide/zip"
require "worldwide/localization_keys"

module Worldwide
  @currencies_cache = {}
  @locales_cache = {}

  class << self
    def address(**kwargs)
      Address.new(**kwargs)
    end

    def currency(code:)
      currency_code = code.to_s.upcase.rjust(3, "0")
      @currencies_cache[currency_code] ||= Currency.new(code: currency_code)
    end

    def discounts
      Discounts
    end

    def locale(code:)
      @locales_cache[code] ||= Locale.new(code)
    end

    def locales
      Locales
    end

    def lists
      Lists
    end

    def names
      Names
    end

    def numbers
      Numbers
    end

    def plurals
      Plurals
    end

    def punctuation
      Punctuation
    end

    def region_by_cldr_code(**kwargs)
      Regions.region_by_cldr_code(**kwargs)
    end

    def region(**kwargs)
      Regions.region(**kwargs)
    end

    def scripts
      Scripts
    end

    def time_zone
      TimeZone
    end

    def unknown_region
      region(code: "ZZ")
    end

    def units
      Units
    end
  end
end
