# frozen_string_literal: false

require "worldwide/util"

# Use these rake tasks to perform data updates (for instance, as part of a complete CLDR upgrade
# or after adding data patches in patch.rb). Tasks should be run in the order defined below.

namespace :cldr do
  namespace :data do
    desc <<~DESCRIPTION
      Cleans up the pre-existing data in preparation for an upgrade to a new version of CLDR.
      Necessary, since some of the files may no longer be needed in the new version.

      eg.: bundle exec rake cldr:data:clean
    DESCRIPTION
    task :clean do
      require_relative "../cldr/cleaner"

      Worldwide::Cldr::Cleaner.perform
    end

    desc <<~DESCRIPTION
      Downloads and exports the data from CLDR (http://cldr.unicode.org)

      The `VERSION` environment variable can be used to specify the version of CLDR to download (see the current version
      in data/cldr/versions.yml).

      eg.: Download the CLDR data for the current version specified in data/cldr.yml
        bundle exec rake cldr:data:import

      eg.: Download v40 of CLDR and export all components
        bundle exec rake cldr:data:import VERSION=40

      eg.: Download v40 of CLDR and export the `Units` and `Calendars` components
        bundle exec rake cldr:data:import VERSION=40 COMPONENTS=Units,Calendars

      eg.: Download the CLDR data from the latest commit of https://github.com/unicode-org/cldr-staging and export all components
        bundle exec rake cldr:data:import VERSION=unreleased
    DESCRIPTION
    task :import, :environment do
      require_relative "../cldr/puller"

      version = ENV["VERSION"] || YAML.load_file("data/cldr.yml")["version"]
      version = nil if version == "unreleased"

      components = ENV["COMPONENTS"]
      Worldwide::Cldr::Puller.perform(version, components)
    end

    desc <<~DESCRIPTION
      Apply Shopify patches to the upstream CLDR data

      This task depends on the data in `vendor/ruby-cldr`, so you should run `rake cldr:data:import` first.

      eg.: bundle exec rake cldr:data:patch
    DESCRIPTION
    task :patch do
      require_relative "../cldr/patch"

      Worldwide::Cldr::Patch::Patcher.new.perform
    end

    desc <<~DESCRIPTION
      Generate additional data from the CLDR data, including missing plurals.

      Run this after importing and patching data from CLDR.

      eg.: bundle exec rake cldr:data:generate
    DESCRIPTION
    task :generate do
      require_relative "../cldr/locale_generator"

      generator = Worldwide::Cldr::LocaleGenerator.new
      generator.perform
    end

    desc <<~DESCRIPTION
      Generate indices of files in the CLDR data

      This task generates a list of all files in the CLDR data, which is used to speed up the loading of the data.

      eg.: bundle exec rake cldr:data:generate_paths
    DESCRIPTION
    task :generate_paths do
      require_relative "../paths/generator"

      Worldwide::Paths::Generator.new.perform
    end
  end
end
