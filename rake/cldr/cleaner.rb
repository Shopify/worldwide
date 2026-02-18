# frozen_string_literal: true

require "fileutils"
require "worldwide/paths"

module Worldwide
  module Cldr
    class Cleaner
      class << self
        def perform
          puts "🗑️  Cleaning up data files."
          FileUtils.rm_rf(Worldwide::Paths::CLDR_ROOT)
          FileUtils.mkdir_p(Worldwide::Paths::CLDR_ROOT)
          FileUtils.rm_rf(Worldwide::Paths::GENERATED_LOCALE_ROOT)
          FileUtils.mkdir_p(Worldwide::Paths::GENERATED_LOCALE_ROOT)

          Dir[File.join(Worldwide::Paths::DATA_ROOT, "**", "paths.txt")].each do |path|
            FileUtils.rm(path)
          end
        end
      end
    end
  end
end
