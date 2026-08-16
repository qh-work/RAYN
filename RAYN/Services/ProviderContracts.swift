import Foundation

struct DataAttribution: Identifiable, Hashable {
  let id: String
  let title: String
  let detail: String
  let urlString: String

  static let openMeteo = DataAttribution(
    id: "open-meteo",
    title: "Open-Meteo",
    detail: "天气、空气质量、海况与地址搜索 · CC BY 4.0",
    urlString: "https://open-meteo.com/"
  )

  static let rainViewer = DataAttribution(
    id: "rainviewer",
    title: "RainViewer",
    detail: "降水雷达地图",
    urlString: "https://www.rainviewer.com/"
  )

  static func unique(_ items: [DataAttribution]) -> [DataAttribution] {
    var seen = Set<String>()
    return items.filter { seen.insert($0.id).inserted }
  }
}

protocol DataAttributionProviding {
  var dataAttributions: [DataAttribution] { get }
}

protocol ForecastProvider: DataAttributionProviding {
  func fetchForecast(for location: SavedLocation) async throws -> WeatherSnapshot
}

protocol AirQualityProvider: DataAttributionProviding {
  func fetchAirQuality(for location: SavedLocation) async throws -> AirQualitySnapshot
}

protocol RadarProvider: DataAttributionProviding {
  func fetchRadar(for location: SavedLocation) async throws -> RadarSnapshot
}

protocol MarineWeatherProvider: DataAttributionProviding {
  func fetchMarineWeather(for location: SavedLocation) async throws -> MarineSnapshot?
}

protocol LocationSearchProvider: DataAttributionProviding {
  func search(query: String) async throws -> [SavedLocation]
}

// Test doubles and private adapters remain source-compatible. Public adapters
// should override this metadata so the About screen can satisfy attribution
// requirements without knowing which concrete provider is in use.
extension ForecastProvider { var dataAttributions: [DataAttribution] { [] } }
extension AirQualityProvider { var dataAttributions: [DataAttribution] { [] } }
extension RadarProvider { var dataAttributions: [DataAttribution] { [] } }
extension MarineWeatherProvider { var dataAttributions: [DataAttribution] { [] } }
extension LocationSearchProvider { var dataAttributions: [DataAttribution] { [] } }

/// The complete external-data boundary used by a refresh operation.
///
/// A distribution can replace one provider without changing AppState,
/// RefreshCoordinator, or any view. Tests can inject the same bundle with
/// deterministic implementations while the production launch path remains
/// live-data-only.
struct WeatherProviderSuite {
  let forecast: ForecastProvider
  let airQuality: AirQualityProvider
  let radar: RadarProvider
  let marine: MarineWeatherProvider

  init(
    forecast: ForecastProvider,
    airQuality: AirQualityProvider,
    radar: RadarProvider,
    marine: MarineWeatherProvider
  ) {
    self.forecast = forecast
    self.airQuality = airQuality
    self.radar = radar
    self.marine = marine
  }

  var dataAttributions: [DataAttribution] {
    DataAttribution.unique(
      forecast.dataAttributions
        + airQuality.dataAttributions
        + radar.dataAttributions
        + marine.dataAttributions
    )
  }
}

enum WeatherProviderError: LocalizedError {
  case invalidURL
  case invalidResponse
  case unavailable(String)

  var errorDescription: String? {
    switch self {
    case .invalidURL: return "天气服务地址无效。"
    case .invalidResponse: return "天气服务返回了无法识别的数据。"
    case .unavailable(let message): return message
    }
  }
}
