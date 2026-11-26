## Gitalytics Changelog

#### v.1.4.0
* Brand new HTML report: a single self-contained page (no CDN assets) with inline SVG charts, light and dark themes, and a mobile-friendly layout.
* New report sections: activity timeline, sortable author leaderboard with trends, weekday/hour punch card, most changed files, top directories and highlights.
* Commits now keep their full timestamp (`Commit#time`).
* Dropped the `haml`, `color-generator` and `matrix` dependencies; gitalytics now has no runtime dependencies.
* Requires Ruby 3.1 or newer.
* Runs on modern Ruby again (fixes for Bundler, Minitest and stdlib changes).
* CI moved to GitHub Actions (Ruby 3.1 to 3.4) with RuboCop.

#### v.1.3.1
* Add Benchmark option.
* Fix lots of Rubocop's warnings.
* Use haml and partials for html report template.
* Improved code-smell.

#### v.1.3.0
* Changed CLI output text.
* Re-structure of gem's source code.
* Authors are now grouped by name.
* Added CLI option -e to group authors by email (old behavior).
* Updated Chart.js version.
* Updated Bootstrap version.
* Updated HTML report design.

#### v.1.2.2
* Sort users by commit count
* Fixed bug when author's name has special characters
* Minor code style fixes

#### v.1.2.1
* Fixed bug that prevented gitalytics to initialize correctly. (Thanks @willyschwindt)

#### v.1.2.0
* Git log parser totally refactored. (Thanks @grilix)
* Gitalytics now open html report in browser automatically. (Thanks @surendrans)
* Moved classes and modules to external files.
* Added CLI option -n that prevents report to load automatically in web browser.
* Dashboard added with some quick stats for your git repository.

#### v1.1.1
* Add Changelog :)
* Update Readme.
* Fix bug which preventing authors with special characters to be shown on the report. (thanks @afrojas)
* Fix bug which may result in a broken report if the user uses a default format for git log. (thanks @dgiunta)

#### v1.1.0
* Add Insertions vs. Deletions graph for Users.
* Add weekday commits count graph for Users.
* Change the way it shows the authors information.
