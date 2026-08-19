# macOS Weather visual polish and 1.2 release record

Date: 2026-08-19

Target: tvOS 27

Primary performance target: Apple TV 4K (2nd generation, A12)

## Scope

This release compared the existing television interface with the public design patterns visible in macOS Weather, then adapted those patterns for remote focus, television safe areas, and long viewing distance. No Apple artwork, private framework, or proprietary Weather app asset was copied.

The review concentrated on the issues raised during physical-device use: shallow and unclear solar presentation, an artificial-looking moon, left-heavy layouts, small values on a projector, clipped focus shadows, radar handoff stalls, non-interactive forecast detail, inactive Settings controls, and maintainability for an open-source provider-neutral project.

## Product changes

- Rebuilt the current-weather composition around a centered temperature and condition hero, live observations, compact clothing guidance, and balanced essential facts.
- Kept hourly temperature, precipitation, and wind as discrete marks; all 24 hourly cards are focusable and horizontally scrollable.
- Replaced the oversized air-quality ring with a six-band European AQI scale, threshold-colored trend bars, readable advice, and pollutant tiles.
- Rebuilt the Sun card with a high 24-hour solar arc, horizon, grid, twilight tails, live solar position, sunrise, sunset, remaining daylight, golden hour, and ten-day daylight bars.
- Rebuilt the Moon card with textured lunar detail, earthshine, a soft illuminated terminator, phase age, illumination, next major phase, provider-supplied rise and set values, and a selectable fourteen-day phase calendar.
- Made the overview Sun and Moon cards open dedicated detail panels; Menu and the visible Close button return to the overview.
- Added scene reordering to Settings while preserving existing enabled and disabled choices across upgrades.
- Added material adaptations for Reduce Transparency and Increased Contrast.

## Architecture and performance

- Removed the former all-in-one `SceneViews.swift` and split current, hourly, daily, radar, air-quality, and astronomy scenes into independent files.
- Kept provider DTOs and URLs out of views. Every new panel still reads only provider-neutral `WeatherSnapshot` fields.
- Added anonymous system signposts for scene transition, weather refresh, radar-map readiness, and radar-frame presentation. They contain no location or weather payload.
- Reused date formatters by locale, time zone, and template. The once-per-second ticker no longer allocates a new formatter every second.
- Preserved the native animation cadence. Radar performance work does not reduce the frame rate and still uses only timestamped live tiles held in a bounded in-memory playback cache.

## Data integrity and privacy

- Production startup still uses current location first and never starts with a hard-coded city, demo response, generated radar image, or stale startup weather cache.
- Open-Meteo values remain live provider responses. Optional WeatherKit moonrise and moonset are shown only when that provider supplies them; missing values are not inferred or turned into zero.
- General screenshots use public Beijing coordinates and radar media uses public New York City coordinates. No maintainer location, Development Team, device identifier, signing identity, or local filesystem path is stored in the release files.
- All added visible strings and focus hints are complete in English, French, German, Spanish, Italian, Japanese, Korean, Simplified Chinese, and Traditional Chinese.

## Verification

- Xcode 27 beta with the tvOS 27 SDK completed the Debug simulator build with no build failure.
- The localization validator reported complete catalogs for all nine locales, and the compiler-emitted key comparison found no missing catalog entry.
- The final unit run passed 39 of 39 tests with no failure or skip.
- Focused UI checks passed the astronomy conditional-marine path and the 24-hour → 10-day → radar handoff path, 2 of 2 tests.
- 3840 × 2160 captures were inspected for current weather, hourly forecast, air quality, astronomy overview, Sun detail, and Moon detail. Public gallery copies were resized to 1920 × 1080.
- `git diff --check` passed, and the public tree was scanned for maintainer paths, private location data, signing identifiers, and access-token patterns.

## Physical-device status

The target A12 Apple TV was reachable on the local network and reported tvOS 27, but it was not advertising an active Xcode developer connection during the final scan. Source publication is therefore supported by simulator and prior A12 performance coverage; installation of build 1.2.0 (4) requires the television to reappear in Xcode's Devices and Simulators window with Developer Mode active. Follow `docs/PHYSICAL_DEVICE_RELEASE_CHECKLIST.md` before treating that installation as a completed physical release check.
