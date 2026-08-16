# RAYN Weather Project Overview

## One-line description

RAYN Weather is an open-source, native tvOS weather studio that turns live weather into a calm, cinematic experience for televisions and projectors.

## Short introduction

RAYN Weather brings current weather, hourly and 10-day forecasts, precipitation radar, air quality, sunlight, moon phase, and optional marine conditions to Apple TV. It is designed around the Siri Remote, long viewing distances, changing display sizes, and the performance limits of real living-room hardware.

The app does not use a hard-coded startup city or production demo weather. Its presentation is driven by live provider responses, while unavailable coverage remains visibly unavailable. Forecast, air-quality, radar, marine, and location-search services are independently replaceable so the project can evolve without rewriting its interface.

## Why RAYN Weather exists

Phone weather apps are optimized for brief, close-range interaction. A television weather experience needs different priorities:

- information must remain readable from across a room without becoming oversized on a smaller projection;
- focus movement and the Back button must behave predictably with a remote;
- animated weather should reflect the reported condition instead of playing a generic blue background;
- expensive maps, materials, shadows, and transitions must be coordinated for sustained 4K use;
- data provenance, coverage, update time, and licensing need to remain explicit in an open-source project.

RAYN Weather treats those constraints as product requirements, not finishing touches.

## Product principles

1. **Live data over visual convenience.** Missing provider data produces an honest unavailable state, never invented values.
2. **Weather drives the atmosphere.** Condition, day or night, visibility, precipitation, and wind inform the visual scene.
3. **Designed for a remote.** Every selectable forecast and setting has a deliberate focus path and return behavior.
4. **Responsive on established hardware.** Apple TV 4K (2nd generation, A12) is a performance reference device.
5. **Replaceable providers.** Views consume provider-neutral models instead of vendor response types.
6. **Open-source safe by default.** The repository excludes credentials, personal signing configuration, user location history, and private account data.

## Current experience

The current build includes six primary scenes:

| Scene | Purpose |
| --- | --- |
| Now | Current conditions, essential values, and a concise comfort or clothing cue. |
| 24 hours | Discrete hourly values for temperature, precipitation probability, and wind. |
| 10 days | A focusable vertical forecast with a detail view for every available day. |
| Radar | Time-based precipitation imagery with explicit coverage and update status. |
| Air quality | Pollutant and index context presented for a large display. |
| Sun, moon, and marine | Solar and lunar detail, with marine information shown only when real coverage exists. |

A full-screen settings experience controls location priority, saved places, visible scenes, automatic rotation, screen wake behavior, and motion preferences.

## Technical profile

- Swift and SwiftUI, with MapKit for the radar map.
- tvOS 27 SDK and deployment target.
- No third-party Swift package dependency.
- `WeatherSnapshot` as the stable presentation contract.
- Separate provider protocols for forecast, air quality, radar, marine weather, and location search.
- Actor-based network transport and coordinated refresh/error isolation.
- XCTest unit coverage and XCUITest Siri Remote navigation coverage.

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the maintenance model and [`DATA_SOURCES.md`](DATA_SOURCES.md) for provider and attribution details.

## Current limitations

- Provider availability, update frequency, and regional coverage vary.
- RainViewer usage is subject to its public API terms and is not a guaranteed operational service.
- WeatherKit requires a contributor's own Apple Developer capability and signing setup.
- The live radar scene has been exercised on Apple TV 4K (2nd generation, A12); broader long-duration and memory-pressure coverage remains ongoing for future releases.
- The public repository is a source-distributed preview. Installing on a physical Apple TV requires each user to sign the app with their own free or paid Apple Account; App Store and TestFlight distribution are not currently available.
- The primary interface is currently Simplified Chinese; English localization is planned.
- This is weather information, not an emergency, aviation, or marine-navigation service.

## Future outlook

Near-term work focuses on accessibility, A12 performance instrumentation, modular scene refactoring, provider conformance tests, localization, and richer solar and lunar detail. Longer-term work may add authoritative alert adapters, additional licensed regional providers, companion Apple-platform clients, and privacy-preserving settings sync.

The maintained plan is in [`ROADMAP.md`](ROADMAP.md). Planned work is not presented as a shipped capability.

## Public attribution

RAYN Weather was created and is maintained by **QHWORK**. Source code and original repository assets are released under the MIT License; external weather data, radar tiles, platform services, and trademarks remain governed by their respective terms.
