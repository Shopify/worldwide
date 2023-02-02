# frozen_string_literal: true

require "test_helper"

module Worldwide
  module Calendar
    class GregorianTest < ActiveSupport::TestCase
      include PluralizationHelper

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

      Worldwide::Locales.each do |locale|
        test "#quarter formatting doesn't fail (i.e., rely on date fields that have not been implemented) in #{locale}" do
          Worldwide::Calendar::Gregorian.quarter(Date.new(2016, 1, 1), locale: locale)
        end
      end
    end
  end
end
