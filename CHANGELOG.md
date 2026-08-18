# Changelog

All notable changes to RAYN Weather will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added an Apple Weather-inspired astronomy presentation with a procedural moon surface, earthshine, soft illumination terminator, and seven-day phase strip.
- Added a sunrise/sunset event card with the next event time, curved solar path, live sun position, and explicit sunrise/sunset labels.
- Added calculated solar elevation, azimuth, and golden-hour boundaries to the astronomy scene.
- Added WeatherKit-backed moonrise and moonset fields while keeping them unavailable when the active provider does not supply them.
- Added condition-aware weather notices for thunderstorms, hail, freezing precipitation, snow, low visibility, strong gusts, and high rain probability.
- Added separate source-update and app-check timestamps for forecast, air-quality, marine, and WeatherKit responses.

### Changed

- Rebalanced the astronomy header and card proportions for large displays so the title and right-side detail remain readable without overlap.
- Tightened solar and lunar card spacing so all astronomy content stays above the persistent live-data ticker.
- Added compact current-scene advisory cards that distinguish provider-supplied official alerts from condition-derived notices.
- Added localized labels and detail copy for the new astronomy, advisory, and freshness fields across all nine supported interface locales.
- Corrected the solar hour-angle conversion so sunrise-adjacent elevation and azimuth remain physically plausible.

### Verification

- Added unit coverage for solar geometry, advisory classification, timestamp preservation, and Open-Meteo source-time mapping.
- The tvOS 27 build and targeted test commands are recorded in `docs/CHANGE_RECORDS/2026-08-17-astronomy-advisories-freshness.md`.

## [1.1.0] - 2026-08-17

### Added

- Added automatic system-language support for English, French, German, Spanish, Italian, Japanese, Korean, Simplified Chinese, and Traditional Chinese.
- Added localization bundle, script-selection, and format-placeholder regression tests.

### Changed

- Localized weather states, summaries, dates, location search, settings, radar, astronomy, marine conditions, and accessibility labels through Xcode String Catalogs.
- Changed unsupported interface languages to fall back consistently to English.
- Removed the secondary `RAYN` and `Weather Studio` branding from the in-app header and Settings screen.
- Improved tvOS focus recovery after weather-scene handoffs while preserving the normal five-second control auto-hide behavior.

## [1.0.1] - 2026-08-17

### Added

- Added a self-install guide for Apple TV users signing with a free Apple Account.

### Changed

- Changed the public app and documentation name to **RAYN Weather** while preserving the stable `RAYN` project, target, module, and icon brand.
- Bumped the app build to 1.0.1 (2).

## [1.0.0] - 2026-08-16

### Added

- Native tvOS weather studio with live forecast, air quality, radar, sun, moon, and marine scenes.
- Provider-neutral services for Open-Meteo, RainViewer, and optional WeatherKit.
- Weather-driven animated backgrounds and large-screen focus behavior.
- Selectable 10-day detail views, settings, privacy manifest, unit tests, and remote-navigation UI tests.

### Changed

- Rebranded the application, Xcode project, targets, schemes, modules, and public documentation as RAYN.
- Isolated radar rendering and constrained transition work for Apple TV 4K (2nd generation, A12).

[Unreleased]: https://github.com/qh-work/RAYN/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/qh-work/RAYN/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/qh-work/RAYN/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/qh-work/RAYN/releases/tag/v1.0.0
