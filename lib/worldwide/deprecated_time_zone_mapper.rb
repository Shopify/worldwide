# frozen_string_literal: true

require "geokit"

module Worldwide
  class DeprecatedTimeZoneMapper
    class << self
      # If the zone name is deprecated, return the supported zone name that corresponds to it.
      # If the zone name is supported, return it unchanged.
      def to_supported(zone)
        DEPRECATED_ZONES_MAP.fetch(zone&.to_sym, zone)
      end

      # Map IANA timezones to Rails timezones
      def to_rails(iana_timezone)
        # If the timezone is already a supported Ruby timezone, return it
        return iana_timezone if RAILS_TIMEZONES.key?(iana_timezone&.to_sym)

        # IANA timezones has aliases. If the timezone is an alias, return the corresponding IANA timezone
        timezone_alias = TIMEZONES_ALIASES.find do |timezone, aliases|
          return timezone.to_s if aliases.include?(iana_timezone)
        end

        # If the alias is also a supported Rails timezone, return it
        return timezone_alias if RAILS_TIMEZONES.key?(timezone_alias&.to_sym)

        timezone = timezone_alias || iana_timezone

        matching_timezones = find_matching_timezones(timezone)

        return timezone if matching_timezones.empty?

        iana_tz_info = TZInfo::Timezone.get(timezone)

        # Find the closest Rails timezone based on geographical coordinates
        closest_timezone = find_closest_timezone(iana_tz_info, matching_timezones)

        closest_timezone
      end

      private

      def extract_offset(offset)
        match = offset.match(/\(GMT([+-]\d{2}:\d{2})\)/)
        match ? match[1] : nil
      end

      # Get the Rails timezones that have the same GMT offset as the given IANA timezone
      def find_matching_timezones(timezone)
        return [] if ActiveSupport::TimeZone[timezone].nil?

        iana_gmt_offset = ActiveSupport::TimeZone[timezone].formatted_offset

        RAILS_TIMEZONES.filter do |_, offset|
          ruby_offset = extract_offset(offset)
          iana_gmt_offset == ruby_offset
        end
      end

      def find_closest_timezone(timezone, neighboring_timezones)
        # Get the geographical coordinates for the given timezone
        coordinates = get_coordinates(timezone)

        return timezone if coordinates.nil?

        # Iterate through the Rails timezones to find the closest match
        closest_timezone = nil
        shortest_distance = Float::INFINITY

        neighboring_timezones.keys.each do |neighboring_timezone|
          timezone_info = TZInfo::Timezone.get(neighboring_timezone.to_s)
          timezone_coordinates = get_coordinates(timezone_info)

          if timezone_coordinates.nil?
            break
          end

          distance = Geokit::LatLng.distance_between(
            coordinates,
            timezone_coordinates,
          )

          if distance < shortest_distance
            shortest_distance = distance
            closest_timezone = neighboring_timezone.to_s
          end
        end

        closest_timezone
      end

      def get_coordinates(timezone)
        # Get the timezone identifier
        identifier = timezone.identifier

        # Use the TZInfo::Country class to find the country and its timezones
        TZInfo::Country.all.each do |country|
          country.zone_identifiers.each do |zone_identifier|
            next unless zone_identifier == identifier

            zone_info = country.zone_info.find { |zone| zone.identifier == zone_identifier }
            return nil if zone_info.nil?

            return Geokit::LatLng.new(zone_info.latitude.to_f, zone_info.longitude.to_f)
          end
        end

        nil
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

    TIMEZONES_ALIASES = {
      "Africa/Abidjan": ["Africa/Accra", "Africa/Bamako", "Africa/Banjul", "Africa/Conakry", "Africa/Dakar", "Africa/Freetown", "Africa/Lome", "Africa/Nouakchott", "Africa/Ouagadougou", "Africa/Timbuktu", "Atlantic/Reykjavik", "Atlantic/St_Helena", "Iceland"],
      "Africa/Cairo": ["Egypt"],
      "Africa/Johannesburg": ["Africa/Maseru", "Africa/Mbabane"],
      "Africa/Lagos": ["Africa/Bangui", "Africa/Brazzaville", "Africa/Douala", "Africa/Kinshasa", "Africa/Libreville", "Africa/Luanda", "Africa/Malabo", "Africa/Niamey", "Africa/Porto-Novo"],
      "Africa/Maputo": ["Africa/Blantyre", "Africa/Bujumbura", "Africa/Gaborone", "Africa/Harare", "Africa/Kigali", "Africa/Lubumbashi", "Africa/Lusaka"],
      "Africa/Nairobi": ["Africa/Addis_Ababa", "Africa/Asmara", "Africa/Asmera", "Africa/Dar_es_Salaam", "Africa/Djibouti", "Africa/Kampala", "Africa/Mogadishu", "Indian/Antananarivo", "Indian/Comoro", "Indian/Mayotte"],
      "Africa/Tripoli": ["Libya"],
      "America/Adak": ["America/Atka", "US/Aleutian"],
      "America/Anchorage": ["US/Alaska"],
      "America/Argentina/Buenos_Aires": ["America/Buenos_Aires"],
      "America/Argentina/Catamarca": ["America/Argentina/ComodRivadavia", "America/Catamarca"],
      "America/Argentina/Cordoba": ["America/Cordoba", "America/Rosario"],
      "America/Argentina/Jujuy": ["America/Jujuy"],
      "America/Argentina/Mendoza": ["America/Mendoza"],
      "America/Chicago": ["US/Central"],
      "America/Denver": ["America/Shiprock", "Navajo", "US/Mountain"],
      "America/Detroit": ["US/Michigan"],
      "America/Edmonton": ["America/Yellowknife", "Canada/Mountain"],
      "America/Halifax": ["Canada/Atlantic"],
      "America/Havana": ["Cuba"],
      "America/Indiana/Indianapolis": ["America/Fort_Wayne", "America/Indianapolis", "US/East-Indiana"],
      "America/Indiana/Knox": ["America/Knox_IN", "US/Indiana-Starke"],
      "America/Iqaluit": ["America/Pangnirtung"],
      "America/Jamaica": ["Jamaica"],
      "America/Kentucky/Louisville": ["America/Louisville"],
      "America/Los_Angeles": ["US/Pacific"],
      "America/Manaus": ["Brazil/West"],
      "America/Mazatlan": ["Mexico/BajaSur"],
      "America/Mexico_City": ["Mexico/General"],
      "America/New_York": ["US/Eastern"],
      "America/Noronha": ["Brazil/DeNoronha"],
      "America/Nuuk": ["America/Godthab"],
      "America/Panama": ["America/Atikokan", "America/Cayman", "America/Coral_Harbour"],
      "America/Phoenix": ["America/Creston", "US/Arizona"],
      "America/Puerto_Rico": ["America/Anguilla", "America/Antigua", "America/Aruba", "America/Blanc-Sablon", "America/Curacao", "America/Dominica", "America/Grenada", "America/Guadeloupe", "America/Kralendijk", "America/Lower_Princes", "America/Marigot", "America/Montserrat", "America/Port_of_Spain", "America/St_Barthelemy", "America/St_Kitts", "America/St_Lucia", "America/St_Thomas", "America/St_Vincent", "America/Tortola", "America/Virgin"],
      "America/Regina": ["Canada/Saskatchewan"],
      "America/Rio_Branco": ["America/Porto_Acre", "Brazil/Acre"],
      "America/Santiago": ["Chile/Continental"],
      "America/Sao_Paulo": ["Brazil/East"],
      "America/St_Johns": ["Canada/Newfoundland"],
      "America/Tijuana": ["America/Ensenada", "America/Santa_Isabel", "Mexico/BajaNorte"],
      "America/Toronto": ["America/Montreal", "America/Nassau", "America/Nipigon", "America/Thunder_Bay", "Canada/Eastern"],
      "America/Vancouver": ["Canada/Pacific"],
      "America/Whitehorse": ["Canada/Yukon"],
      "America/Winnipeg": ["America/Rainy_River", "Canada/Central"],
      "Asia/Ashgabat": ["Asia/Ashkhabad"],
      "Asia/Bangkok": ["Asia/Phnom_Penh", "Asia/Vientiane", "Indian/Christmas"],
      "Asia/Dhaka": ["Asia/Dacca"],
      "Asia/Dubai": ["Asia/Muscat", "Indian/Mahe", "Indian/Reunion"],
      "Asia/Ho_Chi_Minh": ["Asia/Saigon"],
      "Asia/Hong_Kong": ["Hongkong"],
      "Asia/Jerusalem": ["Asia/Tel_Aviv", "Israel"],
      "Asia/Kathmandu": ["Asia/Katmandu"],
      "Asia/Kolkata": ["Asia/Calcutta"],
      "Asia/Kuching": ["Asia/Brunei"],
      "Asia/Macau": ["Asia/Macao"],
      "Asia/Makassar": ["Asia/Ujung_Pandang"],
      "Asia/Nicosia": ["Europe/Nicosia"],
      "Asia/Qatar": ["Asia/Bahrain"],
      "Asia/Riyadh": ["Antarctica/Syowa", "Asia/Aden", "Asia/Kuwait"],
      "Asia/Seoul": ["ROK"],
      "Asia/Shanghai": ["Asia/Chongqing", "Asia/Chungking", "Asia/Harbin", "PRC"],
      "Asia/Singapore": ["Asia/Kuala_Lumpur", "Singapore"],
      "Asia/Taipei": ["ROC"],
      "Asia/Tehran": ["Iran"],
      "Asia/Thimphu": ["Asia/Thimbu"],
      "Asia/Tokyo": ["Japan"],
      "Asia/Ulaanbaatar": ["Asia/Ulan_Bator"],
      "Asia/Urumqi": ["Asia/Kashgar"],
      "Asia/Yangon": ["Asia/Rangoon", "Indian/Cocos"],
      "Atlantic/Faroe": ["Atlantic/Faeroe"],
      "Australia/Adelaide": ["Australia/South"],
      "Australia/Brisbane": ["Australia/Queensland"],
      "Australia/Broken_Hill": ["Australia/Yancowinna"],
      "Australia/Darwin": ["Australia/North"],
      "Australia/Hobart": ["Australia/Currie", "Australia/Tasmania"],
      "Australia/Lord_Howe": ["Australia/LHI"],
      "Australia/Melbourne": ["Australia/Victoria"],
      "Australia/Perth": ["Australia/West"],
      "Australia/Sydney": ["Australia/ACT", "Australia/Canberra", "Australia/NSW"],
      "Etc/GMT": ["Etc/GMT+0", "Etc/GMT-0", "Etc/GMT0", "Etc/Greenwich", "GMT", "GMT+0", "GMT-0", "GMT0", "Greenwich"],
      "Etc/UTC": ["Etc/UCT", "Etc/Universal", "Etc/Zulu", "UCT", "UTC", "Universal", "Zulu"],
      "Europe/Belgrade": ["Europe/Ljubljana", "Europe/Podgorica", "Europe/Sarajevo", "Europe/Skopje", "Europe/Zagreb"],
      "Europe/Berlin": ["Arctic/Longyearbyen", "Atlantic/Jan_Mayen", "Europe/Copenhagen", "Europe/Oslo", "Europe/Stockholm"],
      "Europe/Brussels": ["Europe/Amsterdam", "Europe/Luxembourg"],
      "Europe/Chisinau": ["Europe/Tiraspol"],
      "Europe/Dublin": ["Eire"],
      "Europe/Helsinki": ["Europe/Mariehamn"],
      "Europe/Istanbul": ["Asia/Istanbul", "Turkey"],
      "Europe/Kyiv": ["Europe/Kiev", "Europe/Uzhgorod", "Europe/Zaporozhye"],
      "Europe/Lisbon": ["Portugal"],
      "Europe/London": ["Europe/Belfast", "Europe/Guernsey", "Europe/Isle_of_Man", "Europe/Jersey", "GB", "GB-Eire"],
      "Europe/Moscow": ["W-SU"],
      "Europe/Paris": ["Europe/Monaco"],
      "Europe/Prague": ["Europe/Bratislava"],
      "Europe/Rome": ["Europe/San_Marino", "Europe/Vatican"],
      "Europe/Warsaw": ["Poland"],
      "Europe/Zurich": ["Europe/Busingen", "Europe/Vaduz"],
      "Indian/Maldives": ["Indian/Kerguelen"],
      "Pacific/Auckland": ["Antarctica/McMurdo", "Antarctica/South_Pole", "NZ"],
      "Pacific/Chatham": ["NZ-CHAT"],
      "Pacific/Easter": ["Chile/EasterIsland"],
      "Pacific/Guadalcanal": ["Pacific/Pohnpei", "Pacific/Ponape"],
      "Pacific/Guam": ["Pacific/Saipan"],
      "Pacific/Honolulu": ["Pacific/Johnston", "US/Hawaii"],
      "Pacific/Kanton": ["Pacific/Enderbury"],
      "Pacific/Kwajalein": ["Kwajalein"],
      "Pacific/Pago_Pago": ["Pacific/Midway", "Pacific/Samoa", "US/Samoa"],
      "Pacific/Port_Moresby": ["Antarctica/DumontDUrville", "Pacific/Chuuk", "Pacific/Truk", "Pacific/Yap"],
      "Pacific/Tarawa": ["Pacific/Funafuti", "Pacific/Majuro", "Pacific/Wake", "Pacific/Wallis"],
    }

    RAILS_TIMEZONES = {
      "Etc/GMT+12": "(GMT-12:00) International Date Line West",
      "Pacific/Pago_Pago": "(GMT-11:00) American Samoa",
      "Pacific/Midway": "(GMT-11:00) Midway Island",
      "Pacific/Honolulu": "(GMT-10:00) Hawaii",
      "America/Juneau": "(GMT-09:00) Alaska",
      "America/Los_Angeles": "(GMT-08:00) Pacific Time (US & Canada)",
      "America/Tijuana": "(GMT-08:00) Tijuana",
      "America/Phoenix": "(GMT-07:00) Arizona",
      "America/Chihuahua": "(GMT-07:00) Chihuahua",
      "America/Mazatlan": "(GMT-07:00) Mazatlan",
      "America/Denver": "(GMT-07:00) Mountain Time (US & Canada)",
      "America/Guatemala": "(GMT-06:00) Central America",
      "America/Chicago": "(GMT-06:00) Central Time (US & Canada)",
      "America/Mexico_City": "(GMT-06:00) Guadalajara, Mexico City",
      "America/Monterrey": "(GMT-06:00) Monterrey",
      "America/Regina": "(GMT-06:00) Saskatchewan",
      "America/Bogota": "(GMT-05:00) Bogota",
      "America/New_York": "(GMT-05:00) Eastern Time (US & Canada)",
      "America/Indiana/Indianapolis": "(GMT-05:00) Indiana (East)",
      "America/Lima": "(GMT-05:00) Lima, Quito",
      "America/Halifax": "(GMT-04:00) Atlantic Time (Canada)",
      "America/Caracas": "(GMT-04:00) Caracas",
      "America/Guyana": "(GMT-04:00) Georgetown",
      "America/La_Paz": "(GMT-04:00) La Paz",
      "America/Puerto_Rico": "(GMT-04:00) Puerto Rico",
      "America/Santiago": "(GMT-04:00) Santiago",
      "America/St_Johns": "(GMT-03:30) Newfoundland",
      "America/Sao_Paulo": "(GMT-03:00) Brasilia",
      "America/Argentina/Buenos_Aires": "(GMT-03:00) Buenos Aires",
      "America/Godthab": "(GMT-03:00) Greenland",
      "America/Montevideo": "(GMT-03:00) Montevideo",
      "Atlantic/South_Georgia": "(GMT-02:00) Mid-Atlantic",
      "Atlantic/Azores": "(GMT-01:00) Azores",
      "Atlantic/Cape_Verde": "(GMT-01:00) Cape Verde Is.",
      "Africa/Casablanca": "(GMT+01:00) Casablanca",
      "Europe/Dublin": "(GMT+00:00) Dublin",
      "Europe/London": "(GMT+00:00) Edinburgh, London",
      "Europe/Lisbon": "(GMT+00:00) Lisbon",
      "Africa/Monrovia": "(GMT+00:00) Monrovia",
      "Etc/UTC": "(GMT+00:00) UTC",
      "Europe/Amsterdam": "(GMT+01:00) Amsterdam",
      "Europe/Belgrade": "(GMT+01:00) Belgrade",
      "Europe/Berlin": "(GMT+01:00) Berlin",
      "Europe/Bratislava": "(GMT+01:00) Bratislava",
      "Europe/Brussels": "(GMT+01:00) Brussels",
      "Europe/Budapest": "(GMT+01:00) Budapest",
      "Europe/Copenhagen": "(GMT+01:00) Copenhagen",
      "Europe/Ljubljana": "(GMT+01:00) Ljubljana",
      "Europe/Madrid": "(GMT+01:00) Madrid",
      "Europe/Paris": "(GMT+01:00) Paris",
      "Europe/Prague": "(GMT+01:00) Prague",
      "Europe/Rome": "(GMT+01:00) Rome",
      "Europe/Sarajevo": "(GMT+01:00) Sarajevo",
      "Europe/Skopje": "(GMT+01:00) Skopje",
      "Europe/Stockholm": "(GMT+01:00) Stockholm",
      "Europe/Vienna": "(GMT+01:00) Vienna",
      "Europe/Warsaw": "(GMT+01:00) Warsaw",
      "Africa/Algiers": "(GMT+01:00) West Central Africa",
      "Europe/Zagreb": "(GMT+01:00) Zagreb",
      "Europe/Zurich": "(GMT+01:00) Bern, Zurich",
      "Europe/Athens": "(GMT+02:00) Athens",
      "Europe/Bucharest": "(GMT+02:00) Bucharest",
      "Africa/Cairo": "(GMT+02:00) Cairo",
      "Africa/Harare": "(GMT+02:00) Harare",
      "Europe/Helsinki": "(GMT+02:00) Helsinki",
      "Asia/Jerusalem": "(GMT+02:00) Jerusalem",
      "Europe/Kaliningrad": "(GMT+02:00) Kaliningrad",
      "Europe/Kiev": "(GMT+02:00) Kyiv",
      "Africa/Johannesburg": "(GMT+02:00) Pretoria",
      "Europe/Riga": "(GMT+02:00) Riga",
      "Europe/Sofia": "(GMT+02:00) Sofia",
      "Europe/Tallinn": "(GMT+02:00) Tallinn",
      "Europe/Vilnius": "(GMT+02:00) Vilnius",
      "Asia/Baghdad": "(GMT+03:00) Baghdad",
      "Europe/Istanbul": "(GMT+03:00) Istanbul",
      "Asia/Kuwait": "(GMT+03:00) Kuwait",
      "Europe/Minsk": "(GMT+03:00) Minsk",
      "Africa/Nairobi": "(GMT+03:00) Nairobi",
      "Asia/Riyadh": "(GMT+03:00) Riyadh",
      "Europe/Moscow": "(GMT+03:00) Moscow, St. Petersburg",
      "Europe/Volgograd": "(GMT+03:00) Volgograd",
      "Asia/Tehran": "(GMT+03:30) Tehran",
      "Asia/Baku": "(GMT+04:00) Baku",
      "Asia/Muscat": "(GMT+04:00) Abu Dhabi, Muscat",
      "Europe/Samara": "(GMT+04:00) Samara",
      "Asia/Tbilisi": "(GMT+04:00) Tbilisi",
      "Asia/Yerevan": "(GMT+04:00) Yerevan",
      "Asia/Kabul": "(GMT+04:30) Kabul",
      "Asia/Yekaterinburg": "(GMT+05:00) Ekaterinburg",
      "Asia/Karachi": "(GMT+05:00) Islamabad, Karachi",
      "Asia/Tashkent": "(GMT+05:00) Tashkent",
      "Asia/Kolkata": "(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi",
      "Asia/Colombo": "(GMT+05:30) Sri Jayawardenepura",
      "Asia/Kathmandu": "(GMT+05:45) Kathmandu",
      "Asia/Almaty": "(GMT+06:00) Almaty",
      "Asia/Dhaka": "(GMT+06:00) Astana, Dhaka",
      "Asia/Urumqi": "(GMT+06:00) Urumqi",
      "Asia/Rangoon": "(GMT+06:30) Rangoon",
      "Asia/Bangkok": "(GMT+07:00) Bangkok, Hanoi",
      "Asia/Jakarta": "(GMT+07:00) Jakarta",
      "Asia/Krasnoyarsk": "(GMT+07:00) Krasnoyarsk",
      "Asia/Novosibirsk": "(GMT+07:00) Novosibirsk",
      "Asia/Shanghai": "(GMT+08:00) Beijing",
      "Asia/Chongqing": "(GMT+08:00) Chongqing",
      "Asia/Hong_Kong": "(GMT+08:00) Hong Kong",
      "Asia/Irkutsk": "(GMT+08:00) Irkutsk",
      "Asia/Kuala_Lumpur": "(GMT+08:00) Kuala Lumpur",
      "Australia/Perth": "(GMT+08:00) Perth",
      "Asia/Singapore": "(GMT+08:00) Singapore",
      "Asia/Taipei": "(GMT+08:00) Taipei",
      "Asia/Ulaanbaatar": "(GMT+08:00) Ulaanbaatar",
      "Asia/Seoul": "(GMT+09:00) Seoul",
      "Asia/Tokyo": "(GMT+09:00) Osaka, Sapporo, Tokyo",
      "Asia/Yakutsk": "(GMT+09:00) Yakutsk",
      "Australia/Adelaide": "(GMT+09:30) Adelaide",
      "Australia/Darwin": "(GMT+09:30) Darwin",
      "Australia/Brisbane": "(GMT+10:00) Brisbane",
      "Pacific/Guam": "(GMT+10:00) Guam",
      "Australia/Hobart": "(GMT+10:00) Hobart",
      "Australia/Melbourne": "(GMT+10:00) Canberra, Melbourne",
      "Australia/Canberra": "(GMT+10:00) Canberra, Melbourne",
      "Pacific/Port_Moresby": "(GMT+10:00) Port Moresby",
      "Australia/Sydney": "(GMT+10:00) Sydney",
      "Asia/Vladivostok": "(GMT+10:00) Vladivostok",
      "Asia/Magadan": "(GMT+11:00) Magadan",
      "Pacific/Noumea": "(GMT+11:00) New Caledonia",
      "Pacific/Guadalcanal": "(GMT+11:00) Solomon Is.",
      "Asia/Srednekolymsk": "(GMT+11:00) Srednekolymsk",
      "Pacific/Fiji": "(GMT+12:00) Fiji",
      "Asia/Kamchatka": "(GMT+12:00) Kamchatka",
      "Pacific/Majuro": "(GMT+12:00) Marshall Is.",
      "Pacific/Auckland": "(GMT+12:00) Auckland, Wellington",
      "Pacific/Chatham": "(GMT+12:45) Chatham Is.",
      "Pacific/Tongatapu": "(GMT+13:00) Nuku'alofa",
      "Pacific/Apia": "(GMT+13:00) Samoa",
      "Pacific/Fakaofo": "(GMT+13:00) Tokelau Is.",
    }
  end
end
