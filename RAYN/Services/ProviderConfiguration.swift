import Foundation

/// Forecast backends supported by the app.
///
/// This is intentionally a build-time choice rather than a user-facing setting:
/// provider credentials, attribution, rate limits, and licensing belong to the
/// app distribution, not to the weather screen. Change `forecastSource` below
/// when preparing a WeatherKit-enabled distribution.
enum ForecastSource: String, CaseIterable {
  case openMeteo
  case weatherKit
}

enum AirQualitySource: String, CaseIterable {
  case openMeteo
}

/// Radar backends supported by the app.
///
/// RainViewer is the currently implemented global tile adapter. Regional official
/// feeds such as NOAA NEXRAD/MRMS and DWD composites are documented in
/// `docs/DATA_SOURCES.md` and can be added behind the same `RadarProvider` protocol
/// without changing the views or refresh coordinator.
enum RadarSource: String, CaseIterable {
  case rainViewer
}

enum MarineSource: String, CaseIterable {
  case openMeteo
}

enum LocationSearchSource: String, CaseIterable {
  case openMeteo
}

enum RAYNProviderConfiguration {
  // These lines are the only source-selection switches for a public build.
  // Custom distributions may instead inject a WeatherProviderSuite and a
  // LocationSearchProvider at AppState's composition boundary.
  static let forecastSource: ForecastSource = .openMeteo
  static let airQualitySource: AirQualitySource = .openMeteo
  static let radarSource: RadarSource = .rainViewer
  static let marineSource: MarineSource = .openMeteo
  static let locationSearchSource: LocationSearchSource = .openMeteo

  static func makeWeatherProviderSuite() -> WeatherProviderSuite {
    WeatherProviderSuite(
      forecast: makeForecastProvider(),
      airQuality: makeAirQualityProvider(),
      radar: makeRadarProvider(),
      marine: makeMarineProvider()
    )
  }

  static func makeForecastProvider() -> ForecastProvider {
    switch forecastSource {
    case .openMeteo:
      return OpenMeteoForecastProvider()
    case .weatherKit:
      return AppleWeatherKitProvider()
    }
  }

  static func makeRadarProvider() -> RadarProvider {
    switch radarSource {
    case .rainViewer:
      return RainViewerRadarProvider()
    }
  }

  static func makeAirQualityProvider() -> AirQualityProvider {
    switch airQualitySource {
    case .openMeteo:
      return OpenMeteoAirQualityProvider()
    }
  }

  static func makeMarineProvider() -> MarineWeatherProvider {
    switch marineSource {
    case .openMeteo:
      return OpenMeteoMarineProvider()
    }
  }

  static func makeLocationSearchProvider() -> LocationSearchProvider {
    switch locationSearchSource {
    case .openMeteo:
      return OpenMeteoLocationSearchProvider()
    }
  }
}
