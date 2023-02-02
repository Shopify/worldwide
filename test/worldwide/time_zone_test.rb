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
  end
end
