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

- Add support for `Region#associated_continent` to return the containing continent of the region [#43](https://github.com/Shopify/worldwide/pull/43)
- Add more postal code prefixes for KR [#44](https://github.com/Shopify/worldwide/pull/44)

---

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
