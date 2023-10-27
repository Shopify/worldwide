# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "worldwide/version"

Gem::Specification.new do |spec|
  spec.name          = "worldwide"
  spec.version       = Worldwide::VERSION
  spec.author        = "Shopify"
  spec.email         = "developers@shopify.com"

  spec.summary       = "Internationalization and localization APIs"
  spec.description   = "APIs for I18n, I10n, and mailing address operations in Ruby."
  spec.homepage      = "https://github.com/Shopify/worldwide"

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.files = %x(git ls-files -z).split("\x0").reject do |f|
    f.match(%r{^(rake|test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0.0"

  spec.add_dependency("activesupport", "~> 7.0")
  spec.add_dependency("i18n", "~> 1.12.0")
  spec.add_dependency("phonelib", "~> 0.8")
end
