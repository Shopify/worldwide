# frozen_string_literal: true

# Tools that build the postal code prefix data in data/regions/<CC>.yml. See rake/postal/README.md.

namespace :postal do
  namespace :codes do
    desc "Report on postal code validation pass/fails, e.g.: `postal:codes:check[CA.csv]`"
    task :check, [:file_name] do |_t, args|
      if args.file_name.nil?
        raise "You must specify a filename."
      end

      require_relative "../postal/checker"

      checker = Postal::Checker.new
      checker.examine(args.file_name)
    end

    desc "Import postal codes from geonames.org, e.g.: `postal:codes:import[PT]`"
    task :import, [:country] do |_t, args|
      if args.country.nil?
        raise "You must specify a country, e.g.: `rake postal:codes:import[PT]`"
      end

      require_relative "../postal/codes"

      codes = Postal::Codes.new
      codes.import(args.country)
    end

    desc "Report otherwise-valid codes that aren't allowed in the zone they're in."
    task :zone_check, [:file_name] do |_t, args|
      if args.file_name.nil?
        raise "You must specify a filename"
      end

      require_relative "../postal/zone_checker"

      checker = Postal::ZoneChecker.new
      checker.examine(args.file_name)
    end
  end
end
