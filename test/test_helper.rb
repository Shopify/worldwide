# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "worldwide"

require "active_support"
require "minitest/autorun"
require "minitest/reporters"
require "minitest/focus" unless ENV["CI"]
require "mocha/minitest"
require "debug"

# All the locales used in the tests
I18n.available_locales = Worldwide::Locales.known

Worldwide::Config.configure_i18n

Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new)
