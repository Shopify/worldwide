# frozen_string_literal: true

require_relative "../icu4x/json_exporter"

namespace :icu4x do
  desc <<~DESCRIPTION
    Convert patched CLDR YAML data to CLDR JSON format for icu_datagen.
    
    This task transforms worldwide's patched CLDR data from YAML to JSON,
    following the CLDR JSON schema expected by icu_datagen.
    
    Output: vendor/cldr-json/
    
    eg.: bundle exec rake icu4x:convert
  DESCRIPTION
  task :convert do
    Worldwide::Icu4x::JsonExporter.perform
  end

  desc <<~DESCRIPTION
    Generate ICU4X data blob from CLDR JSON.
    
    This task runs the Rust datagen tool to produce a postcard-serialized
    blob from the CLDR JSON data. Requires Rust toolchain.
    
    Depends on: icu4x:convert
    Output: lang/rust/worldwide-icu4x-data/data/icu4x.postcard
    
    eg.: bundle exec rake icu4x:generate
  DESCRIPTION
  task :generate => :convert do
    require "fileutils"
    
    datagen_dir = File.join("lang", "rust", "worldwide-icu4x-datagen")
    unless File.exist?(File.join(datagen_dir, "Cargo.toml"))
      raise "Datagen crate not found at #{datagen_dir}. Run Phase 2 setup first."
    end

    puts "🦀 Running Rust datagen tool..."
    Dir.chdir(datagen_dir) do
      system("cargo run --release", exception: true)
    end

    puts "✅ ICU4X blob generated"
  end

  desc <<~DESCRIPTION
    Run Rust datagen directly (without convert step).

    Useful for debugging datagen issues with existing CLDR JSON.

    eg.: bundle exec rake icu4x:datagen
  DESCRIPTION
  task :datagen do
    require "fileutils"

    datagen_dir = File.join("lang", "rust", "worldwide-icu4x-datagen")
    unless File.exist?(File.join(datagen_dir, "Cargo.toml"))
      raise "Datagen crate not found at #{datagen_dir}"
    end

    puts "🦀 Running Rust datagen tool..."
    Dir.chdir(datagen_dir) do
      system("cargo run --release", exception: true)
    end

    puts "✅ ICU4X blob generated"
  end

  desc <<~DESCRIPTION
    Run Rust datagen with full backtrace (for debugging).

    eg.: bundle exec rake icu4x:datagen:debug
  DESCRIPTION
  task "datagen:debug" do
    require "fileutils"

    datagen_dir = File.join("lang", "rust", "worldwide-icu4x-datagen")
    unless File.exist?(File.join(datagen_dir, "Cargo.toml"))
      raise "Datagen crate not found at #{datagen_dir}"
    end

    puts "🦀 Running Rust datagen tool with full backtrace..."
    Dir.chdir(datagen_dir) do
      system({"RUST_BACKTRACE" => "full"}, "cargo run --release", exception: false)
    end
  end

  desc <<~DESCRIPTION
    Full ICU4X data pipeline: convert YAML to JSON, then generate blob.

    eg.: bundle exec rake icu4x:all
  DESCRIPTION
  task :all => [:convert, :generate]
end
