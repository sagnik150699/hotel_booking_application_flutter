# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.0.0] - 2026-09-28

A ground-up redesign of the app, its architecture, tooling and platform
configuration.

### Added

- Full booking flow: hotel details page, stay planner with date-range picker
  and guest stepper, checkout form with validation, animated confirmation
  page with a secure confirmation code, and a Trips page with cancellation.
- Saved stays tab with a live badge count.
- Refinements: sort menu (recommended, price, rating), free-cancellation,
  minimum rating, category and amenity chips, with a one-tap clear.
- Responsive shell: bottom navigation on phones, navigation rail on
  tablets, extended rail with the brand mark on desktop and wide web
  windows. Result grids adapt from one to three columns.
- Material 3 light and dark themes derived from a single seed colour.
- Animations: staggered card entrances, hero cover transitions, heart "pop"
  on save, animated price totals, cross-fading tabs, hover lift on
  web/desktop, shimmer skeletons while loading, and a self-drawing success
  tick on confirmation.
- Thirteen illustrated hotels across eight Indian cities, with cover art,
  app icons (Android adaptive + legacy, iOS, web incl. maskable) and README
  images generated from vector definitions by `tool/generate_images.cjs`.
- Domain layer with `StaySearch`, `StayQuote`, `HotelFilters`,
  `HotelSearchEngine`, `GuestDetails` validation, `BookingPolicy` and a
  `ConfirmationCodeGenerator`; repositories with injectable latency and
  clock; `ChangeNotifier` controllers wired through an `InheritedWidget`.
- 100+ unit and widget tests, including an end-to-end booking test, run in
  CI with coverage. `flutter_test_config.dart` makes missed taps fatal.
- Security hardening on every platform (see `SECURITY.md`), a CSP for the
  web build, least-privilege CI, Dependabot, and scripts to verify the web
  bundle and capture screenshots in headless Chromium.

### Changed

- Minimum Dart SDK is now 3.10 and minimum Flutter 3.38; iOS deployment
  target raised from 9.0 to 13.0.
- CI runs on every branch and now builds web, Android (debug and release)
  and iOS (no code signing) in addition to analysis and tests.
- README rewritten with architecture, platform run instructions and
  screenshots.

### Removed

- The single-page `hotel_search` feature and its widgets, replaced by the
  `hotels`, `booking` and `shell` features.
- Generated `ios/Flutter/ephemeral/` files are no longer tracked.

## [1.0.0]

- Initial responsive hotel search sample.
