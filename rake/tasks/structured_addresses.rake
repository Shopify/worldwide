# frozen_string_literal: true

namespace :structured_addresses do
  desc <<~DESCRIPTION
    Generates the Structured Addresses artifact from this gem's region data.

    Writes structured-addresses.json, manifest.json and a copy of the schema to the output
    directory (default: dist/structured-addresses, ignored by git). The artifact is not
    committed; the publish workflow generates and publishes it.

    RELEASE is the data snapshot id, a date (YYYY-MM-DD, or YYYY-MM-DD.N for a second release the
    same day). It defaults to today. COMMIT is recorded in the manifest as provenance and defaults
    to the current git commit.

    eg.: bundle exec rake structured_addresses:export
         RELEASE=2026-11-24 bundle exec rake structured_addresses:export[dist/out]
  DESCRIPTION
  task :export, [:output_dir] do |_, args|
    require_relative "../structured_addresses/exporter"
    require "fileutils"

    output_dir = args[:output_dir] || "dist/structured-addresses"
    release = ENV.fetch("RELEASE") { Time.now.utc.strftime("%Y-%m-%d") }
    commit = ENV.fetch("COMMIT") { %x(git rev-parse --short HEAD 2>/dev/null).strip.then { |c| c.empty? ? nil : c } }

    artifact = Worldwide::StructuredAddresses.write(output_dir, release: release, commit: commit)
    structured = artifact[:countries].count { |c| c[:coverage] == "structured" }
    puts "Wrote #{artifact[:countries].size} countries (#{structured} structured) to #{output_dir}/ " \
      "(schema #{artifact[:schemaVersion]}, release #{release})"
  end
end
