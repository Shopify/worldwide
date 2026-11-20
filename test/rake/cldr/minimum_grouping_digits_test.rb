# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require_relative "../../../rake/cldr/minimum_grouping_digits"

class MinimumGroupingDigitsTest < Minitest::Test
  def test_import_writes_the_values_that_meet_the_draft_status_threshold
    Dir.mktmpdir do |directory|
      main_dir = File.join(directory, "main")
      locales_dir = File.join(directory, "locales")
      write_locale_xml(main_dir, "pl", "<minimumGroupingDigits>2</minimumGroupingDigits>")
      write_locale_xml(main_dir, "pt_PT", "<minimumGroupingDigits>2</minimumGroupingDigits>")
      write_locale_xml(main_dir, "ee", "<minimumGroupingDigits draft=\"contributed\">3</minimumGroupingDigits>")
      write_locale_xml(main_dir, "kab", "<minimumGroupingDigits draft=\"unconfirmed\">1</minimumGroupingDigits>")
      write_locale_xml(main_dir, "fr", "<defaultNumberingSystem>latn</defaultNumberingSystem>")
      write_numbers_yml(locales_dir, "pl", { "pl" => { "numbers" => { "latn" => { "symbols" => { "group" => " " } } } } })
      write_numbers_yml(locales_dir, "kab", { "kab" => { "numbers" => { "latn" => { "symbols" => { "group" => " " } } } } })
      ["pt-PT", "ee", "fr"].each { |locale| FileUtils.mkdir_p(File.join(locales_dir, locale)) }

      values = Worldwide::Cldr::MinimumGroupingDigits.import(
        main_dir: main_dir,
        locales_dir: locales_dir,
        minimum_draft_status: Cldr::DraftStatus::CONTRIBUTED,
      )

      assert_equal({ "ee" => 3, "pl" => 2, "pt-PT" => 2 }, values)
      assert_equal(
        { "pl" => { "numbers" => { "latn" => { "symbols" => { "group" => " " } }, "minimum_grouping_digits" => 2 } } },
        read_numbers_yml(locales_dir, "pl"),
      )
      assert_equal({ "pt-PT" => { "numbers" => { "minimum_grouping_digits" => 2 } } }, read_numbers_yml(locales_dir, "pt-PT"))
      assert_equal({ "ee" => { "numbers" => { "minimum_grouping_digits" => 3 } } }, read_numbers_yml(locales_dir, "ee"))
      assert_equal({ "kab" => { "numbers" => { "latn" => { "symbols" => { "group" => " " } } } } }, read_numbers_yml(locales_dir, "kab"))
      refute_path_exists(File.join(locales_dir, "fr", "numbers.yml"))
    end
  end

  def test_import_keeps_symbol_values
    Dir.mktmpdir do |directory|
      main_dir = File.join(directory, "main")
      locales_dir = File.join(directory, "locales")
      write_locale_xml(main_dir, "root", "<minimumGroupingDigits>1</minimumGroupingDigits>")
      write_numbers_yml(locales_dir, "root", { "root" => { "numbers" => { "arab" => { "symbols" => :"numbers.latn.symbols" } } } })

      Worldwide::Cldr::MinimumGroupingDigits.import(
        main_dir: main_dir,
        locales_dir: locales_dir,
        minimum_draft_status: Cldr::DraftStatus::CONTRIBUTED,
      )

      assert_equal(
        { "root" => { "numbers" => { "arab" => { "symbols" => :"numbers.latn.symbols" }, "minimum_grouping_digits" => 1 } } },
        read_numbers_yml(locales_dir, "root"),
      )
    end
  end

  def test_import_raises_for_a_locale_without_exported_data
    Dir.mktmpdir do |directory|
      main_dir = File.join(directory, "main")
      locales_dir = File.join(directory, "locales")
      write_locale_xml(main_dir, "pl", "<minimumGroupingDigits>2</minimumGroupingDigits>")
      FileUtils.mkdir_p(locales_dir)

      error = assert_raises(RuntimeError) do
        Worldwide::Cldr::MinimumGroupingDigits.import(
          main_dir: main_dir,
          locales_dir: locales_dir,
          minimum_draft_status: Cldr::DraftStatus::CONTRIBUTED,
        )
      end
      assert_match(/pl/, error.message)
    end
  end

  def test_import_raises_without_locale_xml_files
    Dir.mktmpdir do |directory|
      assert_raises(RuntimeError) do
        Worldwide::Cldr::MinimumGroupingDigits.import(
          main_dir: File.join(directory, "main"),
          locales_dir: File.join(directory, "locales"),
          minimum_draft_status: Cldr::DraftStatus::CONTRIBUTED,
        )
      end
    end
  end

  private

  def write_locale_xml(main_dir, locale, numbers_content)
    FileUtils.mkdir_p(main_dir)
    language = locale.split("_").first
    File.write(File.join(main_dir, "#{locale}.xml"), <<~XML)
      <?xml version="1.0" encoding="UTF-8" ?>
      <ldml>
        <identity>
          <language type="#{language}"/>
        </identity>
        <numbers>
          #{numbers_content}
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
