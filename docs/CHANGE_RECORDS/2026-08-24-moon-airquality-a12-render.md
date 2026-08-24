# Change record: moon events, home air quality, and A12 rendering

Date: 2026-08-24
Scope: RAYN Weather tvOS 27
Status: Built, installed, and launched on the paired Apple TV 4K (2nd generation, A12).

## Findings

- The production forecast source was Open-Meteo, but the daily request did not ask for `moonrise` or `moonset`. The model and cards already had optional fields, so the live default provider left them empty.
- Air quality was available in the snapshot but occupied a primary broadcast tab instead of being visible in the home environmental summary.
- The animated background used several independently updating SwiftUI layers, including blurred cloud and fog subtrees. That work continued while tvOS was animating focus and composing glass cards.

## Changes

- Added Open-Meteo daily `moonrise`, `moonset`, and `moon_phase` request/decoding support. Moonrise and moonset are provider-backed; if a location has no event on that date, the UI keeps the value unavailable.
- Added a focusable home air-quality summary with live AQI, level, and source timestamp. Selecting it opens the existing detailed pollutant and hourly trend scene.
- Removed Air Quality from the primary header and automatic-rotation list while keeping the detailed scene reachable from the home summary.
- Replaced the animated background's separate particle, cloud, fog, haze, hail, and ice subtrees with one asynchronous Canvas. Clear-day glow is static, and the remaining weather states retain display-linked animation.
- Reduced generic focus scale/brightness and default card-shadow costs. Radar playback cadence and live tile behavior were not reduced or replaced.

## Verification record

- Xcode 27 beta (`27A5237l`) with the tvOS 27 SDK built the simulator test target successfully.
- The physical Release build succeeded, was installed, and was launched as RAYN Weather `1.2.3 (7)` on the paired A12 Apple TV.
- A 3840×2160 hardware screenshot showed the home air-quality sub-panel with live AQI data.
- A public Beijing Open-Meteo request returned daily moonrise and moonset values; provider mapping tests assert both values and their time zone conversion.
- An Instruments Animation Hitches recording could not be completed because the Xcode tracing service disconnected from the Apple TV. No simulator result was used as a hardware performance claim.
