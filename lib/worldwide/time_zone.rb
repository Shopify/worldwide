# frozen_string_literal: true

module Worldwide
  class TimeZone
    class << self
      def all
        @all ||= uniq_zone_names.map { |zone_name| new(zone_name) }
      end

      private

      def uniq_zone_names
        ActiveSupport::TimeZone.all.map do |time_zone|
          time_zone.tzinfo.name
        end.uniq
      end
    end

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def to_s
      translated_name
    end

    private

    def translated_name
      Cldr.t(name, scope: :timezones)
    end
  end
end
