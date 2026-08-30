# 1.3 promotion preparation — not posted

This is a draft checklist, not a release announcement. Only publish after the release gates in the change record pass. Use QHWORK / `qh-work`; no private social accounts or location.

## Suggested project introduction

RAYN Weather is a free, open-source native weather app for Apple TV, designed for a remote and a large screen. It combines current conditions, hourly and ten-day forecasts, weather-driven backgrounds, radar playback, air-quality details and Sun/Moon views. It supports nine interface languages and separates data providers so contributors can replace a source without rebuilding the interface.

Build from source with the documented Xcode/tvOS toolchain and your own signing configuration. It is not currently an App Store or TestFlight download. Provider licensing and regional coverage apply; weather data is not guaranteed instantaneous or suitable as the sole source for emergencies.

Source: https://github.com/qh-work/RAYN

## Release-media shot list

Capture the actual validated release, never a generated mockup or injected weather fixture:

1. Home: public London or Vancouver, visibly balanced city/temperature/AQI and source update time.
2. Ten-day forecast: focus a middle date, open details, return to the same date.
3. Sun/Moon: public New York, solar trajectory and textured phase with real event times or honest absence.
4. Radar: available real frames; retain provider credit and frame time. Include a slow-network retry in the maintainer test video, not a fabricated weather animation.
5. Settings/languages: English, French and Japanese examples with no truncated focused labels.

Record 45–60 seconds of remote navigation. State hardware, release tag and capture date. Do not call screen-recording FPS an A12 benchmark.

## Publication order

- Green CI and completed A12/visual checklist; signed candidate tag first if needed.
- GitHub release notes linking checks, source limitations and installation instructions.
- Refresh README/gallery with that release's real screenshots and video.
- Re-check the contribution guidelines and schema of `dkhamsing/open-source-ios-apps`; submit one `contents.json` entry for Apple TV/weather, with the public source URL and verified screenshot links. Do not edit its generated README or submit duplicates.
- Respond factually to questions in this repository. No unsolicited private-account posts and no absolute “best weather app” claim.
