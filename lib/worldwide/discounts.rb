# frozen_string_literal: true

module Worldwide
  class Discounts
    ZH_HANS_GROUP = ([:zh] + Worldwide::Locale.new(:zh).sub_locales).freeze
    KU_GROUP = ([:ku, :ckb] + Worldwide::Locale.new(:ku).sub_locales + Worldwide::Locale.new(:ckb).sub_locales).freeze

    class << self
      def format(discount_percent, locale: I18n.locale)
        locale = locale.to_sym
        if ZH_HANS_GROUP.include?(locale)
          format_zh_hans(discount_percent, locale: locale)
        elsif KU_GROUP.include?(locale)
          format_ku(discount_percent, locale: locale)
        elsif locale == :ja
          format_ja(discount_percent, locale: locale)
        else
          format_default(discount_percent, locale: locale)
        end
      end

      private

      def format_default(discount_percent, locale:)
        Worldwide::Numbers.new(locale: locale).format(discount_percent, percent: true)
      end

      # Discounts in Kurdish are formatted using English percentage conventions in a Latin script context
      def format_ku(discount_percent, locale:)
        Worldwide::Numbers.new(locale: :en).format(discount_percent, percent: true)
      end

      # Discounts in Chinese are formatted as a fraction of the original price (20% Off => 8折, 25% Off => 7.5折)
      def format_zh_hans(discount_percent, locale:)
        decile = ((1 - discount_percent) * 10).round(4)
        decile = decile.to_i if integer?(decile)
        "#{decile}折"
      end

      # Discounts in Japanese are formatted in tenths if applicable (20% Off => 2割引, 25% Off => 25%割引)
      def format_ja(discount_percent, locale:)
        discount_percent = discount_percent.round(4)
        result =
          if (discount_percent % 0.1).zero?
            (discount_percent * 10).to_i
          else
            Worldwide::Numbers.new(locale: locale).format(discount_percent, percent: true)
          end
        "#{result}割引"
      end

      def integer?(num)
        num == num.to_i
      end
    end
  end
end
