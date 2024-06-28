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
  end
end
