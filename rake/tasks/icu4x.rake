# frozen_string_literal: true

namespace :icu4x do
  desc <<~DESCRIPTION
    Generate ICU4X data blob from worldwide's patched CLDR data.

    This task runs the Rust datagen tool which:
    1. Converts YAML CLDR data to CLDR JSON format
    2. Generates ICU4X postcard blob

    Requires Rust toolchain.
    Output: lang/rust/worldwide-icu4x-data/data/icu4x.postcard

    eg.: bundle exec rake icu4x:generate
  DESCRIPTION
  task :generate do
    unless File.exist?("Cargo.toml")
      raise "Cargo.toml not found at repo root"
    end

    puts "🦀 Running Rust datagen tool..."
    system({ "RUST_LOG" => "info" }, "cargo run --release -p worldwide-icu4x-datagen", exception: true)

    puts "✅ ICU4X blob generated"
  end

  desc <<~DESCRIPTION
    Run ICU4X datagen with full backtrace (for debugging).

    Runs single-threaded with verbose logging to make errors easier to trace.

    eg.: bundle exec rake icu4x:datagen:debug
  DESCRIPTION
  task "datagen:debug" do
    require "open3"

    unless File.exist?("Cargo.toml")
      raise "Cargo.toml not found at repo root"
    end

    puts "🦀 Running Rust datagen tool in DEBUG mode..."
    puts "📊 Debug mode: RUST_BACKTRACE=full RUST_LOG=debug RAYON_NUM_THREADS=1"
    puts ""

    exit_status = nil

    Open3.popen3(
      {
        "RUST_BACKTRACE" => "full",
        "RUST_LOG" => "debug",
        "RAYON_NUM_THREADS" => "1",
      },
      "cargo run -p worldwide-icu4x-datagen",
    ) do |stdin, stdout, stderr, wait_thr|
      stdin.close

      stderr_thread = Thread.new do
        stderr.each_line { |line| $stderr.puts line }
      end

      stdout.each_line { |line| $stdout.puts line }

      stderr_thread.join
      exit_status = wait_thr.value
    end

    unless exit_status.success?
      puts ""
      puts "=" * 80
      puts "🛑 DATAGEN FAILED"
      puts "=" * 80
      raise "Datagen failed - see output above for details"
    end

    puts "✅ ICU4X blob generated"
  end

  # Alias for backwards compatibility
  task all: :generate
  task datagen: :generate
  task convert: :generate
end
