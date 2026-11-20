# frozen_string_literal: true

module Worldwide
  class TimeZone
    # Rails' curated list omits these Canadian zones before Rails 8.2.
    # Explicit offsets keep the returned list stable when TZInfo's 2026 base offsets change.
    ADDITIONAL_ZONE_OFFSETS = {
      "America/Edmonton" => -6 * 3600,
      "America/Inuvik" => -6 * 3600,
      "America/Vancouver" => -7 * 3600,
      "America/Whitehorse" => -7 * 3600,
      "America/Winnipeg" => -5 * 3600,
    }.freeze

    # Rails 8.1 moved these zones to their current tz names. Older Rails still reports the old names, which
    # have no labels here, so mapping them keeps names and labels the same on every Rails version.
    RAILS_LEGACY_ZONE_NAMES = {
      "America/Godthab" => "America/Nuuk",
      "Asia/Rangoon" => "Asia/Yangon",
      "Europe/Kiev" => "Europe/Kyiv",
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
        end.map { |time_zone| RAILS_LEGACY_ZONE_NAMES.fetch(time_zone.tzinfo.name, time_zone.tzinfo.name) }.uniq
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
      Cldr.t(RAILS_LEGACY_ZONE_NAMES.fetch(name, name), scope: :timezones)
    end
  end
end
