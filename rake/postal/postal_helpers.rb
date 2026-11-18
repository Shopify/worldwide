# frozen_string_literal: true

require_relative "code_mapper"
require "fileutils"
require "tmpdir"
require "yaml"
require "worldwide"

module PostalHelpers
  LEVEL_1_COUNTRIES = ["AU", "BR", "CA", "IN", "JP", "KR", "NZ", "PT", "RO", "TH", "US"]
  LEVEL_2_COUNTRIES = ["ES", "IT"]

  ZONES_KEY_LINE = "zones:\n"
  ZIP_PREFIXES_LINE = /\A {2}zip_prefixes:\s*(\[\])?\s*\z/
  PREFIX_BLOCK_LINE = /\A( {2,}- |\s*#)/
  PREFIX_ITEM_INDENT = /\A( {2,})- /
  COMMENT_LINE = /\A\s*#/
  CROSSING_KEY_LINE = /\Azips_crossing_provinces:/

  def patch_prefix_data(prefixes, country)
    patches = {
      CA: {
        QC: ["K1A"],
      },
      US: {
        PR: ["006", "007", "009"],
        VI: ["008"],
        AE: ["09"],
        AA: ["340"],
        AP: ["962", "963", "964", "965", "966"],
        AS: ["96799"],
        PW: ["96939", "96940"],
        FM: ["96941", "96942", "96943", "96944"],
        GU: ["9691", "9692", "96931", "96932"],
        MP: ["9695"],
      },
    }

    return prefixes unless patches.include?(country.to_sym)

    patches[country.to_sym].each do |zone_code, prefix_array|
      prefix_array.each do |prefix|
        prefixes[prefix.to_sym] = zone_code.to_s
      end
    end

    prefixes
  end

  def map_prefix_data(prefixes, country)
    code_mapper = Postal::CodeMapper.new
    prefixes.each do |prefix, zone_code|
      prefixes[prefix] = code_mapper.map_to_iso(country: country, geonames_code: zone_code)
    end
    prefixes
  end

  def subdivision_level_for_country(country)
    if LEVEL_1_COUNTRIES.include?(country)
      :code1
    elsif LEVEL_2_COUNTRIES.include?(country)
      :code2
    else
      raise "The country code '#{country}' has not been mapped yet. Data is pulled from geonames.org, whose format differs from how Worldwide's data is structured internally."
    end
  end

  # Writes postal code data into data/regions/<country>.yml:
  #  - `zones` maps a zone code to its list of prefixes, which becomes `zip_prefixes` on that zone.
  #  - `codes_crossing_zones` maps a postal code to the zone codes it spans, which becomes the
  #    country's `zips_crossing_provinces`.
  #
  # The file is edited as text, so that comments, key order and formatting stay as they are, and only
  # the two kinds of keys above change. Pass `only_show_diff: true` to leave the data file alone and
  # write the result to a temporary file instead. Returns the path of the file that was written.
  def write_yaml(country, codes_crossing_zones: nil, zones: nil, only_show_diff: false)
    file_path = File.join(Worldwide::Paths::REGIONS_ROOT, "#{country}.yml")
    original = File.read(file_path)
    lines = original.lines

    lines = replace_zone_prefixes(lines, zones, country) if zones
    lines = replace_zips_crossing_provinces(lines, codes_crossing_zones) if codes_crossing_zones

    updated = lines.join
    verify_yaml_changes!(original, updated, zones: zones, codes_crossing_zones: codes_crossing_zones)

    target_path = only_show_diff ? File.join(Dir.tmpdir, "worldwide-postal-#{country}.yml") : file_path
    File.write(target_path, updated)

    # Uncomment to see changes
    # check_diff_yaml(file_path, target_path, country) if only_show_diff

    target_path
  end

  private

  def replace_zone_prefixes(lines, zones, country)
    zones_start = lines.index(ZONES_KEY_LINE)
    raise "No zones found in #{country}.yml" if zones_start.nil?

    unmatched = zones.keys.map(&:to_s)

    zone_ranges(lines, zones_start).reverse_each do |range|
      zone_code = YAML.safe_load(lines[range].join).first["code"]
      prefixes = zones[zone_code.to_s.to_sym]
      next if prefixes.nil?

      unmatched.delete(zone_code.to_s)
      zone_lines = lines[range]
      lines[range] = with_zip_prefixes(zone_lines, prefixes.map(&:to_s).sort)
    end

    warn("No zone with these codes in #{country}.yml, so their prefixes were not written: #{unmatched.join(", ")}") unless unmatched.empty?

    lines
  end

  # Each range covers one zone, from its "- " line to its last line that is not a trailing comment.
  def zone_ranges(lines, zones_start)
    starts = []
    section_end = lines.size
    ((zones_start + 1)...lines.size).each do |index|
      line = lines[index]
      if line.start_with?("- ")
        starts << index
      elsif line.match?(/\A[^\s#-]/)
        section_end = index
        break
      end
    end

    starts.each_with_index.map do |start, i|
      stop = i + 1 < starts.size ? starts[i + 1] : section_end
      stop -= 1 while stop > start + 1 && lines[stop - 1].match?(/\A(#.*)?\s*\z/)
      start...stop
    end
  end

  # The items keep the indentation that the file already uses under the key. Region files indent them
  # by two spaces, except for ES.yml, which uses four.
  def with_zip_prefixes(zone_lines, prefixes)
    key_index = zone_lines.index { |line| line.match?(ZIP_PREFIXES_LINE) }

    if key_index.nil?
      zone_lines = zone_lines.dup
      zone_lines[-1] = "#{zone_lines.last.chomp}\n"
      return zone_lines + zip_prefixes_block(prefixes, "  ")
    end

    stop = key_index + 1
    stop += 1 while stop < zone_lines.size && zone_lines[stop].match?(PREFIX_BLOCK_LINE)
    stop -= 1 while stop > key_index + 1 && zone_lines[stop - 1].match?(COMMENT_LINE)

    item_indent = zone_lines[key_index...stop].filter_map { |line| line[PREFIX_ITEM_INDENT, 1] }.first || "  "

    zone_lines[0...key_index] + zip_prefixes_block(prefixes, item_indent) + zone_lines[stop..]
  end

  def zip_prefixes_block(prefixes, item_indent)
    yaml_block("zip_prefixes", prefixes).each_with_index.map do |line, index|
      index.zero? ? "  #{line}" : "#{item_indent}#{line}"
    end
  end

  def replace_zips_crossing_provinces(lines, codes_crossing_zones)
    normalized = codes_crossing_zones.to_h { |zip, zone_codes| [zip.to_s, zone_codes.map(&:to_s)] }
    block = yaml_block("zips_crossing_provinces", normalized)
    key_index = lines.index { |line| line.match?(CROSSING_KEY_LINE) }

    if key_index.nil?
      lines = lines.dup
      lines[-1] = "#{lines.last.chomp}\n" unless lines.empty?
      return lines + block
    end

    stop = key_index + 1
    stop += 1 while stop < lines.size && lines[stop].match?(/\A\s/)

    lines[0...key_index] + block + lines[stop..]
  end

  def yaml_block(key, value)
    { key => value }.to_yaml.lines.drop(1)
  end

  # The text edit must change nothing but the requested keys. Compare the parsed result with the
  # parsed original, plus the requested changes, to catch a mistake before the file is written.
  def verify_yaml_changes!(original, updated, zones:, codes_crossing_zones:)
    expected = YAML.safe_load(original)

    zones&.each do |zone_code, prefixes|
      zone = expected["zones"].find { |candidate| candidate["code"].to_s == zone_code.to_s }
      zone["zip_prefixes"] = prefixes.map(&:to_s).sort if zone
    end

    if codes_crossing_zones
      expected["zips_crossing_provinces"] = codes_crossing_zones.to_h { |zip, codes| [zip.to_s, codes.map(&:to_s)] }
    end

    return if YAML.safe_load(updated) == expected

    raise "Editing the region file would change more than the postal code data. Nothing was written."
  end

  # This method was written strictly for testing the current implementation. Use it if you're wanting to add in a new
  # country to be mapped to check for validity in the values returned from geonames.
  def check_diff_yaml(old_yaml_path, new_yaml_path, country)
    old_yaml = YAML.load_file(old_yaml_path)
    new_yaml = YAML.load_file(new_yaml_path)
    puts "\nLINES THAT HAVE CHANGED:"
    old_yaml["zones"].each_with_index do |zone, i|
      if zone["zip_prefixes"] != new_yaml["zones"][i]["zip_prefixes"]
        previous_data = zone["zip_prefixes"].nil? ? "nil." : zone["zip_prefixes"]
        puts "#{country}.'#{zone["name"]}':\nOLD: #{previous_data}\n-----\nNEW: #{new_yaml["zones"][i]["zip_prefixes"]}\n\n"
      end
    end
  end

  def cleanup
    vendor_path = File.join(__dir__, "vendor")
    FileUtils.remove_dir(vendor_path) if File.directory?(vendor_path)
  end
end
