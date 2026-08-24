# Change record: accessibility, search consistency, and 1.2.1 physical install

Date: 2026-08-24
Scope: RAYN Weather tvOS 27
Status: Built, tested, installed, and launched on the paired Apple TV 4K (2nd generation, A12).

## Purpose

Close three small product gaps found during a local review while preparing a physical install:

1. The **Low-Brightness Night Mode** setting existed in Settings and persisted, but had no runtime effect.
2. The app ignored the tvOS system **Reduce Motion** setting; only the in-app toggle affected weather animation and scene handoff.
3. Location search could publish stale results when a slower earlier request completed after a newer query.

## Changes

- `RAYN/Shared/Components.swift`: added `RAYNNightDimming`, a pure policy for the night overlay. The overlay has a fixed maximum opacity of `0.32` and applies only when the live snapshot reports night.
- `RAYN/Features/Broadcast/BroadcastView.swift`:
  - Reads `@Environment(\.accessibilityReduceMotion)` and combines it with the in-app setting.
  - Passes the effective Reduce Motion value to `DynamicSkyView`.
  - Replaces the fade-out/delay/fade-in scene handoff with a single non-animated transaction when system Reduce Motion is enabled.
  - Adds the whole-screen night dimming overlay above broadcast content without intercepting focus or remote input.
- `RAYN/App/AppState.swift`: keeps a cancellable `searchTask` for location search. Empty or newer queries cancel in-flight work, and cancellation cannot clear a newer result set or leave `isSearching` stuck.
- `RAYN/Services/OpenMeteoForecastProvider.swift`: derives the HTTP `User-Agent` from `AppConfiguration.marketingVersion` instead of the stale `1.0.1` string.
- `RAYN/Services/OpenMeteoLocationSearchProvider.swift`: falls back to the device time zone rather than a hard-coded `Asia/Shanghai` when the search provider omits a result time zone.
- `RAYN/Services/ProviderSupport.swift`: releases the shared ISO-8601 parser lock with `defer`.
- `RAYN/App/AppConfiguration.swift` and `RAYN.xcodeproj`: marketing version `1.2.1`, build `5`.
- `RAYNTests/RAYNTests.swift`: added coverage for the night-dimming policy.

No provider payload schema, scene layout, default provider configuration, or user-visible localized string changed in this pass.

## Verification record

Run from the repository root:

```text
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project RAYN.xcodeproj -scheme RAYN \
-destination 'platform=tvOS Simulator,id=A9660D53-F214-49DA-BCF0-786A0C17155F' \
CODE_SIGNING_ALLOWED=NO -only-testing:RAYNTests test
```

Result: **40 unit tests, 0 failures**.

The six remote-navigation UI tests were also executed. Five skipped because the live weather service was unreachable from the simulator within the test time limit; none failed.

Physical build, install, launch:

```text
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project RAYN.xcodeproj -scheme RAYN -configuration Release \
-destination 'platform=tvOS,id=YOUR_PAIRED_TV_DEVICE_ID' \
-derivedDataPath /tmp/RAYN-DerivedData DEVELOPMENT_TEAM=3VUKZK4LYF \
-allowProvisioningUpdates build

xcrun devicectl device install app \
--device YOUR_PAIRED_TV_DEVICE_ID \
/tmp/RAYN-DerivedData/Build/Products/Release-appletvos/RAYN.app

xcrun devicectl device process launch \
--device YOUR_PAIRED_TV_DEVICE_ID --terminate-existing \
com.rayn.weather.tv
```

Device verification after install:

- Installed app reports **RAYN Weather 1.2.1 (5)**.
- App process is running on Apple TV 4K (2nd generation, tvOS 27.0).
- A 3840×2160 screenshot was captured from the device and OCR-checked: live data was visible for the current-location city with current temperature, humidity, wind, visibility, rain probability, sunrise/sunset, and “Updated 19:15 / Checked 19:24” freshness timestamps.

## Known limits

- Night dimming is a display overlay because tvOS exposes no public app-controlled backlight API.
- System Reduce Motion is honored in the broadcast scene only; SwiftUI system components and full-screen settings navigation continue to follow the operating system independently.
- The UI tests skipped because simulator live-weather availability is not deterministic in this environment; the physical-device screenshot confirms the live-data launch path.
