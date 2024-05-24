require "json"
require "yaml"
require "pry"
require "pry-byebug"

def read_iana_zones()
  iana_data = JSON.parse(File.read("iana.json"))
  file_zones = iana_data["zones"]

  iana_zones = {}

  file_zones.each do |tz|
    iana_zones[tz["id"]] = tz["offsets"]

    tz["aliases"].each do |tz_alias|
      iana_zones[tz_alias] = tz["offsets"]
    end
  end

  iana_zones
end

def read_rails_zones()
  zones = {}
  fails = []

  file = YAML.load_file("rails.yml")
  rails_zones = file["en"]["timezones"].each do |tz|
    name = tz[0]
    raw_offset = tz[1]
    offset_match = raw_offset.match(/.*GMT([+-].2)/)

    if offset_match == nil
      fails << tz
    end
    zones[name] = offset_match&.captures&.first
  end

  pp fails
  debugger
  zones
end

def invert_hash(hash)
  offset_to_name = {}

  hash.each do |tz_name, tz_offset|
    if offset_to_name.has_key?(tz_offset)
      offset_to_name[tz_offset] << tz_name
    else
      offset_to_name[tz_offset] = [tz_name]
    end
  end

  offset_to_name
end

IANA_ZONES = read_iana_zones
RAILS_ZONES = read_rails_zones
offsets_to_rails = invert_hash(RAILS_ZONES)
offsets_to_iana = invert_hash(IANA_ZONES)

all_iana_zones = Hash[ IANA_ZONES.map { |key, val| [key.to_s, val] }.sort ]

# all_iana_zones.each do |tz_name, offset |
#   pp offset, tz_name
#
#   matching_zones = offsets_to_rails[offset]
#   # pp matching_zones if matching_zones
# end
debugger

pp 'debugger'