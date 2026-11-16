# Postal code rake tasks

These tasks build and check the postal code prefix data in `data/regions/<CC>.yml`: the `zip_prefixes` of
each zone, and the `zips_crossing_provinces` of a country. Worldwide reads that data when it validates a
postal code against a province or state (see `Worldwide::Region#valid_zip?`).

The tasks are development tools. The gemspec does not package `rake/`. They need the `csv` and `rubyzip`
gems, which the Gemfile lists in its `:development` and `:test` groups.

## Data sources and licences

- **GeoNames postal codes.** `postal:codes:import` downloads `https://download.geonames.org/export/zip/<CC>.zip`.
  [GeoNames](https://www.geonames.org/) postal code data is licensed under
  [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/) (CC BY 4.0). Credit GeoNames
  when you publish data that you derive from it.
- **India.** The
  [All India Pincode Directory](https://data.gov.in/catalog/all-india-pincode-directory) on data.gov.in is
  published by the Government of India. Content on data.gov.in is licensed under the
  [Government Open Data License - India](https://data.gov.in/Godl) (GODL-India). Credit the data source
  when you publish data that you derive from it.

## Tasks

Run each task from the root of the repository.

### `postal:codes:import[CC]`

```sh
bundle exec rake "postal:codes:import[PT]"
```

Downloads the postal codes of one country from GeoNames, and computes the shortest prefixes that each map to
only one zone. It writes them as `zip_prefixes` on each zone in `data/regions/<CC>.yml`. The task changes only
`zip_prefixes` (and, for India, `zips_crossing_provinces`). Other keys, key order, comments outside the
replaced lists and the format of the file stay as they are. The comments inside a replaced `zip_prefixes`
list are lost.

GeoNames zone codes can differ from the ISO codes that Worldwide uses. `code_mapper.rb` maps them. Countries
that are not in `PostalHelpers::LEVEL_1_COUNTRIES` or `PostalHelpers::LEVEL_2_COUNTRIES` are not supported
yet: add the country there, and a mapping to `code_mapper.rb` if its zone codes differ.

The task downloads files to `rake/postal/vendor/`, which Git ignores. Review the diff of
`data/regions/<CC>.yml` before you commit it, and run `bundle exec rake test`.

For India the task does not download the data, because the file is large. Download `pincode.csv` from the
[All India Pincode Directory](https://data.gov.in/catalog/all-india-pincode-directory) by hand and put it at
`rake/postal/vendor/geonames/pincode.csv`. Then run `bundle exec rake "postal:codes:import[IN]"`. It also
writes `zips_crossing_provinces`: the postal codes that appear in more than one zone.

### `postal:codes:check[CC.csv]`

```sh
bundle exec rake "postal:codes:check[/path/to/CA.csv]"
```

Checks a CSV of postal codes against the validators of the country, with and without normalization. The CSV
has the postal code in its first column and a count of how many times it appears in the last column, sorted by
count in descending order. Name the file `<CC>.csv`, with the ISO 3166 country code. The task writes the
report to `<CC>.txt` beside the CSV.

### `postal:codes:zone_check[CC.csv]`

```sh
bundle exec rake "postal:codes:zone_check[/path/to/CA.csv]"
```

Reports postal codes that are valid for the country but not for the zone that they are in. The CSV has the
postal code in its first column, the zone name in its second column and a count in its last column, sorted by
count in descending order. Name the file `<CC>.csv`. The task writes the report to `<CC>.txt` beside the CSV.
