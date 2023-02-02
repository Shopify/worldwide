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
- Do not update the CHANGELOG, or the `Worldwide::VERSION` constant.

### Releasing

1. Check the [semantic versioning page](http://semver.org) for info on how to version the new release.
2. Update the  `Worldwide::VERSION` constant in **lib/worldwide/version.rb**.
3. Add a `CHANGELOG.md` entry for the new release with the date.
4. Release the gem to rubygems using ShipIt (this will create tag/push during deploy)
