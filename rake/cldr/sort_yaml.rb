# frozen_string_literal: true

require "active_support"
require "yaml"

require_relative "deep_sort"

module SortYaml
  class << self
    def sort(data)
      flattened = FlattenHash.run(data)
      sorted = flattened.sort.to_h
      UnflattenHash.run(sorted)
    end

    def sort_file(filename, output_filename: nil)
      output_filename ||= begin
        extension = File.extname(filename)
        File.join(File.dirname(filename), "#{File.basename(filename, extension)}_sorted#{extension}")
      end

      data = YAML.load_file(filename, permitted_classes: [Date, Symbol])
      sorted_data = data.deep_sort

      new_contents = YAML.dump(sorted_data)
      File.write(output_filename, new_contents)

      original_contents = YAML.dump(data)
      original_contents != new_contents
    end
  end
end
