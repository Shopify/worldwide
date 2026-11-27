# frozen_string_literal: true

require "test_helper"
require "json_schemer"
require "tmpdir"
require_relative "../../../rake/structured_addresses/exporter"

# Conformance: the artifact this gem's data generates must match the published schema, be
# deterministic, and keep the invariants the schema cannot express. No artifact is committed;
# this test is what keeps the data and the contract from drifting.
class StructuredAddressesExporterTest < Minitest::Test
  RELEASE = "2026-01-01"

  def setup
    @artifact ||= self.class.artifact
  end

  class << self
    def artifact
      @artifact ||= Worldwide::StructuredAddresses::Exporter.new(release: RELEASE).export
    end

    def schema
      @schema ||= JSONSchemer.schema(
        Pathname.new(File.join(Worldwide::Paths::GEM_ROOT, "schema", Worldwide::StructuredAddresses::SCHEMA_FILE)),
      )
    end
  end

  def test_artifact_validates_against_the_schema
    errors = self.class.schema.validate(JSON.parse(JSON.generate(@artifact))).first(5).to_a

    assert_empty(errors.map { |e| "#{e["data_pointer"]}: #{e["type"]}" })
  end

  def test_schema_version_matches_the_schema_file
    assert_equal(Worldwide::StructuredAddresses::SCHEMA_VERSION, self.class.schema.value.dig("properties", "schemaVersion", "const"))
  end

  def test_export_is_deterministic
    again = Worldwide::StructuredAddresses::Exporter.new(release: RELEASE).export

    assert_equal(Worldwide::StructuredAddresses.artifact_json(@artifact), Worldwide::StructuredAddresses.artifact_json(again))
  end

  def test_covers_every_non_deprecated_country_once
    codes = @artifact[:countries].map { |c| c[:code] }

    assert_equal(Worldwide::StructuredAddresses::Exporter.country_codes, codes)
    assert_equal(codes.uniq, codes)
    refute_includes(codes, "AN")
  end

  def test_structured_coverage_is_exactly_the_regions_with_a_structured_layout
    expected = Worldwide::Regions.all.select(&:country?).reject(&:deprecated?)
      .select { |r| r.format_structured && !r.format_structured.empty? }.map(&:iso_code).sort

    assert_equal(expected, @artifact[:countries].select { |c| c[:coverage] == "structured" }.map { |c| c[:code] })
    @artifact[:countries].each do |c|
      assert_equal(c[:coverage] == "structured", !c[:layouts][:edit][:structured].nil?, c[:code])
      assert_equal(c[:coverage] == "structured", !c[:layouts][:show][:structured].nil?, c[:code])
    end
  end

  def test_every_field_has_a_requirement_and_every_layout_key_is_a_field
    @artifact[:countries].each do |c|
      keys = c[:fields].map { |f| f[:key] }

      assert_equal(keys.uniq, keys, c[:code])
      c[:fields].each { |f| assert_includes(Worldwide::StructuredAddresses::REQUIREMENT_VALUES, f[:requirement], "#{c[:code]}.#{f[:key]}") }
      c[:layouts].each_value do |by_shape|
        by_shape.each_value do |rows|
          next if rows.nil?

          used = rows.flatten.grep(String)

          assert_equal(used.uniq, used, c[:code])
          assert_empty(used - keys, c[:code])
          refute_includes(used, "postalCode", c[:code]) unless c[:postalCode][:used]
        end
      end
    end
  end

  def test_contextual_is_exactly_company_and_phone
    @artifact[:countries].each do |c|
      contextual = c[:fields].select { |f| f[:requirement] == "contextual" }.map { |f| f[:key] }.sort
      present = c[:fields].map { |f| f[:key] } & ["company", "phone"]

      assert_equal(present.sort, contextual, c[:code])
    end
  end

  def test_requirement_reads_region_data
    br = country("BR")

    assert_equal("required", requirement(br, "district"))
    assert_equal("optional", requirement(br, "additionalInformation"))
    assert_equal("optional", requirement(country("NZ"), "provinceCode"))
    assert_equal("required", requirement(country("US"), "postalCode"))
    assert_nil(country("HK")[:fields].find { |f| f[:key] == "postalCode" })
  end

  def test_show_rows_round_trip_to_the_source_format_strings
    exporter = Worldwide::StructuredAddresses::Exporter.new(release: RELEASE)
    inverse = Worldwide::StructuredAddresses::TOKEN_TO_KEY.invert
    Worldwide::Regions.all.select(&:country?).reject(&:deprecated?).each do |region|
      [region.format["show"], region.format_structured["show"]].compact.reject(&:empty?).each do |source|
        rows = exporter.send(:show_rows, source)
        rendered = rows.map do |row|
          row.each_with_index.map do |e, i|
            next e[:text] if e.is_a?(Hash)

            (i > 0 && row[i - 1].is_a?(String) ? " " : "") + "{#{inverse.fetch(e, e)}}"
          end.join
        end.join("_")

        assert_equal(source, rendered, region.iso_code)
      end
    end
  end

  def test_only_japan_and_uruguay_carry_literal_text_in_show
    with_text = @artifact[:countries].select do |c|
      c[:layouts][:show].values.compact.flatten.any?(Hash)
    end

    assert_equal(["JP", "UY"], with_text.map { |c| c[:code] })
    jp = country("JP")[:layouts][:show][:flat]

    assert_equal(["countryCode", { text: " 〒" }, "postalCode"], jp.first)
    assert_equal(["lastName", "firstName", { text: "様" }], jp[5])
  end

  def test_show_can_list_a_field_edit_does_not_collect
    gi = country("GI")

    refute_includes(gi[:layouts][:edit][:flat].flatten, "postalCode")
    assert_includes(gi[:layouts][:show][:flat].flatten, "postalCode")
    assert_includes(gi[:fields].map { |f| f[:key] }, "postalCode")
  end

  def test_rejects_unknown_tokens_and_rows_without_fields
    exporter = Worldwide::StructuredAddresses::Exporter.new(release: RELEASE)
    assert_raises(Worldwide::StructuredAddresses::LayoutError) { exporter.send(:edit_rows, "{firstName}{nope}") }
    assert_raises(Worldwide::StructuredAddresses::LayoutError) { exporter.send(:show_rows, "{firstName}_hello") }
  end

  def test_release_must_be_a_date
    assert_raises(ArgumentError) { Worldwide::StructuredAddresses::Exporter.new(release: "v1") }
    Worldwide::StructuredAddresses::Exporter.new(release: "2026-01-01.2")
  end

  def test_write_produces_artifact_manifest_and_schema_with_matching_digest
    Dir.mktmpdir do |dir|
      Worldwide::StructuredAddresses.write(dir, release: RELEASE, commit: "abc1234")
      artifact = File.read(File.join(dir, "structured-addresses.json"))
      manifest = JSON.parse(File.read(File.join(dir, "manifest.json")))

      assert_equal(Digest::SHA256.hexdigest(artifact), manifest.dig("artifact", "sha256"))
      assert_equal(RELEASE, manifest["release"])
      assert_equal(Worldwide::VERSION, manifest.dig("sources", "worldwide", "version"))
      assert_equal("abc1234", manifest.dig("sources", "worldwide", "commit"))
      assert_path_exists(File.join(dir, "structured-addresses.schema.json"))
    end
  end

  def test_configure_i18n_is_idempotent
    before = I18n.load_path.size
    Worldwide::Config.configure_i18n

    assert_equal(before, I18n.load_path.size)
  end

  private

  def country(code)
    @artifact[:countries].find { |c| c[:code] == code }
  end

  def requirement(country, key)
    country[:fields].find { |f| f[:key] == key }[:requirement]
  end
end
