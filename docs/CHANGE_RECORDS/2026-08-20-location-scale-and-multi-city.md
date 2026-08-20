# Location scale and direct multi-city switching

Date: 2026-08-20

## Why this changed

The earlier hierarchy pass treated centering as the main solution, but the television problem was more direct: the location name was too small and too close to surrounding information. Multi-city data already existed in Settings, yet the broadcast interface had no direct way to switch cities.

## What changed

- Increased the shared location-title role from 58 to 82 points before viewing-distance scaling. At the standard distance setting it renders at roughly 90 points.
- Moved the location identity to an isolated upper-left row and added clear space before the scene navigation and weather content.
- Made the location title focusable. Pressing Select opens a dedicated native-glass city chooser.
- Kept the city chooser in its own `LocationPickerView` component so broadcast navigation and location management remain independently maintainable.
- Added direct choices for current location and every saved city; search, addition, and removal remain in Settings.
- Added a stale-response guard so a forecast requested for the previous city cannot appear beneath the newly selected city name.
- Cancelled the effect of an outstanding current-location result after the user has switched to a saved city.
- Kept all capture-only city seeding behind `DEBUG`; release builds continue to use current location and live provider responses.
- Rebalanced the 24-hour and astronomy scene spacing so their enlarged typography and the persistent live ticker remain inside the television safe area.
- Added the new selection-state accessibility value to all nine supported interface locales.

## Verification

- Built successfully with the Xcode beta tvOS 27.0 simulator SDK.
- Installed and launched on the Apple TV 4K (3rd generation) tvOS 27 simulator.
- Visually reviewed the current, 24-hour, 10-day, astronomy, and city-selection screens at 3840 × 2160 simulator output size.
- Confirmed that the location title remains prominent, the city list is focusable, and the live ticker is not obscured by the enlarged header.

## Evidence

- Current conditions: [`../media/screenshots/01-current-weather.png`](../media/screenshots/01-current-weather.png)
- City switcher: [`../media/screenshots/09-city-switcher.png`](../media/screenshots/09-city-switcher.png)
