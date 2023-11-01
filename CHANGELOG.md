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

Nil.

---

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
