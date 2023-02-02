# frozen_string_literal: true

module Worldwide
  module RegionDataTestHelper
    # For compatibality with legacy Shopify systems, we treat territories affiliated with
    # Spain and the United States of America as "provinces".
    ES_AND_US_DUAL_STATUS_PROVINCES = [
      # rubocop:disable Layout/MultilineArrayLineBreaks
      "EA", "IC",
      "AS", "FM", "GU", "MH", "MP", "PR", "PW", "UM", "VI",
      # rubocop:enable Layout/MultilineArrayLineBreaks
    ]
  end
end
