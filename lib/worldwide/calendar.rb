# frozen_string_literal: true

require "worldwide/calendar/gregorian"

module Worldwide
  module Calendar
    class << self
      def first_week_day(territory_code)
        first_day_data[territory_code.to_sym] || first_day_data.fetch(:"001")
      end

      private

      def first_day_data
        return @first_day_data if defined?(@first_day_data)

        weekday_numbers = {
          sun: 0,
          mon: 1,
          tue: 2,
          wed: 3,
          thu: 4,
          fri: 5,
          sat: 6,
        }

        data = YAML.load_file(File.join(Worldwide::Paths::CLDR_ROOT, "week_data.yml"))["first_day"]
        @first_day_data = data.each_with_object({}) do |(day, territories), memo|
          territories.each do |territory|
            memo[territory.to_sym] = weekday_numbers.fetch(day.to_sym)
          end
        end
      end
    end
  end
end
