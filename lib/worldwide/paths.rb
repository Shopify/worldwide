# frozen_string_literal: true

module Worldwide
  module Paths
    GEM_ROOT = File.expand_path(File.join(__dir__, "../.."))
    DATA_ROOT = File.join(GEM_ROOT, "data")
    CLDR_ROOT = File.join(GEM_ROOT, "data/cldr")
    OTHER_DATA_ROOT = File.join(GEM_ROOT, "data/other")
    GENERATED_LOCALE_ROOT = File.join(OTHER_DATA_ROOT, "generated")
    DB_DATA_ROOT = File.join(GEM_ROOT, "db/data")
    REGIONS_ROOT = File.join(DB_DATA_ROOT, "regions")
  end
end
