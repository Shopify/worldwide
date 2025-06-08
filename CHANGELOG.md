# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## How do I make a good changelog?

### Guiding Principles

- Changelogs are for humans, not machines.
- There should be an entry for every single version.
- The same types of changes should be grouped.
- Versions and sections should be linkable.
- The latest version comes first.
- The release date of each version is displayed.
- Mention whether you follow Semantic Versioning.

### Types of changes

- Added for new features.
- Changed for changes in existing functionality.
- Deprecated for soon-to-be removed features.
- Removed for now removed features.
- Fixed for any bug fixes.
- Security in case of vulnerabilities.

## [Unreleased]

- Upgrade phonelib gem from 0.8.7 to 0.10.9 to pick up latest phone number data and bug fixes [#366](https://github.com/Shopify/worldwide/pull/366)

---

## [1.17.3] - 2025-06-23
- Require postal codes in Romania [#368](https://github.com/Shopify/worldwide/pull/368)

## [1.17.2] - 2025-06-18
- Add name formatter translations for missing languages [#367](https://github.com/Shopify/worldwide/pull/367)
- Update South Africa to be considered Tax Inclusive [#352](https://github.com/Shopify/worldwide/pull/352)

## [1.17.1] - 2025-06-06
- Require postcodes and update regex in MT [#354](https://github.com/Shopify/worldwide/pull/354)
- Introduce name_alternates for NZ regions [#357](https://github.com/Shopify/worldwide/pull/357)

## [1.17.0] - 2025-02-27
- Add has_cities? method to regions [#331](https://github.com/Shopify/worldwide/pull/331)
- Update known zip prefixes for Portugal (PT) [#332]https://github.com/Shopify/worldwide/pull/332
- Allow zone lookup by partial zip if country hides provinces [#332]https://github.com/Shopify/worldwide/pull/332
- Add `has_zip_prefixes?` and `neighbors` methods to Region [#332]https://github.com/Shopify/worldwide/pull/332

## [1.16.0] - 2025-02-17
- Add `ignore_provinces` to regions [#329](https://github.com/Shopify/worldwide/pull/329)

## [1.15.2] - 2024-12-27
- Update Indonesia tax rate to 12%

## [1.15.1] - 2024-12-20
- Set Malaysia and Singapore as tax_inclusive [#323](https://github.com/Shopify/worldwide/pull/323)
- Update or correct example zips [#324](https://github.com/Shopify/worldwide/pull/324)
- Correct zip regex patterns and make them Javascript-compatible [#325](https://github.com/Shopify/worldwide/pull/325)
---

## [1.15.0] - 2024-12-16
- Add zip requirement and tax inclusive methods to country regions [#320](https://github.com/Shopify/worldwide/pull/320)
- Set Ireland (IE) zip as a required address field [#321](https://github.com/Shopify/worldwide/pull/321)

## [1.14.4] - 2024-12-12
- Speed up configure_i18n by precomputing paths and indexing descendants [#316](https://github.com/Shopify/worldwide/pull/316)
- Update BV phone number prefix to 47 (Norway) [#318](https://github.com/Shopify/worldwide/pull/318)
- Update Finland's (FI) tax rate [#319](https://github.com/Shopify/worldwide/pull/319)

## [1.14.3] - 2024-12-02
- Add street_number.missing_building_number messages [#313](https://github.com/Shopify/worldwide/pull/313)

## [1.14.2] - 2024-11-11
- Update translations [#303](https://github.com/Shopify/worldwide/pull/303)

## [1.14.1] - 2024-11-08
- Improve Worldwide::Config.configure_i18n performance [#301](https://github.com/Shopify/worldwide/pull/301)

## [1.14.0] - 2024-11-07
- Add example_city_zip and priority accessors to Regions [#298](https://github.com/Shopify/worldwide/pull/298)
- Add tax_type accessor to Regions [#299](https://github.com/Shopify/worldwide/pull/299)

## [1.13.0] - 2024-11-06
- Add `zip_prefixes` for Spain. [#295](https://github.com/Shopify/worldwide/pull/295)
- Move expensive resource initialization into an explicit `eager_load!` namespace method
[#297](https://github.com/Shopify/worldwide/pull/297)

## [1.12.1] - 2024-10-15
- Update BR address1_regex to remove lookbehinds [#](https://github.com/Shopify/worldwide/pull/)

## [1.12.0] - 2024-10-11
- Update Address splitting methods to split on the first delimiter [#291](https://github.com/Shopify/worldwide/pull/291)

## [1.11.1] - 2024-10-02
- Configure regexp timeout in Worldwide#Phone [#290](https://github.com/Shopify/worldwide/pull/290)

## [1.11.0] - 2024-10-02
- Add address1_regex to regions [#281](https://github.com/Shopify/worldwide/pull/281)
- Add address1_regex for BE, CL, MX, ES, IL [#282](https://github.com/Shopify/worldwide/pull/282)
- Add address1_regex for DE [#286](https://github.com/Shopify/worldwide/pull/286)
- Update legacy timezone mappings for Europe/Kiev [#288](https://github.com/Shopify/worldwide/pull/288)


## [1.10.0] - 2024-09-16
- Add alternate Arabic names for UAE zones [#283](https://github.com/Shopify/worldwide/pull/283)

## [1.9.0] - 2024-08-12
- add support for additional address fields streetName, streetNumber in DE [#273](https://github.com/Shopify/worldwide/pull/273)
- set additional_field neighborhood as required in BR [#279](https://github.com/Shopify/worldwide/pull/279)


## [1.8.0] - 2024-08-09
- Bump Ruby to 3.3.1; drop support for 3.0.x [#264](https://github.com/Shopify/worldwide/pull/264)
- Add support for partial zip matching for SG [#271](https://github.com/Shopify/worldwide/pull/271)

## [1.7.5] - 2024-08-01
- Update legacy timezone mappings for America/Indianapolis and Asia/Calcutta [#267](https://github.com/Shopify/worldwide/pull/267)

## [1.7.4] - 2024-08-01
- Nothing, released by mistake.

## [1.7.3] - 2024-07-30
- Update NZ postcode prefixes [#265](https://github.com/Shopify/worldwide/pull/265)

## [1.7.2] - 2024-07-25
- Associates Kosovo with Southern Europe [#216](https://github.com/Shopify/worldwide/pull/261)

## [1.7.1] - 2024-07-25
- Update iana_to_rails_time_zone mappings for 11 tz's, add time zone data consistency tests[#259](https://github.com/Shopify/worldwide/pull/259)
- Add consistency test for default and optional field labels [#258](https://github.com/Shopify/worldwide/pull/258)

## [1.7.0] - 2024-07-17
- Introduce example_address to the worldwide region, update country ymls [#257](https://github.com/Shopify/worldwide/pull/257)

## [1.6.2] - 2024-07-10

- Improve tests related to building number requiredness [#249](https://github.com/Shopify/worldwide/pull/249)
- Update Dutch translations for street_number [#236](https://github.com/Shopify/worldwide/pull/236)

## [1.6.1] - 2024-07-03
- Move Units constants `SUPPORTED_HUMANIZATIONS` and `MEASUREMENT_KEYS` to `Worldwide.units.supported_humanizations` and `Worldwide.units.measurement_keys` [#240](https://github.com/Shopify/worldwide/pull/240)
- Allow house numbers on address2 for Japan [#245](https://github.com/Shopify/worldwide/pull/245)

## [1.6.0] - 2024-06-21
- Support multiple script-based address concatenation rules for each country [#224](https://github.com/Shopify/worldwide/pull/224)
- Fixed a typo in list of supported scripts from `Latn` to `Latin`

## [1.5.0] - 2024-06-17
- Make street number optional in CL [#228](https://github.com/Shopify/worldwide/pull/228)

## [1.4.1] - 2024-06-17
- Add translations for neighborhood error strings in AE, CR, KW, PA, PE, SA [#220](https://github.com/Shopify/worldwide/pull/220)

## [1.4.0] - 2024-06-14
- Add localized error strings for neighborhood in AE, CR, KW, PA, PE, SA [#215](https://github.com/Shopify/worldwide/pull/215)
- Change delimiter from Non-Breaking Space to Word Joiner [#221](https://github.com/Shopify/worldwide/pull/221)

## [1.3.1] - 2024-06-11
Patch release containing many non-english translation updates

## [1.3.0] - 2024-06-10

- Update translations for neighborhood too_long error message, add translations for localized neighborhood errors in MX, PH [#191](https://github.com/Shopify/worldwide/pull/191)
- Generate concatenated address1/2 values when some additional field values are present [#199](https://github.com/Shopify/worldwide/pull/199)
- update street_name and street_number too_long error message [#203](https://github.com/Shopify/worldwide/pull/203)
- Additional field definitions in AE, CR, KW, PA, PE, SA, updated decorators for PH, VN  [#206](https://github.com/Shopify/worldwide/pull/206)
- All error messages now contain an `_instructional` and `_informative` key. If the `Worldwide::Field::error` method is called with a `code` that does not end in either `_instructional` or `_informative`, the `Worldwide::Field::error` method will append `_instructional` to the `code` and returns this error message. [#205](https://github.com/Shopify/worldwide/pull/205)

## [1.2.0] - 2024-06-05

- Merge duplicate language definition on some region yaml files to restore missing languages; `NO` adds "en" and "nb", `SA` adds "en", SG does not change [#188](https://github.com/Shopify/worldwide/pull/188)
- updated format_extended for TW VN [#187]https://github.com/Shopify/worldwide/pull/187)
-  Add IANA timezone to rails timezone mappings [#194](https://github.com/Shopify/worldwide/pull/194)

## [1.1.0] - 2024-06-04

- Add support for `_instructional` and `_informative` error message types. Fields without an `_instructional` error
translation key, will fall back to their previous field's error message [#140](https://github.com/Shopify/worldwide/pull/140)

## [1.0.0] - 2024-05-30

- update neighborhood too_long error message, add MX, PH neighborhood labels [#182](https://github.com/Shopify/worldwide/pull/182)

## [0.15.0] - 2024-05-30

- Created npm package `@shopify/worldwide` (see [README.md](./lang/typescript/README.md)) [#167](https://github.com/Shopify/worldwide/pull/167)
- Update additional_address_fields and introduce combined_address_format definitions, introduce Region#{field}_required? methods for street_name, street_number, and neighborhood [#177](https://github.com/Shopify/worldwide/pull/177)

## [0.14.0] - 2024-05-29

- Add support for a line2 address field [#173](https://github.com/Shopify/worldwide/pull/173)
- Re-add city to UAE address form and disable city autofill [#175](https://github.com/Shopify/worldwide/pull/175)

## [0.13.0] - 2024-05-27

- Add Address#split_address1 and Address#split_address2 methods [#165](https://github.com/Shopify/worldwide/pull/165)
- Add Address#concatenated_address1 and Address#concatenated_address2 methods [#158](https://github.com/Shopify/worldwide/pull/158)
- Updated root translation keys for regional locales `bg-BG`, `hr-HR`, `lt-LT`, `ro-RO`, `sk-SK`, `sl-SI`  to the base locale (e.g. `bg`) [#164](https://github.com/Shopify/worldwide/pull/164).
- Remove city from UAE address form and enable city autofill [#159](https://github.com/Shopify/worldwide/pull/159)
- Support additional fields in IL, update streetNumber and neighborhood requirement for BE, CL, ES, MX [#166](https://github.com/Shopify/worldwide/pull/166)

## [0.12.2] - 2024-05-21

- Add missing `address1` and `address1_with_unit` formatting keys for GB [#160](https://github.com/Shopify/worldwide/pull/160).

## [0.12.1] - 2024-05-17
- Use `>=` instead of `~>` for `activesupport` in `.gemspec` [#156](https://github.com/Shopify/worldwide/pull/156)

## [0.12.0] - 2024-05-15

- Add pry-byebug gem [#149](https://github.com/Shopify/worldwide/pull/149)
- Introduce additional_address_fields to Region class and define them for BE, BR, CL, CO, ES, ID, MX, NL, PH, TR, VN [#148](https://github.com/Shopify/worldwide/pull/148)
- Define format_extended attribute on 12 country regions [#150](https://github.com/Shopify/worldwide/pull/150)

## [0.11.1] - 2024-05-13

- Handle blank strings for Region, country_code parameter in Zip normalization
  [#138](https://github.com/Shopify/worldwide/pull/138)
- Reposition zip in NF show: format to come after country, not before city. [#142](https://github.com/Shopify/worldwide/pull/142)
- Allow building number on address2 for CH [#143](https://github.com/Shopify/worldwide/pull/143)
- Attempt to fix stringio incompatibility with Ruby 3.3 (deployment error) [#145](https://github.com/Shopify/worldwide/pull/145)

## [0.11.0] - 2024-04-11

- Add country_prefix to phone [#133](https://github.com/Shopify/worldwide/pull/133)
- Add autofill_city to region [#132](https://github.com/Shopify/worldwide/pull/132)
- Re-introduce city from UAE address form and disable city autofill [#131](https://github.com/Shopify/worldwide/pull/131)
- Add translations for regionalized zip_unknown_for_address, province_unknown_for_address [#125](https://github.com/Shopify/worldwide/pull/125), [#126](https://github.com/Shopify/worldwide/pull/126)
- Remove city from UAE address form and enable city autofill [#127](https://github.com/Shopify/worldwide/pull/127)
- Add logic for known-to-exist extant outcodes for GB [#136](https://github.com/Shopify/worldwide/pull/136)

## [0.10.3] - 2024-03-14

- Add regional language for zip_unknown_for_address, province_unknown_for_address. Remove error message for zip_unknown_for_street_and_city [#121](https://github.com/Shopify/worldwide/pull/121)
- Fix broken CLDR `import`/`patch`/`generate` rake tasks [#119](https://github.com/Shopify/worldwide/pull/119)
- Patch El Salvador department names, standardizing on not including "department of" [#120](https://github.com/Shopify/worldwide/pull/120)

---

## [0.10.2] - 2024-03-12

- Add translations for address line 1, 2 concern messages [#115](https://github.com/Shopify/worldwide/pull/115), [#116](https://github.com/Shopify/worldwide/pull/116)
- Make new concern messages more generic for address line 1, 2 [#114](https://github.com/Shopify/worldwide/pull/114)
- Add localized concern messages when field is unknown for address [#109](https://github.com/Shopify/worldwide/pull/109)

---

## [0.10.1] - 2024-02-27

- Return early if country_code is nil Zip::Normalize [#110](https://github.com/Shopify/worldwide/pull/110)

## [0.10.0] - 2024-02-13

- New UTC long timezone format [#103](https://github.com/shopify/worldwide/pull/103)
- Configure FR to hide provinces from addresses [#101](https://github.com/Shopify/worldwide/pull/101)

## [0.9.0] - 2024-02-05

- Add Thai to the list of scripts identified by `Worldwide::Scripts.identify`. [#96](https://github.com/Shopify/worldwide/pull/96)
- Add translations for address fields with invalid province errors. [#97](https://github.com/Shopify/worldwide/pull/97)

## [0.8.0] - 2024-02-02

- Add translations for address fields with mathematical symbols errors. [#92](https://github.com/Shopify/worldwide/pull/92)
- Enable lookup of Region by alternate name. [#93](https://github.com/Shopify/worldwide/93)
- Allow lookup of EU region using alternate code QUU. [#94](http://github.com/Shopify/worldwide/pull/94)

## [0.7.1] - 2024-02-01

- Patch in a name for CQ (Sark). [#84](https://github.com/Shopify/worldwide/pull/84)
- Patch data related to region 830 (Channel Islands). [#85](https://github.com/Shopify/worldwide/pull/85)
- Patch name of SZ (eSwatini) in Italian. [#86](https://github.com/Shopify/worldwide/pull/86)
- Patch names of HK and MO in zh-TW and zh-Hant. [#87](https://github.com/Shopify/worldwide/pull/87)
- Patch name of GB (United Kingdom) in Suomi. [#88](https://github.com/Shopify/worldwide/pull/88)

## [0.7.0] - 2024-01-31

- Support address field lookup when there is no country code. [#82](https://github.com/Shopify/worldwide/pull/82)

## [0.6.8] - 2024-01-31

- Prefer "SAR" over "SAR China" in Chinese-language names for regions `HK` and `MO`. [#79](https://github.com/Shopify/worldwide/pull/79).
- Add Worldwide::Field.valid_key? method. [#80](https://github.com/Shopify/worldwide/pull/80)

## [0.6.7] - 2024-01-30

- Patch some territory names (BQ, NL, TF, TR) [#77](https://github.com/Shopify/worldwide/pull/77)

## [0.6.6] - 2024-01-25

- Allow building numbers on address2 field for Portugal addresses [#73](https://github.com/Shopify/worldwide/pull/73)

## [0.6.5] - 2024-01-24

- Allow building numbers on address2 field for Polish addresses [#71](https://github.com/Shopify/worldwide/pull/71)

## [0.6.4] - 2024-01-22

- Allow building number in address2 for BE [#70](https://github.com/Shopify/worldwide/pull/70)
- Update Singapore GST in preparation for January 1 2024 increase [#68](https://github.com/Shopify/worldwide/pull/68)

## [0.6.3] - 2023-12-11

- Change HM, TF and GS `group_name` to respective continents based on M49. [#60](https://github.com/Shopify/worldwide/pull/60)

## [0.6.2] - 2023-12-11

- Zone lookup by Hash [#61](https://github.com/Shopify/worldwide/pull/61)

## [0.6.1] - 2023-12-11

- Allow building number in address2 for DK [#53](https://github.com/Shopify/worldwide/pull/53)
- Avoid .present? and .blank? so we don't require Rails [#57](https://github.com/Shopify/worldwide/pull/57)
- (bugfix) Zone lookup by name [#58](https://github.com/Shopify/worldwid/pull/58)

## [0.6.0] - 2023-12-08

- Add localized concern messages for address1 + 2 warnings and address may not exist message [#54](https://github.com/Shopify/worldwide/pull/54)
- Change gem description [#51](https://github.com/Shopify/worldwide/pull/51)

## [0.5.1] - 2023-11-29

- Fix for building_number_required to default to false [#48]

## [0.5.0] - 2023-11-20

- Add support for `Region#associated_continent` to return the containing continent of the region [#43](https://github.com/Shopify/worldwide/pull/43)
- Add more postal code prefixes for KR [#44](https://github.com/Shopify/worldwide/pull/44)
- Add name alternates for the zones of South Korea [#45](https://github.com/Shopify/worldwide/pull/45)
- Add support for Hangul and Arabic script detection, update Latn regexp [#46](https://github.com/Shopify/worldwide/pull/46)

## [0.4.1] - 2023-11-10

- Add support for deprecated timezone Australia/Canberra [#35](https://github.com/Shopify/worldwide/pull/35)
- Add alternate codes for territories [#39](https://github.com/Shopify/worldwide/pull/39)
- Allow building numbers on address2 field for Austrian addresses [#40](https://github.com/Shopify/worldwide/pull/40)
- Add zone name alternates for Italy [#42](https://github.com/Shopify/worldwide/pull/35)

## [0.4.0] - 2023-11-08

- Add region name alternates [#32](https://github.com/Shopify/worldwide/pull/32)
- Cache `Region#parent_name` [#33](https://github.com/Shopify/worldwide/pull/33)
- Use hash tables to look up regions by code [#36](https://github.com/Shopify/worldwide/pull/36)

## [0.3.0] - 2023-11-03

- Add code alternates for Japan [#23](https://github.com/Shopify/worldwide/pull/23)
- Add code alternates for Puerto Rico [#24](https://github.com/Shopify/worldwide/pull/24)
- Record multiple parents per region [#27](https://github.com/Shopify/worldwide/pull/27)
- Add region.building_number_may_be_in_address2 [#28](https://github.com/Shopify/worldwide/pull/28)
- Lookup by parent-child ISO and CLDR codes for dual-status territories
  [#29](https://github.com/Shopify/worldwide/pull/29)
- Handle ISO_CODE only zones lookup [#26](https://github.com/Shopify/worldwide/pull/26)

## [0.2.0] - 2023-11-01

- Add Region#group and Region#group_name [#15](https://github.com/Shopify/worldwide/pull/15)
- Ensure Region#has_zip? returns a boolean for all regions [#17](https://github.com/Shopify/worldwide/pull/17)
- Zip normalization bugfix when parent isocode is not set [#6](https://github.com/Shopify/worldwide/pull/6)
- Update region parent when alternates are defined [#18](https://github.com/Shopify/worldwide/pull/18)
- Add partial matching for Region#valid_zip? [#19](https://github.com/Shopify/worldwide/pull/19)

## [0.1.1] - 2023-10-27

- Fix issue with deploy to rubygems.org failing

[0.1.0] - 2023-10-27

- Initial release of Worldwide
