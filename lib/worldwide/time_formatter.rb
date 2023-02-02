# frozen_string_literal: true

module Worldwide
  class TimeFormatter
    def initialize(locale: I18n.locale)
      @locale = locale
    end

    def hour_minute_separator
      format_string = Worldwide::Cldr.t("time.formats.time_only", locale: @locale)
      /%\-?\d?\d?[Akl](.*)%\-?\d?\d?M/.match(format_string)&.captures&.first || ":"
    end

    def twelve_hour_clock?
      Worldwide::Cldr.t("time.formats.time_only", locale: @locale)&.include?("%P")
    end
  end
end
