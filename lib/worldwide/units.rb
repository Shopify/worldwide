# frozen_string_literal: true

module Worldwide
  class Units
    class << self
      def format(amount, unit, humanize: :short)
        supported_humanization = supported_humanizations[humanize.to_sym]
        raise ArgumentError, "Unsupported value for `humanize`: #{humanize}." unless supported_humanization

        measurement_key = measurement_keys[unit.to_sym]
        raise ArgumentError, "Unsupported value for `unit`: #{unit}." unless measurement_key

        Cldr.t("units.unit_length.#{supported_humanization}.#{measurement_key}", count: amount)
      end

      def supported_humanizations
        {
          short: :short,
          long: :long,
        }.freeze
      end

      def measurement_keys
        {
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

          # Area
          square_meter: :area_square_meter,
          square_meters: :area_square_meter,
          square_centimeter: :area_square_centimeter,
          square_centimeters: :area_square_centimeter,
          square_foot: :area_square_foot,
          square_feet: :area_square_foot,
          square_inch: :area_square_inch,
          square_inches: :area_square_inch,
          square_yard: :area_square_yard,
          square_yards: :area_square_yard,

          # Duration
          second: :duration_second,
          seconds: :duration_second,
          millisecond: :duration_millisecond,
          milliseconds: :duration_millisecond,
          microsecond: :duration_microsecond,
          microseconds: :duration_microsecond,
          nanosecond: :duration_nanosecond,
          nanoseconds: :duration_nanosecond,
          minute: :duration_minute,
          minutes: :duration_minute,
          hour: :duration_hour,
          hours: :duration_hour,
          day: :duration_day,
          days: :duration_day,
          month: :duration_month,
          months: :duration_month,
          year: :duration_year,
          years: :duration_year,

          # Electric
          ampere: :electric_ampere,
          amperes: :electric_ampere,
          milliampere: :electric_milliampere,
          milliamperes: :electric_milliampere,
          ohm: :electric_ohm,
          ohms: :electric_ohm,
          volt: :electric_volt,
          volts: :electric_volt,

          # Energy
          joule: :energy_joule,
          joules: :energy_joule,
          calorie: :energy_calorie,
          calories: :energy_calorie,
          kilojoule: :energy_kilojoule,
          kilojoules: :energy_kilojoule,
          kilocalorie: :energy_kilocalorie,
          kilocalories: :energy_kilocalorie,

          # Frequency
          hertz: :frequency_hertz,
          kilohertz: :frequency_kilohertz,
          megahertz: :frequency_megahertz,
          gigahertz: :frequency_gigahertz,

          # Light
          lux: :light_lux,
          lumen: :light_lumen,
          lumens: :light_lumen,

          # Power
          watt: :power_watt,
          watts: :power_watt,
          milliwatt: :power_milliwatt,
          milliwatts: :power_milliwatt,
          kilowatt: :power_kilowatt,
          kilowatts: :power_kilowatt,
          horsepower: :power_horsepower,

          # Pressure
          pound_per_square_inch: :pressure_pound_force_per_square_inch,
          pounds_per_square_inch: :pressure_pound_force_per_square_inch,
          bar: :pressure_bar,
          bars: :pressure_bar,

          # Speed
          meter_per_second: :speed_meter_per_second,
          meters_per_second: :speed_meter_per_second,
          kilometer_per_hour: :speed_kilometer_per_hour,
          kilometers_per_hour: :speed_kilometer_per_hour,
          mile_per_hour: :speed_mile_per_hour,
          miles_per_hour: :speed_mile_per_hour,

          # Temperature
          celsius: :temperature_celsius,
          fahrenheit: :temperature_fahrenheit,
          kelvin: :temperature_kelvin,

          # Digital
          byte: :digital_byte,
          bytes: :digital_byte,
          kilobyte: :digital_kilobyte,
          kilobytes: :digital_kilobyte,
          megabyte: :digital_megabyte,
          megabytes: :digital_megabyte,
          gigabyte: :digital_gigabyte,
          gigabytes: :digital_gigabyte,
          terabyte: :digital_terabyte,
          terabytes: :digital_terabyte,

          # Graphics
          pixel: :graphics_pixel,
          pixels: :graphics_pixel,
          megapixel: :graphics_megapixel,
          megapixels: :graphics_megapixel,
          pixel_per_inch: :graphics_pixel_per_inch,
          pixels_per_inch: :graphics_pixel_per_inch,
          dot_per_inch: :graphics_dot_per_inch,
          dots_per_inch: :graphics_dot_per_inch,
        }.freeze
      end
    end
  end
end
