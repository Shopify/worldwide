# frozen_string_literal: true

require "test_helper"

module Worldwide
  module Cldr
    class ContextTransformsTest < ActiveSupport::TestCase
      test "'titlecase-firstword' transform works" do
        transform = Worldwide::Cldr::ContextTransforms::TRANSFORMS.fetch(:titlecase_first_word)

        assert_equal "Hello world", transform.call("hello world")
        assert_equal "Мария", transform.call("мария")
        assert_equal "POTATO", transform.call("POTATO")
      end

      test "'no-change' transform does nothing" do
        transform = Worldwide::Cldr::ContextTransforms::TRANSFORMS.fetch(:no_change)

        assert_equal "English", transform.call("English")
        assert_equal "english", transform.call("english")
        assert_equal "мария", transform.call("мария")
        assert_equal "POTATO", transform.call("POTATO")
      end

      test "#for returns the correct transform" do
        no_change_transform = Worldwide::Cldr::ContextTransforms::TRANSFORMS.fetch(:no_change)
        titlecase_transform = Worldwide::Cldr::ContextTransforms::TRANSFORMS.fetch(:titlecase_first_word)

        assert_equal no_change_transform, Worldwide::Cldr::ContextTransforms.for(:languages, :middle_of_sentence)
        assert_equal titlecase_transform, Worldwide::Cldr::ContextTransforms.for(:languages, :start_of_sentence)
        assert_equal titlecase_transform, Worldwide::Cldr::ContextTransforms.for(:languages, :ui_list_or_menu, locale: :"cs-CZ")
        assert_equal no_change_transform, Worldwide::Cldr::ContextTransforms.for(:languages, :completely_made_up_context)
      end
    end
  end
end
