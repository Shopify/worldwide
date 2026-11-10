# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"
require "tmpdir"

module Worldwide
  class PhonelibDependencyTest < ActiveSupport::TestCase
    test "phonelib is not a runtime dependency" do
      specification = Gem::Specification.load(File.expand_path("../../worldwide.gemspec", __dir__))

      refute_includes specification.runtime_dependencies.map(&:name), "phonelib"
    end

    test "subprocesses support Bundler specifications without a gemspec file" do
      # Bundler can provide a synthetic specification whose loaded_from is a directory.
      Gem.loaded_specs.fetch("bundler").stubs(:loaded_from).returns(__dir__)

      assert_ruby(<<~RUBY)
        require "worldwide"
        phone = Worldwide::Phone.new(number: "6135551212", country_code: "CA")
        raise "Phone parsing failed" unless phone.valid? && phone.e164 == "+16135551212"
      RUBY
    end

    test "phonelib is loaded on first use even if its namespace already exists" do
      assert_ruby(<<~RUBY)
        require "worldwide"
        raise "Phonelib loaded eagerly" if defined?(Phonelib)

        module Phonelib
        end

        phone = Worldwide::Phone.new(number: "6135551212", country_code: "CA")
        raise "Phone parsing failed" unless phone.valid? && phone.e164 == "+16135551212"
      RUBY
    end

    test "worldwide loads and formats addresses without phonelib but phone features explain its absence" do
      assert_ruby(<<~RUBY, without_phonelib: true)
        require "worldwide"
        raise "Phonelib loaded eagerly" if defined?(Phonelib)
        raise "Region lookup failed" unless Worldwide.region(code: "JP").full_name(locale: :en) == "Japan"

        address = Worldwide.address(country_code: "CA", province_code: "ON", city: "Ottawa",
          zip: "K1A 0A6", address1: "1 Main St", phone: "6135551212")
        raise "Address formatting failed" unless address.format.include?("1 Main St")

        operations = [
          -> { Worldwide::Phone.new(number: "6135551212", country_code: "CA") },
          -> { address.normalize },
          -> { address.errors },
          -> { address.valid? },
          -> { Worldwide::AddressValidator.errors(address) },
          -> { Worldwide::AddressValidator.valid?(address) },
          -> { Worldwide.address(country_code: "CA").normalize },
        ]

        operations.each do |operation|
          begin
            operation.call
          rescue LoadError => error
            raise unless error.message.include?('Add gem "phonelib", "~> 0.8" to your Gemfile.')
            next
          end
          raise "A phone feature unexpectedly worked without phonelib"
        end
      RUBY
    end

    test "load errors inside phonelib retain their original cause" do
      Dir.mktmpdir do |directory|
        File.write(File.join(directory, "phonelib.rb"), 'require "worldwide_phonelib_missing_dependency"')

        assert_ruby(<<~RUBY, extra_load_path: directory)
          require "worldwide"

          begin
            Worldwide::Phone.new(number: "6135551212", country_code: "CA")
          rescue LoadError => error
            raise unless error.path == "worldwide_phonelib_missing_dependency"
            exit
          end
          raise "Expected phonelib's missing dependency to raise LoadError"
        RUBY
      end
    end

    test "incompatible phonelib versions explain the required version" do
      assert_ruby(<<~RUBY)
        Gem::Specification.find_by_name("phonelib").version = "1.0.0"
        require "worldwide"

        begin
          Worldwide::Phone.new(number: "6135551212", country_code: "CA")
        rescue LoadError => error
          raise unless error.message.include?('Add gem "phonelib", "~> 0.8" to your Gemfile.')
          exit
        end
        raise "Expected an incompatible phonelib version to raise LoadError"
      RUBY
    end

    private

    def assert_ruby(source, without_phonelib: false, extra_load_path: nil)
      specifications = Gem.loaded_specs.values
      specifications = specifications.reject { |specification| specification.name == "phonelib" } if without_phonelib
      load_paths = specifications.flat_map(&:full_require_paths)
      load_paths << File.expand_path("../../lib", __dir__)
      load_paths.unshift(extra_load_path) if extra_load_path

      # Limit gem activation to these specifications so excluded gems cannot be found elsewhere on the machine.
      source = <<~RUBY + source
        require "rubygems"
        # Synthetic Bundler specifications do not have a gemspec file to reload.
        specifications = #{specifications.map(&:loaded_from).inspect}.filter_map do |path|
          Gem::Specification.load(path)
        end
        Gem::Specification.all = (specifications + Gem::Specification.default_stubs.map(&:to_spec)).uniq(&:name)
      RUBY

      stdout, stderr, status = Open3.capture3(
        { "RUBYOPT" => nil, "RUBYLIB" => nil, "BUNDLER_SETUP" => nil },
        RbConfig.ruby,
        "--disable-gems",
        "-I",
        load_paths.join(File::PATH_SEPARATOR),
        "-e",
        source,
      )

      assert_predicate(status, :success?, "#{stdout}\n#{stderr}")
    end
  end
end
