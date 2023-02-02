# frozen_string_literal: true

module Worldwide
  module Lists
    extend self
    # We assume that the data is expected to returned in the same
    # order as it is received. We are aware of one counter example,
    # Urdu, that we do not support.

    def format(data, join: :and, locale: I18n.locale)
      cldr_connector = case join
      when :and
        "default"
      when :or
        "or"
      when :narrow
        "narrow"
      else
        raise ArgumentError, "Unknown connector #{join}."
      end
      return "" if data.nil? || data.empty?
      return data.first if data.size == 1

      if data.size == 2
        str = Worldwide::Cldr.t("lists.#{cldr_connector}.2", locale: locale)
        str.sub!("{0}", data[0])
        str.sub!("{1}", data[1])
        return str
      end

      start = get_connector(cldr_connector, position: "start", locale: locale)
      middle = get_connector(cldr_connector, position: "middle", locale: locale)
      endd = get_connector(cldr_connector, position: "end", locale: locale)

      positions = [start] + ([middle] * (data.size - 3)) + [endd]
      data.zip(positions).join("")
    end

    private

    def get_connector(cldr_connector, position:, locale:)
      str = Worldwide::Cldr.t("lists.#{cldr_connector}.#{position}", locale: locale)
      str.sub("{0}", "").sub("{1}", "")
    end
  end
end
