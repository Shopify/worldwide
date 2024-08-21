# frozen_string_literal: true

require "worldwide/calendar/gregorian"

module Worldwide
  module Calendar
    data = YAML.load_file(File.join(Worldwide::Paths::CLDR_ROOT, "week_data.yml"))["first_day"]
    weekday_numbers = {
      sun: 0,
      mon: 1,
      tue: 2,
      wed: 3,
      thu: 4,
      fri: 5,
      sat: 6,
    }
    FIRST_DAY_DATA = data.each_with_object({}) do |(day, territories), memo|
      territories.each do |territory|
        memo[territory.to_sym] = weekday_numbers.fetch(day.to_sym)
      end
    end
    FIRST_DAY_DATA.freeze
    private_constant :FIRST_DAY_DATA

    class << self
      def first_week_day(territory_code)
        FIRST_DAY_DATA[territory_code.to_sym] || FIRST_DAY_DATA.fetch(:"001")
      end
    end
  end
end
