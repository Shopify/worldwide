# frozen_string_literal: true

require "test_helper"

module Worldwide
  class PaTest < ActiveSupport::TestCase
    setup do
      @region = Worldwide.region(code: "PA")
    end

    test "four digit postal codes are valid" do
      assert @region.valid_zip?("0815") # Correos y Telégrafos, Avenida Central y Calle 34
    end

    test "ten character postal codes are valid" do
      assert @region.valid_zip?("ADC96-M8H44") # Municipio de Panamá, Avenida Justo Arosemena
    end

    test "ten character postal codes are valid without the hyphen, in lowercase, or with spaces" do
      ["ADC96M8H44", "adc96-m8h44", "ADC96 M8H44", "ADC96M-8H44", "ADC96\u2013M8H44"].each do |zip|
        assert @region.valid_zip?(zip), "Expected #{zip.inspect} to be valid"
      end
    end

    test "zip_regex accepts a hyphen, a space, or nothing between the two groups" do
      regex = Regexp.new(@region.zip_regex)

      ["ADC96-M8H44", "ADC96 M8H44", "ADC96M8H44"].each do |zip|
        assert_match regex, zip
      end
      ["ADC96--M8H44", "ADC96  M8H44", "ADC96_M8H44"].each do |zip|
        assert_no_match regex, zip
      end
    end

    test "blank postal codes are valid because the postal code is optional" do
      assert @region.valid_zip?(nil)
      assert @region.valid_zip?("")
    end

    test "ten character postal codes with characters outside the official alphabet are invalid" do
      # After the 2-character prefix, codes use only 23456789ABCDEFGHJKLMNPQRSTVWXZ
      ["AD096-M8H44", "ADC16-M8H44", "ADC96-I8H44", "ADC96-M8O44", "ADC96-M8H4U", "ADC96-Y8H44"].each do |zip|
        assert_not @region.valid_zip?(zip), "Expected #{zip.inspect} to be invalid"
      end
    end

    test "codes of other lengths are invalid" do
      ["815", "08150", "C96M8H44", "ADC96-M8H4", "ADC96-M8H442"].each do |zip|
        assert_not @region.valid_zip?(zip), "Expected #{zip.inspect} to be invalid"
      end
    end
  end
end
