# frozen_string_literal: true

module Worldwide
  class Util
    class << self
      def blank?(value)
        value.nil? ||
          (value.respond_to?(:empty?) && value.empty?) ||
          (value.is_a?(String) && value.strip.empty?)
      end

      def present?(value)
        !blank?(value)
      end
    end
  end
end
