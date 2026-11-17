# frozen_string_literal: true

require "fileutils"
require "tmpdir"

module Worldwide
  module BundledDataTestHelper
    # A host backend that holds only what a test stores in it, and never reads I18n.load_path.
    class HostBackend < I18n::Backend::Simple
      def initialized?
        true
      end
    end

    # Values that differ from Worldwide's data, as a host application's own translations can.
    HOST_TRANSLATIONS = {
      de: {
        numbers: { latn: { symbols: { decimal: "HOST-DECIMAL" } } },
        lists: { or: { "2": "HOST {0} {1}" } },
      },
      en: {
        currencies: {
          EUR: { narrow_symbol: "HOST-€", symbol: "HOST-€", one: "host euro", other: "host euros", name: "Host Euro" },
        },
        date_time_translation: { today_at_time: "HOST today" },
        languages: { fr: "HOST French" },
      },
      fr: {
        languages: { fr: "HOST français" },
        numbers: { latn: { symbols: { group: "_" } } },
      },
      pl: {
        numbers: { latn: { symbols: { group: "HOST" } }, minimum_grouping_digits: 1 },
      },
    }.freeze

    private

    # Puts a backend holding translations in front of the host's own backend while the block runs.
    def with_host_overrides(translations = HOST_TRANSLATIONS)
      host = HostBackend.new
      translations.each { |locale, data| host.store_translations(locale, data) }
      original_backend = I18n.backend
      # I18n::Backend::Simple reads its files on first use, once in each thread that finds them unread,
      # so read them here rather than in every thread that a test starts.
      original_backend.translations(do_init: true) if original_backend.is_a?(I18n::Backend::Simple)
      I18n.backend = I18n::Backend::Chain.new(host, original_backend)
      yield
    ensure
      I18n.backend = original_backend
    end

    # Changes the host's I18n settings while the block runs.
    def with_host_i18n(available_locales: nil, enforce_available_locales: nil, default_locale: nil)
      original = [I18n.available_locales, I18n.enforce_available_locales, I18n.default_locale]
      I18n.available_locales = available_locales if available_locales
      I18n.enforce_available_locales = enforce_available_locales unless enforce_available_locales.nil?
      I18n.default_locale = default_locale if default_locale
      yield
    ensure
      I18n.available_locales, I18n.enforce_available_locales, I18n.default_locale = original if original
    end

    # Runs the block with the host's interpolation settings changed, and restores them afterwards.
    def with_host_interpolation(patterns:, missing_argument_handler:)
      original = [I18n.config.interpolation_patterns, I18n.config.missing_interpolation_argument_handler]
      I18n.config.interpolation_patterns = patterns
      I18n.config.missing_interpolation_argument_handler = missing_argument_handler
      yield
    ensure
      I18n.config.interpolation_patterns, I18n.config.missing_interpolation_argument_handler = original
    end

    # Runs the block with a fresh bundled data source in place of the process-wide one, so that a test
    # can register files and inspect what was loaded without affecting other tests.
    def with_fresh_bundled_data(**options)
      source = Worldwide::Cldr::BundledData.new(**options)
      Worldwide::Cldr::BundledData.stubs(:instance).returns(source)
      yield source
    end

    # Writes YAML files into a temporary directory and yields their paths.
    # files maps a file name to the data it holds, with String keys, or to the YAML text to write.
    def with_yaml_files(files)
      Dir.mktmpdir("worldwide-bundled-data") do |directory|
        paths = files.map do |name, data|
          path = File.join(directory, name)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, data.is_a?(String) ? data : YAML.dump(data))
          path
        end
        yield paths, directory
      end
    end
  end
end
