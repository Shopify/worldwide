# frozen_string_literal: true

require "test_helper"

module Worldwide
  class CanadianTimezonesTest < ActiveSupport::TestCase
    test "Nunavut and neighboring postal codes have the correct timezone prefixes" do
      expected_timezones = {
        "X0B 0C0" => "America/Cambridge_Bay",
        "X0B 1J0" => "America/Cambridge_Bay",
        "X0C 0A0" => "America/Rankin_Inlet",
        "X0C 0A1" => "America/Rankin_Inlet",
        "X0C 0A3" => "America/Rankin_Inlet",
        "X0C 0A4" => "America/Rankin_Inlet",
        "X0C 0A5" => "America/Rankin_Inlet",
        "X0C 0A6" => "America/Rankin_Inlet",
        "X0C 0A7" => "America/Rankin_Inlet",
        "X0C 0B0" => "America/Rankin_Inlet",
        "X0C 0E0" => "America/Rankin_Inlet",
        "X0C 0G0" => "America/Rankin_Inlet",
        "X0C 0H0" => "America/Rankin_Inlet",
        "X0C 0J0" => "America/Rankin_Inlet",
        "X0A 0V0" => "America/Resolute",
        "X0A 0A2" => "America/Resolute",
        "X0A 0A0" => "America/Iqaluit",
        "X0A 0B3" => "America/Iqaluit",
        "X0A 0H0" => "America/Toronto",
        "X0C 0A2" => "America/Atikokan",
        "X0C 0C0" => "America/Atikokan",
        "X0E 0A0" => "America/Edmonton",
        "X0G 0A0" => "America/Edmonton",
        "X1A 2N8" => "America/Edmonton",
        "T5J 2R7" => "America/Edmonton",
        "R3C 4T3" => "America/Winnipeg",
      }

      timezones = Worldwide.region(code: "CA").timezones
      expected_timezones.each do |postal_code, timezone|
        matches = timezones.select { |_name, prefixes| prefixes.any? { |prefix| postal_code.start_with?(prefix) } }.keys

        assert_equal [timezone], matches, postal_code
      end
    end
  end
end
