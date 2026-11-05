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
  spec.description   = "The worldwide gem internationalizes and localizes Ruby code, enhancing user experience globally. It also aids in inputting, validating, and formatting mailing addresses."
  spec.homepage      = "https://github.com/Shopify/worldwide"

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"
  spec.metadata["changelog_uri"] = "https://github.com/Shopify/worldwide/blob/main/CHANGELOG.md"

  spec.files = %x(git ls-files -z).split("\x0").reject do |f|
    f.match(%r{^(rake|test|spec|features|lang/typescript)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependabot resolves the bundle with the lowest Ruby this allows. Some dev
  # gems need a newer Ruby and are held back for that reason. When you raise
  # this floor, also remove:
  #   - the pry-byebug `ignore` rule in .github/dependabot.yml
  #   - the pry-byebug "< 3.12" cap in Gemfile
  spec.required_ruby_version = ">= 3.1.0"

  spec.add_dependency("activesupport", ">= 7.0")
  spec.add_dependency("i18n", ">= 1.15")
  spec.add_dependency("phonelib", "~> 0.8")
end
