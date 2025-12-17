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

    Runs single-threaded with verbose logging to make errors easier to trace.
    Automatically identifies which locale caused the panic.

    eg.: bundle exec rake icu4x:datagen:debug
  DESCRIPTION
  task "datagen:debug" do
    require "fileutils"
    require "open3"

    datagen_dir = File.join("lang", "rust", "worldwide-icu4x-datagen")
    unless File.exist?(File.join(datagen_dir, "Cargo.toml"))
      raise "Datagen crate not found at #{datagen_dir}"
    end

    puts "🦀 Running Rust datagen tool in DEBUG mode (aborts on first panic)..."
    puts "📊 Debug mode: RUST_BACKTRACE=full RUST_LOG=debug RAYON_NUM_THREADS=1"
    puts "⚠️  Using debug build (no --release) to enable panic abort"
    puts ""

    last_locale_files = []
    exit_status = nil

    Dir.chdir(datagen_dir) do
      Open3.popen3(
        {
          "RUST_BACKTRACE" => "full",
          "RUST_LOG" => "debug",
          "RAYON_NUM_THREADS" => "1"
        },
        "cargo run --verbose"
      ) do |stdin, stdout, stderr, wait_thr|
        stdin.close

        # Read stderr in a separate thread to capture debug logs
        stderr_thread = Thread.new do
          stderr.each_line do |line|
            # Capture last few locale files being read
            if line =~ /Reading: <zip>\/(.+?\.json)/
              locale_file = $1
              last_locale_files << locale_file
              last_locale_files.shift if last_locale_files.size > 10
            end
            $stderr.puts line
          end
        end

        # Forward stdout
        stdout.each_line do |line|
          $stdout.puts line
        end

        stderr_thread.join
        exit_status = wait_thr.value
      end
    end

    unless exit_status.success?
      puts ""
      puts "=" * 80
      puts "🛑 DATAGEN FAILED"
      puts "=" * 80
      puts ""

      if last_locale_files.any?
        puts "📍 Last locales/files read before panic:"
        last_locale_files.last(5).each do |file|
          puts "   - #{file}"
        end
        puts ""
        puts "💡 The problematic locale is likely: #{last_locale_files.last}"
        puts ""

        # Extract locale from path
        if last_locale_files.last =~ /\/main\/([^\/]+)\//
          locale = $1
          puts "🔍 Suggested next step:"
          puts "   Inspect data/cldr/locales/#{locale}/calendars.yml"
          puts "   Look for mixed hour cycle types (h vs HH, K vs k)"
        end
      else
        puts "⚠️  Could not identify problematic locale from output"
      end

      puts ""
      raise "Datagen failed - see output above for details"
    end

    puts "✅ ICU4X blob generated"
  end

  desc <<~DESCRIPTION
    Full ICU4X data pipeline: convert YAML to JSON, then generate blob.

    eg.: bundle exec rake icu4x:all
  DESCRIPTION
  task :all => [:convert, :generate]
end
