# frozen_string_literal: false

require "fileutils"

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
        end
      end
    end
  end
end
