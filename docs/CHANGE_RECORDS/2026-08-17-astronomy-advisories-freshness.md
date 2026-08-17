# Change record: astronomy, advisories, and data freshness

Date: 2026-08-17
Scope: RAYN Weather tvOS 27
Status: Implemented in the working tree; build and test evidence is appended below.

## Purpose

This change closes three product gaps without presenting calculated or stale values as provider observations:

1. The Sun and Moon scene now explains more of the daily cycle.
2. The current-weather scene now gives a visible, weather-specific notice when the live conditions warrant attention.
3. Each live-data surface distinguishes when the source says the observation was made from when the app received the response.

## Data contract

`WeatherSnapshot.updatedAt` is the source/model time when the provider exposes one. `WeatherSnapshot.fetchedAt` is the time the app completed receipt of that response.

- Open-Meteo forecast: `updatedAt` comes from `current.time`; `fetchedAt` is set after decoding the live response.
- WeatherKit forecast: `updatedAt` comes from `currentWeather.date`; `fetchedAt` is the `makeSnapshot` receipt time.
- Open-Meteo air quality: `updatedAt` comes from `current.time`; `fetchedAt` is set after decoding.
- Open-Meteo marine: `updatedAt` comes from `current.time` or the nearest hourly model point; `fetchedAt` is set after decoding.

The UI labels these as “Updated” and “Checked”. It does not expose provider names in the scene chrome, and it does not imply that a check time makes an older source observation real-time.

## Astronomy behavior

- Sunrise, sunset, daylight duration, and the ten-day daylight strip remain provider-backed.
- Solar elevation and azimuth are calculated from the selected location, timestamp, and an explicit solar-position formula. They are labeled as solar position, not as a provider measurement.
- Golden-hour boundaries are calculated by scanning the selected local day for the -4° and 6° solar-elevation crossings. They are a transparent approximation and are kept out of the provider data contract.
- Moon phase, illumination, age, and the next major phase remain calculated from the phase model.
- Moonrise and moonset are copied only from WeatherKit’s daily moon events. Open-Meteo leaves them unavailable, so the UI shows `--:--` instead of inventing times.

## Advisory behavior

`WeatherAdvisoryBuilder` has two intentionally separate paths:

- WeatherKit `WeatherAlert` values become “Weather Alert” cards and retain their official-alert identity internally.
- Live WMO condition codes and forecast thresholds become “Weather Notice” cards. These are app-generated notices, not government warnings.

The derived notice set covers thunderstorms, hail, freezing precipitation, snow, low visibility, strong gusts, and an elevated rain probability in the next 24 hours. Duplicate notices are removed and the current scene shows at most two cards at once, while the model retains at most three.

## Files changed

- `RAYN/Models/WeatherModels.swift`: solar calculation, advisory model/builder, moon event fields, freshness fields, and summary alert state.
- `RAYN/Services/*Provider.swift`: provider mapping for source time, receipt time, and WeatherKit moon events.
- `RAYN/Features/Broadcast/BroadcastView.swift`: forecast freshness display.
- `RAYN/Features/Broadcast/SceneViews.swift`: advisory cards, solar position panel, lunar rise/set, and air/marine freshness display.
- `RAYN/Shared/Components.swift`: reusable freshness label.
- `RAYN/Resources/Localizable.xcstrings`: nine-locale strings and placeholder-safe translations.
- `RAYNTests/RAYNTests.swift`: pure calculation, advisory, source-time, and Codable regression tests.

## Verification record

Run from the repository root:

```text
jq empty RAYN/Resources/Localizable.xcstrings
ruby Scripts/validate-localizations.rb
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project RAYN.xcodeproj -scheme RAYN -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation),OS=27.0' CODE_SIGNING_ALLOWED=NO test
```

The initial full regression passed on 2026-08-17 with Xcode 27.0 (`27A5237l`) and the tvOS 27.0 simulator: 35 unit tests and 6 UI tests completed with 0 failures. The UI run included the astronomy layout, all-ten-day selection/detail flow, radar handoff, repeated scene traversal, root Menu exit, and settings presentation.

After visual review found an incorrect solar elevation near sunrise, the solar hour-angle conversion was corrected: right ascension is already stored in degrees and must not be multiplied by 15 a second time. The strengthened regression then passed with 37 unit tests and the targeted astronomy UI test (1 test), all with 0 failures. The UI attachment showed Beijing at 05:30 with source sunrise at 05:28, solar elevation `-0.2°`, azimuth `72°`, and golden-hour windows `05:10–06:04` and `18:31–19:26`.

The full regression passed with 43 tests and 0 failures (37 unit tests plus 6 UI tests), with no runtime warnings. The result bundle is recorded at `/Users/zhangyue/Library/Developer/Xcode/DerivedData/RAYN-dvaibqgtuyusbpgfffjywvhbuhla/Logs/Test/Test-RAYN-2026.08.17_05-32-09-+0800.xcresult`. A final cleanup-only unit run after the marine fallback and formatting touch-ups passed all 37 unit tests; its result bundle is `/Users/zhangyue/Library/Developer/Xcode/DerivedData/RAYN-dvaibqgtuyusbpgfffjywvhbuhla/Logs/Test/Test-RAYN-2026.08.17_05-37-59-+0800.xcresult`.

One test-only compilation failure occurred during the first targeted pass because an `async` provider call was placed inside `XCTUnwrap`'s synchronous autoclosure. The result was awaited before unwrapping, and the corrected test passed.

## Known limits

- Open-Meteo is a forecast/model service, not a local weather sensor; its source time is not a guarantee of zero latency.
- The default Open-Meteo path does not provide official weather alerts, so its cards are condition-derived notices only.
- The default Open-Meteo path does not provide moonrise/moonset in the current adapter.
- The solar-position and golden-hour values are calculated approximations and should be compared with a reference implementation before being treated as navigation or safety data.
