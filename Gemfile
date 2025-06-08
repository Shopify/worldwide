# frozen_string_literal: true

source "https://rubygems.org"

# The current latest released version of ruby-cldr is v0.5.0 from November 2020.
# We need a newer version to cope with more recent releases of CLDR.
gem "ruby-cldr", git: "https://github.com/ruby-i18n/ruby-cldr.git", ref: "86a5d7b84ddb1b59a792d7ba4b93b927bc7f3406"

# Specify your gem's dependencies in worldwide.gemspec
gemspec

group :development do
  gem "minitest-focus", require: false
  gem "rake-compiler"
  gem "rake", "~> 13.0"
  gem "rubocop-minitest", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-shopify", require: false
  gem "rubocop", require: false
  gem "ruby-lsp", require: false
  gem "debug", require: false
end

group :test do
  gem "minitest", "~> 5.0"
  gem "minitest-reporters"
  gem "mocha"
end
