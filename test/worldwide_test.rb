# frozen_string_literal: true

require "test_helper"

class WorldwideTest < ActiveSupport::TestCase
  test "it has a version number" do
    refute_nil(::Worldwide::VERSION)
  end

  test ".lists class method returns the Lists singleton" do
    assert_equal Worldwide::Lists, Worldwide.lists
  end

  test ".names class method returns the Names singleton" do
    assert_equal Worldwide::Names, Worldwide.names
  end

  test ".numbers class method returns the Numbers singleton" do
    assert_equal Worldwide::Numbers, Worldwide.numbers
  end

  test ".punctuation class method returns the Punctuation singleton" do
    assert_equal Worldwide::Punctuation, Worldwide.punctuation
  end

  test ".scripts class method returns the Scripts singleton" do
    assert_equal Worldwide::Scripts, Worldwide.scripts
  end
end
