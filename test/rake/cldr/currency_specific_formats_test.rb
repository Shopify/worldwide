# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require_relative "../../../rake/cldr/currency_specific_formats"

class CurrencySpecificFormatsTest < Minitest::Test
  RESOLVED = {
    ["en-150", "numbers.latn.symbols.decimal"] => ".",
    ["en-150", "numbers.latn.symbols.group"] => ",",
    ["en-150", "numbers.latn.formats.currency.patterns.default.standard"] => "#,##0.00\u00A0¤",
    ["pt-CV", "numbers.latn.symbols.decimal"] => ",",
    ["pt-CV", "numbers.latn.symbols.group"] => "\u00A0",
    ["pt-CV", "numbers.latn.formats.currency.patterns.default.standard"] => "#,##0.00\u00A0¤",
  }.freeze

  def test_import_writes_each_currency_format_with_the_defining_locale_values_it_leaves_out
    Dir.mktmpdir do |directory|
      main_dir = File.join(directory, "main")
      locales_dir = File.join(directory, "locales")
      write_locale_xml(main_dir, "en_150", <<~XML)
        <currency type="EUR">
          <displayName>euro</displayName>
          <pattern>¤#,##0.00</pattern>
        </currency>
        <currency type="USD">
          <symbol>US$</symbol>
        </currency>
      XML
      write_locale_xml(main_dir, "pt_CV", "<currency type=\"CVE\"><decimal>$</decimal><symbol>\u200B</symbol></currency>")
      write_locale_xml(main_dir, "kab", "<currency type=\"DZD\"><pattern draft=\"unconfirmed\">¤#,##0.00</pattern></currency>")
      write_numbers_yml(locales_dir, "en-150", { "en-150" => { "numbers" => { "latn" => { "symbols" => { "group" => "," } } } } })
      ["pt-CV", "kab"].each { |locale| FileUtils.mkdir_p(File.join(locales_dir, locale)) }

      values = Worldwide::Cldr::CurrencySpecificFormats.import(
        main_dir: main_dir,
        locales_dir: locales_dir,
        minimum_draft_status: Cldr::DraftStatus::CONTRIBUTED,
        resolve: ->(locale, key) { RESOLVED.fetch([locale, key]) },
      )

      en_150_eur = { "decimal" => ".", "group" => ",", "pattern" => "¤#,##0.00" }
      pt_cv_cve = { "decimal" => "$", "group" => "\u00A0", "pattern" => "#,##0.00\u00A0¤" }

      assert_equal({ "en-150" => { "EUR" => en_150_eur }, "pt-CV" => { "CVE" => pt_cv_cve } }, values)
      assert_equal(
        { "en-150" => { "numbers" => { "latn" => { "symbols" => { "group" => "," } }, "currencies" => { "EUR" => en_150_eur } } } },
        read_numbers_yml(locales_dir, "en-150"),
      )
      assert_equal({ "pt-CV" => { "numbers" => { "currencies" => { "CVE" => pt_cv_cve } } } }, read_numbers_yml(locales_dir, "pt-CV"))
      refute_path_exists(File.join(locales_dir, "kab", "numbers.yml"))
    end
  end

  def test_import_ignores_alternate_values
    Dir.mktmpdir do |directory|
      main_dir = File.join(directory, "main")
      locales_dir = File.join(directory, "locales")
      write_locale_xml(main_dir, "en_150", <<~XML)
        <currency type="EUR">
          <pattern>¤#,##0.00</pattern>
          <pattern alt="alphaNextToNumber">¤\u00A0#,##0.00</pattern>
        </currency>
      XML
      FileUtils.mkdir_p(File.join(locales_dir, "en-150"))

      values = Worldwide::Cldr::CurrencySpecificFormats.import(
        main_dir: main_dir,
        locales_dir: locales_dir,
        minimum_draft_status: Cldr::DraftStatus::CONTRIBUTED,
        resolve: ->(locale, key) { RESOLVED.fetch([locale, key]) },
      )

      assert_equal({ "en-150" => { "EUR" => { "decimal" => ".", "group" => ",", "pattern" => "¤#,##0.00" } } }, values)
    end
  end

  def test_import_raises_for_a_locale_without_exported_data
    Dir.mktmpdir do |directory|
      main_dir = File.join(directory, "main")
      locales_dir = File.join(directory, "locales")
      write_locale_xml(main_dir, "en_150", "<currency type=\"EUR\"><pattern>¤#,##0.00</pattern></currency>")
      FileUtils.mkdir_p(locales_dir)

      error = assert_raises(RuntimeError) do
        Worldwide::Cldr::CurrencySpecificFormats.import(
          main_dir: main_dir,
          locales_dir: locales_dir,
          minimum_draft_status: Cldr::DraftStatus::CONTRIBUTED,
          resolve: ->(locale, key) { RESOLVED.fetch([locale, key]) },
        )
      end
      assert_match(/en-150/, error.message)
    end
  end

  def test_import_raises_without_locale_xml_files
    Dir.mktmpdir do |directory|
      assert_raises(RuntimeError) do
        Worldwide::Cldr::CurrencySpecificFormats.import(
          main_dir: File.join(directory, "main"),
          locales_dir: File.join(directory, "locales"),
          minimum_draft_status: Cldr::DraftStatus::CONTRIBUTED,
          resolve: ->(_locale, _key) { nil },
        )
      end
    end
  end

  private

  def write_locale_xml(main_dir, locale, currencies_content)
    FileUtils.mkdir_p(main_dir)
    language, territory = locale.split("_")
    File.write(File.join(main_dir, "#{locale}.xml"), <<~XML)
      <?xml version="1.0" encoding="UTF-8" ?>
      <ldml>
        <identity>
          <language type="#{language}"/>
          #{"<territory type=\"#{territory}\"/>" if territory}
        </identity>
        <numbers>
          <currencies>
            #{currencies_content}
          </currencies>
        </numbers>
      </ldml>
    XML
  end

  def write_numbers_yml(locales_dir, locale, data)
    FileUtils.mkdir_p(File.join(locales_dir, locale))
    File.write(File.join(locales_dir, locale, "numbers.yml"), data.to_yaml)
  end

  def read_numbers_yml(locales_dir, locale)
    YAML.safe_load_file(File.join(locales_dir, locale, "numbers.yml"), permitted_classes: [Symbol])
  end
end
