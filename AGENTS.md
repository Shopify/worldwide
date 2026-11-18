# Contributing to Worldwide

Worldwide is a public Ruby gem for localization and address handling. It also contains the public `@shopify/worldwide` TypeScript package.

## Keep contributions public

- Use public sources and synthetic address examples. Use a published address for a public institution only when the example needs a real location.
- Do not include customer or merchant data, internal links, private tickets, logs, screenshots, credentials, or unpublished findings. This rule also applies to PR text, comments, commit messages, fixtures, generated data, and CI output.
- Cite the public source for data changes. Prefer the relevant postal authority, government agency, ISO list, Unicode CLDR, or IANA time zone database. Check that readers can open the source without private access. Check the license and keep any required attribution.

## Find the right file

| Change | Start here |
| --- | --- |
| Address layouts, postal rules, zone codes, country settings | `data/regions/<CC>.yml`, `lib/worldwide/region.rb`, `lib/worldwide/zip.rb` |
| Region labels and translations | `data/regions/<CC>/`, `data/cldr/`, `data/other/` |
| CLDR corrections | [`rake/cldr/patch.rb`](rake/cldr/patch.rb), [`rake/tasks/cldr.rake`](rake/tasks/cldr.rake) |
| Postal prefix imports | [`rake/postal/README.md`](rake/postal/README.md) |
| TypeScript address code | [`lang/typescript/`](lang/typescript/) |

## Make the change easy to review

- Keep the change to one behavior or one related group of countries. Split unrelated cleanup and dependency updates into separate PRs.
- Match nearby YAML key order, indentation, and quoting. For generated CLDR data, change the patch or generator and include the matching output. Run `bundle exec rake cldr:data:generate_paths` after you add, move, or remove indexed data files.
- Treat changes to canonical codes, defaults, locale scripts, fallback rules, and validation as API changes. Show the old and new output. Keep historical codes as lookup alternates when appropriate. Test lookup by both codes and check the value the API returns.
- For postal changes, test old and new formats, normalization, and invalid input. Check that examples match the rule. An example can also affect the reported postal code type. For address layouts, check both `edit` and `show` where applicable. See [Address format strings](docs/address_format_strings.md).
- Add focused Minitest coverage next to related tests. For country-specific tests in `test/worldwide/regions/`, use `<cc>_test.rb` and a class such as `PaTest`. If shared region data changes, check its effect on the TypeScript package too.

## Run checks

Use `.ruby-version` for local setup. Check [`worldwide.gemspec`](worldwide.gemspec) for the supported Ruby minimum and [Ruby CI](.github/workflows/ci.yml) for the test matrix. Do not assume the oldest Ruby in CI is the supported minimum.

```sh
bundle install
bundle exec ruby -Itest test/worldwide/regions/pa_test.rb  # example focused test
bin/test
bin/style
```

Run `bin/test-cldr-rake-tasks` from a clean checkout to check that the full CLDR pipeline reproduces the committed data. The script downloads data and reports unexpected changes to the working tree.

For changes that affect TypeScript, use the Node and pnpm versions in [TypeScript CI](.github/workflows/ci-typescript.yml):

```sh
cd lang/typescript
pnpm install
pnpm typecheck
pnpm lint
pnpm test
pnpm build
```

## Open the PR

- Use the [PR template](.github/pull_request_template.md). State the problem, why you chose this fix, which behavior changes, and what you tested. Include public sources, a small reproduction, or a before-and-after example when useful.
- Add an entry under `Unreleased` in [`CHANGELOG.md`](CHANGELOG.md) for every change except routine updates such as dependency bumps. Add the public PR link once it exists. Leave the version bump to the release unless a maintainer asks for both in the same PR.
- For a TypeScript change that affects package users, add a changeset with `pnpm changeset` from `lang/typescript`. See the [package README](lang/typescript/README.md) for the release process.
