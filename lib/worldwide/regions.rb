# frozen_string_literal: true

require "forwardable"
require "singleton"
require "yaml"

require "worldwide/regions_loader"

module Worldwide
  class Regions
    include Singleton

    class << self
      extend Forwardable
      def_delegators :instance, :all, :region_by_cldr_code, :region
    end

    def initialize
      @regions, @regions_by_cldr_code, @regions_by_iso_code = RegionsLoader.new.load_regions
    end

    def all
      @regions
    end

    def region(cldr: nil, code: nil, name: nil)
      unless exactly_one_present?(cldr, code, name)
        raise ArgumentError, "Must specify exactly one of cldr:, code: or name:. (code: is preferred)"
      end

      result = if cldr
        @regions_by_cldr_code[cldr.to_s.upcase]
      elsif code
        @regions_by_iso_code[code.to_s.upcase]
      else # search by name
        search_name = name.upcase

        @regions.find do |r|
          r.legacy_name&.upcase == search_name || r.full_name&.upcase == search_name
        end
      end

      result || Worldwide.unknown_region
    end

    private

    def exactly_one_present?(first, second, third)
      a = Util.present?(first)
      b = Util.present?(second)
      c = Util.present?(third)

      (a ^ b ^ c) && !(a && b && c)
    end
  end
end
