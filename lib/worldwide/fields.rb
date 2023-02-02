# frozen_string_literal: true

require "forwardable"
require "singleton"
require "yaml"

require "worldwide/field"

module Worldwide
  class Fields
    include Singleton

    class << self
      extend Forwardable
      def_delegators :instance, :field
    end

    def initialize
      @fields = {}
    end

    # Return a Worldwide::Field for the specified country_code and field_key
    def field(country_code:, field_key:)
      code = country_code.upcase.to_sym
      key = field_key.downcase.to_sym

      cache_key = "#{code}|#{key}".to_sym
      cached = @fields[cache_key]
      return cached if cached

      @fields[cache_key] = Field.new(country_code: code, field_key: key)
    end
  end
end
