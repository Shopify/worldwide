# frozen_string_literal: true

require "test_helper"
require_relative "../../../rake/postal/codes"
require_relative "../../../rake/postal/postal_helpers"
require "stringio"

class ZoneCheckerTest < ActiveSupport::TestCase
  include PostalHelpers

  test "Canadian codes are zoned as expected" do
    input = <<~CSV
      zip,province,CNT
      K1A 1A1,Ontario,14
      K1A 0C9,Quebec,13
      A1A 1A1,Newfoundland and Labrador,12
      V6B 4A2,British Columbia,11
      M5W 1E6,Ontario,10
      J8X 2K5,Ontario,9
      C1A 4N7,Prince Edward Island,8
      X0A 0H0,Nunavut,7
      X1A 3T5,Northwest Territories,6
      X0C 0H0,Northwest Territories,5
      Y0B 1N0,Yukon,4
      T5J 2Z2,Saskatchewan,3
      T5J 1B9,Alberta,2
      R3C 1A3,Manitoba,1
    CSV

    checker = Postal::ZoneChecker.new
    output = StringIO.new
    country = Worldwide.region(code: "CA")

    checker.send(:check_codes, input, output, country, 120)

    expected = <<~EXPECTED
      "K1A 1A1" "ON" true (14 occurrences, 11.67%, cumulative failed 0.00%)
      "K1A 0C9" "QC" true (13 occurrences, 10.83%, cumulative failed 0.00%)
      "A1A 1A1" "NL" true (12 occurrences, 10.00%, cumulative failed 0.00%)
      "V6B 4A2" "BC" true (11 occurrences, 9.17%, cumulative failed 0.00%)
      "M5W 1E6" "ON" true (10 occurrences, 8.33%, cumulative failed 0.00%)
      "J8X 2K5" "ON" false (9 occurrences, 7.50%, cumulative failed 7.50%)
      "C1A 4N7" "PE" true (8 occurrences, 6.67%, cumulative failed 7.50%)
      "X0A 0H0" "NU" true (7 occurrences, 5.83%, cumulative failed 7.50%)
      "X1A 3T5" "NT" true (6 occurrences, 5.00%, cumulative failed 7.50%)
      "X0C 0H0" "NT" false (5 occurrences, 4.17%, cumulative failed 11.67%)
      "Y0B 1N0" "YT" true (4 occurrences, 3.33%, cumulative failed 11.67%)
      "T5J 2Z2" "SK" false (3 occurrences, 2.50%, cumulative failed 14.17%)
      "T5J 1B9" "AB" true (2 occurrences, 1.67%, cumulative failed 14.17%)
      "R3C 1A3" "MB" true (1 occurrences, 0.83%, cumulative failed 14.17%)
    EXPECTED

    assert_equal expected, output.string
  end

  test "Italian codes are zoned as expected" do
    # Notes:
    # - 00120 is intentionally dropped from the output, because it fails country.valid_zip?()
    input = <<~CSV
      zip,province,CNT
      62010,Macerata,11
      20122,Milano,10
      30123,Venezia,9
      00000,Agrigento,8
      59100,Prato,7
      39100,Bolzano,6
      00120,Vatican City,5
      20121,Milano,4
      18025,Cuneo,3
      18025,Imperia,2
      22060,Como,1
    CSV

    checker = Postal::ZoneChecker.new
    output = StringIO.new
    country = Worldwide.region(code: "IT")

    checker.send(:check_codes, input, output, country, 100)

    expected = <<~EXPECTED
      "62010" "MC" true (11 occurrences, 11.00%, cumulative failed 0.00%)
      "20122" "MI" true (10 occurrences, 10.00%, cumulative failed 0.00%)
      "30123" "VE" true (9 occurrences, 9.00%, cumulative failed 0.00%)
      "00000" "AG" false (8 occurrences, 8.00%, cumulative failed 8.00%)
      "59100" "PO" true (7 occurrences, 7.00%, cumulative failed 8.00%)
      "39100" "BZ" true (6 occurrences, 6.00%, cumulative failed 8.00%)
      "20121" "MI" true (4 occurrences, 4.00%, cumulative failed 8.00%)
      "18025" "CN" true (3 occurrences, 3.00%, cumulative failed 8.00%)
      "18025" "IM" true (2 occurrences, 2.00%, cumulative failed 8.00%)
      "22060" "CO" true (1 occurrences, 1.00%, cumulative failed 8.00%)
    EXPECTED

    assert_equal expected, output.string
  end

  test "New Zealand codes are zoned as expected" do
    input = <<~CSV
      zip,province,CNT
      1000,Auckland,9
      2330,Auckland,8
      3378,Waikato,7
      3378,Auckland,6
      3378,Bay of Plenty,5
      3378,Hawke's Bay,4
      8110,Canterbury,3
      8016,Canterbury,2
      8016,Chatham Islands,1
    CSV

    checker = Postal::ZoneChecker.new
    output = StringIO.new
    country = Worldwide.region(code: "NZ")

    checker.send(:check_codes, input, output, country, 60)

    expected = <<~EXPECTED
      "1000" "AUK" true (9 occurrences, 15.00%, cumulative failed 0.00%)
      "3378" "WKO" true (7 occurrences, 11.67%, cumulative failed 0.00%)
      "3378" "AUK" false (6 occurrences, 10.00%, cumulative failed 10.00%)
      "3378" "BOP" true (5 occurrences, 8.33%, cumulative failed 10.00%)
      "3378" "HKB" true (4 occurrences, 6.67%, cumulative failed 10.00%)
      "8110" "CAN" true (3 occurrences, 5.00%, cumulative failed 10.00%)
      "8016" "CAN" false (2 occurrences, 3.33%, cumulative failed 13.33%)
      "8016" "CIT" true (1 occurrences, 1.67%, cumulative failed 13.33%)
    EXPECTED

    assert_equal expected, output.string
  end
end
