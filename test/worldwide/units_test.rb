# frozen_string_literal: true

require "test_helper"

module Worldwide
  class UnitsTest < ActiveSupport::TestCase
    test "#format returns the right unit format when `unit` is plural" do
      I18n.with_locale("en") do
        result = Worldwide::Units.format(5, :imperial_fluid_ounces)

        assert_equal "5 fl oz Imp.", result
      end
    end

    test "#format returns the abbreviated version of the unit when `humanize` isn't specified" do
      I18n.with_locale("ar") do
        result = Worldwide::Units.format(1, :kilogram)

        assert_equal "1 كغم", result
      end
    end

    test "#format with :long `humanize` returns the full-word version of the unit" do
      I18n.with_locale("en") do
        result = Worldwide::Units.format(5, :imperial_fluid_ounces, humanize: :long)

        assert_equal "5 Imp. fluid ounces", result
      end
    end

    test "#format raises an argument error when `humanize` is unsupported" do
      I18n.with_locale("en") do
        err = assert_raises(ArgumentError) do
          Worldwide::Units.format(5, :imperial_fluid_ounces, humanize: :unsupported)
        end

        assert_equal "Unsupported value for `humanize`: unsupported.", err.message
      end
    end

    test "#format raises an argument error when `unit` is unsupported" do
      I18n.with_locale("en") do
        err = assert_raises(ArgumentError) do
          Worldwide::Units.format(5, :unsupported)
        end

        assert_equal "Unsupported value for `unit`: unsupported.", err.message
      end
    end

    test "#format defaults to the right translation if the measurement unit doesn't exist for a language" do
      I18n.with_locale("de-CH") do
        result = Worldwide::Units.format(5, :centimeter, humanize: :long)

        assert_equal "5 Zentimeter", result
      end
    end

    test "#format retrieves the value from the en.yml file for imperial_pints" do
      I18n.with_locale("en") do
        result = Worldwide::Units.format(27, :imperial_pints, humanize: :long)

        assert_equal "27 Imp. pints", result
      end
    end

    test "#format defaults to the right translation if the language doesn't have an unit.yml file" do
      I18n.with_locale("de-IT") do
        result = Worldwide::Units.format(5, :centimeter, humanize: :long)

        assert_equal "5 Zentimeter", result
      end
    end

    test "#format accepts string values for the `unit` and `humanize` parameters" do
      I18n.with_locale("en") do
        result = Worldwide::Units.format(5, "centimeters", humanize: "short")

        assert_equal "5 cm", result
      end
    end

    test "#supported_humanizations returns supported humanizations" do
      assert_not Worldwide.units.supported_humanizations.empty?
    end

    test "#measurement_keys returns supported measurement keys" do
      assert_not Worldwide.units.measurement_keys.empty?
    end

    # Short format tests for new unit categories

    test "#format short area: square_meters" do
      I18n.with_locale("en") do
        assert_equal "5 m²", Worldwide::Units.format(5, :square_meters)
      end
    end

    test "#format short temperature: fahrenheit" do
      I18n.with_locale("en") do
        assert_equal "72°F", Worldwide::Units.format(72, :fahrenheit)
      end
    end

    test "#format short power: watts" do
      I18n.with_locale("en") do
        assert_equal "150 W", Worldwide::Units.format(150, :watts)
      end
    end

    test "#format short frequency: gigahertz" do
      I18n.with_locale("en") do
        assert_equal "2.4 GHz", Worldwide::Units.format(2.4, :gigahertz)
      end
    end

    test "#format short digital: gigabytes" do
      I18n.with_locale("en") do
        assert_equal "500 GB", Worldwide::Units.format(500, :gigabytes)
      end
    end

    test "#format short speed: miles_per_hour" do
      I18n.with_locale("en") do
        assert_equal "60 mph", Worldwide::Units.format(60, :miles_per_hour)
      end
    end

    test "#format short pressure: pounds_per_square_inch" do
      I18n.with_locale("en") do
        assert_equal "30 psi", Worldwide::Units.format(30, :pounds_per_square_inch)
      end
    end

    test "#format short energy: kilojoules" do
      I18n.with_locale("en") do
        assert_equal "100 kJ", Worldwide::Units.format(100, :kilojoules)
      end
    end

    test "#format short duration: minutes" do
      I18n.with_locale("en") do
        assert_equal "30 min", Worldwide::Units.format(30, :minutes)
      end
    end

    test "#format short electric: volts" do
      I18n.with_locale("en") do
        assert_equal "120 V", Worldwide::Units.format(120, :volts)
      end
    end

    test "#format short light: lux" do
      I18n.with_locale("en") do
        assert_equal "500 lx", Worldwide::Units.format(500, :lux)
      end
    end

    test "#format short graphics: megapixels" do
      I18n.with_locale("en") do
        assert_equal "12 MP", Worldwide::Units.format(12, :megapixels)
      end
    end

    # Long format tests with pluralization

    test "#format long power: singular watt" do
      I18n.with_locale("en") do
        assert_equal "1 watt", Worldwide::Units.format(1, :watt, humanize: :long)
      end
    end

    test "#format long power: plural watts" do
      I18n.with_locale("en") do
        assert_equal "5 watts", Worldwide::Units.format(5, :watts, humanize: :long)
      end
    end

    test "#format long temperature: singular celsius" do
      I18n.with_locale("en") do
        assert_equal "1 degree Celsius", Worldwide::Units.format(1, :celsius, humanize: :long)
      end
    end

    test "#format long temperature: plural celsius" do
      I18n.with_locale("en") do
        assert_equal "100 degrees Celsius", Worldwide::Units.format(100, :celsius, humanize: :long)
      end
    end

    test "#format long duration: singular second" do
      I18n.with_locale("en") do
        assert_equal "1 second", Worldwide::Units.format(1, :second, humanize: :long)
      end
    end

    test "#format long duration: plural seconds" do
      I18n.with_locale("en") do
        assert_equal "30 seconds", Worldwide::Units.format(30, :seconds, humanize: :long)
      end
    end

    # Non-English locale tests

    test "#format short power: watts in French" do
      I18n.with_locale("fr") do
        assert_equal "5\u202FW", Worldwide::Units.format(5, :watts)
      end
    end

    test "#format long power: watts in French" do
      I18n.with_locale("fr") do
        assert_equal "5\u00A0watts", Worldwide::Units.format(5, :watts, humanize: :long)
      end
    end

    test "#format long power: watts in German via de-CH fallback" do
      I18n.with_locale("de-CH") do
        assert_equal "5 Watt", Worldwide::Units.format(5, :watts, humanize: :long)
      end
    end
  end
end
