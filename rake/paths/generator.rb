# frozen_string_literal: true

module Worldwide
  module Paths
    class Generator
      def perform
        cldr_locale_paths = Dir[File.join(Worldwide::Paths::CLDR_ROOT, "locales", "*", "*.{yml,rb}")].map do |path|
          path.delete_prefix(Worldwide::Paths::GEM_ROOT)
        end
        File.write(Worldwide::Paths::CLDR_LOCALE_PATHS_FILE, cldr_locale_paths.join("\n"))

        other_data_paths = Dir[File.join(Worldwide::Paths::OTHER_DATA_ROOT, "*", "*.{yml,rb}")].map do |path|
          path.delete_prefix(Worldwide::Paths::GEM_ROOT)
        end
        File.write(Worldwide::Paths::OTHER_DATA_PATHS_FILE, other_data_paths.join("\n"))

        region_data_paths = Dir[File.join(Worldwide::Paths::REGIONS_ROOT, "*", "*.{yml}")].map do |path|
          path.delete_prefix(Worldwide::Paths::GEM_ROOT)
        end
        File.write(Worldwide::Paths::REGION_DATA_PATHS_FILE, region_data_paths.join("\n"))
      end
    end
  end
end
