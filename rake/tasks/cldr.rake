# frozen_string_literal: false

require_relative "../cldr/locale_generator"
require_relative "../cldr/patch"
require_relative "../cldr/puller"
require_relative "../cldr/cleaner"

namespace :cldr do
  namespace :data do
    desc <<~DESCRIPTION
      Cleans up the pre-existing data in preparation for an upgrade to a new version of CLDR.
      Necessary, since some of the files may no longer be needed in the new version.

      eg.: bundle exec rake cldr:data:clean
    DESCRIPTION
    task :clean do
      Worldwide::Cldr::Cleaner.perform
    end

    desc <<~DESCRIPTION
      Downloads and exports the data from CLDR (http://cldr.unicode.org)

      The `VERSION` environment variable can be used to specify the version of CLDR to download (see the current version
      in data/cldr/versions.yml).

      eg.: Download v40 of CLDR and export all components
        bundle exec rake cldr:data:import VERSION=40

      eg.: Download v40 of CLDR and export the `Units` and `Calendars` components
        bundle exec rake cldr:data:import VERSION=40 COMPONENTS=Units,Calendars

      eg.: Download the CLDR data from latest commit of https://github.com/unicode-org/cldr-staging and export all components
        bundle exec rake cldr:data:import
    DESCRIPTION
    task :import, :environment do
      version = ENV["VERSION"]
      components = ENV["COMPONENTS"]
      Worldwide::Cldr::Puller.perform(version, components)
    end

    desc <<~DESCRIPTION
      Apply Shopify patches to the upstream CLDR data

      This task depends on the data in `vendor/ruby-cldr`, so you should run `rake cldr:data:import` first.

      eg.: bundle exec rake cldr:data:patch
    DESCRIPTION
    task :patch do
      Worldwide::Cldr::Patch::Patcher.new.perform
    end

    desc <<~DESCRIPTION
      Generate indices of files in the CLDR data

      This task generates a list of all files in the CLDR data, which is used to speed up the loading of the data.

      eg.: bundle exec rake cldr:data:generate_paths
    DESCRIPTION
    task :generate_paths do
      cldr_locale_paths = Dir[File.join(Worldwide::Paths::CLDR_ROOT, "locales", "*", "*.{yml,rb}")].map do |path|
        path.delete_prefix(Worldwide::Paths::GEM_ROOT)
      end
      File.write(Worldwide::Paths::CLDR_LOCALE_PATHS_FILE, cldr_locale_paths.join("\n"))

      other_data_paths = Dir[File.join(Worldwide::Paths::OTHER_DATA_ROOT, "*", "*.{yml,rb}")].map do |path|
        path.delete_prefix(Worldwide::Paths::GEM_ROOT)
      end
      File.write(Worldwide::Paths::OTHER_DATA_PATHS_FILE, other_data_paths.join("\n"))

      region_data_paths = Dir[File.join(Worldwide::Paths::REGIONS_ROOT, "*", "*.{yml}")].map do |path|
        path.delete_prefix(Worldwide::Paths::GEM_ROOT)
      end
      File.write(Worldwide::Paths::REGION_DATA_PATHS_FILE, region_data_paths.join("\n"))
    end

    desc <<~DESCRIPTION
      Generate additional data from the CLDR data, including missing plurals.

      Run this after importing and patching data from CLDR.

      eg.: bundle exec rake cldr:data:generate
    DESCRIPTION
    task :generate do
      generator = Worldwide::Cldr::LocaleGenerator.new
      generator.perform
    end
  end
end
