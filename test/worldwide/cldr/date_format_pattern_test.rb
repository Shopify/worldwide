# frozen_string_literal: true

require "test_helper"

module Worldwide
  module Cldr
    class DateFormatPatternTest < ActiveSupport::TestCase
      test "#format works with era fields" do
        bce_date = Date.new(-2018, 1, 1)
        ce_date = Date.new(2018, 1, 1)

        assert_equal "ก่อน ส.ศ. 2018", Worldwide::Cldr::DateFormatPattern.format(bce_date, "G y", locale: "th")
        assert_equal "ก่อน ส.ศ. 2018", Worldwide::Cldr::DateFormatPattern.format(bce_date, "GG y", locale: "th")
        assert_equal "ก่อน ส.ศ. 2018", Worldwide::Cldr::DateFormatPattern.format(bce_date, "GGG y", locale: "th")

        assert_equal "ส.ศ. 2018", Worldwide::Cldr::DateFormatPattern.format(ce_date, "G y", locale: "th")
        assert_equal "ส.ศ. 2018", Worldwide::Cldr::DateFormatPattern.format(ce_date, "GG y", locale: "th")
        assert_equal "ส.ศ. 2018", Worldwide::Cldr::DateFormatPattern.format(ce_date, "GGG y", locale: "th")

        assert_equal "2018 BCE", Worldwide::Cldr::DateFormatPattern.format(bce_date, "y G", locale: :en)
        assert_equal "2018 Before Common Era", Worldwide::Cldr::DateFormatPattern.format(bce_date, "y GGGG", locale: :en)
        assert_equal "2018 B", Worldwide::Cldr::DateFormatPattern.format(bce_date, "y GGGGG", locale: :en)

        assert_equal "2018 CE", Worldwide::Cldr::DateFormatPattern.format(ce_date, "y G", locale: :en)
        assert_equal "2018 Common Era", Worldwide::Cldr::DateFormatPattern.format(ce_date, "y GGGG", locale: :en)
        assert_equal "2018 A", Worldwide::Cldr::DateFormatPattern.format(ce_date, "y GGGGG", locale: :en)
      end

      test "#format works on Gregorian era boundaries" do
        bce_date = Date.new(0, 12, 31)
        ce_date = Date.new(1, 1, 1)

        assert_equal "0 BCE", Worldwide::Cldr::DateFormatPattern.format(bce_date, "y G", locale: :en)
        assert_equal "1 CE", Worldwide::Cldr::DateFormatPattern.format(ce_date, "y G", locale: :en)
      end

      test "#format works with quarter fields" do
        date = Date.new(2018, 1, 1)

        assert_equal "2018年第1季度", Worldwide::Cldr::DateFormatPattern.format(date, "y年第Q季度", locale: "zh-Hans-CN")
        assert_equal "01 2018", Worldwide::Cldr::DateFormatPattern.format(date, "QQ y", locale: :en)
        assert_equal "Q1 2018", Worldwide::Cldr::DateFormatPattern.format(date, "QQQ y", locale: :en)
        assert_equal "1st quarter 2018", Worldwide::Cldr::DateFormatPattern.format(date, "QQQQ y", locale: :en)
        assert_equal "1", Worldwide::Cldr::DateFormatPattern.format(date, "QQQQQ", locale: :en)

        assert_equal "1", Worldwide::Cldr::DateFormatPattern.format(date, "q", locale: "zh-Hans-CN")
        assert_equal "01", Worldwide::Cldr::DateFormatPattern.format(date, "qq", locale: :en)
        assert_equal "Q1", Worldwide::Cldr::DateFormatPattern.format(date, "qqq", locale: :en)
        assert_equal "1st quarter", Worldwide::Cldr::DateFormatPattern.format(date, "qqqq", locale: :en)
        assert_equal "1", Worldwide::Cldr::DateFormatPattern.format(date, "qqqqq", locale: :en)
      end

      test "#format works with year fields" do
        date = Date.new(2018, 1, 1)

        assert_equal "2018年", Worldwide::Cldr::DateFormatPattern.format(date, "y年", locale: "zh-Hans-CN")
        assert_equal "18", Worldwide::Cldr::DateFormatPattern.format(date, "yy", locale: :en)
        assert_equal "2018", Worldwide::Cldr::DateFormatPattern.format(date, "yyy", locale: :en)
        assert_equal "2018", Worldwide::Cldr::DateFormatPattern.format(date, "yyyy", locale: :en)
        assert_equal "0000002018", Worldwide::Cldr::DateFormatPattern.format(date, "yyyyyyyyyy", locale: :en)
      end

      test "#format works with single-quoted strings" do
        date = Date.new(2018, 1, 1)

        assert_equal "2018 y oh y?! 2018", Worldwide::Cldr::DateFormatPattern.format(date, "y 'y oh y?!' y", locale: :en)
        assert_equal "'' 2018 ''", Worldwide::Cldr::DateFormatPattern.format(date, "''''' 'y' '''''", locale: :en)
        assert_equal "2018 Single quote ' within quotes 2018", Worldwide::Cldr::DateFormatPattern.format(date, "y 'Single quote '' within quotes' y", locale: :en)
      end

      test "#format raises on invalid formats" do
        date = Date.new(2018, 1, 1)
        exc = assert_raises(Worldwide::Cldr::DateFormatPattern::InvalidPattern) do
          Worldwide::Cldr::DateFormatPattern.format(date, "y 'Unterminated string literal", locale: :en)
        end

        assert_equal "Invalid token at index 2: \"'Unt\"", exc.message
      end

      test "#format raises NotImplementedError when using unimplemented fields" do
        date = Date.new(2018, 1, 1)
        exc = assert_raises(NotImplementedError) do
          Worldwide::Cldr::DateFormatPattern.format(date, "Y", locale: :en)
        end

        assert_equal "Unimplemented field: Y", exc.message
      end

      test "#tokenize handles single-quoted strings" do
        # Two single quotes, followed by a quoted literal space
        tokens = Worldwide::Cldr::DateFormatPattern.tokenize("''''' '")
        expected = [
          Worldwide::Cldr::DateFormatPattern::Literal.new("'"),
          Worldwide::Cldr::DateFormatPattern::Literal.new("'"),
          Worldwide::Cldr::DateFormatPattern::Literal.new(" "),
        ]

        assert_equal expected, tokens

        # A quoted literal space, followed by two single quotes
        tokens = Worldwide::Cldr::DateFormatPattern.tokenize("' '''''")
        expected = [
          Worldwide::Cldr::DateFormatPattern::Literal.new(" "),
          Worldwide::Cldr::DateFormatPattern::Literal.new("'"),
          Worldwide::Cldr::DateFormatPattern::Literal.new("'"),
        ]

        assert_equal expected, tokens
      end
    end
  end
end
