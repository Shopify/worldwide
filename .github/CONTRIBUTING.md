# Contributing to Worldwide

We gladly accept bugfixes to this library. Please read the guidelines for reporting issues and submitting pull requests below.

### Reporting issues

- Include the version of Worldwide and Ruby you are using.
- If you run into an unexpected exception, please include a stacktrace.
- Try to include a code snippet that demonstrates the problem.

### Pull request guidelines

1. [Fork it](http://github.com/Shopify/worldwide/fork) and clone your new repo
2. Create a branch (`git checkout -b my_awesome_feature`)
3. Commit your changes (`git add my/awesome/file.rb; git commit -m "Added my awesome feature"`)
4. Push your changes to your fork (`git push origin my_awesome_feature`)
5. Open a [Pull Request](https://github.com/shopify/worldwide/pulls)

The most important guidelines:

- All changes should be covered by tests.
- Your code should support all the Ruby versions we have enabled on CI.
- Add an entry under `Unreleased` in [`CHANGELOG.md`](../CHANGELOG.md) for every change except routine updates such as dependency bumps. Add the public PR link once it exists.
- Leave `Worldwide::VERSION` unchanged unless this PR also prepares a release.

### Releasing

1. Check the [semantic versioning page](http://semver.org) for info on how to version the new release.
2. Update the  `Worldwide::VERSION` constant in **lib/worldwide/version.rb**.
3. Move the entries for this release from `Unreleased` to a dated section in `CHANGELOG.md`.
4. Release the gem to rubygems using ShipIt (this will create tag/push during deploy)
