# frozen_string_literal: true

require "test_helper"

module Worldwide
  class ListsTest < ActiveSupport::TestCase
    test "format list when data is empty" do
      result = Lists.format([])

      assert_equal "", result
    end

    test "format list when data is nil" do
      result = Lists.format(nil)

      assert_equal "", result
    end

    test "format list when data contains one element" do
      result = Lists.format(["hello"])

      assert_equal "hello", result
    end

    test "format list when data contains two element using default join" do
      data = [
        [:en, "hello and world"],
        [:es, "hello y world"],
        [:ja, "hello、world"],
        [:ru, "hello и world"],
      ]

      data.each do |locale, expected|
        I18n.with_locale(locale) do
          result = Lists.format(["hello", "world"])

          assert_equal expected, result
        end
      end
    end

    test "format list with locale override" do
      I18n.with_locale(:en) do
        assert_equal "hello、world", Lists.format(["hello", "world"], locale: :ja)
      end
    end

    test "format list when data contains two element using or join" do
      data = [
        [:en, "hello or world"],
        [:es, "hello o world"],
        [:ja, "helloまたはworld"],
        [:ru, "hello или world"],
      ]

      data.each do |locale, expected|
        I18n.with_locale(locale) do
          result = Lists.format(["hello", "world"], join: :or)

          assert_equal expected, result
        end
      end
    end

    test "format list when data contains no elements using narrow join" do
      data = [
        [:en, ""],
        [:es, ""],
        [:ja, ""],
        [:ru, ""],
      ]

      data.each do |locale, expected|
        I18n.with_locale(locale) do
          result = Lists.format([""], join: :narrow)

          assert_equal expected, result
        end
      end
    end

    test "format list when data contains one element using narrow join" do
      data = [
        [:en, "hello"],
        [:es, "hello"],
        [:ja, "hello"],
        [:ru, "hello"],
      ]

      data.each do |locale, expected|
        I18n.with_locale(locale) do
          result = Lists.format(["hello"], join: :narrow)

          assert_equal expected, result
        end
      end
    end

    test "format list when data contains two element using narrow join" do
      data = [
        [:en, "hello, world"],
        [:es, "hello, world"],
        [:ja, "hello、world"],
        [:ru, "hello, world"],
      ]

      data.each do |locale, expected|
        I18n.with_locale(locale) do
          result = Lists.format(["hello", "world"], join: :narrow)

          assert_equal expected, result, "Unexpected result for locale #{locale}"
        end
      end
    end

    test "format list when data contains three element using narrow join" do
      data = [
        [:en, "hello, world, testing"],
        [:es, "hello, world, testing"],
        [:ja, "hello、world、testing"],
        [:ru, "hello, world, testing"],
      ]

      data.each do |locale, expected|
        I18n.with_locale(locale) do
          result = Lists.format(["hello", "world", "testing"], join: :narrow)

          assert_equal expected, result
        end
      end
    end

    test "format list when join is not supported" do
      err = assert_raises(ArgumentError) do
        Lists.format([], join: :abc)
      end

      assert_equal "Unknown connector abc.", err.message
    end

    test "format list when data contains three element using default join" do
      data = [
        [:en, "hello, world, and ruby"],
        [:es, "hello, world y ruby"],
        [:ja, "hello、world、ruby"],
        [:ru, "hello, world и ruby"],
      ]

      data.each do |locale, expected|
        I18n.with_locale(locale) do
          result = Lists.format(["hello", "world", "ruby"])

          assert_equal expected, result
        end
      end
    end

    test "format list when data contains three element using or join" do
      data = [
        [:en, "hello, world, or ruby"],
        [:es, "hello, world o ruby"],
        [:ja, "hello、world、またはruby"],
        [:ru, "hello, world или ruby"],
      ]

      data.each do |locale, expected|
        I18n.with_locale(locale) do
          result = Lists.format(["hello", "world", "ruby"], join: :or)

          assert_equal expected, result
        end
      end
    end

    test "format list when data contains more than three element using default join" do
      data = [
        [:en, "hello, world, ruby, good, and bye"],
        [:es, "hello, world, ruby, good y bye"],
        [:ja, "hello、world、ruby、good、bye"],
        [:ru, "hello, world, ruby, good и bye"],
      ]

      data.each do |locale, expected|
        I18n.with_locale(locale) do
          result = Lists.format(["hello", "world", "ruby", "good", "bye"])

          assert_equal expected, result
        end
      end
    end

    test "format list when data contains more than three element using or join" do
      data = [
        [:en, "hello, world, ruby, good, or bye"],
        [:es, "hello, world, ruby, good o bye"],
        [:ja, "hello、world、ruby、good、またはbye"],
        [:ru, "hello, world, ruby, good или bye"],
      ]

      data.each do |locale, expected|
        I18n.with_locale(locale) do
          result = Lists.format(["hello", "world", "ruby", "good", "bye"], join: :or)

          assert_equal expected, result
        end
      end
    end
  end
end
