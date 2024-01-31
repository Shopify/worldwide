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

nil.

---

[0.6.7] - 2024-01-30

- Patch some territory names (BQ, NL, TF, TR) [#77](https://github.com/Shopify/worldwide/pull/77)

[0.6.6] - 2024-01-25

- Allow building numbers on address2 field for Portugal addresses [#73](https://github.com/Shopify/worldwide/pull/73)

[0.6.5] - 2024-01-24

- Allow building numbers on address2 field for Polish addresses [#71](https://github.com/Shopify/worldwide/pull/71)

[0.6.4] - 2024-01-22

- Allow building number in address2 for BE [#70](https://github.com/Shopify/worldwide/pull/70)
- Update Singapore GST in preparation for January 1 2024 increase [#68](https://github.com/Shopify/worldwide/pull/68)

[0.6.3] - 2023-12-11

- Change HM, TF and GS `group_name` to respective continents based on M49. [#60](https://github.com/Shopify/worldwide/pull/60)

[0.6.2] - 2023-12-11

- Zone lookup by Hash [#61](https://github.com/Shopify/worldwide/pull/61)

[0.6.1] - 2023-12-11

- Allow building number in address2 for DK [#53](https://github.com/Shopify/worldwide/pull/53)
- Avoid .present? and .blank? so we don't require Rails [#57](https://github.com/Shopify/worldwide/pull/57)
- (bugfix) Zone lookup by name [#58](https://github.com/Shopify/worldwid/pull/58)

[0.6.0] - 2023-12-08

- Add localized concern messages for address1 + 2 warnings and address may not exist message [#54](https://github.com/Shopify/worldwide/pull/54)
- Change gem description [#51](https://github.com/Shopify/worldwide/pull/51)

[0.5.1] - 2023-11-29

- Fix for building_number_required to default to false [#48]

[0.5.0] - 2023-11-20

- Add support for `Region#associated_continent` to return the containing continent of the region [#43](https://github.com/Shopify/worldwide/pull/43)
- Add more postal code prefixes for KR [#44](https://github.com/Shopify/worldwide/pull/44)
- Add name alternates for the zones of South Korea [#45](https://github.com/Shopify/worldwide/pull/45)
- Add support for Hangul and Arabic script detection, update Latn regexp [#46](https://github.com/Shopify/worldwide/pull/46)

[0.4.1] - 2023-11-10

- Add support for deprecated timezone Australia/Canberra [#35](https://github.com/Shopify/worldwide/pull/35)
- Add alternate codes for territories [#39](https://github.com/Shopify/worldwide/pull/39)
- Allow building numbers on address2 field for Austrian addresses [#40](https://github.com/Shopify/worldwide/pull/40)
- Add zone name alternates for Italy [#42](https://github.com/Shopify/worldwide/pull/35)

[0.4.0] - 2023-11-08

- Add region name alternates [#32](https://github.com/Shopify/worldwide/pull/32)
- Cache `Region#parent_name` [#33](https://github.com/Shopify/worldwide/pull/33)
- Use hash tables to look up regions by code [#36](https://github.com/Shopify/worldwide/pull/36)

[0.3.0] - 2023-11-03

- Add code alternates for Japan [#23](https://github.com/Shopify/worldwide/pull/23)
- Add code alternates for Puerto Rico [#24](https://github.com/Shopify/worldwide/pull/24)
- Record multiple parents per region [#27](https://github.com/Shopify/worldwide/pull/27)
- Add region.building_number_may_be_in_address2 [#28](https://github.com/Shopify/worldwide/pull/28)
- Lookup by parent-child ISO and CLDR codes for dual-status territories
  [#29](https://github.com/Shopify/worldwide/pull/29)
- Handle ISO_CODE only zones lookup [#26](https://github.com/Shopify/worldwide/pull/26)

[0.2.0] - 2023-11-01

- Add Region#group and Region#group_name [#15](https://github.com/Shopify/worldwide/pull/15)
- Ensure Region#has_zip? returns a boolean for all regions [#17](https://github.com/Shopify/worldwide/pull/17)
- Zip normalization bugfix when parent isocode is not set [#6](https://github.com/Shopify/worldwide/pull/6)
- Update region parent when alternates are defined [#18](https://github.com/Shopify/worldwide/pull/18)
- Add partial matching for Region#valid_zip? [#19](https://github.com/Shopify/worldwide/pull/19)

[0.1.1] - 2023-10-27

- Fix issue with deploy to rubygems.org failing

[0.1.0] - 2023-10-27

- Initial release of Worldwide
