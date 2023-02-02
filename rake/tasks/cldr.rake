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
    DESCRIPTION
    task :clean do
      Worldwide::Cldr::Cleaner.perform
    end

    desc <<~DESCRIPTION
      Downloads and exports the data from CLDR (http://cldr.unicode.org)

      eg.: Download v40 of CLDR and export all components
        rake cldr:data:import VERSION=40

      eg.: Download v40 of CLDR and export the `Units` and `Calendars` components
        rake cldr:data:import VERSION=40 COMPONENTS=Units,Calendars

      eg.: Download the CLDR data from latest commit of https://github.com/unicode-org/cldr-staging and export all components
        rake cldr:data:import

    DESCRIPTION
    task :import, :environment do
      version = ENV["VERSION"]
      components = ENV["COMPONENTS"]
      Worldwide::Cldr::Puller.perform(version, components)
    end

    desc <<~DESCRIPTION
      Apply Shopify patches to the upstream CLDR data

      rake cldr:data:patch
    DESCRIPTION
    task :patch do
      Worldwide::Cldr::Patch::Patcher.new.perform
    end

    desc "Generate additional data files from the CLDR data."
    task :generate do
      generator = Worldwide::Cldr::LocaleGenerator.new
      generator.perform
    end
  end
end
