# frozen_string_literal: true

require "test_helper"

module Worldwide
  class CalendarTest < ActiveSupport::TestCase
    test "#first_week_day direct lookup" do
      assert_equal(0, Worldwide::Calendar.first_week_day(:US))
    end

    test "#first_week_day fallback to world default" do
      assert_equal(1, Worldwide::Calendar.first_week_day(:BO))
    end

    test "#first_week_day non-existent territory returns Monday (world default)" do
      assert_equal(1, Worldwide::Calendar.first_week_day(:"NON-EXISTENT"))
    end
  end
end
