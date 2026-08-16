import Foundation

struct OpenMeteoMarineProvider: MarineWeatherProvider {
  private let httpClient: HTTPClient

  init(httpClient: HTTPClient = URLSessionHTTPClient()) {
    self.httpClient = httpClient
  }
  let dataAttributions: [DataAttribution] = [.openMeteo]

  func fetchMarineWeather(for location: SavedLocation) async throws -> MarineSnapshot? {
    var components = URLComponents(string: "https://marine-api.open-meteo.com/v1/marine")
    components?.queryItems = [
      URLQueryItem(name: "latitude", value: String(location.latitude)),
      URLQueryItem(name: "longitude", value: String(location.longitude)),
      URLQueryItem(name: "timezone", value: "auto"),
      URLQueryItem(name: "cell_selection", value: "sea"),
      URLQueryItem(name: "past_hours", value: "1"),
      URLQueryItem(name: "forecast_hours", value: "25"),
      URLQueryItem(
        name: "current",
        value:
          "wave_height,wave_direction,wave_period,wind_wave_height,swell_wave_height,sea_surface_temperature,ocean_current_velocity,ocean_current_direction,sea_level_height_msl"
      ),
      URLQueryItem(
        name: "hourly",
        value:
          "wave_height,wave_direction,wave_period,wind_wave_height,swell_wave_height,sea_surface_temperature,ocean_current_velocity,ocean_current_direction,sea_level_height_msl"
      ),
    ]
    guard let url = components?.url else { throw WeatherProviderError.invalidURL }
    var request = URLRequest(url: url)
    request.timeoutInterval = 12
    let data = try await httpClient.data(for: request)
    let payload = try JSONDecoder().decode(OpenMeteoMarinePayload.self, from: data)
    let timezone = TimeZone(identifier: payload.timezone ?? location.timezoneIdentifier) ?? .current
    let hourlyPoints = marineForecastPoints(from: payload.hourly, timezone: timezone)
    if let current = payload.current, let waveHeight = current.waveHeight {
      return MarineSnapshot(
        waveHeight: waveHeight,
        waveDirection: current.waveDirection ?? 0,
        wavePeriod: current.wavePeriod ?? 0,
        windWaveHeight: current.windWaveHeight ?? 0,
        swellWaveHeight: current.swellWaveHeight ?? 0,
        updatedAt: current.time.flatMap { WeatherDateParser.date(from: $0, timezone: timezone) }
          ?? Date(),
        seaSurfaceTemperature: current.seaSurfaceTemperature,
        oceanCurrentVelocity: current.oceanCurrentVelocity,
        oceanCurrentDirection: current.oceanCurrentDirection,
        seaLevelHeight: current.seaLevelHeight,
        hourly: hourlyPoints
      )
    }
    if let nearest = hourlyPoints.min(by: {
      abs($0.time.timeIntervalSinceNow) < abs($1.time.timeIntervalSinceNow)
    }) {
      return MarineSnapshot(
        waveHeight: nearest.waveHeight,
        waveDirection: nearest.waveDirection,
        wavePeriod: nearest.wavePeriod,
        windWaveHeight: nearest.windWaveHeight,
        swellWaveHeight: nearest.swellWaveHeight,
        updatedAt: nearest.time,
        seaSurfaceTemperature: nearest.seaSurfaceTemperature,
        oceanCurrentVelocity: nearest.oceanCurrentVelocity,
        oceanCurrentDirection: nearest.oceanCurrentDirection,
        seaLevelHeight: nearest.seaLevelHeight,
        hourly: hourlyPoints
      )
    }
    return nil
  }

  private func marineForecastPoints(
    from hourly: OpenMeteoMarinePayload.Hourly?,
    timezone: TimeZone
  ) -> [MarineForecastPoint] {
    guard let hourly,
      let times = hourly.time,
      let waveHeights = hourly.waveHeight
    else { return [] }

    func value(_ values: [Double?]?, at index: Int) -> Double? {
      guard let values, values.indices.contains(index) else { return nil }
      return values[index]
    }

    return times.indices.compactMap { index in
      guard waveHeights.indices.contains(index),
        let waveHeight = waveHeights[index],
        let date = WeatherDateParser.date(from: times[index], timezone: timezone)
      else {
        return nil
      }
      return MarineForecastPoint(
        time: date,
        waveHeight: waveHeight,
        waveDirection: value(hourly.waveDirection, at: index) ?? 0,
        wavePeriod: value(hourly.wavePeriod, at: index) ?? 0,
        windWaveHeight: value(hourly.windWaveHeight, at: index) ?? 0,
        swellWaveHeight: value(hourly.swellWaveHeight, at: index) ?? 0,
        seaSurfaceTemperature: value(hourly.seaSurfaceTemperature, at: index),
        oceanCurrentVelocity: value(hourly.oceanCurrentVelocity, at: index),
        oceanCurrentDirection: value(hourly.oceanCurrentDirection, at: index),
        seaLevelHeight: value(hourly.seaLevelHeight, at: index)
      )
    }
  }
}

private struct OpenMeteoMarinePayload: Decodable {
  var timezone: String?
  var current: Current?
  var hourly: Hourly?

  struct Current: Decodable {
    var time: String?
    var waveHeight: Double?
    var waveDirection: Double?
    var wavePeriod: Double?
    var windWaveHeight: Double?
    var swellWaveHeight: Double?
    var seaSurfaceTemperature: Double?
    var oceanCurrentVelocity: Double?
    var oceanCurrentDirection: Double?
    var seaLevelHeight: Double?

    enum CodingKeys: String, CodingKey {
      case time
      case waveHeight = "wave_height"
      case waveDirection = "wave_direction"
      case wavePeriod = "wave_period"
      case windWaveHeight = "wind_wave_height"
      case swellWaveHeight = "swell_wave_height"
      case seaSurfaceTemperature = "sea_surface_temperature"
      case oceanCurrentVelocity = "ocean_current_velocity"
      case oceanCurrentDirection = "ocean_current_direction"
      case seaLevelHeight = "sea_level_height_msl"
    }
  }

  struct Hourly: Decodable {
    var time: [String]?
    var waveHeight: [Double?]?
    var waveDirection: [Double?]?
    var wavePeriod: [Double?]?
    var windWaveHeight: [Double?]?
    var swellWaveHeight: [Double?]?
    var seaSurfaceTemperature: [Double?]?
    var oceanCurrentVelocity: [Double?]?
    var oceanCurrentDirection: [Double?]?
    var seaLevelHeight: [Double?]?

    enum CodingKeys: String, CodingKey {
      case time
      case waveHeight = "wave_height"
      case waveDirection = "wave_direction"
      case wavePeriod = "wave_period"
      case windWaveHeight = "wind_wave_height"
      case swellWaveHeight = "swell_wave_height"
      case seaSurfaceTemperature = "sea_surface_temperature"
      case oceanCurrentVelocity = "ocean_current_velocity"
      case oceanCurrentDirection = "ocean_current_direction"
      case seaLevelHeight = "sea_level_height_msl"
    }
  }
}
