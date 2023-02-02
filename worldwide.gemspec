# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "worldwide/version"

Gem::Specification.new do |spec|
  spec.name          = "worldwide"
  spec.version       = Worldwide::VERSION
  spec.authors       = ["Christian Jaekl", "Michael Overmeyer"]
  spec.email         = ["christian.jaekl@shopify.com"]

  spec.summary       = "Internationalization and localization APIs"
  spec.description   = "APIs to support i18n and l10n of Ruby code"
  spec.homepage      = "https://github.com/Shopify/worldwide"

  spec.files         = %x(git ls-files -z).split("\x0").reject do |f|
    f.match(%r{^(rake|test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0.0"

  spec.add_dependency("activesupport", ">= 5.0")
  spec.add_dependency("i18n", ">= 1.12")
  spec.add_dependency("phonelib")
end
