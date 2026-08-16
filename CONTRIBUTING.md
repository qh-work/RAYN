# Contributing to RAYN Weather

Thank you for helping improve RAYN Weather. Contributions should preserve the project's real-data, provider-neutral, and television-first design.

## Before opening a pull request

1. Search existing issues and pull requests.
2. Open an issue before a broad visual redesign, new external provider, breaking model change, or large dependency.
3. Keep one pull request focused on one problem.
4. Do not commit credentials, user locations, signing teams, device identifiers, DerivedData, or Xcode user state.

## Architecture rules

- Views consume `WeatherSnapshot` and provider-neutral models only.
- Decode external JSON and perform unit conversion inside the corresponding provider adapter.
- Register provider choices in `ProviderConfiguration.swift`; do not scatter source switches through the UI.
- Missing or uncovered data stays missing. Do not invent values, radar frames, or a fallback city.
- Test fixtures may be used only by tests and previews that cannot enter the production startup path.
- Record provider attribution, coverage, licensing, and refresh semantics in `docs/DATA_SOURCES.md`.

## tvOS interaction and performance

- Every interactive element must work with the Siri Remote focus engine.
- Provide useful accessibility labels or hints for new controls.
- Check focused scaling for clipping at 1080p and 4K logical layouts.
- Keep MapKit, tile overlays, and particle effects out of unrelated scene transitions.
- Do not reduce functionality or animation frame rate as a substitute for finding a performance regression.

## Verification

Run the deterministic suite before submitting:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project RAYN.xcodeproj -scheme RAYN \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation),OS=27.0' \
  CODE_SIGNING_ALLOWED=NO -only-testing:RAYNTests test
```

Changes involving focus, navigation, radar, or rendering should also run the relevant UI tests and be checked on physical hardware when available.

## Commit and pull-request style

Use concise, imperative commit messages. Conventional prefixes such as `feat:`, `fix:`, `perf:`, `test:`, and `docs:` are welcome but not mandatory.

A pull request should explain the user-visible outcome, affected providers or scenes, verification performed, and any remaining hardware or regional limitations.
