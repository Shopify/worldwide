# frozen_string_literal: true

require "test_helper"

# Miscellaneous assertions about our files in data/other/timezones/??.yml
# and the iana_to_rails_time_zone.yml file.
# This is intended to catch errors introduced when editing those files.

module Worldwide
  class TimeZoneDataConsistencyTest < ActiveSupport::TestCase
    setup do
      @raw_yml = Dir["#{Worldwide::Paths::TIME_ZONE_ROOT}/*.yml"].map do |filename|
        YAML.safe_load_file(filename).freeze
      end
    end

    test "every timezone file has the expected top-level keys" do
      @raw_yml.each do |file|
        locale = file.keys.first

        assert_equal "timezones", file[locale].keys.first
      end
    end

    test "each timezone key corresponds to a rails tz identifier" do
      rails_timezones = ActiveSupport::TimeZone.all.map { |tz| ActiveSupport::TimeZone.find_tzinfo(tz.name).name }
      @raw_yml.each do |file|
        file.each do |_locale, data|
          data["timezones"].each do |tz_name, _translation|
            assert_includes rails_timezones, iana_timezones[tz_name], "#{tz_name} timezone is not supported by Rails"
          end
        end
      end
    end

    test "iana_to_rails_time_zone keys map to an equivalent value when supported by rails" do
      rails_timezones = ActiveSupport::TimeZone.all.map { |tz| ActiveSupport::TimeZone.find_tzinfo(tz.name).name }

      iana_timezones.each do |iana_tz, rails_tz|
        if rails_timezones.include?(iana_tz)
          assert_equal iana_tz, rails_tz
        end
      end
    end

    test "iana_to_rails_time_zone values are supported by rails" do
      rails_timezones = ActiveSupport::TimeZone.all.map { |tz| ActiveSupport::TimeZone.find_tzinfo(tz.name).name }

      iana_timezones.each do |_iana_tz, rails_tz|
        assert_includes rails_timezones, rails_tz, "#{rails_tz} timezone is not supported by Rails"
      end
    end

    def iana_timezones
      @iana_timezones ||= YAML.safe_load_file("#{Worldwide::Paths::DB_DATA_ROOT}/iana_to_rails_time_zone.yml")
    end
  end
end
