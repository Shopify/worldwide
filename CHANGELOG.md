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
- Re-introduce city from UAE address form and disable city autofill [#131](https://github.com/Shopify/worldwide/pull/131)
- Add translations for regionalized zip_unknown_for_address, province_unknown_for_address [#125](https://github.com/Shopify/worldwide/pull/125), [#126](https://github.com/Shopify/worldwide/pull/126)
- Remove city from UAE address form and enable city autofill [#127](https://github.com/Shopify/worldwide/pull/127)
---

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
