# Change record: A12 focus performance

Date: 2026-08-24  
Scope: RAYN Weather tvOS 27  
Status: Built, installed, and launched on the paired Apple TV 4K (2nd generation, A12).

## Finding

The remaining focus hitch was caused by SwiftUI work triggered by remote navigation, not by the A12 chip being unable to run a weather interface. Directional input refreshed global control state, the hourly page read the focused hour while building its complete Charts hierarchy, and the 10-day list kept focus state in the same view branch as the detail page. Custom animated white shadows added another offscreen composition during each transition.

## Changes

- `RAYN/App/AppState.swift`: focus interaction no longer publishes when controls are already visible; the hide task is reused; automatic rotation now resets a deadline instead of cancelling and recreating a task.
- `RAYN/Features/Broadcast/HourlyForecastScene.swift`: removed parent-page dependence on the focused hour and moved focus presentation into a local button style and focus scope. Charts now change only when the user presses Select.
- `RAYN/Features/Broadcast/DailyForecastScene.swift`: moved the vertical list's focus state into `DailyForecastList`, keeping row navigation separate from the detail-card branch.
- `RAYN/Shared/Components.swift`: removed the redundant animated focus shadow from the shared button style.
- `RAYNTests/RAYNTests.swift`: added a regression test that a focus interaction does not publish a whole-scene update.

No radar frame-rate reduction, demo weather, synthetic radar, startup weather cache, or provider change was introduced.

## Verification record

- Xcode 27 beta reports build version `27A5237l` and used the tvOS 27 SDK.
- Release build succeeded for the physical Apple TV target with the local signing team supplied at build time; no signing identity or device identifier was committed.
- RAYN Weather `1.2.2 (6)` was installed and launched on the paired A12 Apple TV. A 3840×2160 screenshot showed live current-location weather, observations, sunrise/sunset, and freshness timestamps.
- The tvOS 27 simulator was left shut down after a stale boot chain and system storage analysis made its CPU load unsuitable for performance conclusions. The prior 40-test simulator baseline passed before this final focus-isolation patch; the physical Release build provides the final compile/signing check for this patch.

## Expected result

Moving focus across the hourly cards or 10-day rows should update the focused control without rebuilding the full Charts/list hierarchy. Scene changes and the radar playback path remain unchanged, including native display cadence and live-data-only behavior.
