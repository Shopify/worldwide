# frozen_string_literal: true

module Worldwide
  module Paths
    GEM_ROOT = File.expand_path(File.join(__dir__, "../.."))
    DATA_ROOT = File.join(GEM_ROOT, "data")
    CLDR_ROOT = File.join(GEM_ROOT, "data/cldr")
    CLDR_LOCALE_PATHS_FILE = File.join(CLDR_ROOT, "paths.txt")

    OTHER_DATA_ROOT = File.join(GEM_ROOT, "data/other")
    OTHER_DATA_PATHS_FILE = File.join(OTHER_DATA_ROOT, "paths.txt")

    CURRENCY_MAPPINGS = File.join(OTHER_DATA_ROOT, "currency/mappings")
    GENERATED_LOCALE_ROOT = File.join(OTHER_DATA_ROOT, "generated")

    REGIONS_ROOT = File.join(DATA_ROOT, "regions")
    REGION_DATA_PATHS_FILE = File.join(REGIONS_ROOT, "paths.txt")

    TIME_ZONE_ROOT = File.join(OTHER_DATA_ROOT, "timezones")
  end
end
