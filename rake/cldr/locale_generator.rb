# frozen_string_literal: false

require "fileutils"
require "worldwide"
require "yaml"

require_relative "hash_utils"
require_relative "pluralization_subkey_expander"
require_relative "sort_yaml"

module Worldwide
  module Cldr
    class LocaleGenerator
      def initialize
        @cache = {}
      end

      def perform
        initialize_i18n

        generate_plural_keys_lookup

        initialize_i18n # We need to re-initialize i18n to load the new data for the next step

        # CLDR is missing pluralization keys in some cases
        # We fill in the holes by copying from the existing values
        # based on the premise that having poor grammar is better than falling back
        # to a different language.
        expand_cldr_to_cover_missing_plurals

        # Sort the expanded files.
        # Ideally, plural key expansion would be done in rake/cldr/patch.rb
        # However, it depends on `generate_plural_keys_lookup` being run, which belongs in this file
        # So instead, we just sort the files again.
        sort_cldr_files

        Worldwide::Locales.map(&:to_s).each do |locale|
          puts "Generating date/time formats for locale '#{locale}'..."
          generate_locale(locale)
        end

        # During the generation process, we may have fallen back to `root`, which only has
        # pluralization data for the `other` key, despite the language needing more keys than that
        # Expand the keys to cover all the keys needed for the language.
        expand_output_to_cover_missing_plurals

        initialize_i18n # We need to re-initialize i18n to load the new data for the next step

        generate_format_documentation
      end

      # Map the given dotted_form hash of CLDR formats to a corresponding
      # dotted_form hash of Ruby strftime formats.
      def map_cldr_to_shopify(map)
        shopify_dotted = {}

        [
          [:date_and_time, :date],
          [:date_and_time, :time],
          [:date, :date],
          [:time, :time],
        ].each do |map_section, shopify_section|
          sub_map = map.fetch(map_section)
          shopify_dotted.merge!(strftime_formats_from_cldr(sub_map, shopify_section))
        end

        [
          [
            [
              "calendars.gregorian.days.format.abbreviated",
              "calendars.gregorian.days.stand_alone.abbreviated",
            ],
            "date.abbr_day_names",
            CLDR_DAYS_OF_WEEK,
          ],
          [
            [
              "calendars.gregorian.months.stand_alone.abbreviated",
              "calendars.gregorian.months.format.abbreviated",
              "calendars.gregorian.months.stand_alone.narrow",
            ],
            "date.abbr_month_names",
            CLDR_MONTHS_OF_YEAR,
          ],
          [
            [
              "calendars.gregorian.days.format.wide",
              "calendars.gregorian.days.stand_alone.wide",
            ],
            "date.day_names",
            CLDR_DAYS_OF_WEEK,
          ],
          [
            [
              "calendars.gregorian.months.stand_alone.wide",
              "calendars.gregorian.months.format.wide",
            ],
            "date.month_names",
            CLDR_MONTHS_OF_YEAR,
          ],
        ].each do |cldr_key_list, shopify_key, indices|
          shopify_dotted[shopify_key.to_sym] = list_from_cldr(cldr_key_list, indices)
        end

        DATETIME_FORMAT_MAP.each do |shopify_key, mapping|
          shopify_format = compound_datetime_format(mapping)

          shopify_dotted["date.formats.#{shopify_key}".to_sym] = shopify_format
          shopify_dotted["time.formats.#{shopify_key}".to_sym] = shopify_format
        end

        # Some formats are not directly available in CLDR, but can be inferred/constructed from those that are.
        shopify_dotted.merge!(infer_formats)

        shopify_dotted.merge!(construct_formats)

        # cc_expiry_date: is the same for all locales, and has no basis in CLDR
        ["date", "time"].each do |shopify_section|
          shopify_dotted["#{shopify_section}.formats.cc_expiry_date".to_sym] = "%m/%Y"
        end

        shopify_dotted["date.order".to_sym] = infer_ymd_order

        shopify_dotted
      end

      # Convert from CLDR format string to a Ruby strftime format string
      # Note this lacks error checking, and doesn't handle possible situations like embedded '%'.
      # It should be solid enough for the limited use we're making of it,
      # to convert well-known CLDR formats to strftime formats.
      #
      def to_strftime_format(cldr_format)
        tokens = Worldwide::Cldr::DateFormatPattern.tokenize(cldr_format)

        formatted = tokens.map do |token|
          case token
          when Worldwide::Cldr::DateFormatPattern::Field
            strftime_field = CLDR_TO_STRFTIME_MAP[token.pattern.to_sym]

            raise StandardError, "Unknown CLDR field '#{token.pattern}' (from #{cldr_format.inspect})" unless strftime_field

            strftime_field || "�" # "Emit U+FFFD REPLACEMENT CHARACTER for the invalid field": https://www.unicode.org/reports/tr35/tr35.html#Invalid_Patterns
          when Worldwide::Cldr::DateFormatPattern::Literal
            token.value
          end
        end
        formatted.join("")
      end

      private

      CLDR_DAYS_OF_WEEK = [:sun, :mon, :tue, :wed, :thu, :fri, :sat]

      CLDR_MONTHS_OF_YEAR = [nil, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

      CLDR_TO_STRFTIME_MAP = {
        "cccc": "%A",  # Weekday, full form (e.g. "Wednesday")
        "EEEE": "%A",  # Weekday, full form (e.g. "Wednesday")
        "LLLL": "%B",  # Month, full name (e.g. "December")
        "MMMM": "%B",  # Month, full name (e.g. "December")

        "ccc": "%a",  # Weekday, abbreviated form (e.g. "Wed.")
        "EEE": "%a",  # Weekday, abbreviated form (e.g. "Wed.")
        "LLL": "%b",  # Month, abbreviated name (e.g. "Dec.")
        "MMM": "%b",  # Month, abbreviated name (e.g. "Dec.")

        "dd": "%02d",  # Day of month, zero padded (00..31)
        "hh": "%02l",  # Hour, zero padded (01..12)
        "HH": "%02k",  # Hour, zero padded (00..23)
        "mm": "%M", # Minute (00..59)
        "MM": "%02m", # Month of year, zero padded (01..12)
        "ss": "%S", # Second (00..60)
        "yy": "%02y", # Year, two digits (e.g. 19)

        "a": "%P",  # am/pm indicator
        "b": "%P",  # Should be am/noon/pm/midnight; use am/pm
        "B": "%P",  # Should be "in the morning"/"in the evening"; use am/pm
        "d": "%-d", # Day of month, no padding (1..31)
        "E": "%A", # Weekday (e.g. Wednesday)
        "h": "%-l", # Hour (1..12)
        "H": "%02k", # Hour (0..23)
        "m": "%-M", # Minute, no padding (0..59)
        "M": "%-m", # Month of the year, no padding (1..12)
        "s": "%-S", # Second, no padding (0..60)
        "v": "%z",  # Time zone offset (e.g., -0500)
        "y": "%Y",  # Year, all digits (e.g. 2019)
        "z": "%z",  # Time zone offset (e.g., -0500)
        "xxx": "%:z", # Time zone offset with colon (e.g., -05:00)
      }

      DATETIME_FORMAT_MAP = {
        "date_time_current_year" => [
          "calendars.gregorian.formats.datetime.short.pattern",
          "calendars.gregorian.additional_formats.MMMd",
          "calendars.gregorian.formats.time.short.pattern",
        ],
        "default_long_with_zone" => [
          "calendars.gregorian.formats.datetime.medium.pattern",
          "calendars.gregorian.formats.date.full.pattern",
          "pseudo.time_long",
        ],
        "friendly_date_time" => [
          "calendars.gregorian.formats.datetime.medium.pattern",
          "calendars.gregorian.additional_formats.yMMMd",
          "calendars.gregorian.formats.time.short.pattern",
        ],
        "long_with_zone" => [
          "calendars.gregorian.formats.datetime.long.pattern",
          "calendars.gregorian.formats.date.long.pattern",
          "pseudo.time_long",
        ],
        "weekday_at_time" => [
          "calendars.gregorian.formats.datetime.long.pattern",
          "pseudo.weekday_long",
          "calendars.gregorian.formats.time.short.pattern",
        ],
        "weekday_with_time" => [
          "calendars.gregorian.formats.datetime.medium.pattern",
          "pseudo.weekday_long",
          "calendars.gregorian.formats.time.short.pattern",
        ],
      }

      FORMAT_FROM_CLDR_MAP = {
        date_and_time: {
          "abbr_date": "calendars.gregorian.additional_formats.yMMMd",
          "basic_date": "calendars.gregorian.additional_formats.yMd",
          "date": "calendars.gregorian.formats.date.long.pattern",
          "day_only": "calendars.gregorian.additional_formats.d",
          "month_year": "calendars.gregorian.additional_formats.yMMMM",
          "month_day": "calendars.gregorian.additional_formats.MMMMd",
          "time_only": "calendars.gregorian.formats.time.short.pattern",
          "weekday": "pseudo.weekday_long",
          "year": "calendars.gregorian.additional_formats.y",
        },
        date: {
          "long": "calendars.gregorian.formats.date.long.pattern",
          "short": "calendars.gregorian.additional_formats.MMMd",
        },
        time: {},
      }

      def sort_cldr_files
        puts("🔀 Sorting the keys in the CLDR files")
        Dir.glob(File.join(["data", "cldr", "**", "*.yml"])).each do |filepath|
          next if filepath.start_with?("data/cldr/transforms")
          next if filepath.start_with?("data/cldr/metazones.yml")

          # These files are sorted non-alphabetically, so we don't want to sort them.
          next 0 if filepath.end_with?("calendars.yml")
          next 0 if filepath.end_with?("delimiters.yml")
          next 0 if filepath.end_with?("lists.yml")

          SortYaml.sort_file(filepath, output_filename: filepath)
        end
      end

      # Return a hash with the given format for both "date" and "time"
      def add_format(shopify_key, format_string)
        strftime_dotted = {}

        ["date", "time"].each do |shopify_section|
          strftime_dotted["#{shopify_section}.#{shopify_key}".to_sym] = format_string
        end

        strftime_dotted
      end

      # Unfortunate special cases:
      # for some locales, we use a different name than CLDR does.
      # TODO: Make this data / patch.rb driven
      def cldr_locale(locale)
        case locale.to_s
        when "zh-CN"
          "zh-Hans"
        when "zh-HK"
          "zh-Hant-HK"
        when "zh-TW"
          "zh-Hant"
        else
          locale
        end
      end

      # CLDR is missing some basic formats that can be easily inferred
      # We construct and insert them here, so that we can then combine
      # them with other formats in later use of DATE_TIME_FORMAT_MAP.
      def cldr_pseudo_entries
        {
          pseudo: {
            weekday_long: "EEEE",
            time_long: cldr_pseudo_long_time_no_seconds,
            time_long_utc_offset: cldr_pseudo_long_time_utc_offset,
          },
        }
      end

      # We want a time that includes hour, minute, and timezone, but not seconds.
      # That is not available in CLDR.
      # But, there is a time that includes hour, minute, seconds and timezone.
      # So, we start with that, and discard the ':ss' portion.
      def cldr_pseudo_long_time_no_seconds
        Worldwide::Cldr.t("calendars.gregorian.formats.time.long.pattern").sub(":mm:ss", ":mm")
      end

      # We want a time that includes hour, minute, and the GMT time offset in a radable format, but not seconds.
      def cldr_pseudo_long_time_utc_offset
        Worldwide::Cldr.t("calendars.gregorian.formats.time.long.pattern").sub(":mm:ss", ":mm").sub("z", "'(UTC'xxx')'")
      end

      # CLDR does not define "date-time" format strings by themselves.
      # Instead, it defines "date" and "time" strings, and separately
      # describes how they can be pieced together to form a "date-time" string.
      # We unpack that here to create our "date-time" format strings.
      #
      def compound_datetime_format(mapping)
        datetime_key, date_key, time_key = mapping

        datetime_format = Worldwide::Cldr.t(datetime_key)
        date_format = Worldwide::Cldr.t(date_key)
        time_format = Worldwide::Cldr.t(time_key)

        cldr_format = datetime_format.sub("{{date}}", date_format).sub("{{time}}", time_format)
        if block_given?
          cldr_format = yield(cldr_format)
        end
        to_strftime_format(cldr_format)
      end

      # Some formats require additional terminology (e.g. "Yesterday at") that isn't in CLDR.
      # To create these, we combine a list of select hand-translated strings
      # (see data/other/hand_translated/xx.yml)
      # with the format strings that we find in CLDR.
      #
      def construct_formats
        strftime_dotted = {}

        # today_at_time:
        strftime_dotted.merge!(construct_today_at_time)

        # yesterday_at_time:
        strftime_dotted.merge!(construct_yesterday_at_time)

        # tomorrow_at_time:
        strftime_dotted.merge!(construct_tomorrow_at_time)

        # on_weekday_at_time:
        strftime_dotted.merge!(construct_on_weekday_at_time)

        # on_date_time_current_year:
        strftime_dotted.merge!(construct_on_date_time_current_year)

        # on_date:
        strftime_dotted.merge!(construct_on_date)

        # ago:
        strftime_dotted.merge!(copy_format(
          ["date.formats", "time.formats"],
          "ago",
          Worldwide::Cldr.t("date_time_translation.ago", default: nil) || "%{time} ago",
        ))

        # x_hours_ago:
        strftime_dotted.merge!(construct_x_hours_ago)

        # x_minutes_ago:
        strftime_dotted.merge!(construct_x_minutes_ago)

        # Other strings that are copied over verbatim from the hand-translated data
        strftime_dotted.merge!(copy_hand_translations)

        # relative names: e.g., yesterday, today, tomorrow
        strftime_dotted.merge!(relative_names)

        strftime_dotted
      end

      def construct_on_date
        cldr_format = Worldwide::Cldr.t("calendars.gregorian.additional_formats.yMMMd")
        date = to_strftime_format(cldr_format)
        on_date = (
          Worldwide::Cldr.t("date_time_translation.on_date", default: nil) ||
          "%{date}"
        ).sub(
          "%{date}",
          date,
        )
        add_format("formats.on_date", on_date)
      end

      def construct_on_date_time_current_year
        cldr_format = Worldwide::Cldr.t("calendars.gregorian.additional_formats.MMMd")
        date = to_strftime_format(cldr_format)
        cldr_format = Worldwide::Cldr.t("calendars.gregorian.formats.time.short.pattern")
        time = to_strftime_format(cldr_format)
        on_date_time_current_year = (
          Worldwide::Cldr.t("date_time_translation.on_date_time_current_year", default: nil) ||
          "%{time} %{month_and_day}"
        ).sub(
          "%{month_and_day}",
          date,
        ).sub(
          "%{time}",
          time,
        )
        add_format("formats.on_date_time_current_year", on_date_time_current_year)
      end

      def construct_on_weekday_at_time
        cldr_format = Worldwide::Cldr.t("calendars.gregorian.formats.time.short.pattern")
        time = to_strftime_format(cldr_format)
        on_weekday_at_time = (
          Worldwide::Cldr.t("date_time_translation.on_weekday_at_time", default: nil) ||
          "%{time} %{weekday_name}"
        ).sub(
          "%{weekday_name}",
          "%A",
        ).sub(
          "%{time}",
          time,
        )
        add_format("formats.on_weekday_at_time", on_weekday_at_time)
      end

      def construct_today_at_time
        cldr_format = Worldwide::Cldr.t("calendars.gregorian.formats.time.short.pattern")
        time = to_strftime_format(cldr_format)
        today_at_time = (
          Worldwide::Cldr.t("date_time_translation.today_at_time", default: nil) ||
          "%{time} #{Worldwide::Cldr.t("fields.day.relative.0")}"
        ).sub("%{time}", time)
        add_format("formats.today_at_time", today_at_time)
      end

      def construct_x_hours_ago
        # Unfortunate special case:  for :ja and :zh, we must use hour_narrow instead
        # of hour.  Japanese and Chinese don't use spaces between words, but CLDR adds
        # a space between the count and the phrase "hour(s) before" in the "hour" data.
        # They don't include the incorrect space in their "hour_narrow" format, though.
        source = if I18n.locale.to_s.start_with?("ja", "zh")
          "fields.hour_narrow.relative_time.past"
        else
          "fields.hour.relative_time.past"
        end

        copy_nested_format(source, ["date.formats.x_hours_ago", "time.formats.x_hours_ago"])
      end

      def construct_x_minutes_ago
        # Unfortunate special case for :ja and :zh.  See comment in construct_x_hours_ago.
        source = if I18n.locale.to_s.start_with?("ja", "zh")
          "fields.minute_narrow.relative_time.past"
        else
          "fields.minute.relative_time.past"
        end

        copy_nested_format(source, ["date.formats.x_minutes_ago", "time.formats.x_minutes_ago"])
      end

      def construct_yesterday_at_time
        cldr_format = Worldwide::Cldr.t("calendars.gregorian.formats.time.short.pattern")
        time = to_strftime_format(cldr_format)
        yesterday_at_time = (
          Worldwide::Cldr.t("date_time_translation.yesterday_at_time", default: nil) ||
          "%{time} #{Worldwide::Cldr.t("fields.day.relative.-1")}"
        ).sub("%{time}", time)
        add_format("formats.yesterday_at_time", yesterday_at_time)
      end

      def construct_tomorrow_at_time
        cldr_format = Worldwide::Cldr.t("calendars.gregorian.formats.time.short.pattern")
        time = to_strftime_format(cldr_format)
        tomorrow_at_time = (
          Worldwide::Cldr.t("date_time_translation.tomorrow_at_time", default: nil) ||
          "%{time} #{Worldwide::Cldr.t("fields.day.relative.+1")}"
        ).sub("%{time}", time)
        add_format("formats.tomorrow_at_time", tomorrow_at_time)
      end

      def copy_format(destinations, key, format)
        strftime_dotted = {}

        destinations.each do |shopify_section|
          strftime_dotted["#{shopify_section}.#{key}".to_sym] = format
        end

        strftime_dotted
      end

      def copy_nested_format(source, destinations)
        strftime_dotted = {}

        # For some languages (e.g., Akan), CLDR data is missing information.
        # As a last resort, we fall back to using English, which is presumably better than no information at all.
        data = Worldwide::Cldr.t(source, default: nil) || Worldwide::Cldr.t(source, locale: :en, raise: true)
        data.each do |key, _|
          strftime_dotted.merge!(copy_format(
            destinations,
            key.to_s,
            data[key].sub("{0}", "%{count}"),
          ))
        end

        strftime_dotted
      end

      # Some formats are present, verbatim, in the hand_translated/*.yml files.
      # We just copy these over into the date and/or time formats of the generated locale, as appropriate.
      def copy_hand_translations
        strftime_dotted = {}

        strftime_dotted.merge!(copy_format(
          ["time"],
          "am",
          Worldwide::Cldr.t("date_time_translation.am", default: nil) || "am",
        ))
        strftime_dotted.merge!(copy_format(
          ["time"],
          "pm",
          Worldwide::Cldr.t("date_time_translation.pm", default: nil) || "pm",
        ))
        strftime_dotted.merge!(copy_format(
          ["time"],
          "just_now",
          Worldwide::Cldr.t("date_time_translation.just_now", default: nil) ||
            Worldwide::Cldr.t("fields.second.relative.0", default: nil) ||
            "just now",
        ))

        strftime_dotted.merge!(copy_format(
          ["date.relative_day_names"],
          "this_week",
          Worldwide::Cldr.t("date_time_translation.this_week", default: nil) ||
            Worldwide::Cldr.t("fields.week.relative.0", default: nil) ||
            "this week",
        ))
        strftime_dotted.merge!(copy_format(
          ["date.relative_day_names"],
          "this_month",
          Worldwide::Cldr.t("date_time_translation.this_month", default: nil) ||
            Worldwide::Cldr.t("fields.month.relative.0", default: nil) ||
            "this month",
        ))

        strftime_dotted
      end

      # Relative day names leveraged from CLDR
      def relative_names
        result = {}

        relative_days = Worldwide::Cldr.t("fields.day.relative")

        result.merge!(if_present("date.relative_day_names.day_before_yesterday", relative_days, -2))
        result.merge!(if_present("date.relative_day_names.yesterday", relative_days, -1))
        result.merge!(if_present("date.relative_day_names.today", relative_days, 0))
        result.merge!(if_present("date.relative_day_names.tomorrow", relative_days, 1))
        result.merge!(if_present("date.relative_day_names.day_after_tomorrow", relative_days, 2))

        result.merge!(if_present("time.yesterday", relative_days, -1))

        result
      end

      # Returns the result of I18n.t(key) if it exists, or an empty hash if the translation is not available.
      def if_present(strftime_key, relative_days, key)
        if relative_days.include?(key)
          { strftime_key.to_sym => relative_days[key] }
        else
          {}
        end
      end

      # Some format strings are not given directly in CLDR.
      # Here, we infer / construct them based in part on what's in CLDR,
      # and in part on some heuristics we've coded below.
      def infer_formats
        strftime_dotted = {}

        # weekday_with_date:  Take MMMEd, convert it into MMMMEd.
        strftime_dotted.merge!(
          modify_format(
            "calendars.gregorian.additional_formats.MMMEd",
            "weekday_with_date",
          ) do |base|
            base.sub(/(?<!M)M{3}(?!M)/, "MMMM")
          end,
        )

        # short_weekday_with_date:  Take MMMEd, convert it to MMMEEEd
        strftime_dotted.merge!(
          modify_format(
            "calendars.gregorian.additional_formats.MMMEd",
            "short_weekday_with_date",
          ) do |base|
            base.sub(/(?<!E)E(?!E)/, "EEE")
          end,
        )

        strftime_dotted.merge!(
          modify_format(
            "calendars.gregorian.additional_formats.MMMEd",
            "weekday_with_short_date",
          ),
        )

        # long_readable_with_time:
        #   Use datetime: merge of yMMMd with time.formats.short.pattern.
        #   Then, replace the MMM ('%b') with MMMM ('%B').
        strftime_format = compound_datetime_format([
          "calendars.gregorian.formats.datetime.long.pattern",
          "calendars.gregorian.additional_formats.yMMMd",
          "calendars.gregorian.formats.time.short.pattern",
        ]) do |cldr_format|
          cldr_format.sub(/(?<!M)M{3}(?!M)/, "MMMM").sub(/(?<!E)E{3}(?!E)/, "EEEE")
        end
        ["date", "time"].each do |shopify_section|
          strftime_dotted["#{shopify_section}.formats.long_readable_with_time".to_sym] = strftime_format
        end

        # long_readable_with_zone:
        #   Use datetime: merge of yMMMEd with time.formats.long.pattern.
        #   Then, replace the MMM ('%b') with MMMM ('%B')
        #   Also, if the format uses EEE (as is true, e.g, for `es`), replace it with EEEE.
        strftime_format = compound_datetime_format(
          [
            "calendars.gregorian.formats.datetime.long.pattern",
            "calendars.gregorian.additional_formats.yMMMEd",
            "pseudo.time_long",
          ],
        ) do |cldr_format|
          cldr_format.sub(/(?<!M)M{3}(?!M)/, "MMMM").sub(/(?<!E)E{3}(?!E)/, "EEEE")
        end
        ["date", "time"].each do |shopify_section|
          strftime_dotted["#{shopify_section}.formats.long_readable_with_zone".to_sym] = strftime_format
        end

        # long_readable_with_utc_zone_offset:
        #  Use datetime: merge of yMMMEd with time.formats.short.pattern.
        #  Then, replace the MMM ('%b') with MMMM ('%B')
        #  Also, if the format uses EEE (as is true, e.g, for `es`), replace it with EEEE.
        #  Then append the gmt timezone offset.
        strftime_format = compound_datetime_format(
          [
            "calendars.gregorian.formats.datetime.long.pattern",
            "calendars.gregorian.additional_formats.yMMMd",
            "pseudo.time_long_utc_offset",
          ],
        ) do |cldr_format|
          cldr_format.sub(/(?<!M)M{3}(?!M)/, "MMMM").sub(/(?<!E)E{3}(?!E)/, "EEEE")
        end
        ["date", "time"].each do |shopify_section|
          strftime_dotted["#{shopify_section}.formats.long_readable_with_utc_zone_offset".to_sym] = strftime_format
        end

        # date_at_time:
        #   Use datetime: merge of yMMMd with time.formats.short.pattern.
        #   Then, replace MMM with MMMM to get the unabbreviated month name.
        strftime_format = compound_datetime_format(
          [
            "calendars.gregorian.formats.datetime.long.pattern",
            "calendars.gregorian.additional_formats.yMMMd",
            "calendars.gregorian.formats.time.short.pattern",
          ],
        ) do |cldr_format|
          cldr_format.sub(/(?<!M)M{3}(?!M)/, "MMMM")
        end
        ["date", "time"].each do |shopify_section|
          strftime_dotted["#{shopify_section}.formats.date_at_time".to_sym] = strftime_format
        end

        # time.formats.default:
        #   Use datetime: merge of yMMMEd with time.formats.long.pattern.
        #   Then, replace E with EEE to get an abbreviated day-of-week name.
        strftime_format = compound_datetime_format(
          [
            "calendars.gregorian.formats.datetime.short.pattern",
            "calendars.gregorian.additional_formats.yMMMEd",
            "pseudo.time_long",
          ],
        ) do |cldr_format|
          if /(?<!E)E{3}(?!E)/.match?(cldr_format)
            # Some locales, e.g. `es`, already use the abbreviated day-of-week form
            cldr_format
          else
            cldr_format.sub(/(?<!E)E(?!E)/, "EEE")
          end
        end
        strftime_dotted["time.formats.default".to_sym] = strftime_format

        # time.formats.long:
        #   Use datetime: merge of yMMMd with time.formats.short.pattern
        #   Then, replace MMM with MMMM to get the unabbreviated month-name.
        strftime_format = compound_datetime_format(
          [
            "calendars.gregorian.formats.datetime.medium.pattern",
            "calendars.gregorian.additional_formats.yMMMd",
            "calendars.gregorian.formats.time.short.pattern",
          ],
        ) do |cldr_format|
          cldr_format.sub(/(?<!M)M{3}(?!M)/, "MMMM")
        end
        strftime_dotted["time.formats.long".to_sym] = strftime_format

        # time.formats.short:
        #   Use datetime: merge of MMMd with time.formats.short.pattern.
        #   Note that this is only a "time" format, not a "date" one.
        strftime_dotted["time.formats.short".to_sym] = compound_datetime_format(
          [
            "calendars.gregorian.formats.datetime.short.pattern",
            "calendars.gregorian.additional_formats.MMMd",
            "calendars.gregorian.formats.time.short.pattern",
          ],
        )

        # date.formats.default:
        #   The "default" date format is a touchy subject, and different organizations have differing
        #   opinions regarding how it should be presented.
        #   We do some special-casing here to maintain consistency with our historical behaviour.
        #   For `en`, we use YYYY-MM-dd (the ISO standard), which is not present in CLDR.
        #   For `ja` and `zh-XX`, we use `y年MM月dd日`, given by formats.date.long.pattern.
        #   For the remaining locales, we use what's given by `additional_formats.yMd`.
        cldr_format = if I18n.locale == :en
          "y-MM-dd"
        elsif I18n.locale.to_s.start_with?("ja", "zh")
          Worldwide::Cldr.t("calendars.gregorian.formats.date.long.pattern")
        else
          Worldwide::Cldr.t("calendars.gregorian.additional_formats.yMd")
        end
        strftime_dotted["date.formats.default".to_sym] = to_strftime_format(cldr_format)

        # date_time.formats.billing:
        #   This legacy format is very inconsistent between locales.
        #   'en' and 'de' use 'YYYY/M/d', which has no basis in CLDR.
        #   'ja' and 'zh-XX' use 'YYYY年M月d日', which we derive from 'additional_formats.yMMMd'
        #   For other locales, we use the CLDR 'additional_formats.yMd'
        cldr_format = if I18n.locale.to_s.start_with?("de", "en")
          "y/M/d"
        elsif I18n.locale.to_s.start_with?("ja", "zh")
          Worldwide::Cldr.t("calendars.gregorian.additional_formats.yMMMd")
        else
          Worldwide::Cldr.t("calendars.gregorian.additional_formats.yMd")
        end
        ["date", "time"].each do |shopify_section|
          strftime_dotted["#{shopify_section}.formats.billing".to_sym] = to_strftime_format(cldr_format)
        end

        # yearless_ordinal:
        #   There are three patterns here.  We infer which one to use based on CLDR's MMMd format.
        #   (1) "%B %{ordinalized_day}" (e.g., en)
        #   (2) "%{ordinalized_day} %B" (e.g., most of Western Europe)
        #   (3) "%B%{ordinalized_day}" (e.g., ja and zh)
        cldr_format = Worldwide::Cldr.t("calendars.gregorian.additional_formats.MMMd")
        strftime_format = if cldr_format.start_with?("M")
          if cldr_format.include?(" ")
            "%B %{ordinalized_day}"
          else
            "%B%{ordinalized_day}"
          end
        else
          "%{ordinalized_day} %B"
        end
        strftime_dotted.merge!(add_format("formats.yearless_ordinal", strftime_format))

        strftime_dotted
      end

      # Examine the CLDR data to infer the order of date elements (day, month, year).
      # Return an array of symbols [:day, :month, :year] in the locale-specific order.
      def infer_ymd_order
        # special case:  'en' is different for legacy reasons
        return [:year, :month, :day] if I18n.locale.to_s.start_with?("en")

        ret = []

        cldr_format = Worldwide::Cldr.t("calendars.gregorian.additional_formats.yMd")
        cldr_format.each_char do |char|
          case char
          when "d"
            ret.push(:day) unless ret.include?(:day)
          when "M"
            ret.push(:month) unless ret.include?(:month)
          when "y"
            ret.push(:year) unless ret.include?(:year)
          end
        end

        ret
      end

      # Load all locales and add some pseudo entries
      def initialize_i18n
        I18n.reload!
        I18n.load_path += Dir[File.join(Worldwide::Paths::GEM_ROOT, "data/other/generated/*.yml")]
        I18n.load_path += Dir[File.join(Worldwide::Paths::GEM_ROOT, "data/other/hand_translated/*.yml")]
        I18n.load_path += Dir[File.join(Worldwide::Paths::CLDR_ROOT, "locales", "*/calendars.yml")]
        I18n.load_path += Dir[File.join(Worldwide::Paths::CLDR_ROOT, "locales", "*/fields.yml")]

        load("lib/worldwide/plurals.rb")

        I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

        I18n.enforce_available_locales = false
        I18n.default_locale = :en

        Worldwide::Locales.each do |locale|
          # add pseudo locales
          I18n.with_locale(locale) do
            I18n.backend.store_translations(locale, cldr_pseudo_entries)
          end

          adjusted_locale = cldr_locale(locale)
          I18n.with_locale(adjusted_locale) do
            I18n.backend.store_translations(adjusted_locale, cldr_pseudo_entries)
          end
        end
      end

      def modify_format(cldr_key, shopify_key)
        strftime_dotted = {}

        base = Worldwide::Cldr.t(cldr_key.to_s)
        modified = if block_given?
          yield(base)
        else
          base
        end

        strftime_format = to_strftime_format(modified)

        ["date", "time"].each do |shopify_section|
          key = "#{shopify_section}.formats.#{shopify_key}".to_sym
          strftime_dotted[key] = strftime_format
        end

        strftime_dotted
      end

      def numeric?(text)
        !Float(text).nil?
      rescue
        false
      end

      def strftime_formats_from_cldr(map, shopify_section)
        strftime_dotted = {}

        map.each do |key, value|
          cldr_format = Worldwide::Cldr.t(value)
          raise "CLDR key #{cldr_key} not found in CLDR data." unless cldr_format.is_a?(String)

          strftime_format = to_strftime_format(cldr_format)
          shopify_key = "#{shopify_section}.formats.#{key}".to_sym
          strftime_dotted[shopify_key] = strftime_format
        end

        strftime_dotted
      end

      def generate_locale(locale)
        I18n.with_locale(locale) do
          shopify_dotted = map_cldr_to_shopify(FORMAT_FROM_CLDR_MAP)
          @cache[locale] = shopify_dotted

          shopify_nested = { locale => HashUtils.to_nested_hash(shopify_dotted) }

          directory = Worldwide::Paths::GENERATED_LOCALE_ROOT
          FileUtils.mkdir_p(directory)

          File.write(File.join(directory, "#{locale}.yml"), shopify_nested.to_yaml)
        end
      end

      # Create Markdown file that we can reference from README.md
      # with a list of all supported formats in the various locales
      def generate_format_documentation
        all_date_formats = [
          :default,
          :abbr_date,
          :ago,
          :basic_date,
          :billing,
          :cc_expiry_date,
          :date,
          :date_at_time,
          :date_time_current_year,
          :day_only,
          :default_long_with_zone,
          :friendly_date_time,
          :long,
          :long_readable_with_time,
          :long_readable_with_zone,
          :long_readable_with_utc_zone_offset,
          :long_with_zone,
          :month_year,
          :month_day,
          :on_date,
          :on_date_time_current_year,
          :on_weekday_at_time,
          :short,
          :short_weekday_with_date,
          :today_at_time,
          :tomorrow_at_time,
          :time_only,
          :weekday,
          :weekday_at_time,
          :weekday_with_date,
          :weekday_with_short_date,
          :weekday_with_time,
          :year,
          :yearless_ordinal,
          :yesterday_at_time,
        ]

        I18n.reload!

        # We only put a subset of our locales in `formats.md` because, otherwise, the table becomes too wide.
        locales = ["en", "cs", "da", "de", "es", "fi", "fr", "it", "ja", "ko", "hi", "ms", "nb", "nl", "pl", "pt-BR", "pt-PT", "sv", "th", "tr", "vi", "zh-CN", "zh-TW"]

        File.open("formats.md", "w") do |file|
          file.write("<!--- Do not hand-edit this file. It is auto-generated by rake/cldr/locale_generator.rb -->\n")

          file.write("# `worldwide` supported date/time formats\n")
          file.write("|Formats|#{locales.join("|")}|\n")
          locales.length.times do
            file.write("|---")
          end
          file.write("|---|\n")

          time = Time.new(2018, 12, 26, 13, 23, 45, "+00:00")

          all_date_formats.each do |format|
            outputs = locales.map do |locale|
              I18n.with_locale(locale) do
                Worldwide::Cldr.l(time, format: @cache[locale]["date.formats.#{format}".to_sym])
              end
            end
            file.write("`#{format}`|#{outputs.join("|")}|\n")
          end
        end
      end

      def pluralization_keys(locale, type: "cardinal")
        plural_rules_path = File.expand_path(File.join(Worldwide::Paths::CLDR_ROOT, "locales", locale, "plural_rules.yml"))

        return [] unless File.exist?(plural_rules_path)

        rules = YAML.safe_load(
          File.read(plural_rules_path),
        ).dig(locale, type)

        (rules || {}).keys.sort.map(&:to_sym)
      end

      def generate_plural_keys_lookup
        cardinal_results = Worldwide::Locales.send(:cldr_locales).map(&:to_s).sort.to_h do |locale|
          [locale, pluralization_keys(locale, type: "cardinal")]
        end

        ordinal_results = Worldwide::Locales.send(:cldr_locales).map(&:to_s).sort.to_h do |locale|
          [locale, pluralization_keys(locale, type: "ordinal")]
        end

        all_cardinal_pluralization_keys = cardinal_results.flat_map { |_locale, keys| keys }.sort.uniq
        all_ordinal_pluralization_keys = ordinal_results.flat_map { |_locale, keys| keys }.sort.uniq

        auto_generated_content_start_regex = /^( *)# START OF AUTO-GENERATED CONTENT/
        auto_generated_content_end_regex = /# END OF AUTO-GENERATED CONTENT/
        plurals_filepath = "lib/worldwide/plurals.rb"

        existing_file_contents = File.read(plurals_filepath)

        start_of_auto_generated_content = existing_file_contents.match(auto_generated_content_start_regex)
        end_of_auto_generated_content = existing_file_contents.match(auto_generated_content_end_regex)

        raise StandardError, "Could not find the expected boundaries for replacing the auto-generated content." unless start_of_auto_generated_content && end_of_auto_generated_content

        indentation_of_starting_line = start_of_auto_generated_content.captures.first

        contents = <<~CONTENTS
          # START OF AUTO-GENERATED CONTENT
          # Do not hand-edit this section. It is auto-generated by rake/cldr/locale_generator.rb
          def all_cardinal_pluralization_keys
            #{all_cardinal_pluralization_keys}.freeze
          end

          def all_ordinal_pluralization_keys
            #{all_ordinal_pluralization_keys}.freeze
          end

          private

          def cardinal_pluralization_keys
            {
          #{cardinal_results.map { |locale, keys| "    #{locale.to_sym.inspect.sub(/^:/, "")}: #{keys}.freeze," }.join("\n")}
            }.freeze
          end

          def ordinal_pluralization_keys
            {
          #{ordinal_results.map { |locale, keys| "    #{locale.to_sym.inspect.sub(/^:/, "")}: #{keys}.freeze," }.join("\n")}
            }.freeze
          end

          # END OF AUTO-GENERATED CONTENT
        CONTENTS

        contents = contents.split("\n").map { |line| "#{line.strip.empty? ? "" : indentation_of_starting_line}#{line}" }.join("\n")

        new_file_contents = existing_file_contents[0...start_of_auto_generated_content.begin(0)] + contents + existing_file_contents[end_of_auto_generated_content.end(0)..]

        File.write(plurals_filepath, new_file_contents.to_s)
      end

      def expand_cldr_to_cover_missing_plurals
        puts("Expanding to cover missing plural keys")
        Dir.glob(File.join(["data", "cldr", "locales", "*", "*.yml"])).each do |filepath|
          locale = File.basename(File.dirname(filepath)).to_sym
          PluralizationSubkeyExpander.expand_file(filepath, locale, output_filename: filepath)
        end
      end

      def expand_output_to_cover_missing_plurals
        puts("Expanding to cover missing plural keys in output")
        Dir.glob(File.join(["data", "other", "generated", "*.yml"])).each do |filepath|
          locale = File.basename(filepath).sub(/\.yml$/, "").to_sym
          PluralizationSubkeyExpander.expand_file(filepath, locale.to_s, output_filename: filepath)
        end
      end

      def list_from_cldr(cldr_key_list, indices)
        # Unfortunate special case:
        # For some locales, CLDR defines one set of formats by cross-referencing another set
        ref = Worldwide::Cldr.t(cldr_key_list.first)
        if ref.is_a?(Symbol)
          return list_from_cldr(ref, indices)
        end

        indices.filter_map do |idx|
          if idx.nil?
            ""
          else
            cldr_key_list.lazy.map { |cldr_key| Worldwide::Cldr.t("#{cldr_key}.#{idx}", default: nil) }.find { |value| !value.nil? }
          end
        end
      end
    end
  end
end
