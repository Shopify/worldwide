# frozen_string_literal: true

module Worldwide
  SUPPORTED_HUMANIZATIONS = {
    short: :short,
    long: :long,
  }.freeze

  MEASUREMENT_KEYS = {
    millimeter: :length_millimeter,
    millimeters: :length_millimeter,
    centimeter: :length_centimeter,
    centimeters: :length_centimeter,
    foot: :length_foot,
    feet: :length_foot,
    inch: :length_inch,
    inches: :length_inch,
    meter: :length_meter,
    meters: :length_meter,
    gram: :mass_gram,
    grams: :mass_gram,
    kilogram: :mass_kilogram,
    kilograms: :mass_kilogram,
    ounce: :mass_ounce,
    ounces: :mass_ounce,
    pound: :mass_pound,
    pounds: :mass_pound,
    centiliter: :volume_centiliter,
    centiliters: :volume_centiliter,
    cubic_meter: :volume_cubic_meter,
    cubic_meters: :volume_cubic_meter,
    imperial_fluid_ounce: :volume_fluid_ounce_imperial,
    imperial_fluid_ounces: :volume_fluid_ounce_imperial,
    fluid_ounce: :volume_fluid_ounce,
    fluid_ounces: :volume_fluid_ounce,
    imperial_gallon: :volume_gallon_imperial,
    imperial_gallons: :volume_gallon_imperial,
    gallon: :volume_gallon,
    gallons: :volume_gallon,
    liter: :volume_liter,
    liters: :volume_liter,
    milliliter: :volume_milliliter,
    milliliters: :volume_milliliter,
    pint: :volume_pint,
    pints: :volume_pint,
    imperial_pint: :volume_pint_imperial,
    imperial_pints: :volume_pint_imperial,
    quart: :volume_quart,
    quarts: :volume_quart,
    imperial_quart: :volume_quart_imperial,
    imperial_quarts: :volume_quart_imperial,
    yard: :length_yard,
    yards: :length_yard,
  }.freeze

  class Units
    class << self
      def format(amount, unit, humanize: :short)
        supported_humanization = SUPPORTED_HUMANIZATIONS[humanize.to_sym]
        raise ArgumentError, "Unsupported value for `humanize`: #{humanize}." unless supported_humanization

        measurement_key = MEASUREMENT_KEYS[unit.to_sym]
        raise ArgumentError, "Unsupported value for `unit`: #{unit}." unless measurement_key

        Cldr.t("units.unit_length.#{supported_humanization}.#{measurement_key}", count: amount)
      end
    end
  end
end
