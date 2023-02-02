# frozen_string_literal: true

require "test_helper"

module Worldwide
  class DiscountsTest < ActiveSupport::TestCase
    test "#format discount: true formats as expected" do
      [
        ["en", 1, "100%"],
        ["en-CA", 0.5, "50%"],
        ["en-US", 0.001, "0.1%"],
        ["es", 0.3, "30 %"],
        ["fi", 0.25, "25 %"],
        ["fr", 0.001, "0,1 %"],
        ["he", 0.75, "75%"],
        ["ku", 0.1, "10%"],
        ["ckb", 0.5, "50%"],
        ["tr", 1, "%100"],
        ["ja", 0.2, "2割引"],
        ["ja", 0.25, "25%割引"],
        ["zh-Hans", 0.2, "8折"],
        ["zh-Hans", 0.25, "7.5折"],
        ["zh-Hans", 0.975, "0.25折"],
      ].each do |locale, amount, expected|
        actual = Worldwide.discounts.format(amount, locale: locale)

        assert_equal("[#{locale}]:#{expected}", "[#{locale}]:#{actual}")
      end
    end
  end
end
