# RAYN Weather for Apple TV

**Weather, alive.**

[![tvOS CI](https://github.com/qh-work/RAYN/actions/workflows/ci.yml/badge.svg)](https://github.com/qh-work/RAYN/actions/workflows/ci.yml)

> **Project status:** Public open-source preview. Source builds, tests, hardware validation, and self-install instructions are available; App Store and TestFlight distribution are not currently provided.

[简体中文](README.zh-CN.md) | English

RAYN Weather is a native, open-source weather studio for Apple TV. It turns live weather, air quality, radar, sunlight, moon, and marine conditions into a cinematic interface designed for televisions and projectors.

The production launch path uses real network data only. It does not fall back to demo weather, a hard-coded city, or invented radar imagery when a provider is unavailable.

## Preview

![RAYN Weather current conditions on tvOS 27](docs/media/screenshots/01-current-weather.png)

More live captures and a tvOS 27 walkthrough are available in the [media gallery](docs/media/README.md).

[Watch the 34-second tvOS 27 walkthrough](docs/media/RAYN-tvOS27-demo.mp4)

## Highlights

- Native SwiftUI application built for tvOS 27.
- Weather-aware animated backgrounds for clear skies, clouds, rain, freezing rain, snow, hail, fog, haze, and thunderstorms.
- Remote-friendly hourly and 10-day forecasts with focusable values and per-day detail views.
- Radar playback with lazy map creation, bounded tile caching, and transition safeguards for Apple TV 4K (2nd generation, A12).
- Air quality, sun, moon phase, and optional marine conditions without fake fallback values.
- Location-first startup, saved-place fallback, and no default city baked into the production path.
- Provider-neutral architecture so forecast, air quality, radar, marine, and location-search services can be replaced independently.
- Automatic system-language support for English, French, German, Spanish, Italian, Japanese, Korean, Simplified Chinese, and Traditional Chinese.
- No advertising, analytics SDK, account system, or third-party Swift package dependency.

## Languages

RAYN Weather follows the Apple TV system language automatically. The complete interface, weather conditions, accessibility labels, dates, and dynamic summaries are localized for:

- English, French, German, Spanish, and Italian
- Japanese and Korean
- Simplified Chinese and Traditional Chinese

Other system languages fall back to English. Location-search requests use the matching supported language when the provider offers it, while saved provider data remains independent from the interface language.

Translations live in Xcode String Catalogs under `RAYN/Resources`. Run `ruby Scripts/validate-localizations.rb` after adding or changing user-facing text; the validator rejects missing locales, stale entries, and unsafe format placeholders.

## Requirements

- Xcode 27 beta or newer with the tvOS 27 SDK.
- A tvOS 27 simulator or Apple TV capable of running the configured deployment target.
- Internet access for live providers.
- An Apple Development team only when installing on physical hardware; Xcode's free Personal Team is sufficient for a seven-day self-signed installation.

## Install or build

No paid Apple Developer Program membership is required to build RAYN Weather for your own Apple TV. A free Apple Account can sign the app through Xcode's Personal Team, but Apple's free provisioning profile expires after seven days and then requires another build and install. See the step-by-step [Apple TV installation guide](docs/INSTALLATION.md).

Clone the repository, open `RAYN.xcodeproj`, select the `RAYN` scheme, and run it on an Apple TV simulator.

For command-line verification:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project RAYN.xcodeproj -scheme RAYN \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation),OS=27.0' \
  CODE_SIGNING_ALLOWED=NO test
```

The project intentionally stores no personal Development Team. For a physical Apple TV, choose your own team in Xcode and change the example bundle identifier if it conflicts with an existing App ID.

## Live data and licensing

| Capability | Default provider | Public-build constraint |
| --- | --- | --- |
| Forecast and location search | [Open-Meteo](https://open-meteo.com/) | Free API is non-commercial, CC BY 4.0, and rate-limited. |
| Air quality | [Open-Meteo Air Quality](https://open-meteo.com/en/docs/air-quality-api) | Model data is not a local sensor reading. |
| Marine weather | [Open-Meteo Marine](https://open-meteo.com/en/docs/marine-weather-api) | Inland and uncovered coordinates may return no marine values. |
| Radar | [RainViewer](https://www.rainviewer.com/api.html) | Personal, educational, and small-community use; attribution required; no SLA. |
| Optional forecast adapter | [Apple WeatherKit](https://developer.apple.com/weatherkit/) | Requires your own capability, signing configuration, and Apple attribution. |

Provider terms are not relicensed by this repository. Review [`docs/DATA_SOURCES.md`](docs/DATA_SOURCES.md) and [`NOTICE.md`](NOTICE.md) before distributing a fork, especially for commercial use.

## Architecture

```text
External services
      ↓
Provider protocols and adapters
      ↓
RefreshCoordinator
      ↓
WeatherSnapshot
      ↓
SwiftUI scenes, animations, and tvOS focus
```

`WeatherSnapshot` is the boundary between data providers and presentation. Views do not decode provider JSON or construct provider URLs. Service selection is centralized in [`RAYN/Services/ProviderConfiguration.swift`](RAYN/Services/ProviderConfiguration.swift).

```text
RAYN/
├── App/             startup, location priority, and settings state
├── Models/          provider-neutral weather models
├── Services/        protocols, HTTP transport, adapters, and refresh orchestration
├── Features/        broadcast scenes and settings
├── VisualEffects/   weather-state visual mapping and animation
├── Shared/          large-screen layout, glass, and focus components
└── Resources/       app icon and privacy manifest
```

Read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) before changing a provider or scene. The A12 performance investigation and remaining refactoring priorities are documented in [`docs/CODE_REVIEW.md`](docs/CODE_REVIEW.md).

For the product story, current limitations, and public-facing introduction, see [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md). Planned work is tracked separately in [`docs/ROADMAP.md`](docs/ROADMAP.md), so future ideas are not confused with shipped behavior.

## Testing

- Unit tests cover weather-code mapping, themes, model conversion, provider configuration, source attribution, and failure isolation.
- Localization tests verify that all nine language bundles are packaged and that Simplified and Traditional Chinese stay distinct.
- UI tests cover hourly-to-daily-to-radar handoff, all 10 daily detail selections, settings navigation, scene traversal, and focus restoration.
- CI builds with the public Xcode 27 runner and executes deterministic unit tests.
- MapKit composition and remote focus are checked on physical Apple TV hardware before each release.

## Contributing

Issues and pull requests are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md), [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md), and [`SECURITY.md`](SECURITY.md) first.

The production application must continue to use real provider responses. Fixtures belong in tests and must never become a startup fallback.

## Creator

RAYN Weather was created and is maintained by **QHWORK**. See [`AUTHORS.md`](AUTHORS.md) for the public attribution policy and [`PROVENANCE.md`](PROVENANCE.md) for the signed origin record and verification instructions.

## License and disclaimer

Source code and original repository assets are available under the [MIT License](LICENSE). Third-party data, platform services, trademarks, and provider output remain subject to their own terms.

RAYN Weather is not affiliated with or endorsed by Apple, Open-Meteo, RainViewer, or any government weather agency. Forecasts can be delayed, incomplete, or inaccurate and must not be used as the sole source for emergency, aviation, marine-navigation, or other safety-critical decisions.
