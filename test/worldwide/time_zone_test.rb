# frozen_string_literal: true

require "test_helper"

module Worldwide
  class TimeZoneTest < ActiveSupport::TestCase
    test ".all contains object respond to name" do
      timezone_object = Worldwide::TimeZone.all.sample

      assert_respond_to timezone_object, :name
    end

    test ".all has no duplicates" do
      all_time_zone_names = Worldwide::TimeZone.all.map(&:name)

      assert_equal all_time_zone_names.count, all_time_zone_names.uniq.count
    end

    test ".all includes Canadian time zones with independent clock changes" do
      zone_names = Worldwide::TimeZone.all.map(&:name)

      canadian_zone_labels.each_key do |name|
        assert_includes zone_names, name
      end
    end

    test ".all retains all Rails time zones" do
      rails_zone_names = ActiveSupport::TimeZone.all.map { |zone| zone.tzinfo.name }

      assert_empty rails_zone_names - Worldwide::TimeZone.all.map(&:name)
    end

    test ".all orders time zones with the permanent Canadian offsets" do
      offsets = Worldwide::TimeZone.all.map do |zone|
        canadian_zone_offsets.fetch(zone.name) { ActiveSupport::TimeZone[zone.name].utc_offset }
      end

      assert_equal offsets.sort, offsets
    end

    test ".all keeps the same order across the Canadian base-offset changes" do
      {
        "America/Vancouver" => -8 * 3600,
        "America/Whitehorse" => -7 * 3600,
        "America/Edmonton" => -7 * 3600,
        "America/Winnipeg" => -6 * 3600,
      }.each do |name, offset|
        ActiveSupport::TimeZone[name].stubs(:utc_offset).returns(offset)
      end
      before_names = Class.new(Worldwide::TimeZone).all.map(&:name)

      canadian_zone_offsets.each do |name, offset|
        ActiveSupport::TimeZone[name].stubs(:utc_offset).returns(offset)
      end
      after_names = Class.new(Worldwide::TimeZone).all.map(&:name)

      assert_equal before_names, after_names
    end

    test ".all has the same unique order when Rails includes the additional zones" do
      expected_names = Class.new(Worldwide::TimeZone).all.map(&:name)
      rails_zones = ActiveSupport::TimeZone.all
      canadian_zones = canadian_zone_labels.keys.map { |name| ActiveSupport::TimeZone[name] }
      ActiveSupport::TimeZone.stubs(:all).returns(rails_zones + canadian_zones)

      assert_equal expected_names, Class.new(Worldwide::TimeZone).all.map(&:name)
    end

    test "#to_s displays Canadian time zones with their permanent offsets" do
      I18n.with_locale(:en) do
        canadian_zone_labels.each do |name, label|
          assert_equal label, Worldwide::TimeZone.new(name).to_s
        end
      end
    end

    test "#to_s displays Canadian time zones in Canadian French" do
      I18n.with_locale(:"fr-CA") do
        assert_equal "(GMT-07:00) Colombie-Britannique", Worldwide::TimeZone.new("America/Vancouver").to_s
        assert_equal "(GMT-07:00) Yukon", Worldwide::TimeZone.new("America/Whitehorse").to_s
        assert_equal "(GMT-06:00) Alberta, Territoires du Nord-Ouest", Worldwide::TimeZone.new("America/Edmonton").to_s
        assert_equal "(GMT-05:00) Manitoba", Worldwide::TimeZone.new("America/Winnipeg").to_s
      end
    end

    test "#to_s displays Canadian time zones in German" do
      I18n.with_locale(:de) do
        assert_equal "(GMT-07:00) British Columbia", Worldwide::TimeZone.new("America/Vancouver").to_s
        assert_equal "(GMT-07:00) Yukon", Worldwide::TimeZone.new("America/Whitehorse").to_s
        assert_equal "(GMT-06:00) Alberta, Nordwest-Territorien", Worldwide::TimeZone.new("America/Edmonton").to_s
        assert_equal "(GMT-05:00) Manitoba", Worldwide::TimeZone.new("America/Winnipeg").to_s
      end
    end

    test "#to_s falls back to English for untranslated Canadian time zones" do
      I18n.with_locale(:gsw) do
        canadian_zone_labels.each do |name, label|
          assert_equal label, Worldwide::TimeZone.new(name).to_s
        end
      end
    end

    test "#to_s lookup the translation" do
      zone = Worldwide::TimeZone.new("Etc/GMT+12")

      assert_equal "(GMT-12:00) International Date Line West", zone.to_s
    end

    test "#to_s display for zone America/Mexico_City" do
      zone = Worldwide::TimeZone.new("America/Mexico_City")

      assert_equal "(GMT-06:00) Guadalajara, Mexico City", zone.to_s
    end

    test "#to_s display for zone America/Lima" do
      zone = Worldwide::TimeZone.new("America/Lima")

      assert_equal "(GMT-05:00) Lima, Quito", zone.to_s
    end

    test "#to_s display for zone Europe/London" do
      zone = Worldwide::TimeZone.new("Europe/London")

      assert_equal "(GMT+00:00) Edinburgh, London", zone.to_s
    end

    test "#to_s display for zone Europe/Zurich" do
      zone = Worldwide::TimeZone.new("Europe/Zurich")

      assert_equal "(GMT+01:00) Bern, Zurich", zone.to_s
    end

    test "#to_s display for zone Europe/Moscow" do
      zone = Worldwide::TimeZone.new("Europe/Moscow")

      assert_equal "(GMT+03:00) Moscow, St. Petersburg", zone.to_s
    end

    test "#to_s display for zone Asia/Muscat" do
      zone = Worldwide::TimeZone.new("Asia/Muscat")

      assert_equal "(GMT+04:00) Abu Dhabi, Muscat", zone.to_s
    end

    test "#to_s display for zone Asia/Karachi" do
      zone = Worldwide::TimeZone.new("Asia/Karachi")

      assert_equal "(GMT+05:00) Islamabad, Karachi", zone.to_s
    end

    test "#to_s display for zone Asia/Kolkata" do
      zone = Worldwide::TimeZone.new("Asia/Kolkata")

      assert_equal "(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi", zone.to_s
    end

    test "#to_s display for zone Asia/Dhaka" do
      zone = Worldwide::TimeZone.new("Asia/Dhaka")

      assert_equal "(GMT+06:00) Astana, Dhaka", zone.to_s
    end

    test "#to_s display for zone Asia/Bangkok" do
      zone = Worldwide::TimeZone.new("Asia/Bangkok")

      assert_equal "(GMT+07:00) Bangkok, Hanoi", zone.to_s
    end

    test "#to_s display for zone Asia/Tokyo" do
      zone = Worldwide::TimeZone.new("Asia/Tokyo")

      assert_equal "(GMT+09:00) Osaka, Sapporo, Tokyo", zone.to_s
    end

    test "#to_s display for zone Australia/Melbourne" do
      zone = Worldwide::TimeZone.new("Australia/Melbourne")

      assert_equal "(GMT+10:00) Canberra, Melbourne", zone.to_s
    end

    test "#to_s display for zone Pacific/Auckland" do
      zone = Worldwide::TimeZone.new("Pacific/Auckland")

      assert_equal "(GMT+12:00) Auckland, Wellington", zone.to_s
    end

    private

    def canadian_zone_labels
      {
        "America/Vancouver" => "(GMT-07:00) British Columbia",
        "America/Whitehorse" => "(GMT-07:00) Yukon",
        "America/Edmonton" => "(GMT-06:00) Alberta, Northwest Territories",
        "America/Winnipeg" => "(GMT-05:00) Manitoba",
      }
    end

    def canadian_zone_offsets
      {
        "America/Vancouver" => -7 * 3600,
        "America/Whitehorse" => -7 * 3600,
        "America/Edmonton" => -6 * 3600,
        "America/Winnipeg" => -5 * 3600,
      }
    end
  end
end
