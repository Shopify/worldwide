# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require_relative "../../../rake/cldr/sort_yaml"

class SortYamlTest < Minitest::Test
  def test_sort_file_writes_sorted_yaml_and_reports_change
    Dir.mktmpdir do |directory|
      filename = File.join(directory, "input.yml")
      File.write(filename, { "z" => 1, "a" => 2 }.to_yaml)

      assert_equal(true, SortYaml.sort_file?(filename, output_filename: filename))
      assert_equal({ "a" => 2, "z" => 1 }, YAML.load_file(filename))
    end
  end

  def test_sort_file_reports_no_change_for_sorted_yaml
    Dir.mktmpdir do |directory|
      filename = File.join(directory, "input.yml")
      File.write(filename, { "a" => 2, "z" => 1 }.to_yaml)

      assert_equal(false, SortYaml.sort_file?(filename, output_filename: filename))
    end
  end
end
