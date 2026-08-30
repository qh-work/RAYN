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
/// Regional selects NOAA in the contiguous US and RainViewer elsewhere (or
/// after a NOAA failure). Views consume provider-neutral tile metadata.
enum RadarSource: String, CaseIterable {
  case rainViewer
  case regional
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
  #if RAYN_WEATHERKIT
  static let forecastSource: ForecastSource = .weatherKit
  #else
  static let forecastSource: ForecastSource = .openMeteo
  #endif
  static let airQualitySource: AirQualitySource = .openMeteo
  static let radarSource: RadarSource = .regional
  static let marineSource: MarineSource = .openMeteo
  static let locationSearchSource: LocationSearchSource = .openMeteo

  static func makeWeatherProviderSuite() -> WeatherProviderSuite {
    WeatherProviderSuite(
      forecast: makeForecastProvider(),
      airQuality: makeAirQualityProvider(),
      radar: makeRadarProvider(),
      marine: makeMarineProvider(),
      alerts: NWSAlertProvider()
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
    case .regional:
      return RegionalRadarProvider()
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
