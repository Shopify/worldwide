# Worldwide  <!-- omit in toc -->

The `worldwide` gem internationalizes and localizes Ruby code, enhancing user experience globally. It also aids in inputting, validating, and formatting mailing addresses.

For mailing addresses, `worldwide` can identify common address issues, including:
- Validity of the country code
- Completeness of address fields
- For countries using political subdivisions in addresses:
  - Completeness and validity of the subdivision
  - Compatibility of the postal code with the subdivision
- For countries using postal codes:
  - Presence of a postal code if required
  - Plausibility of the postal code (matching expected format and known prefixes)

> [!NOTE]
> Shopify developers should consult the [`country_db`](https://github.com/Shopify/country_db) gem's readme before leveraging the Worldwide gem.

## 💻  Installation  <!-- omit in toc -->

Add this line to your application's `Gemfile`:

```ruby
gem 'worldwide'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install worldwide

### Usage  <!-- omit in toc -->

`worldwide` depends on `ruby-i18n` being configured in a particular way.

If you have opinions about how your `ruby-i18n` should be configured, you are welcome to configure it yourself.

It's easier, however, to let `worldwide` configure it for you like this:

```ruby
I18n.available_locales = Worldwide::Locales.top_25
Worldwide::Config.configure_i18n
```

⚠️ Note that, if you don't set `I18n.available_locales` before calling `configure_i18n`, `worldwide` will
default to only loading translations for English.  If you then try to use a locale that's not loaded,
you'll see an error like this:

```ruby
irb(main):005:0> I18n.with_locale(:fr) { Worldwide.currency(code: "CAD").name }
/Users/cejaekl/.gem/ruby/3.1.3/gems/i18n-1.12.0/lib/i18n.rb:351:in `enforce_available_locales!': :fr is not a valid locale (I18n::InvalidLocale)
```

`worldwide` requires that you to explicitly decide which languages to service, because there is a runtime overhead
(both CPU cycles and RAM) associated with loading translations for more langages.  `worldwide` will automatically
extend the locales you specify to include locales that are needed for fallbacks, and specialized locales that are derived from the configured list of locales.  For example:
  - `available_locales = [:en, :fr]` will also load support for locales like `en-GB`, `en-US`, `fr-CA` and `fr-FR`
  - `available_locales = [:'fr-FR']` will also load support for `fr`

If you want to support all locales that Unicode CLDR supports, you can achieve that with:

```ruby
I18n.available_locales = Worldwide::Locales.known
Worldwide::Config.configure_i18n
```

Also, if you'd rather not raise an `I18n::InvalidLocale` when using a locale that's not available, you can
change that behaviour like this:

```ruby
I18n.enforce_available_locales = false
```

## What you will get for free  <!-- omit in toc -->

Here the list of the features we currently support:

- [🌏  Regions (Countries / Territories / Subdivisions / States / Provinces / Prefectures / etc.)](#--regions-countries--territories--subdivisions--states--provinces--prefectures--etc)
  - [Regional Validations](#regional-validations)
  - [Phone Validations](#phone-validations)
- [📫  Addresses](#--addresses)
  - [Formatting](#formatting)
  - [Validation](#validation)
  - [Auto-correction](#auto-correction)
- [🗓  / ⌚  Date and Time formats](#-----date-and-time-formats)
  - [Calendar quarter formatting](#calendar-quarter-formatting)
- [📅  Calendar Information](#--calendar-information)
  - [Month and Weekday labels](#month-and-weekday-labels)
- [🕰  Localized Timezone](#--localized-timezone)
  - [➡🕰  Map Deprecated Timezone Name to Modern Name](#--map-deprecated-timezone-name-to-modern-name)
- [👥  Names](#--names)
- [👥  Lists](#--lists)
- [❣️   Punctuation](#️---punctuation)
- [🤑  Currency support](#--currency-support)
- [🔢  Numbers](#--numbers)
- [💰 Discount Percentage Formatting](#-discount-percentage-formatting)
- [🗺  Locales / Languages](#--locales--languages)
- [👨‍👩‍👧‍👧  Pluralization](#--pluralization)
- [📐  Measurement support](#--measurement-support)
- [📜 Scripts](#-scripts)
- [🐛  Error handling](#--error-handling)

### 🌏  Regions (Countries / Territories / Subdivisions / States / Provinces / Prefectures / etc.)

Worldwide exposes the notion of a "region", or political subdivision.  This can be a "continent"
(e.g. "North America"), a "country" (e.g. "Canada"), or a "province" (e.g. "Ontario").

Note that, when exposing geographic information to users, you should be careful what you refer
to as a "country".  For backward compatibility with historical APIs, we use the term "country"
to refer to what CLDR refers to as a "territory", and what we describe in our user interface as
a "country / region".  Examples of such entities include Canada, the United States, and Russia,
but also territories with a "dual" status such as Guernsey, Hong Kong, and Martinique.

For backward compatibility with legacy data, we consider dual-status subdivisions of the USA
and Spain to be "provinces" (subdivisions), but we consider dual-status subdivisions of other
countries (including the United Kingdom, France, Norway, and Denmark) to be "countries".
It is possible to look up a dual-status region as both a "country" and a "province", but if
you ask the returned object what it is, it'll only give you the one answer.

This module provides translated country (territory / region) and province (subdivision) names.
```ruby
$ Worldwide.region(code: "001").full_name
=> "World"
$ Worldwide.region(code: "003").full_name
=> "North America"
$ Worldwide.region(code: "CA").full_name
=> "Canada"
$ Worldwide.region(code: "CA-ON").full_name
=> "Ontario"
$ Worldwide.region(code: "CA").zone(code: "ON").full_name
=> "Ontario"
$ Worldwide.region(code: "001").zone(code: "003").zone(code: "021").zone(code: "CA").zone(code: "ON").full_name
=> "Ontario"
$ Worldwide.region(code: "CA-ON").short_name
=> "ON"
$ Worldwide.region(code: "JP-13").full_name
=> "Tokyo"
$ Worldwide.region(code: "JP-13").short_name
=> "Tokyo"
$ unknown = Worldwide.region(code: "bogus-does-not-exist")
=> <Worldwide::Region>
$ unknown.full_name
=> "Unknown Region"
$ unknown.iso_code
=> "ZZ"

# Get array of all "countries" (with attributes in the current locale)
$ Worldwide::Regions.all.select{|r| r.country?}
=> [
      Region <code: "AD", name: "Andorra", ... >,
      Region <code: "AE", name: "United Arab Emirates", ... >,
      ...
   ]

# Get array of all Country names in the current locale
$ Worldwide::Regions.all.select{|r| r.country?}.map(&:full_name)
=> [ "Andorra", "United Arab Emirates", ...]

# Get mapping of all country codes and names in the current locale
$ Worldwide::Regions.all.select{|r| r.country?}.each_with_object({}) { |country, hash| hash[country.iso_code] = country.full_name }
=> {
        'AD' => 'Andorra',
        'AE' => 'United Arab Emirates',
        ...
   }

# Get Country object with code passed in (with attributes in the current locale)
# Codes can be in any ISO_3166-1 format (`alpha-2`, `alpha-3`, or `numeric-3`).
$ Worldwide.region(code: "BR")
=> Worldwide::Region <code: 'BR', name: 'Brazil', ... >
$ Worldwide.region(code: "BRA")
=> Worldwide::Region <code: 'BR', name: 'Brazil', ... >
$ Worldwide.region(code: "076")
=> Worldwide::Region <code: 'BR', name: 'Brazil', ... >

# Get Worldwide::Region object with name passed in
# ⚠️ WARNING:  You should avoid doing this unless you have no other choice.
# Lookup by name is doomed to fail in some cases, because countries have multiple forms
# of their names, and we do not and will not support all of them.
# Use of lookup-by-name has been the cause of many bugs in the past; e.g., trying to look up
# Deutschland (the German name for Germany) in English will not find a country.
# However, if you need to convert data ingested from a third party that you don't control,
# then this method is better than nothing.
$ Worldwide.region(name: "Brazil")
=> Worldwide::Region <code: 'BR', name: 'Brazil', ... >

# Get Worldwide::Region object based on an internal code used by Unicode CLDR
# Note that you can't pass such a code directly as a `code:` argument, because the result
# would be ambiguous:  `are` might be `ARE` (three-letter code for the United Arab Emirates)
# or `AR-E` (province of Entre Ríos in Argentina).
$ Worldwide.region(cldr: "caon")
=> Worldwide::Region <iso_code: 'CA-ON', full_name: 'Ontario', ...>
$ Worldwide.region(code: "are")
=> Worldwide::Region <iso_code: 'AE', full_name: 'United Arab Emirates', ...>
$ Worldwide.region(cldr: "are")
=> Worldwide::Region <iso_code: 'AR-E', full_name: 'Entre Ríos', ...>

# Get array of Region objects for country code passed in (with attributes in the current locale)
$ Worldwide.region(code: "CA").zones
=> [ Worldwide::Region <code: 'caab', name: 'Alberta', ... >, Worldwide::Region <code: 'cabc', name: 'British Columbia', ... >]
```
For some countries, there is a conventional ordering when provinces are listed (for example, both Chile and Japan normally order theirs North-to-South).  If the country has such an order, then the provinces will be returned sorted in that order.  Otherwise, the zones will be sorted by name, using the sorting rules appropriate for the currently-configured locale.

This hierarchy includes continents:
```ruby
$ na = Worldwide.region(code: "021")
=> #<Worldwide::Region:0x00007f9df6466310 @code="021", @deprecated=false>
$ na.zones
=> [#<Worldwide::Region @iso_code="CA">, #<Worldwide::Region @iso_code="US"> ... ]
$ na.zones.map { |zone| [zone.iso_code, zone.full_name] }
=> [["CA", "Canada"], ["US", "United States"] ... ]
$ I18n.with_locale(:ja) { na.zones.map { |zone| [zone.iso_code, zone.full_name] } }
=> [["CA", "カナダ"], ["US", "アメリカ合衆国"] ... ]
```

A Region can provide its:
  - `full_name`: a user-facing name in the currently-active locale's language
  - `short_name`: a user-facing abbreviation in the currently-active locale's language.  E.g., `ON` for Ontario, Canada.
  - `legacy_name`: the name that used to be provided by the country_db gem; you may need this to look up countries stored in records in the DB, but you should never show this name to the user
  - `alpha_two`/`iso_code`: ISO-3166-1 two-letter code, e.g. `AF`
  - `legacy_code`: the code that used to be provided by the country_db gem; you may need this to look up countries stored in records in the DB, but you should never show this code to the user
  - `iso_code`: the ISO-3166 code for this region
  - `alpha_three`: ISO-3166-1 three-letter code, e.g. `AFG`
  - `numeric_three`: ISO-3166-1 three-digit code (returned as a string to preserve leading zeroes), e.g. `004`

and also answer questions about its status:
  - `continent?`: is this region a continent?
  - `country?`: is this region a "country"?  (Note that, for backward compatibility with legacy code in Shopify's ecosystem,  we do not consider dependent territories of Spain and the United States to be countries, but we do consider dependencies of Australia, Britain, Denmark, Finland, France and Norway to be "countries")
  - `deprecated?`: has this territory ceased to exist? (e.g. `AN` which dissolved in 2010)

```ruby
$ ca = Worldwide.region(code: "CA")
=> #<Worldwide::Region:0x00007ff72b1c25a8 @code="CA">
$ ca.full_name
=> "Canada"
$ ca.iso_code
=> "CA"
$ ca.alpha_three
=> "CAN"
$ ca.numeric_three
=> "124"
```
⚠️ WARNING: the `name` is subject to change in the future, if/when the Unicode organization accepts any modifications.  Recent examples of name changes include `MK` (`Macedonia` => `Northern Macedonia`) and `SZ` (`Swaziland` => `Eswatini`).  If you need to store a country in the database, *please* *use* *the* *alpha-two* *country* *code* to prevent problems in the future.

You can also get the names of zone (subdivisions/provinces/states/regions) within countries:
```ruby
$ ca = Worldwide.region(code: 'CA')
=> #<Worldwide::Region:0x00007fdcee7b8a90 @code="CA">
$ ont = ca.zone(code: 'on')
=> #<Worldwide::Region:0x00007fdcf3853a68 @code="CA-ON">
$ ont.full_name
=> "Ontario"
$ jp = Worldwide.region(code: 'JP')
=> #<Worldwide::Region:0x00007fdcee8f8d60 @code="JP">
$ okayama = jp.zone(code: 'JP-33')
=> #<Worldwide::Region:0x00007f9f69acced8 @code="JP-33">
$ I18n.with_locale(:en) { okayama.full_name }
=> "Okayama"
$ I18n.with_locale(:ja) { okayama.full_name }
=> "岡山県"
```

Province lookup by name is possible.

⚠️  WARNING:  you should avoid doing it if at all possible (try to use the zone's code instead).

Sometimes, e.g. when interfacing with a 3rd-party data source, you have no choice and must try to look up
by name.  Worldwide will make an effort to locate the given zone, but you must understand that zones
may be known by more than one linguistic variation, and Worldwide cannot, and does not, support all
possible variations.
```
$ Worldwide.region(code: "CA").zone(name: "Prince Edward Island")&.iso_code
=> "CA-PE"
$ I18n.with_locale(:fr){ Worldwide.region(code: "CA").zone(name: "Île-du-Prince-Édouard")&.iso_code }
=> "CA-PE"
$ I18n.with_locale(:fr){ Worldwide.region(code: "CA").zone(name: "Québec") }
=> #<Worldwide::Region:0x00007fd80d9059d8 @code="CA-QC", @is_country=false>
$ I18n.with_locale(:fr){Worldwide.region(code: "CA").zone(name: "Province de Québec")}
=> #<Worldwide::Region @code="ZZ"> # the unknown region, returned when no match is found
```

#### Regional Validations

```
$ Worldwide.region(code: "CA").valid_zip?("K1A 1A1")
=> true
$ Worldwide.region(code: "CA").zone(code: "ON").valid_zip?("K1A 1A1")
=> true
$ Worldwide.region(code: "CA").zone(code: "MB").valid_zip?("K1A 1A1")
=> false
```

#### Phone Validations

```
$ Worldwide::Phone.new(number: "(613) 555-1212", country_code: "CA").valid?
=> true
$ Worldwide::Phone.new(number: "(613) 555-1212 ext 123", country_code: "CA").valid?
=> true
$ Worldwide::Phone.new(number: "+41 44 268 66 66", country_code: "CA").valid?
=> true
$ Worldwide::Phone.new(number: "44 268 66 66", country_code: "CA").valid?
=> false
```

### 📫  Addresses

This module provides localized address validation, autocorrection, and display formatting.

#### Formatting

```ruby
$ library_address = Worldwide.address(
  first_name: "Liz",
  last_name: "Jolly",
  company: "British Library",
  address1: "96 Euston Rd",
  address2: nil,
  zip: "NW1 2DB",
  city: "London",
  country_code: "GB"
)
=> Worldwide::Address
$ library_address.format
=>
[
  "Liz Jolly",
  "British Library",
  "96 Euston Rd",
  "London NW1 2DB",
  "United Kingdom",
]
=> jr_address = Worldwide.address(
  first_name: "賢",
  last_name: "田中",
  company: "JR東日本",
  address1: "丸の内１丁目９",
  zip: "100-0005",
  city: "千代田区",
  province_code: "JP-13",
  country_code: "JP"
)
=> Worldwide::Address
$ I18n.with_locale(:ja) { jr_address.format }
=>
[
  "日本 〒100-0005",
  "東京都 千代田区",
  "丸の内１丁目９",
  "JR東日本",
  "田中 賢様",
]
$ I18n.with_locale(:en) { jr_address.format }
=>
[
  "Japan 〒100-0005",
  "Tokyo 千代田区",
  "丸の内１丁目９",
  "JR東日本",
  "田中 賢様",
]

# You can also hide some fields
$ library_address.format(
   excluded_fields: [:name],
  )
=>
[
  "British Library",
  "96 Euston Rd",
  "London NW1 2DB",
  "United Kingdom",
]
```
You can also generate a single-line form of the address.  This can be useful, for example,
to identify cities in which warehouses are located.
```ruby
$ lon = Worldwide.address( country_code: 'GB', city: 'London' )
=> Worldwide::Address
$ lon.single_line
=> "London, United Kingdom"
$ I18n.with_locale(:ja) { lon.single_line }
=> "イギリス：London"
$ I18n.with_locale(:'zh-CN') { lon.single_line }
=> "英国London"
```

Address format strings are described in detail [here](docs/address_format_strings.md).

The Address class also offers concatenation & splitting methods for converting between the standard and extended address formats. Equivalent Typescript methods are offered in the NPM package (see [README](https://github.com/Shopify/worldwide/blob/main/lang/typescript/README.md)).
```ruby
$ address = Worldwide.address(street_name: "Main Street", street_number: "123", country_code: "BR")
=> Worldwide::Address
$ address.concatenate_address1
=> "Main Street, 123"

$ address = Worldwide.address(address1: "Main Street, 123", country_code: "BR")
=> Worldwide::Address
$ address.split_address1
=> { "street_name" => "Main Street", "street_number" => "123" }

$ address = Worldwide.address(line2: "dpto 4", neighborhood: "Centro", country_code: "BR")
=> Worldwide::Address
$ address.concatenate_address2
=> "dpto 4, Centro"

$ address = Worldwide.address(address2: "dpto 4, Centro", country_code: "BR")
=> Worldwide::Address
$ address.split_address2
=> { "line2" => "dpto 4", "neighborhood" => "Centro" }
```

The additional address fields that are part of each country's extended address format and their concatenation rules are defined in the country YAML files. For example:
```ruby
# data/region/BR.yml
additional_address_fields:
  - name: streetName
    required: true
  - name: streetNumber
    required: true
  - name: line2
  - name: neighborhood
combined_address_format:
  address1:
    - key: streetName
    - key: streetNumber
      decorator: ","
  address2:
    - key: line2
    - key: neighborhood
      decorator: ","
```
If a country does not have additional address fields, concatenation will simply return `address1`, and splitting will return `nil`.

#### Validation

```ruby
$ library_address = Worldwide.address(
  first_name: "Liz",
  last_name: "Jolly",
  company: "British Library",
  address1: "96 Euston Rd",
  address2: nil,
  zip: "NW1 2DB",
  city: "London",
  country_code: "GB"
)
=> Worldwide::Address
$ library_address.valid?
=> true

$ bogus_address = Worldwide.address(
  first_name: "John",
  last_name: "Doe",
  address1: "123 Fake Street",
  province_code: "MB",
  zip: "A1A 1A1",
  city: "London",
  country_code: "CA"
)
=> Worldwide::Address
$ bogus_address.valid?
=> false
$ bogus_address.errors
=> [[:zip, :invalid_for_province_and_country]]  # zip in MB must start with R, not A
```

#### Auto-correction

Some autocorrections are high-confidence, and will be applied all the time:
```ruby
$ typo_address = Worldwide.address(
  first_name: "John",
  last_name: "Doe",
  address1: "2370 Lancaster Rd",
  city: "Ottawa",
  province_code: "ON",
  zip: "k181ao", # 8 should be B, o should be 0
  country_code: "CA"
)
=> Worldwide::Address
$ typo_address.valid?
=> true # We consider in valid because we can autocorrect into something valid
$ typo_address.normalize.zip
=> "K1B 1A0"

$ jersey_address = Worldwide.address(
  first_name: "John",
  last_name: "Smith",
  address1: "The Weighbridge",
  city: "St. Helier",
  zip: "JE2 3NG",
  country_code: "GB", # GB is the United Kingdom, but Jersey is not in the UK.  It has its own code, JE.
)
=> Worldwide::Address
$ jersey_address.country_code
=> "GB"
$ jersey_address.normalize.country_code
=> "JE"
```

But, some autocorrections are less clear-cut, and will only be applied if aggressive normalization is requested.
```ruby
$ atlanta_address = Worldwide.address(
  first_name: "Scarlett",
  last_name: "O'Hara",
  address1: "181 Peachtree St NE",
  city: "Atlanta",
  zip: "30303",
  country_code: "GE" # Country Georgia, which is not the USA State of Georgia
)
=> Worldwide::Address
$ atlanta_address.country_code
=> "GE"
$ atlanta_address.valid?
=> false
$ atlanta_address.normalize(autocorrect_level: 9).country_code
=> "US"
$ atlanta_address.normalize!(autocorrect_level: 9)
=> Worldwide::Address
$ atlanta_address.province_code
=> "GA"
$ atlanta_address.country_code
=> "US"
$ atlanta_address.valid?
=> true
```

### 🗓  / ⌚  Date and Time formats
```ruby
$ I18n.l(Date.current, format: :long)
=> "October 17, 2018"

$ I18n.l(Time.current, format: :long)
=> "October 17, 2018, 9:54 pm"
```

See the [table of supported formats](formats.md).

You can also ask about some aspects of how the locale formats times:
```ruby
$ ['en-CA', 'en-DK', 'fr-CA'].map { |locale| [locale, Worldwide::TimeFormatter.new(locale: locale).hour_minute_separator ] }
=> [["en-CA", ":"], ["en-DK", "."], ["fr-CA", " h "]]
$ ['en-CA', 'en-DK', 'fr-CA'].map { |locale| [locale, Worldwide::TimeFormatter.new(locale: locale).twelve_hour_clock? ] }
=> [["en-CA", true], ["en-DK", false], ["fr-CA", false]]
```

#### Calendar quarter formatting

There is also an API for formatting `Date`s as calendar quarters (e.g., `Q2 2023`):

```ruby
$ Worldwide::Calendar::Gregorian.quarter(Date.current)
=> "Q4 2018"
$ Worldwide::Calendar::Gregorian.quarter(Date.current, locale: "zh-Hans-CN")
=> "2018年第4季度"
```

### 📅  Calendar Information

#### Month and Weekday labels

To get the translated days of the week, use `Worldwide::Calendar::Gregorian#weekday_names`.
To get the translated months of the year, use `Worldwide::Calendar::Gregorian#month_names`.

**Note:** These can only be used in contexts where the month or weekday is presented in a stand-alone context. For example, they cannot be used as part of a date format, since the grammatical genders and capitalizations will be incorrect for some languages. Instead, use [`I18n.l`](#-----date-and-time-formats) for datetime formatting.

```ruby
$ Worldwide::Calendar::Gregorian.weekday_names(locale: :"en-US")
=> { sun: "Sunday", mon: "Monday", tue: "Tuesday", wed: "Wednesday", thu: "Thursday", fri: "Friday", sat: "Saturday" }
$ Worldwide::Calendar::Gregorian.month_names(locale: :"en-US")
=> ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
```

Use `width` parameter to get shorter versions:

```ruby
$ Worldwide::Calendar::Gregorian.weekday_names(width: :abbreviated)
=> { sun: "Sun", mon: "Mon", tue: "Tue", wed: "Wed", thu: "Thu", fri: "Fri", sat: "Sat" }
$ Worldwide::Calendar::Gregorian.month_names(width: :abbreviated)
=> ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

# Note that the values returned by `width: :narrow` are not unique
# and should only be used in contexts where this ambiguity is not a problem
# (e.g., date picker column headings)
$ Worldwide::Calendar::Gregorian.weekday_names(width: :narrow)
=> { sun: "S", mon: "M", tue: "T", wed: "W", thu: "T", fri: "F", sat: "S" }
$ Worldwide::Calendar::Gregorian.month_names(width: :narrow)
=> ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
```

### 🕰  Localized Timezone

This implementation will provide you a localized timezone that you can use with [time_zone_options_for_select](https://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html#method-i-time_zone_options_for_select):

```ruby
<%= form.ui_select :timezone,
      time_zone_options_for_select(
        @shop.timezone.name,
        nil,
        Worldwide::TimeZone
      ),
      {},
      label: t('shop_identity.views.admin.settings.general.timezone_label') %>
```

#### ➡🕰  Map Deprecated Timezone Name to Modern Name

The Olson database has deprecated time zone names over the years (particularly in 1993).
Some browsers don't support deprecated time zone names, and trying to use them may result in JS exceptions.

```ruby
mapped_zone = Worldwide::DeprecatedTimeZoneMapper.to_supported(time_zone)
```

### 👥  Names

This module will offer you a way to display user names while respecting locale preferences.

Say, for example, your customer has the given name "Ken" and surname "Tanaka".  In English, you'd want to say something like "Hello, Ken," but in Japanese that would be considered overly familiar (to the point that it would cause offence), so the appropriate greeting would be "Hello, Tanaka-sama."  `Names.greeting` will give you a culturally-appropriate equivalent of "Ken".

`Names.full` will give you both the given and surnames, arranging them in the culturally-appropriate order.  (E.g., in Japanese, this would be "TanakaKen-sama" (note there is no space), but in English it would be "Ken Tanaka".)

`Names.surname_first?` will let you know if the current locale places the surname (family name, last name) before the given name ("first name", forename).

```ruby
I18n.with_locale(:en) { Worldwide.names.full(given: "John", surname: "Smith") }
=> "John Smith"
I18n.with_locale(:de) { Worldwide.names.full(given: "Max", surname: "Mustermann") }
=> "Max Mustermann"
I18n.with_locale(:ja) { Worldwide.names.full(given: "賢", surname: "田中") }
=> "田中賢様"
I18n.with_locale(:en) { Worldwide.names.greeting(given: "John", surname: "Smith") }
=> "John"
I18n.with_locale(:ja) { Worldwide.names.greeting(given: "John", surname: "Smith") }
=> "Smith様"
Worldwide.names.surname_first?("en")
=> false
Worldwide.names.surname_first?("ja")
=> true
```

### 👥  Lists

This module will offer you a way to display a list while respecting locale preferences.

```ruby
Worldwide.lists.format(["a", "b", "c"])
=> "a, b, and c"
Worldwide.lists.format(["a", "b", "c"], join: :or)
=> "a, b, or c"
Worldwide.lists.format(["a", "b", "c"], join: :narrow)
=> "a, b, c"
I18n.with_locale(:es) { Worldwide.lists.format(["a", "b", "c"], join: :or) }
=> "a, b o c"
```

### ❣️   Punctuation

`end_sentence` will add a terminating period ("full stop") in a language-appropriate manner.
It is an idempotent operation; you can safely call `end_sentence` on its own output and get the same value back.

```ruby
$ Worldwide.punctuation.end_sentence("See spot run")
=> "See spot run."
$ Worldwide.punctuation.end_sentence("See spot run.")
=> "See spot run."
$ Worldwide.punctuation.end_sentence("See spot run. ")
=> "See spot run."
$ I18n.with_locale(:ja) { Worldwide.punctuation.end_sentence("スポットを走るのは見て下さい") }
=> "スポットを走るのは見て下さい。"
$ I18n.with_locale(:ja) { Worldwide.punctuation.end_sentence("スポットを走るのは見て下さい。") }
=> "スポットを走るのは見て下さい。"
```

`to_paragraph` takes an array of sentences.  It ensures that each sentence ends in a local-appropriate "full stop"
(via `end_sentence`) and then concatenates the sentences, inserting an inter-sentence space if the locale uses them.

```ruby
$ Worldwide.punctuation.to_paragraph(["See Spot", "See Spot run.", "Run, Spot, run"])
=> "See Spot. See Spot run. Run, Spot, run."
$ I18n.with_locale(:ja) { Worldwide.punctuation.to_paragraph(["スポットを見る", "スポットが走る。", "早く走る。"])}
=> "スポットを見る。スポットが走る。早く走る。"
```

### 🤑  Currency support

This module offers you a way to display currency names and symbols in your favorite locale.

```ruby
$ currency = Worldwide.currency(code: "USD")
$ currency.symbol
=> "$"
# Use label when dealing with money amounts
$ currency.label(count: 1)
=> "US dollar"
$ currency.label(count: 2)
=> "US dollars"
# Use name when needing the actual name of the currency
$ currency.name
=> "US Dollar"
```

ISO-4217 alpha-three and numeric-three codes are both supported.
```
$ Worldwide.currency(code: "USD").numeric_code
=> 840
$ Worldwide.currency(code: 840).currency_code
=> "USD"
```

The ability to fetch all currencies is available.
 ```ruby
$ currencies = Worldwide::Currencies.all
=> [#<Worldwide::Currency:0x00007fc831834db0 @currency_code=:AOA>, #<Worldwide::Currency:0x00007fc831834ce8 @currency_code=:ARS>, #<Worldwide::Currency:0x00007fc831834c70 @currency_code=:AUD>...]
```

You can also format a numeric amount as a currency.

Two options are provided:

`format_short` shows a short form (symbol only), where available.  Examples:
  - `CHF 1,25`
  - `€1,25`
  - `£1.25`
  - `₹125`
  - `OMR 1.250`
  - `$1.25`

`format_explicit` shows the short form, but also appends the ISO currency code
even when the currency has a symbol. Examples:
  - `CHF 1,25`
  - `€1,25 EUR`
  - `£1.25 GBP`
  - `₹125 INR`
  - `OMR 1.250`
  - `$1.25 USD`

Note that formatting depends not just on the currency, but also on the locale.
For example, the amount "6 and a half Euros" would format as:
  - `€ 6,50` in the Netherlands,
  - `€6.50` in Ireland, and
  - `6,50 €` in France.

Both `format_short` and `format_explicit` support the following keyword arguments:
  - `as_minor_units`:  format in minor units (e.g., cents) for currencies that have a minor unit symbol defined.  Note that, even when formatting in minor units, the `decimal_places:` argument is still relative to the *major* unit, not the *minor* unit.  If there is no minor unit symbol for the given currency, then the `as_minor_units:` argument has no effect, and the result will still be formatted in major units anyway.
  - `decimal_places:` use at least the given number of decimal places after the currency's major unit.  If this parameter is not given, then the default is to use the currency's number of decimal places for normal formatting, or only the number that is required to display a precise answer for `humanize`d formatting.
  - `humanize:` can be `:short` or `:long` to produce a human-friendly display for large numbers, or `:japan` to use Japanese-style alternative formatting (see examples below)
  - `locale:` the locale to use when formatting (default is the active `I18n.locale`)
  - `use_symbol:` use the currency's symbol or, if it has no symbol, its ISO code where the symbol would be (default is `true`).  Note that, if `as_minor_units` is true, then `use_symbol` will be forced to `true`, even if `use_symbol: false` is passed.

```ruby
$ eur = Worldwide.currency(code: "EUR")
$ jpy = Worldwide.currency(code: "JPY")
$ usd = Worldwide.currency(code: "USD")

$ usd.format_short(12.5, locale: "en-US")
=> "$12.50"
$ usd.format_explicit(12.5, locale: "en-US")
=> "$12.50 USD"
$ usd.format_short(12.5, locale: "fr")
=> "12,50 $"
$ usd.format_explicit(12.5, locale: "fr")
=> "12,50 $ USD"

$ usd.format_short(10_000_000, humanize: :short)
==> "$10M"
$ usd.format_short(10_000_000, humanize: :long)
==> "$10 million"
$ usd.format_explicit(10_000_000, humanize: :short)
==> "$10M USD"
$ jpy.format_short(12345)
==> "￥12,345"
$ jpy.format_short(12345, humanize: :japan)
==> "1万2345円"

$ usd.format_short(0.75, as_minor_units: true)
==> "75¢"
$ usd.format_short(1.219, as_minor_units: true)
==> "122¢"
$ usd.format_short(1.219, as_minor_units: true, decimal_places: 1)
==> "122¢"
$ usd.format_short(1.219, as_minor_units: true, decimal_places: 3)
==> "121.9¢"
$ usd.format_explicit(0.75, as_minor_units: true)
==> "75¢ USD"
$ eur.format_short(0.75, as_minor_units: true)
==> "€0.75"
```

### 🔢  Numbers

`Worldwide::Numbers` can convert numbers to locale-appropriate strings.

Optional keyword arguments:
  - `decimal_places:` force a certain number of decimal places to be used.
  - `humanize:` can be `:short` or `:long` to produce a human-friendly display for large numbers, or `:japan` to use Japanese-style alternative formatting (see examples below)
  - `percent: true` format the number as a percentage. (Note: in this case, `0.1` is `10%`, not `0.1%`).

```ruby
$ Worldwide.numbers.format(12345.67)
==> "12,345.67"
$ Worldwide.numbers.format(12345.67, decimal_places: 0)
==> "12,346"
$ Worldwide.numbers(locale: :'fr-FR').format(12345.67)
==> "12 345,67"
$ Worldwide.numbers(locale: :en).format(1_500_000)
==> "1,500,000"
$ Worldwide.numbers(locale: :en).format(1_500_000, humanize: :long)
==> "1.5 million"
$ Worldwide.numbers(locale: :en).format(1_500_000, humanize: :short)
==> "1.5M"
$ Worldwide.numbers(locale: :'fr-Fr').format(2_000_000_000, humanize: :long)
==> "2 milliards"
$ Worldwide.numbers(locale: :'ja').format(1_2345, humanize: :japan)
==> "1万2345"
$ Worldwide.numbers(locale: 'en-US').format(0.75, percent: true)
==> "75%"
$ Worldwide.numbers(locale: 'fr').format(0.75, percent: true)
==> "75 %"
$ Worldwide.numbers(locale: 'tr').format(0.75, percent: true)
==> "%75"
$ Worldwide.numbers(locale: 'en').format(0.6, percent: true, relative: true)
==> "+60%"
```

Note: If you want to display a discount off a price (e.g. "Now 20% off"), then a percentage may not be
the most natural way to do this in some locales.  For example, that `20% off` would normally be `2割引`
in Japan, and `8折` in China.

### 💰 Discount Percentage Formatting

If you want to display a discount off a price (e.g. "Now 20% off"), then a percentage may not be
the most natural way to do this in some locales.  For example, that `20% off` would normally be `2割引`
in Japan, and `8折` in China.

`Worldwide.discounts` can display discount percentages according to locale.

```ruby
# Format percentage as a discount
$ Worldwide.discounts.format(0.75, locale: :'en-CA')
==> "75%"
$ Worldwide.discounts.format(0.1, locale: :'ku')
==> "10%"
$ Worldwide.discounts.format(0.8, locale: :'ja')
==> "8割引"
$ Worldwide.discounts.format(0.85, locale: :'ja')
==> "85%割引"
$ Worldwide.discounts.format(2.5, locale: :'zh-Hans-CN')
==> "7.5折"
```

### 🗺  Locales / Languages

This module provides ways to work with locale codes.
```ruby
# Get the list of known locales
$ Worldwide.locales.known
=> ["af", "af-NA", "af-ZA", "...", "zu", "zu-ZA"]
# Get the language subtag from a locale
$ Worldwide.locale(code: "pt-BR").language_subtag
=> "pt"
# Get a list of valid locales (from the CLDR data)
$ Worldwide.locale(code: "it").sub_locales
=> ["it-CH", "it-IT", "it-SM", "it-VA"]
# Which script does the locale use?
$ [:en, :ja, :ru, :'zh-Hans', :'zh-Hant'].map { |locale| [locale, Worldwide.locale(code: locale).script] }
=> [["en", "Latn"], ["ja", "Jpan"], ["ru", "Cyrl"], ["zh-Hans", "Hans"], ["zh-Hant", "Hant"]]
```

This module also provides translated names based on some recommendations provided by the [CLDR](https://cldr.unicode.org/index).
```ruby
# Get the name translated in the current locale
$ Worldwide.locale(code: 'pt-BR').name
=> "Brazilian Portuguese"
# Or you can specify a locale
$ Worldwide.locale(code: "fr-CA").name(locale: :fr)
=> "français canadien"
# Add region in parentheses when full locale is provided
$ Worldwide.locale(code: "fr-FR").name
=> "French (France)"
$ Worldwide.locale(code: "bogus-does-not-exist").name(throw: false) || Worldwide::Locale.unknown.name
=> "Unknown language"
```

If you want a mapping of locale codes to names (in the current `I18n.locale` locale):
```ruby
$ map = Worldwide.locales.known.to_h { |code| [ code, Worldwide::Locale.new(code).name ]}
==> { ..., :de => "German", ..., :"fr-CA" => "Canadian French", ..., :"zu-ZA" => "Zulu" }
```

### 👨‍👩‍👧‍👧  Pluralization

Provides insight into which keys are used to resolve plurals in a specified locale.

Typically you don't need to use this. In most cases, you just need pass in the number as the [`count` parameter of `I18n.translate`](https://guides.rubyonrails.org/i18n.html#pluralization). These methods are provided for use in other i18n systems.

```ruby
$ Worldwide.plurals.keys(:pl, type: :cardinal)
=> [:few, :many,:one, :other]
```

### 📐  Measurement support

This module provides localized measurement unit formatting.

`Units.format` supports the following arguments:
- `amount`: the amount associated with the unit. This parameter is used to apply the unique pluralization rules of the requested locale.
- `unit`: the measurement unit. The keys listed in [`Worldwide.Units.measurement_keys`](https://github.com/Shopify/worldwide/blob/main/lib/worldwide/units.rb#L23-L70) are supported.
- `humanize`: can be `:long` or `:short`. `:long` returns the translated word of the unit. `:short` returns the localized abbreviation of the unit. The default value is `:short`.

```ruby
# To display the abbreviated version of the unit
$ Worldwide.units.format(5, :kilogram)
=> "5 kg"
# To display the full-word version of the unit
$ Worldwide.units.format(5, :kilogram, humanize: :long)
=> "5 kilograms"
# You can also use the plural form of the measurement unit
$ Worldwide.units.format(5, :kilograms)
=> "5 kg"

$ I18n.with_locale(:ja) { Worldwide.units.format(5, :kilogram, humanize: :long) }
=> "5 キログラム"
```

### 📜 Scripts

This modules provides the ability to identify the `script` used in a block of text.

```ruby
Worldwide::Scripts.identify(text: "The quick brown fox jumps")
=> [:Latn]

Worldwide::Scripts.identify(text: "日本語がわかります。")
=> [:Han, :Hiragana]
```

### 🐛  Error handling

`worldwide` will provide you 2 features for a better international experience:
- 👨‍🔧  Fallback mechanism which will default to `english` in case of a missing translation
- 🚀  Fire off an exception notification in case of a missing translation in `production`

It should looks like this on your development environment:

```ruby
$ I18n.t('missing')
I18n::MissingTranslation: translation missing: en.missing
```

## Contributing  <!-- omit in toc -->

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/worldwide/issues. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://www.contributor-covenant.org/translations) code of conduct.

## Code of Conduct  <!-- omit in toc -->

Everyone interacting in the worldwide project’s codebases, issue trackers is expected to follow the [code of conduct](https://github.com/Shopify/worldwide/blob/main/.github/CODE_OF_CONDUCT.md).
