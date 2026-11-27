# frozen_string_literal: true

require "test_helper"

module Worldwide
  class UtilTest < ActiveSupport::TestCase
    test ".utf8_handle lowercases and replaces runs of punctuation and spaces with a hyphen" do
      assert_equal "al-fayyum", Util.utf8_handle("Al Fayyūm")
      assert_equal "new-south-wales", Util.utf8_handle("New South Wales")
      assert_equal "a-b", Util.utf8_handle("A  /  B")
      assert_equal "a_b", Util.utf8_handle("a_b")
      assert_equal "a-b", Util.utf8_handle("--a--b--")
    end

    test ".utf8_handle drops quotes and brackets" do
      assert_equal "obrien-test", Util.utf8_handle("O'Brien (Test)")
      assert_equal "ab", Util.utf8_handle("\"a\"[b]")
    end

    test ".utf8_handle replaces Latin letters that have diacritics with the base letter" do
      assert_equal "quebec", Util.utf8_handle("Québec")
      assert_equal "sao-paulo", Util.utf8_handle("São Paulo")
      assert_equal "nandu", Util.utf8_handle("ñandú")
      assert_equal "zurich", Util.utf8_handle("Zürich")
    end

    test ".utf8_handle keeps letters with diacritics that are outside of Latin-1 and Latin Extended-A" do
      assert_equal "ḥasakah", Util.utf8_handle("Ḥasakah")
    end

    test ".utf8_handle approximates Latin letters that have no base letter" do
      assert_equal "aeroskobing", Util.utf8_handle("Ærøskøbing")
      assert_equal "strasse", Util.utf8_handle("Straße")
      assert_equal "lodz", Util.utf8_handle("Łódź")
      assert_equal "dong-nai", Util.utf8_handle("Đông Nai")
      assert_equal "thor", Util.utf8_handle("Þór")
      assert_equal "oe", Util.utf8_handle("œ")
      assert_equal "n", Util.utf8_handle("ŉ")
    end

    test ".utf8_handle gives the same result for composed and decomposed letters" do
      assert_equal Util.utf8_handle("Québec"), Util.utf8_handle("Que\u0301bec")
    end

    test ".utf8_handle keeps letters of other scripts and emoji" do
      assert_equal "日本", Util.utf8_handle("日本")
      assert_equal "москва", Util.utf8_handle("Москва")
      assert_equal "йошкар-ола", Util.utf8_handle("Йошкар-Ола")
      assert_equal "ελλάδα", Util.utf8_handle("Ελλάδα")
      assert_equal "aeroskobing-日本-👴🏾", Util.utf8_handle("Ærøskøbing 日本 👴🏾")
    end

    test ".utf8_handle returns an empty string for a string without letters" do
      assert_equal "", Util.utf8_handle("")
      assert_equal "", Util.utf8_handle(" - ")
    end

    test ".utf8_handle returns a frozen string and does not change its argument" do
      input = +"Al Fayyūm"
      result = Util.utf8_handle(input)

      assert_predicate result, :frozen?
      assert_equal "Al Fayyūm", input
      assert_equal Encoding::UTF_8, input.encoding
    end

    test ".utf8_handle repairs a string with invalid bytes" do
      assert_equal "ebc", Util.utf8_handle((+"\xE9bc").force_encoding(Encoding::BINARY))
      assert_equal "cafe", Util.utf8_handle((+"caf\xC3\xA9").force_encoding(Encoding::BINARY))
    end

    test ".ascii_casecmp_substring? with basic functionality" do
      assert_equal(true, Util.ascii_casecmp_substring?("example", "example", start1: 0, length1: 7, start2: 0, length2: 7))
      assert_equal(true, Util.ascii_casecmp_substring?("AbCdEf", "abcdef", start1: 0, length1: 6, start2: 0, length2: 6))
      assert_equal(false, Util.ascii_casecmp_substring?("hello", "world", start1: 0, length1: 7, start2: 0, length2: 5))

      assert_equal(true, Util.ascii_casecmp_substring?("start", "finishstart", start1: 0, length1: 5, start2: 6, length2: 5))
      assert_equal(true, Util.ascii_casecmp_substring?("full", "full", start1: 0, length1: 4, start2: 0, length2: 4))
      assert_equal(true, Util.ascii_casecmp_substring?("a", "a", start1: 0, length1: 1, start2: 0, length2: 1))

      assert_equal(false, Util.ascii_casecmp_substring?("", "", start1: 0, length1: 1, start2: 0, length2: 1))
    end

    test ".ascii_casecmp_substring? with a difference in the case of ASCII letters only" do
      assert_equal(true, Util.ascii_casecmp_substring?("[@`{", "[@`{", start1: 0, length1: 4, start2: 0, length2: 4))
      assert_equal(false, Util.ascii_casecmp_substring?("@", "`", start1: 0, length1: 1, start2: 0, length2: 1))
      assert_equal(false, Util.ascii_casecmp_substring?("[", "{", start1: 0, length1: 1, start2: 0, length2: 1))
      assert_equal(true, Util.ascii_casecmp_substring?("Z", "z", start1: 0, length1: 1, start2: 0, length2: 1))
    end

    test ".ascii_casecmp_substring? with length exceeding string size" do
      assert_equal(false, Util.ascii_casecmp_substring?("short", "longer", start1: 0, length1: 10, start2: 0, length2: 10))
    end

    test ".ascii_casecmp_substring? with non-ASCII characters" do
      assert_equal(false, Util.ascii_casecmp_substring?("ñandú", "nandu", start1: 0, length1: 5, start2: 0, length2: 5))
    end

    test ".ascii_casecmp_substring? counts bytes, not characters" do
      assert_equal(true, Util.ascii_casecmp_substring?("ñ-ON", "ñ-on", start1: 3, length1: 2, start2: 3, length2: 2))
      assert_equal(false, Util.ascii_casecmp_substring?("ñ-ON", "ñ-on", start1: 3, length1: 3, start2: 3, length2: 3))
    end

    test ".ascii_casecmp_substring? with boundary ASCII characters" do
      assert_equal(true, Util.ascii_casecmp_substring?("\x00\x7F", "\x00\x7F", start1: 0, length1: 2, start2: 0, length2: 2))
    end

    test ".ascii_casecmp_substring? throws for nil comparison" do
      assert_raises(ArgumentError) do
        Util.ascii_casecmp_substring?(nil, "test", start1: 1, length1: 1, start2: 1, length2: 1)
      end
      assert_raises(ArgumentError) do
        Util.ascii_casecmp_substring?("test", nil, start1: 1, length1: 1, start2: 1, length2: 2)
      end
    end

    test ".ascii_casecmp_substring? throws for zero length" do
      assert_raises(ArgumentError) do
        Util.ascii_casecmp_substring?("test", "test", start1: 1, length1: 1, start2: 1, length2: 0)
      end
      assert_raises(ArgumentError) do
        Util.ascii_casecmp_substring?("test", "test", start1: 1, length1: 0, start2: 1, length2: 1)
      end
    end

    test ".ascii_casecmp_substring? throws for negative start1 or start2" do
      assert_raises(ArgumentError) do
        Util.ascii_casecmp_substring?("test", "test", start1: -1, length1: 1, start2: 1, length2: 1)
      end
      assert_raises(ArgumentError) do
        Util.ascii_casecmp_substring?("test", "test", start1: 1, length1: 1, start2: -1, length2: 1)
      end
    end

    test ".ascii_casecmp_substring? does not allocate" do
      measure = -> do
        GC.start
        GC.disable
        before = GC.stat(:total_allocated_objects)
        10.times { Util.ascii_casecmp_substring?("start", "finishSTART", start1: 0, length1: 5, start2: 6, length2: 5) }
        GC.stat(:total_allocated_objects) - before
      ensure
        GC.enable
      end
      measure.call

      assert_equal 0, measure.call
    end
  end
end
