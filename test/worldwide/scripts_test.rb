# frozen_string_literal: true

require "test_helper"

module Worldwide
  class ScriptsTest < ActiveSupport::TestCase
    test "identify returns expected script values for several text inputs" do
      {
        "The quick brown fox jumps": [:Latn],
        "日本": [:Han],
        "にほん": [:Hiragana],
        "ニホン": [:Katakana],
        "素早い茶色のキツネが怠け者の犬を飛び越えます。": [:Han, :Hiragana, :Katakana],
        "車": [:Han],
        "车": [:Han],
      }.each do |text, expected|
        actual = Worldwide::Scripts.identify(text: text)

        assert_equal expected.to_set, actual.to_set
      end
    end
  end
end
