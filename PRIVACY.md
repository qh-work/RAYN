# Privacy

This statement describes the upstream RAYN Weather project. Forks and redistributed builds may behave differently and must publish their own accurate disclosures.

## Data RAYN Weather does not collect

The upstream application has no RAYN Weather account system, advertising SDK, analytics SDK, telemetry endpoint, or user-profile service. The project maintainer does not receive a user's location history, favorites, or settings from the application.

## Location and network requests

- RAYN Weather requests location permission only when the user enables current-location weather.
- Coordinates needed for a weather query are sent to the configured forecast, air-quality, marine, location or official-alert provider. The 1.3 candidate sends US alert coordinates to NWS and requests NOAA radar tiles for applicable US map areas, with RainViewer as the regional fallback.
- Radar and MapKit requests can reveal the requested map area and the device's network address to the relevant service operator.
- Provider operators may retain server logs under their own privacy policies. See [`docs/DATA_SOURCES.md`](docs/DATA_SOURCES.md).

## Local storage

Saved locations, presentation preferences, and migration flags are stored locally using platform preferences. The production startup path does not persist a weather-history database or a location-history log.

Radar tiles use a bounded, in-memory cache keyed by source, frame and map tile. It is not a persistent location history or a startup substitute for a weather response. Diagnostic signposts identify interactions and scenes, not weather values, coordinates or favorite names.

## Permissions

The privacy manifest is stored at `RAYN/Resources/PrivacyInfo.xcprivacy`. A distributor that adds analytics, accounts, different providers, or other tracking must update both the manifest and this statement.
