# frozen_string_literal: true

module Worldwide
  class DeprecatedTimeZoneMapper
    class << self
      # If the zone name is deprecated, return the supported zone name that corresponds to it.
      # If the zone name is supported, return it unchanged.
      def to_supported(zone)
        DEPRECATED_ZONES_MAP.fetch(zone&.to_sym, zone)
      end

      # Maps from any IANA timezone to the closest Rails timezone.
      def to_rails(zone)
        IANA_TO_RAILS_ZONES_MAP.fetch(zone&.to_sym, zone)
      end
    end

    DEPRECATED_ZONES_MAP = {
      "America/Indiana": "America/Indiana/Indianapolis",
      "America/Argentina": "America/Argentina/Buenos_Aires",
      "Asia/Chongqing": "Asia/Shanghai",
      "Asia/Istanbul": "Europe/Istanbul",
      "Australia/ACT": "Australia/Sydney",
      "Australia/LHI": "Australia/Lord_Howe",
      "Australia/North": "Australia/Darwin",
      "Australia/NSW": "Australia/Sydney",
      "Australia/Queensland": "Australia/Brisbane",
      "Australia/South": "Australia/Adelaide",
      "Australia/Tasmania": "Australia/Hobart",
      "Australia/Victoria": "Australia/Melbourne",
      "Australia/West": "Australia/Perth",
      "Brazil/Acre": "America/Rio_Branco",
      "Brazil/DeNoronha": "America/Noronha",
      "Brazil/East": "America/Sao_Paulo",
      "Brazil/West": "America/Manaus",
      "Canada/Atlantic": "America/Halifax",
      "Canada/Central": "America/Winnipeg",
      "Canada/Eastern": "America/Toronto",
      "Canada/Mountain": "America/Edmonton",
      "Canada/Newfoundland": "America/St_Johns",
      "Canada/Pacific": "America/Vancouver",
      "Canada/Saskatchewan": "America/Regina",
      "Canada/Yukon": "America/Whitehorse",
      "Chile/Continental": "America/Santiago",
      "Chile/EasterIsland": "Pacific/Easter",
      Cuba: "America/Havana",
      Egypt: "Africa/Cairo",
      Eire: "Europe/Dublin",
      "Etc/Greenwich": "Etc/GMT",
      "Etc/UCT": "UTC",
      "Etc/Universal": "UTC",
      "Etc/Zulu": "UTC",
      GB: "Europe/London",
      "GB-Eire": "Europe/London",
      "GMT+0": "Etc/GMT",
      GMT0: "Etc/GMT",
      "GMT−0": "Etc/GMT",
      Greenwich: "Etc/GMT",
      Hongkong: "Asia/Hong_Kong",
      Iceland: "Atlantic/Reykjavik",
      Iran: "Asia/Tehran",
      Israel: "Asia/Jerusalem",
      Jamaica: "America/Jamaica",
      Japan: "Asia/Tokyo",
      Kwajalein: "Pacific/Kwajalein",
      Libya: "Africa/Tripoli",
      "Mexico/BajaNorte": "America/Tijuana",
      "Mexico/BajaSur": "America/Mazatlan",
      "Mexico/General": "America/Mexico_City",
      Navajo: "America/Denver",
      NZ: "Pacific/Auckland",
      "NZ-CHAT": "Pacific/Chatham",
      Poland: "Europe/Warsaw",
      Portugal: "Europe/Lisbon",
      PRC: "Asia/Shanghai",
      ROC: "Asia/Taipei",
      ROK: "Asia/Seoul",
      Singapore: "Asia/Singapore",
      Turkey: "Europe/Istanbul",
      UCT: "UTC",
      Universal: "UTC",
      "US/Alaska": "America/Anchorage",
      "US/Aleutian": "America/Adak",
      "US/Arizona": "America/Phoenix",
      "US/Central": "America/Chicago",
      "US/Eastern": "America/New_York",
      "US/East-Indiana": "America/Indiana/Indianapolis",
      "US/Hawaii": "Pacific/Honolulu",
      "US/Indiana-Starke": "America/Indiana/Knox",
      "US/Michigan": "America/Detroit",
      "US/Mountain": "America/Denver",
      "US/Pacific": "America/Los_Angeles",
      "US/Pacific-New": "America/Los_Angeles",
      "US/Samoa": "Pacific/Pago_Pago",
      "W-SU": "Europe/Moscow",
      Zulu: "UTC",
    }

    IANA_TO_RAILS_ZONES_MAP = {
      "Africa/Abidjan" => "Europe/London",
      "Africa/Accra" => "Europe/London",
      "Africa/Addis_Ababa" => "Europe/Moscow",
      "Africa/Algiers" => "Africa/Algiers",
      "Africa/Asmara" => "Europe/Moscow",
      "Africa/Asmera" => "Europe/Moscow",
      "Africa/Bamako" => "Europe/London",
      "Africa/Bangui" => "Africa/Algiers",
      "Africa/Banjul" => "Europe/London",
      "Africa/Bissau" => "Europe/London",
      "Africa/Blantyre" => "Africa/Cairo",
      "Africa/Brazzaville" => "Africa/Algiers"
      "Africa/Bujumbura"
    }
  end
end
