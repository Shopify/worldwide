# frozen_string_literal: true

require "test_helper"

module Worldwide
  class AddressFormattingTest < ActiveSupport::TestCase
    test "format_address returns an array of address lines given an address" do
      bobs_home = {
        first_name: "Bob",
        last_name: "Bobsen",
        company: "",
        address1: "123 Amoebobacterieae St",
        address2: "",
        zip: "K2P0V6",
        city: "Ottawa",
        province_code: "ON",
        country_code: "CA",
      }

      expected = [
        "Bob Bobsen",
        "123 Amoebobacterieae St",
        "Ottawa ON K2P0V6",
        "Canada",
      ]

      assert_equal expected, Worldwide.address(**bobs_home).format
    end

    test "format_address supports formats besides the default Canada format" do
      china_address = {
        first_name: "Zhimin",
        last_name: "Li",
        address1: "63 Renmin Lu",
        city: "Qingdao Shi",
        zip: "266033",
        province_code: "SD", # Shandong
        country_code: "CN",
      }

      expected = [
        "Zhimin Li",
        "63 Renmin Lu Qingdao Shi",
        "266033 Shandong",
        "China",
      ]

      assert_equal expected, Worldwide.address(**china_address).format
    end

    test "format_address uses the province short_name instead of full_name for some countries" do
      us_address = {
        first_name: "Francisco",
        last_name: "de Asis",
        address1: "3321 16th St",
        city: "San Francisco",
        zip: "94114",
        province_code: "CA",
        country_code: "US",
      }

      expected = [
        "Francisco de Asis",
        "3321 16th St",
        "San Francisco CA 94114",
        "United States",
      ]

      assert_equal expected, Worldwide.address(**us_address).format
    end

    test "format_address returns province_name instead of province_code for some countries" do
      portugal_address = {
        first_name: "Fulano",
        last_name: "de Tal",
        address1: "Largo da Conceicao 5",
        province_code: "PT-02",
        country_code: "PT",
      }

      expected = [
        "Fulano de Tal",
        "Largo da Conceicao 5",
        "Beja",
        "Portugal",
      ]

      assert_equal expected, Worldwide.address(**portugal_address).format
    end

    test "format_address returns province_name instead of province_code for Chilean addresses" do
      chile_address = {
        first_name: "Juan",
        last_name: "Pérez",
        address1: "Catorce Ote. 888",
        city: "Talca",
        province_code: "ML",
        country_code: "CL",
      }

      expected = [
        "Juan Pérez",
        "Catorce Ote. 888",
        "Talca",
        "Maule",
        "Chile",
      ]

      assert_equal expected, Worldwide.address(**chile_address).format
    end

    test "format_address returns province_name instead of province_code for Malaysian addresses" do
      malaysian_address = {
        first_name: "Si",
        last_name: "fulan",
        address1: "Jalan P10/13",
        address2: "Kawasan Perindustrian Miel",
        city: "Bandar Baru Bangi",
        zip: "43650",
        province_code: "SGR",
        country_code: "MY",
      }

      expected = [
        "Si fulan",
        "Jalan P10/13",
        "Kawasan Perindustrian Miel",
        "43650 Bandar Baru Bangi",
        "Selangor",
        "Malaysia",
      ]

      assert_equal expected, Worldwide.address(**malaysian_address).format
    end

    test "format_address supports formats with additional characters" do
      japan_address = {
        first_name: "賢",
        last_name: "鈴木",
        address1: "柏町２丁目１３−１",
        address2: nil,
        city: "立川市",
        province_code: "JP-13",
        country_code: "JP",
        zip: "190-0004",
      }

      expected = [
        "Japan 〒190-0004",
        "Tokyo 立川市",
        "柏町２丁目１３−１",
        "鈴木 賢様", # NOTE: the 3rd-char space shouldn't be there, but our current implementation puts it in
      ]

      assert_equal expected, Worldwide.address(**japan_address).format
    end

    test "format_address has specified excluded fields excluded" do
      bobs_home = {
        first_name: "Bob",
        last_name: "Bobsen",
        company: "",
        address1: "100 Queens Park",
        address2: "",
        zip: "M5S 2C6",
        city: "Toronto",
        province_code: "ON",
        country_code: "CA",
        phone: "(416)555-5555",
      }
      excluded_fields = [:country, :province]

      expected = [
        "Bob Bobsen",
        "100 Queens Park",
        "Toronto M5S 2C6",
        "\u200E(416)555-5555",
      ]

      result = Worldwide.address(**bobs_home).format(excluded_fields: excluded_fields)

      assert_equal expected, result
    end

    test "format_address has both first and last names excluded when excluding name" do
      bobs_home = {
        first_name: "Bob",
        last_name: "Bobsen",
        company: "",
        address1: "974 Carling Ave.",
        address2: "",
        zip: "K1Y 4E4",
        city: "Ottawa",
        province_code: "ON",
        country_code: "CA",
        phone: "(555)555-5555",
      }

      excluded_fields = [:name]

      expected = [
        "974 Carling Ave.",
        "Ottawa ON K1Y 4E4",
        "Canada",
        "\u200E(555)555-5555",
      ]

      result = Worldwide.address(**bobs_home).format(excluded_fields: excluded_fields)

      assert_equal expected, result
    end

    test "format_address renders when excluding a field with underscores" do
      nb_legislature = {
        first_name: "Blaine",
        last_name: "Higgs",
        company: "",
        address1: "706 Queen St",
        address2: "",
        zip: "E3B 1C5",
        city: "Fredericton",
        province_code: "NB",
        country_code: "CA",
        phone: "(506)453-2506",
      }

      excluded_fields = [:first_name]

      expected = [
        "Higgs",
        "706 Queen St",
        "Fredericton NB E3B 1C5",
        "Canada",
        "\u200E(506)453-2506",
      ]

      result = Worldwide.address(**nb_legislature).format(excluded_fields: excluded_fields)

      assert_equal expected, result
    end

    test "format_address does not exclude country when excluding country_code" do
      ns_legislature = {
        first_name: "Tim",
        last_name: "Houston",
        company: "",
        address1: "1726 Hollis St",
        address2: "",
        zip: "B3J 2Y3",
        city: "Halifax",
        province_code: "NS",
        country_code: "CA",
        phone: "(902)497-6942",
      }

      excluded_fields = [:country_code]

      expected = [
        "Tim Houston",
        "1726 Hollis St",
        "Halifax NS B3J 2Y3",
        "Canada",
        "\u200E(902)497-6942",
      ]

      result = Worldwide.address(**ns_legislature).format(excluded_fields: excluded_fields)

      assert_equal expected, result
    end

    test "format_address renders with additional field lines" do
      speaker = {
        first_name: "Anthony",
        last_name: "Rota",
        company: "",
        address1: "111 Wellington Street",
        address2: "",
        zip: "K1A 0A4",
        city: "Ottawa",
        province_code: "ON",
        country_code: "CA",
        phone: "(613)992-4793",
      }

      additional_lines = ["Attention:", "Office of the Speaker", "of the House of Commons"]

      expected = [
        "Anthony Rota",
        "111 Wellington Street",
        "Ottawa ON K1A 0A4",
        "Canada",
        "\u200E(613)992-4793",
        "Attention:",
        "Office of the Speaker",
        "of the House of Commons",
      ]

      result = Worldwide.address(**speaker).format(additional_lines: additional_lines)

      assert_equal expected, result
    end

    test "format_address translates the country and province" do
      japan_address = {
        first_name: "賢",
        last_name: "鈴木",
        company: "",
        address1: "大黒２丁目１３−１",
        address2: nil,
        zip: "097-0005",
        city: "稚内市",
        province_code: "JP-01",
        country_code: "JP",
      }

      # NOTE:  Ideally, we would not have spaces in the output below.
      # But our current implementation puts them in, and we've decided we can live with this for now, so the test reflects the current reality.
      expected = [
        "日本 〒097-0005",
        "北海道 稚内市",
        "大黒２丁目１３−１",
        "鈴木 賢様",
      ]

      I18n.with_locale(:ja) do
        address_lines = Worldwide.address(**japan_address).format

        assert_equal expected, address_lines
      end
    end

    test "format_address is using the default format if country_code is invalid" do
      weird_address = {
        first_name: "Chocolate",
        last_name: "Brownie",
        address1: "fake address 1",
        country_code: "missing",
      }

      expected = [
        "Chocolate Brownie",
        "fake address 1",
        "Unknown Region",
      ]

      address_lines = Worldwide.address(**weird_address).format

      assert_equal expected, address_lines
    end

    test "single_line works as expected when given (only) country and city" do
      # locale, country, city, expected_output
      data = [
        [:de, "DE", "Berlin", "Berlin, Deutschland"],
        [:de, "GB", "London", "London, Vereinigtes Königreich"],
        [:en, "GB", "London", "London, United Kingdom"],
        [:en, "JP", "Tokyo", "Tokyo, Japan"],
        [:en, "US", "New York", "New York, United States"],
        [:ja, "GB", "ロンドン", "イギリス：ロンドン"],
        [:ja, "JP", "仙台市", "日本：仙台市"],
        [:"zh-CN", "GB", "伦敦", "英国伦敦"],
        [:"zh-CN", "JP", "東京", "日本東京"],
      ]

      data.each do |locale, country_code, city_name, expected|
        try_formatting_single_line(locale, country_code, city_name, expected)
      end
    end

    test "single_line uses a colon after the first element and no spaces in Japanese locales" do
      data = [
        [:ja, "JP", "京都", "日本：京都"],
        [:"ja-JP", "TW", "台北", "台湾：台北"],
        [:ja, "US", "シカゴ", "アメリカ合衆国：シカゴ"],
      ]

      data.each do |locale, country_code, city_name, expected|
        try_formatting_single_line(locale, country_code, city_name, expected)
      end
    end

    test "single_line uses neither a colon nor spaces in Chinese locales" do
      data = [
        [:zh, "GB", "伦敦", "英国伦敦"],
        [:"zh-CN", "JP", "仙台市", "日本仙台市"],
        [:"zh-CN", "CN", "北京", "中国北京"],
        [:"zh-CN", "TW", "台北", "台湾台北"],
      ]

      data.each do |locale, country_code, city_name, expected|
        try_formatting_single_line(locale, country_code, city_name, expected)
      end
    end

    test "single_line does not raise an error when passed a bogus province_code:" do
      data = [
        [:en, "GB", "Bogus", "Edinburgh", "Edinburgh", "Edinburgh, United Kingdom"],
        [:en, "GB", "Sodor", "London", "London", "London, United Kingdom"],
        [:en, "CA", "Lilliput", "Toronto", "Toronto, Unknown Region", "Toronto, Unknown Region, Canada"],
        [:es, "ES", "falso", "Barcelona", "Barcelona, Región desconocida", "Barcelona, Región desconocida, España"],
        [:it, "CH", "fasullo", "Lugano", "Lugano", "Lugano, Svizzera"],
        [:ja, "JP", "何これ", "市川市", "不明な地域市川市", "日本：不明な地域市川市"],
      ]

      data.each do |locale, country_code, province_code, city_name, expected_brief, expected_full| # rubocop:disable Metrics/ParameterLists
        I18n.with_locale(locale) do
          address = { country_code: country_code, province_code: province_code, city: city_name }

          actual = Worldwide.address(**address).single_line(excluded_fields: [:country])

          assert_equal expected_brief, actual

          actual = Worldwide.address(**address).single_line

          assert_equal expected_full, actual
        end
      end
    end

    test "single_line behaviour for a country that has no cities" do
      locales = [:de, :en, :es, :fr, :it, :ja, :"zh-CN"]

      locales.each do |locale|
        I18n.with_locale(locale) do
          expected = Worldwide.region(code: "SG").full_name
          address = { country_code: "SG", province_code: "NOT_APPLICABLE", city: "ShouldNotBeUsed" }

          actual = Worldwide.address(**address).single_line(excluded_fields: [:country])

          assert_equal expected, actual

          actual = Worldwide.address(**address).single_line

          assert_equal expected, actual
        end
      end
    end

    test "single_line trims leading spaces when address contains empty fields" do
      address = { city: "", province_code: "ON", country_code: "CA" }
      actual = Worldwide.address(**address).single_line
      expected = "ON, Canada"

      assert_equal(expected, actual)
    end

    test "single_line returns the correct formatting for MY addresses" do
      address = { zip: "53300", province_code: "my14", country_code: "MY" }
      actual = Worldwide.address(**address).single_line
      expected = "53300, Kuala Lumpur, Malaysia"

      assert_equal(expected, actual)
    end

    test "single_line handles codes returned by Zone.code as expected" do
      [
        [:en, "Ottawa", "Ontario", "CA", "Ottawa, ON, Canada"],
        [:fr, "Summerside", "Île-du-Prince-Édouard", "CA", "Summerside, PE, Canada"],
        [:ja, "市川市", "千葉県", "JP", "日本：千葉県市川市"],
        # Whether we should follow the Canadian-address convention of "ON" vs "オンタリオ州" is unclear...
        [:ja, "オタワ市", "オンタリオ州", "CA", "カナダ：ONオタワ市"],
        [:ja, "Ichikawa City", "Chiba", "JP", "日本：千葉県Ichikawa City"],
        [:en, "Yokohama", "Kanagawa", "JP", "Yokohama, Kanagawa, Japan"],
      ].each do |locale, city, province_name, country_code, expected|
        I18n.with_locale(locale) do
          address = {
            city: city,
            province_code: Worldwide.region(code: country_code).zone(name: province_name).iso_code,
            country_code: country_code,
          }

          actual = Worldwide.address(**address).single_line

          assert_equal expected, actual
        end
      end
    end

    test "japan formats single_line differently for japanese" do
      I18n.with_locale(:en) do
        address = {
          city: "Yokohama",
          address1: "Hodogaya Bukkocho",
          province_code: "JP-14",
          zip: "240-0044",
          country_code: "JP",
        }

        expected = "Hodogaya Bukkocho, Yokohama, Kanagawa, Japan, 〒240-0044"
        actual = Worldwide.address(**address).single_line

        assert_equal expected, actual
      end

      I18n.with_locale(:ja) do
        address = {
          city: "横浜市",
          address1: "保土ケ谷区仏向町",
          province_code: "JP-14",
          zip: "240-0044",
          country_code: "JP",
        }

        expected = "日本：〒240-0044神奈川県横浜市保土ケ谷区仏向町"
        actual = Worldwide.address(**address).single_line

        assert_equal expected, actual
      end
    end

    test "single_line 'BR' address1 provided but not address2" do
      address = {
        address1: "R. Dr. Macário Cerqueira, 214",
        address2: "",
        city: "Feira de Santana",
        province_code: "BA",
        zip: "44005-000",
        country_code: "BR",
      }
      expected = "R. Dr. Macário Cerqueira, 214, 44005-000 Feira de Santana - Bahia, Brazil"
      actual = Worldwide.address(**address).single_line

      assert_equal expected, actual
    end

    test "single_line 'BR' address2 provided but not address1" do
      address = {
        address1: "",
        address2: "Muchila",
        city: "Feira de Santana",
        province_code: "BA",
        zip: "44005-000",
        country_code: "BR",
      }
      expected = "Muchila, 44005-000 Feira de Santana - Bahia, Brazil"
      actual = Worldwide.address(**address).single_line

      assert_equal expected, actual
    end

    test "single_line 'BR' address1 & address2 not provided" do
      address = {
        address1: "",
        address2: "",
        city: "Feira de Santana",
        province_code: "BA",
        zip: "44005-000",
        country_code: "BR",
      }
      expected = "44005-000 Feira de Santana - Bahia, Brazil"
      actual = Worldwide.address(**address).single_line

      assert_equal expected, actual
    end

    test "single_line 'BR' city provided but not province_code" do
      address = {
        address1: "R. Macário Cerqueira, 214",
        address2: "Muchila",
        city: "Feira de Santana",
        province_code: "",
        zip: "44005-000",
        country_code: "BR",
      }
      expected = "R. Macário Cerqueira, 214 - Muchila, 44005-000 Feira de Santana, Brazil"
      actual = Worldwide.address(**address).single_line

      assert_equal expected, actual
    end

    test "single_line 'BR' province_code provided but not city" do
      address = {
        address1: "address1",
        address2: "address2",
        city: "",
        province_code: "BA",
        zip: "44009796",
        country_code: "BR",
      }
      expected = "address1 - address2, 44009796 - Bahia, Brazil"
      actual = Worldwide.address(**address).single_line

      assert_equal expected, actual
    end

    test "single_line 'BR' province_code & city not provided" do
      address = {
        address1: "address1",
        address2: "address2",
        city: "",
        province_code: "",
        zip: "44009796",
        country_code: "BR",
      }
      expected = "address1 - address2, 44009796, Brazil"
      actual = Worldwide.address(**address).single_line

      assert_equal expected, actual
    end

    test "single_line 'BR' address1 & address2 & city & province_code provided" do
      address = {
        address1: "address1",
        address2: "address2",
        city: "Feira de Santana",
        province_code: "BA",
        zip: "44009796",
        country_code: "BR",
      }
      expected = "address1 - address2, 44009796 Feira de Santana - Bahia, Brazil"
      actual = Worldwide.address(**address).single_line

      assert_equal expected, actual
    end

    test "single_line 'BR' address1 & address2 & city & province provided" do
      address = {
        address1: "address1",
        address2: "address2",
        city: "Feira de Santana",
        province_code: "BA",
        zip: "44009796",
        country_code: "BR",
      }
      expected = "address1 - address2, 44009796 Feira de Santana - Bahia, Brazil"
      actual = Worldwide.address(**address).single_line

      assert_equal expected, actual
    end

    test "single_line 'BR' :address1 & :address2 & :city & :province provided as symbol instead of string" do
      address = {
        address1: "address1",
        address2: "address2",
        city: "Feira de Santana",
        province_code: "BA",
        zip: "44009796",
        country_code: "BR",
      }
      expected = "address1 - address2, 44009796 Feira de Santana - Bahia, Brazil"
      actual = Worldwide.address(**address).single_line

      assert_equal expected, actual
    end

    test "single_line 'BR' city & province provided but province is excluded." do
      address = {
        address1: "address1",
        address2: "address2",
        city: "Feira de Santana",
        province_code: "BA",
        zip: "44009796",
        country_code: "BR",
      }

      expected = "address1 - address2, 44009796 Feira de Santana, Brazil"
      actual = Worldwide.address(**address).single_line(excluded_fields: [:province])

      assert_equal expected, actual
    end

    test "single_line 'BR' city & province_code provided but city is excluded." do
      address = {
        address1: "address1",
        address2: "address2",
        city: "Feira de Santana",
        province_code: "BA",
        zip: "44009796",
        country_code: "BR",
      }

      expected = "address1 - address2, 44009796 - Bahia, Brazil"
      actual = Worldwide.address(**address).single_line(excluded_fields: [:city])

      assert_equal expected, actual
    end

    test "single_line 'BR' address1 & address2 provided but address1 is excluded." do
      address = {
        address1: "address1",
        address2: "address2",
        city: "Feira de Santana",
        province_code: "BA",
        zip: "44009796",
        country_code: "BR",
      }

      expected = "address2, 44009796 Feira de Santana - Bahia, Brazil"
      actual = Worldwide.address(**address).single_line(excluded_fields: [:address1])

      assert_equal expected, actual
    end

    test "single_line 'BR' provide 'city' and 'province_code', and 'province_code' is excluded" do
      address = {
        address1: "address1",
        address2: "address2",
        city: "Feira de Santana",
        province_code: "BA",
        zip: "44009796",
        country_code: "BR",
      }

      expected = "address1 - address2, 44009796 Feira de Santana - Bahia, Brazil"
      actual = Worldwide.address(**address).single_line(excluded_fields: [:province_code])

      assert_equal expected, actual
    end

    test "single_line 'th'" do
      address = {
        address1: "2194 ถ. เจริญกรุง แขวง", # Charoen Krung Rd
        address2: "วัดพระยาไกร", # Wat Phraya Krai
        city: "เขตบางคอแหลม", # Bang Kho Laem
        province_code: "TH-10", # Bangkok
        zip: "10120",
        country_code: "TH",
      }

      expected = "2194 ถ. เจริญกรุง แขวง วัดพระยาไกร เขตบางคอแหลม กรุงเทพมหานคร 10120"
      I18n.with_locale(:th) do
        actual = Worldwide.address(**address).single_line(excluded_fields: [:country])

        assert_equal expected, actual
      end
    end

    test "single_line picks up hand-translated province name" do
      address = {
        address1: "马里兰法院",
        province_code: "KL",
        country_code: "HK",
        zip: "999077", # this code is assigned by China Post for all of HK; it's not recognized by HK Post
      }

      expected = "中国香港特别行政区九龙马里兰法院"
      I18n.with_locale(:"zh-CN") do
        actual = Worldwide.address(**address).single_line

        assert_equal expected, actual
      end
    end

    private

    def try_formatting_single_line(locale, country_code, city_name, expected)
      address = { country_code: country_code, city: city_name }

      # Try it once with the locale set via I18n.locale
      I18n.with_locale(locale) do
        actual = Worldwide.address(**address).single_line

        assert_equal(expected, actual)
      end
    end
  end
end
