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
      def_delegators :instance, :all, :region
    end

    def initialize
      @regions = RegionsLoader.new.load_regions
    end

    def all
      @regions
    end

    def region(code: nil, name: nil)
      unless code.nil? ^ name.nil?
        raise ArgumentError, "Must specify exactly one of code: or name:."
      end

      result = if code
        search_code = code.to_s.upcase

        @regions.find do |r|
          r.iso_code == search_code || r.alpha_three == search_code || r.numeric_three == search_code
        end
      else # search by name
        search_name = name.upcase

        @regions.find do |r|
          r.legacy_name&.upcase == search_name || r.full_name&.upcase == search_name
        end
      end

      result || @regions.find do |r|
        r.iso_code == "ZZ" # Unknown region
      end
    end
  end
end
