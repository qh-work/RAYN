# Changelog

All notable changes to RAYN Weather will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.3] - 2026-08-24

### Added

- Requested Open-Meteo daily moonrise and moonset fields and mapped them into the live astronomy cards.
- Added an air-quality summary sub-panel to the home screen with a focusable path to pollutant and hourly-detail views.

### Changed

- Removed Air Quality from the primary broadcast tab and automatic-rotation sequence; it remains available from the home summary.
- Consolidated the animated weather atmosphere into one asynchronous Canvas and removed unnecessary per-layer blur subtrees.
- Reduced generic focus scaling and card-shadow composition to keep A12 focus transitions responsive without reducing radar display cadence.

### Verification

- Built the simulator test target and signed the Release configuration with Xcode 27 beta and the tvOS 27 SDK.
- Installed and launched RAYN Weather 1.2.3 (7) on the paired physical Apple TV 4K (2nd generation, A12).
- Queried the live Open-Meteo forecast contract for a public Beijing coordinate and confirmed daily moonrise and moonset values are returned and decoded.

## [1.2.2] - 2026-08-24

### Fixed

- Removed whole-scene publication and task churn from remote focus movement; focus steps now update the local control state without rebuilding the broadcast hierarchy.
- Isolated hourly-card focus styling from the 24-hour Charts view so moving across values does not recalculate the chart or all 24 cards.
- Isolated the 10-day list focus state from its detail scene so vertical navigation does not rebuild the detail branch on every row change.
- Removed redundant animated focus shadows and shortened the remaining local focus transition while retaining native tvOS focus and glass behavior.
- Changed automatic rotation to reset a deadline instead of cancelling and recreating its async task for every interaction.

### Verification

- Built and signed the Release configuration with Xcode 27 beta and the tvOS 27 SDK for Apple TV 4K (2nd generation, A12).
- Installed and launched RAYN Weather 1.2.2 (6) on the paired physical Apple TV; captured a 3840×2160 live-data screenshot.
- The tvOS 27 simulator was shut down after a stale boot/storage-analysis process made its CPU behavior unrepresentative of the app or A12 hardware.

## [1.2.1] - 2026-08-24

### Added

- Implemented the previously inactive Low-Brightness Night Mode as a whole-screen night dimming overlay, with a fixed maximum opacity chosen to preserve text contrast.

### Changed

- Promoted the active location to a large, isolated upper-left page identity and direct city-switching control; current location and saved cities can now be selected without entering Settings.
- Prevented in-flight weather or location responses from replacing a city selected more recently.
- Replaced dashboard-style leading alignment with balanced weather hierarchies and codified shared native-glass typography, radius, and alignment roles.
- Rebalanced the current-weather page into evenly spaced temperature, condition, and live-observation zones; split clothing guidance across both sides of its card; distributed the live ticker into clock, weather, and freshness zones; and increased spacing between navigation and content.
- Increased the television typography baseline across broadcast scenes and enlarged the current-weather labels, navigation, and live-data ticker for comfortable viewing at living-room distances.
- Honored the tvOS system Reduce Motion setting in the weather background and scene handoff animations.
- Canceled stale location-search requests so a slower earlier query cannot overwrite newer results.
- Updated the Open-Meteo request User-Agent to track the app marketing version instead of the obsolete 1.0.1 string.
- Used the current device time zone, rather than a hard-coded Asian city fallback, when a search result omits its time zone.
- Guarded the shared ISO-8601 parser lock with `defer` so every code path releases it.

### Verification

- Ran 40 unit tests on the tvOS 27 simulator with 0 failures.
- Ran the six remote-navigation UI tests; five skipped because live weather was unavailable in the simulator, with 0 failures.
- Built the 1.2.1 Release configuration for Apple TV 4K (2nd generation, A12), installed it over 1.2.0, launched it, and verified live weather and the updated version on the paired device.
- Detailed evidence is recorded in `docs/CHANGE_RECORDS/2026-08-24-accessibility-search-polish.md`.

## [1.2.0] - 2026-08-19

### Added

- Added an Apple Weather-inspired astronomy presentation with a high-detail lunar surface asset, earthshine, soft illumination terminator, and seven-day phase strip.
- Added a sunrise/sunset event card with a 24-hour grid, high solar arc, twilight tails, live sun position, and explicit sunrise/sunset labels.
- Added selectable Sun and Moon detail views with a 10-day daylight trend and a focusable 14-day lunar calendar.
- Added calculated solar elevation, azimuth, and golden-hour boundaries to the astronomy scene.
- Added WeatherKit-backed moonrise and moonset fields while keeping them unavailable when the active provider does not supply them.
- Added condition-aware weather notices for thunderstorms, hail, freezing precipitation, snow, low visibility, strong gusts, and high rain probability.
- Added separate source-update and app-check timestamps for forecast, air-quality, marine, and WeatherKit responses.
- Added user-configurable scene ordering with backward-compatible settings migration.
- Added privacy-safe performance signposts for scene transitions, refreshes, radar-map readiness, and radar-frame presentation.
- Added high-contrast and Reduce Transparency adaptations for glass cards.

### Changed

- Rebalanced the astronomy header and card proportions for large displays so the title and right-side detail remain readable without overlap.
- Tightened solar and lunar card spacing so all astronomy content stays above the persistent live-data ticker.
- Focused the solar card on the trajectory, remaining daylight, solar position, and golden-hour details instead of allowing a lower forecast strip to crowd the chart.
- Added compact current-scene advisory cards that distinguish provider-supplied official alerts from condition-derived notices.
- Added localized labels and detail copy for the new astronomy, advisory, and freshness fields across all nine supported interface locales.
- Corrected the solar hour-angle conversion so sunrise-adjacent elevation and azimuth remain physically plausible.
- Rebalanced the current-weather page, made all 24 hourly values remotely selectable, and replaced the oversized air-quality ring with a readable European AQI scale.
- Split the former all-in-one scene file into independent current, hourly, daily, radar, air-quality, and astronomy modules.
- Reused cached date formatters in the once-per-second ticker and provider parsing paths instead of allocating formatters during rendering.

### Verification

- Added unit coverage for solar geometry, advisory classification, timestamp preservation, and Open-Meteo source-time mapping.
- Added settings-migration and scene-order normalization coverage.
- Verified 39 unit tests and the targeted astronomy plus hourly-to-daily-to-radar UI paths on the tvOS 27 simulator.
- The release checks and visual evidence are recorded in `docs/CHANGE_RECORDS/2026-08-19-macos-weather-polish.md`.

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

[Unreleased]: https://github.com/qh-work/RAYN/compare/v1.2.3...HEAD
[1.2.3]: https://github.com/qh-work/RAYN/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/qh-work/RAYN/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/qh-work/RAYN/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/qh-work/RAYN/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/qh-work/RAYN/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/qh-work/RAYN/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/qh-work/RAYN/releases/tag/v1.0.0
