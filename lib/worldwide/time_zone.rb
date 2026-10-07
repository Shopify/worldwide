# frozen_string_literal: true

module Worldwide
  class TimeZone
    # Rails' curated list omits these Canadian zones.
    # Explicit offsets keep the returned list stable when TZInfo's 2026 base offsets change.
    ADDITIONAL_ZONE_OFFSETS = {
      "America/Edmonton" => -6 * 3600,
      "America/Vancouver" => -7 * 3600,
      "America/Whitehorse" => -7 * 3600,
      "America/Winnipeg" => -5 * 3600,
    }.freeze

    class << self
      def all
        @all ||= uniq_zone_names.map { |zone_name| new(zone_name) }
      end

      private

      def uniq_zone_names
        additional_zones = ADDITIONAL_ZONE_OFFSETS.keys.map { |name| ActiveSupport::TimeZone[name] }

        (ActiveSupport::TimeZone.all + additional_zones).sort_by do |time_zone|
          [ADDITIONAL_ZONE_OFFSETS.fetch(time_zone.tzinfo.name) { time_zone.utc_offset }, time_zone.name]
        end.map { |time_zone| time_zone.tzinfo.name }.uniq
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
