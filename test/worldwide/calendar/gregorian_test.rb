# frozen_string_literal: true

require "test_helper"

module Worldwide
  module Calendar
    class GregorianTest < ActiveSupport::TestCase
      include PluralizationHelper

      WIDTHS = [:abbreviated, :narrow, :wide].freeze

      setup do
        @calendar = Worldwide::Calendar::Gregorian
      end

      test "#weekday_names in stand-alone context" do
        expected = { sun: "Sunday", mon: "Monday", tue: "Tuesday", wed: "Wednesday", thu: "Thursday", fri: "Friday", sat: "Saturday" }

        assert_equal expected, Worldwide::Calendar::Gregorian.weekday_names(locale: :"en-US")

        expected = { sun: "星期日", mon: "星期一", tue: "星期二", wed: "星期三", thu: "星期四", fri: "星期五", sat: "星期六" }

        assert_equal expected, Worldwide::Calendar::Gregorian.weekday_names(locale: :"zh-Hans-CN")

        expected = { sun: "Sun", mon: "Mon", tue: "Tue", wed: "Wed", thu: "Thu", fri: "Fri", sat: "Sat" }

        assert_equal expected, Worldwide::Calendar::Gregorian.weekday_names(locale: :"en-US", width: :abbreviated)
        expected = { sun: "周日", mon: "周一", tue: "周二", wed: "周三", thu: "周四", fri: "周五", sat: "周六" }

        assert_equal expected, Worldwide::Calendar::Gregorian.weekday_names(locale: :"zh-Hans-CN", width: :abbreviated)

        expected = { sun: "S", mon: "M", tue: "T", wed: "W", thu: "T", fri: "F", sat: "S" }

        assert_equal expected, Worldwide::Calendar::Gregorian.weekday_names(locale: :"en-US", width: :narrow)

        expected = { sun: "日", mon: "一", tue: "二", wed: "三", thu: "四", fri: "五", sat: "六" }

        assert_equal expected, Worldwide::Calendar::Gregorian.weekday_names(locale: :"zh-Hans-CN", width: :narrow)
      end

      test "#month_names in stand-alone context" do
        assert_equal ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"], Worldwide::Calendar::Gregorian.month_names(locale: :"en-US")
        assert_equal ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"], Worldwide::Calendar::Gregorian.month_names(locale: :"zh-Hans-CN")

        assert_equal ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"], Worldwide::Calendar::Gregorian.month_names(locale: :"en-US", width: :abbreviated)
        assert_equal ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"], Worldwide::Calendar::Gregorian.month_names(locale: :"zh-Hans-CN", width: :abbreviated)

        assert_equal ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"], Worldwide::Calendar::Gregorian.month_names(locale: :"en-US", width: :narrow)
        assert_equal ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"], Worldwide::Calendar::Gregorian.month_names(locale: :"zh-Hans-CN", width: :narrow)
      end

      test "#quarter in format context" do
        assert_equal "Q1 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 1, 1))
        assert_equal "2016年第1季度", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 1, 1), locale: :"zh-Hans-CN")

        assert_equal "Q1 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 2, 1))
        assert_equal "Q1 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 3, 1))
        assert_equal "Q2 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 4, 1))
        assert_equal "Q2 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 5, 1))
        assert_equal "Q2 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 6, 1))
        assert_equal "Q3 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 7, 1))
        assert_equal "Q3 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 8, 1))
        assert_equal "Q3 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 9, 1))
        assert_equal "Q4 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 10, 1))
        assert_equal "Q4 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 11, 1))
        assert_equal "Q4 2016", Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 12, 1))
      end

      # `stand_alone` is an alias to `format` in CLDR for these locales, so the names only
      # resolve if the alias in `root` is followed and then read back in the requested locale.
      test "#weekday_names resolves the CLDR stand-alone alias" do
        expected = { sun: "Sunday", mon: "Monday", tue: "Tuesday", wed: "Wednesday", thu: "Thursday", fri: "Friday", sat: "Saturday" }

        assert_equal expected, @calendar.weekday_names(locale: :en)

        expected = { sun: "søndag", mon: "mandag", tue: "tirsdag", wed: "onsdag", thu: "torsdag", fri: "fredag", sat: "lørdag" }

        # `nb` holds no calendar data of its own; it inherits everything from `no`.
        assert_equal expected, @calendar.weekday_names(locale: :nb)
      end

      test "#month_names resolves the CLDR stand-alone alias" do
        assert_equal ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"], @calendar.month_names(locale: :en)
        assert_equal ["januar", "februar", "mars", "april", "mai", "juni", "juli", "august", "september", "oktober", "november", "desember"], @calendar.month_names(locale: :nb)
      end

      # CLDR inheritance is item by item, so a locale that overrides one entry still
      # inherits its siblings. `en-CA` only overrides September.
      test "#month_names inherits the entries a locale does not override" do
        expected = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec"]

        assert_equal expected, @calendar.month_names(locale: :"en-CA", width: :abbreviated)
        assert_equal expected, @calendar.month_names(locale: :"en-GB", width: :abbreviated)

        # `ar-MA` overrides 7 of the 12 wide month names.
        expected = ["يناير", "فبراير", "مارس", "أبريل", "ماي", "يونيو", "يوليوز", "غشت", "شتنبر", "أكتوبر", "نونبر", "دجنبر"]

        assert_equal expected, @calendar.month_names(locale: :"ar-MA")
      end

      test "#weekday_names inherits the entries a locale does not override" do
        # `se-FI` overrides 4 of the 7 wide weekday names.
        expected = { sun: "sotnabeaivi", mon: "mánnodat", tue: "disdat", wed: "gaskavahkku", thu: "duorastat", fri: "bearjadat", sat: "lávvordat" }

        assert_equal expected, @calendar.weekday_names(locale: :"se-FI")
      end

      Worldwide::Locales.each do |locale|
        test "#quarter formatting doesn't fail (i.e., rely on date fields that have not been implemented) in #{locale}" do
          Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 1, 1), locale: locale)
        end

        # Guards the whole class of bug: a missing key degrades into a humanized copy of its
        # last segment, so an unresolved lookup hands back the string "wide" rather than raising.
        test "#weekday_names and #month_names return complete data in #{locale}" do
          WIDTHS.each do |width|
            weekdays = Worldwide::Calendar::Gregorian.weekday_names(width: width, locale: locale)

            assert_equal [:sun, :mon, :tue, :wed, :thu, :fri, :sat], weekdays.keys, "#{locale} #{width} weekday names"
            assert_empty weekdays.values.select { |name| name.nil? || name.empty? }, "#{locale} #{width} weekday names"

            months = Worldwide::Calendar::Gregorian.month_names(width: width, locale: locale)

            assert_equal 12, months.size, "#{locale} #{width} month names"
            assert_empty months.select { |name| name.nil? || name.empty? }, "#{locale} #{width} month names"
          end
        end
      end
    end
  end
end
