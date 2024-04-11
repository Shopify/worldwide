# frozen_string_literal: true

require "forwardable"
require "singleton"
require "yaml"

module Worldwide
  class ExtantOutcodes
    include Singleton

    class << self
      extend Forwardable
      def_delegators :instance, :for_country
    end

    def for_country(code:)
      extant[code.to_s.downcase]
    end

    private

    def initialize
      @extant = nil
    end

    def extant
      @extant ||= YAML.safe_load_file("#{::Worldwide::Paths::GEM_ROOT}/db/extant_outcodes.yml").dig("extant_outcodes")&.map do |key, value|
        [key, value.to_set]
      end&.to_h || {}
    end
  end
end
