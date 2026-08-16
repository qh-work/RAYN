# RAYN Weather Roadmap

RAYN Weather aims to become a dependable, provider-neutral weather experience for the largest screen in the home. This roadmap describes direction, not a promise of release dates. Items move only after they work with live data, pass focus and accessibility checks, and remain responsive on Apple TV 4K (2nd generation, A12).

## What is available now

- Native SwiftUI application built for tvOS 27.
- Current, hourly, and 10-day forecasts backed by live provider responses.
- Selectable 10-day rows with a dedicated detail view for every available day.
- Weather-driven animated scenes for clear, cloudy, rainy, snowy, foggy, hazy, icy, and storm conditions.
- Precipitation radar playback with deferred MapKit creation, cancellation, bounded in-memory tile caching, and frame handoff safeguards.
- Air-quality, sunlight, moon-phase, and conditional marine views.
- Current-location-first startup, saved locations, scene visibility controls, reduced motion, and opt-in automatic rotation.
- Independent forecast, air-quality, radar, marine, and location-search provider boundaries.
- Unit tests, remote-navigation UI tests, privacy documentation, provider attribution, and a public CI workflow.

## Near term — solidify the 1.x foundation

### Performance and reliability

- Add signposts and repeatable performance baselines for scene transition time, main-thread stalls, memory pressure, radar tile latency, and dropped frames on A12 hardware.
- Expand cancellation and request-coalescing tests for slow or rapidly changing radar connections.
- Add graceful retry controls and clearer no-coverage states without presenting cached or invented weather as current data.
- Split the large scene implementation into focused feature modules while preserving the provider-neutral model boundary.

### Interaction and accessibility

- Complete a VoiceOver pass for navigation, weather values, radar status, and daily details.
- Verify high-contrast, reduce-transparency, reduce-motion, and overscan behavior across televisions and projectors.
- Add focus-path regression tests for every scene and for returning from nested detail views.
- Refine text and icon scaling using viewing-distance-aware layout rules rather than fixed enlargement.

### Weather detail

- Expand solar detail with elevation, azimuth, golden-hour boundaries, and a clearer daylight timeline where the provider can supply or derive them accurately.
- Expand lunar detail with illumination, phase age, rise and set times, and upcoming phase milestones.
- Keep marine information compact and conditional, with better explanation of coastal coverage and unavailable values.
- Improve severe-condition messaging and make provider update time more prominent without cluttering the primary scene.

### Open-source readiness

- Add English localization while retaining Simplified Chinese.
- Publish provider conformance tests and a sample adapter that can be implemented without changing views.
- Add screenshot-diff checks for core layouts and a documented physical-device release checklist.
- Improve contributor documentation for Xcode signing, WeatherKit capability setup, and data-attribution review.

## Mid term — RAYN Weather 2

- Ship a production-ready WeatherKit adapter path with required Apple attribution and a clear bring-your-own-Apple-Developer configuration.
- Add alternative, properly licensed radar adapters, with regional coverage and update-frequency metadata exposed through the common radar contract.
- Add official weather-alert support when a configured provider supplies authoritative alerts for the selected region.
- Support multiple saved places with a deliberate remote-control flow and per-place refresh status.
- Allow users to choose scene order and a small set of legibility-tested visual modes without disconnecting visuals from real weather conditions.
- Introduce provider comparison diagnostics for maintainers. RAYN Weather will not silently blend conflicting sources or label estimates as observations.

## Longer-term exploration

- Share the provider and model layer with companion Apple-platform clients while keeping the television experience purpose-built.
- Establish a community-maintained provider registry with licensing, attribution, region, freshness, and conformance metadata.
- Explore privacy-preserving settings sync only if it can remain optional and does not require a RAYN Weather account.
- Evaluate public TestFlight or App Store distribution after data licensing, operational ownership, accessibility, and physical-device reliability are ready.

## Explicit non-goals

- Scraping services without permission or bypassing provider terms.
- Fabricating weather, radar, marine values, or AI-written observations when live data is missing.
- Turning the app into an embedded web page or advertising surface.
- Optimizing only for the newest Apple TV while regressing A12 hardware.
- Copying Apple artwork, private frameworks, or proprietary Weather app assets.

## Good first contributions

- Add tests for weather-code edge cases and missing provider fields.
- Improve English localization and accessibility labels.
- Document a new provider proposal, including license, attribution, region, freshness, and rate limits.
- Reproduce and measure a focus or performance issue on physical Apple TV hardware.
- Review layouts on different display sizes and submit screenshots with the viewing setup documented.

Before starting a larger item, open an issue so the data contract, licensing, focus behavior, and A12 performance impact can be agreed on first.
