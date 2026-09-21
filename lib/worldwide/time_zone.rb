# frozen_string_literal: true

module Worldwide
  class TimeZone
    # Rails 8.1 renamed America/Godthab to America/Nuuk. Reuse the existing translation.
    TRANSLATION_KEYS = {
      "America/Nuuk" => "America/Godthab",
    }.freeze
    private_constant :TRANSLATION_KEYS

    DEFAULT_LABELS = {
      "America/Asuncion" => "(GMT-04:00) Asuncion",
    }.freeze
    private_constant :DEFAULT_LABELS

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
      key = TRANSLATION_KEYS.fetch(name, name)
      default = DEFAULT_LABELS[name]

      if default
        Cldr.t(key, scope: :timezones, default: default)
      else
        Cldr.t(key, scope: :timezones)
      end
    end
  end
end
