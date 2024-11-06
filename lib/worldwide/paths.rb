# frozen_string_literal: true

module Worldwide
  module Paths
    GEM_ROOT = File.expand_path(File.join(__dir__, "../.."))
    DATA_ROOT = File.join(GEM_ROOT, "data")
    CLDR_ROOT = File.join(GEM_ROOT, "data/cldr")
    OTHER_DATA_ROOT = File.join(GEM_ROOT, "data/other")
    GENERATED_LOCALE_ROOT = File.join(OTHER_DATA_ROOT, "generated")
    REGIONS_ROOT = File.join(DATA_ROOT, "regions")
    TIME_ZONE_ROOT = File.join(OTHER_DATA_ROOT, "timezones")
  end
end
