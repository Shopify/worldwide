# frozen_string_literal: true

require "test_helper"

module Worldwide
  class MyTest < ActiveSupport::TestCase
    setup do
      @region = Worldwide.region(code: "MY")
    end

    test "zone resolves the long-form federal territory and state names Google returns" do
      {
        "Johor Darul Ta'zim" => "JHR",
        "Johor Darul Takzim" => "JHR",
        "Wilayah Persekutuan Kuala Lumpur" => "KUL",
        "Federal Territory of Kuala Lumpur" => "KUL",
        "WP Kuala Lumpur" => "KUL",
        "Wilayah Persekutuan Labuan" => "LBN",
        "Labuan Federal Territory" => "LBN",
        "Wilayah Persekutuan Putrajaya" => "PJY",
      }.each do |name, code|
        assert_equal code, @region.zone(name: name).legacy_code, "expected #{name.inspect} to resolve to #{code}"
      end
    end

    test "zone does not resolve the bare Wilayah Persekutuan, which names three territories" do
      assert_equal Worldwide.unknown_region, @region.zone(name: "Wilayah Persekutuan")
    end
  end
end
