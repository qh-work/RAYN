# Privacy

This statement describes the upstream RAYN Weather project. Forks and redistributed builds may behave differently and must publish their own accurate disclosures.

## Data RAYN Weather does not collect

The upstream application has no RAYN Weather account system, advertising SDK, analytics SDK, telemetry endpoint, or user-profile service. The project maintainer does not receive a user's location history, favorites, or settings from the application.

## Location and network requests

- RAYN Weather requests location permission only when the user enables current-location weather.
- Coordinates needed for a weather query are sent to the configured forecast, air-quality, marine, or location provider.
- Radar and MapKit requests can reveal the requested map area and the device's network address to the relevant service operator.
- Provider operators may retain server logs under their own privacy policies. See [`docs/DATA_SOURCES.md`](docs/DATA_SOURCES.md).

## Local storage

Saved locations, presentation preferences, and migration flags are stored locally using platform preferences. The production startup path does not persist a weather-history database or a location-history log.

## Permissions

The privacy manifest is stored at `RAYN/Resources/PrivacyInfo.xcprivacy`. A distributor that adds analytics, accounts, different providers, or other tracking must update both the manifest and this statement.
