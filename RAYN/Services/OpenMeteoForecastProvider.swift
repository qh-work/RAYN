import Foundation

struct OpenMeteoForecastProvider: ForecastProvider {
  private let httpClient: HTTPClient

  init(httpClient: HTTPClient = URLSessionHTTPClient()) {
    self.httpClient = httpClient
  }
  let dataAttributions: [DataAttribution] = [.openMeteo]

  func fetchForecast(for location: SavedLocation) async throws -> WeatherSnapshot {
    var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
    components?.queryItems = [
      URLQueryItem(name: "latitude", value: String(location.latitude)),
      URLQueryItem(name: "longitude", value: String(location.longitude)),
      URLQueryItem(name: "timezone", value: "auto"),
      URLQueryItem(name: "forecast_days", value: "10"),
      URLQueryItem(
        name: "current",
        value:
          "temperature_2m,relative_humidity_2m,apparent_temperature,dew_point_2m,is_day,precipitation,rain,snowfall,weather_code,cloud_cover,cloud_cover_low,cloud_cover_mid,cloud_cover_high,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m,visibility,uv_index"
      ),
      URLQueryItem(
        name: "hourly",
        value:
          "temperature_2m,apparent_temperature,precipitation_probability,precipitation,rain,snowfall,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m,visibility,uv_index,is_day"
      ),
      URLQueryItem(
        name: "daily",
        value:
          "temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max,precipitation_sum,wind_speed_10m_max,wind_gusts_10m_max,sunrise,sunset,moonrise,moonset,moon_phase,uv_index_max,daylight_duration"
      ),
    ]
    guard let url = components?.url else { throw WeatherProviderError.invalidURL }

    var request = URLRequest(url: url)
    request.timeoutInterval = 12
    request.setValue(
      "RAYN-Weather/\(AppConfiguration.marketingVersion)",
      forHTTPHeaderField: "User-Agent"
    )
    let data = try await httpClient.data(for: request)

    let payload = try JSONDecoder().decode(OpenMeteoForecastPayload.self, from: data)
    try validateLivePayload(payload)
    return makeSnapshot(from: payload, location: location)
  }

  /// The production request promises a current observation and ten daily
  /// points. If either contract is broken, fail visibly instead of filling a
  /// card with plausible-looking defaults. `makeSnapshot` remains tolerant so
  /// unit tests can exercise partial JSON conversion in isolation.
  private func validateLivePayload(_ payload: OpenMeteoForecastPayload) throws {
    guard let current = payload.current,
      let time = current.time, !time.isEmpty,
      current.temperature != nil,
      current.relativeHumidity != nil,
      current.apparentTemperature != nil,
      current.dewPoint != nil,
      current.isDay != nil,
      current.precipitation != nil,
      current.weatherCode != nil,
      current.cloudCover != nil,
      current.pressure != nil,
      current.windSpeed != nil,
      current.windDirection != nil,
      current.windGust != nil,
      current.visibility != nil,
      current.uvIndex != nil,
      let daily = payload.daily,
      let dates = daily.time, dates.count >= 10,
      let highs = daily.temperatureMax, highs.count >= 10,
      let lows = daily.temperatureMin, lows.count >= 10,
      let codes = daily.weatherCode, codes.count >= 10,
      let probabilities = daily.precipitationProbabilityMax, probabilities.count >= 10,
      let precipitation = daily.precipitationSum, precipitation.count >= 10,
      let wind = daily.windSpeedMax, wind.count >= 10,
      let gust = daily.windGustMax, gust.count >= 10,
      let hourly = payload.hourly, let hours = hourly.time, !hours.isEmpty,
      let temperatures = hourly.temperature, temperatures.count == hours.count,
      let apparent = hourly.apparentTemperature, apparent.count == hours.count,
      let hourlyRainChance = hourly.precipitationProbability, hourlyRainChance.count == hours.count,
      let hourlyRain = hourly.precipitation, hourlyRain.count == hours.count,
      let hourlySnow = hourly.snowfall, hourlySnow.count == hours.count,
      let hourlyWind = hourly.windSpeed, hourlyWind.count == hours.count,
      let hourlyDirection = hourly.windDirection, hourlyDirection.count == hours.count,
      let hourlyCode = hourly.weatherCode, hourlyCode.count == hours.count,
      let hourlyDay = hourly.isDay, hourlyDay.count == hours.count
    else {
      throw WeatherProviderError.invalidResponse
    }
    guard let timezoneName = payload.timezone, let timezone = TimeZone(identifier: timezoneName),
          let currentDate = WeatherDateParser.date(from: time, timezone: timezone),
          dates.allSatisfy({ WeatherDateParser.date(from: $0, timezone: timezone) != nil }),
          hours.allSatisfy({ WeatherDateParser.date(from: $0, timezone: timezone) != nil }),
          hours.compactMap({ WeatherDateParser.date(from: $0, timezone: timezone) })
            .filter({ $0 >= currentDate.addingTimeInterval(-3600) }).count >= 24 else {
      throw WeatherProviderError.invalidResponse
    }
  }

  func makeSnapshot(from payload: OpenMeteoForecastPayload, location: SavedLocation)
    -> WeatherSnapshot
  {
    let timezone = TimeZone(identifier: payload.timezone ?? location.timezoneIdentifier) ?? .current
    let now = Date()
    let currentPayload = payload.current
    let dailyPayload = payload.daily
    let currentTime = WeatherDateParser.date(from: currentPayload?.time, timezone: timezone) ?? now
    let currentCode = currentPayload?.weatherCode ?? 2
    let high = dailyPayload?.temperatureMax?.first ?? (currentPayload?.temperature ?? 20) + 3
    let low = dailyPayload?.temperatureMin?.first ?? (currentPayload?.temperature ?? 20) - 4
    let sunrise = dailyPayload?.sunrise?.first.flatMap {
      WeatherDateParser.date(from: $0, timezone: timezone)
    }
    let sunset = dailyPayload?.sunset?.first.flatMap {
      WeatherDateParser.date(from: $0, timezone: timezone)
    }
    var current = CurrentConditions(
      temperature: currentPayload?.temperature ?? 0,
      feelsLike: currentPayload?.apparentTemperature ?? currentPayload?.temperature ?? 0,
      high: high,
      low: low,
      relativeHumidity: currentPayload?.relativeHumidity ?? 0,
      dewPoint: currentPayload?.dewPoint ?? 0,
      pressure: currentPayload?.pressure ?? 0,
      visibility: (currentPayload?.visibility ?? 100_000) / 1000,
      cloudCover: currentPayload?.cloudCover ?? 0,
      windSpeed: currentPayload?.windSpeed ?? 0,
      windDirection: currentPayload?.windDirection ?? 0,
      windGust: currentPayload?.windGust ?? 0,
      uvIndex: currentPayload?.uvIndex ?? 0,
      precipitationProbability: 0,
      precipitation: currentPayload?.precipitation ?? 0,
      weatherCode: currentCode,
      isDay: (currentPayload?.isDay ?? 1) == 1,
      sunrise: sunrise,
      sunset: sunset,
      rain: currentPayload?.rain,
      snowfall: currentPayload?.snowfall,
      cloudCoverLow: currentPayload?.cloudCoverLow,
      cloudCoverMid: currentPayload?.cloudCoverMid,
      cloudCoverHigh: currentPayload?.cloudCoverHigh,
      daylightDuration: dailyPayload?.daylightDuration?.first ?? nil,
      moonrise: dailyPayload?.moonrise?.first.flatMap {
        WeatherDateParser.date(from: $0, timezone: timezone)
      },
      moonset: dailyPayload?.moonset?.first.flatMap {
        WeatherDateParser.date(from: $0, timezone: timezone)
      }
    )

    let hourlyTimes = payload.hourly?.time ?? []
    let upcomingIndices = hourlyTimes.indices.filter {
      guard let date = WeatherDateParser.date(from: hourlyTimes[$0], timezone: timezone) else { return false }
      return date >= currentTime.addingTimeInterval(-3600)
    }
    var hourly = upcomingIndices.prefix(48).map { index in
      let time =
        WeatherDateParser.date(from: hourlyTimes[index], timezone: timezone)
        ?? currentTime.addingTimeInterval(Double(index) * 3600)
      let code = payload.hourly?.weatherCode?[safe: index] ?? currentCode
      return HourlyForecastPoint(
        time: time,
        temperature: payload.hourly?.temperature?[safe: index] ?? current.temperature,
        apparentTemperature: payload.hourly?.apparentTemperature?[safe: index] ?? current.feelsLike,
        precipitationProbability: payload.hourly?.precipitationProbability?[safe: index] ?? 0,
        precipitation: payload.hourly?.precipitation?[safe: index] ?? 0,
        snowfall: payload.hourly?.snowfall?[safe: index] ?? 0,
        windSpeed: payload.hourly?.windSpeed?[safe: index] ?? current.windSpeed,
        windDirection: payload.hourly?.windDirection?[safe: index] ?? current.windDirection,
        weatherCode: code,
        isDay: (payload.hourly?.isDay?[safe: index] ?? 1) == 1,
        windGust: payload.hourly?.windGust?[safe: index],
        visibility: payload.hourly?.visibility?[safe: index].map { $0 / 1000 },
        uvIndex: payload.hourly?.uvIndex?[safe: index]
      )
    }
    if hourly.isEmpty {
      hourly = [
        HourlyForecastPoint(
          time: currentTime, temperature: current.temperature,
          apparentTemperature: current.feelsLike, precipitationProbability: 0,
          precipitation: current.precipitation, snowfall: 0, windSpeed: current.windSpeed,
          windDirection: current.windDirection, weatherCode: currentCode, isDay: current.isDay,
          windGust: current.windGust, visibility: current.visibility, uvIndex: current.uvIndex)
      ]
    }
    if let nearest = hourly.min(by: {
      abs($0.time.timeIntervalSince(currentTime)) < abs($1.time.timeIntervalSince(currentTime))
    }) {
      current.precipitationProbability = nearest.precipitationProbability
    }

    let dailyTimes = dailyPayload?.time ?? []
    let daily = dailyTimes.indices.prefix(10).map { index in
      DailyForecastPoint(
        date: WeatherDateParser.date(from: dailyTimes[index], timezone: timezone)
          ?? currentTime.addingTimeInterval(Double(index) * 86400),
        high: dailyPayload?.temperatureMax?[safe: index] ?? high,
        low: dailyPayload?.temperatureMin?[safe: index] ?? low,
        weatherCode: dailyPayload?.weatherCode?[safe: index] ?? currentCode,
        precipitationProbability: dailyPayload?.precipitationProbabilityMax?[safe: index] ?? 0,
        precipitation: dailyPayload?.precipitationSum?[safe: index] ?? 0,
        windSpeed: dailyPayload?.windSpeedMax?[safe: index] ?? current.windSpeed,
        windGust: dailyPayload?.windGustMax?[safe: index] ?? current.windGust,
        sunrise: dailyPayload?.sunrise?[safe: index].flatMap {
          WeatherDateParser.date(from: $0, timezone: timezone)
        },
        sunset: dailyPayload?.sunset?[safe: index].flatMap {
          WeatherDateParser.date(from: $0, timezone: timezone)
        },
        uvIndex: dailyPayload?.uvIndexMax?[safe: index] ?? nil,
        daylightDuration: dailyPayload?.daylightDuration?[safe: index] ?? nil
      )
    }

    var snapshot = WeatherSnapshot(
      location: location,
      timezoneIdentifier: payload.timezone ?? location.timezoneIdentifier,
      current: current,
      hourly: hourly,
      daily: daily,
      airQuality: nil,
      radar: .unavailable,
      marine: nil,
      alerts: [],
      summary: .empty,
      updatedAt: currentTime,
      fetchedAt: now,
      source: "Open-Meteo",
      isOffline: false,
      theme: WeatherTheme.from(
        weatherCode: currentCode,
        isDay: current.isDay,
        precipitation: current.precipitation,
        windSpeed: current.windSpeed,
        visibility: current.visibility
      )
    )
    snapshot.summary = WeatherSummaryBuilder.make(from: snapshot)
    return snapshot
  }
}

struct OpenMeteoForecastPayload: Decodable {
  var timezone: String?
  var current: CurrentPayload?
  var hourly: HourlyPayload?
  var daily: DailyPayload?

  struct CurrentPayload: Decodable {
    var time: String?
    var temperature: Double?
    var relativeHumidity: Double?
    var apparentTemperature: Double?
    var dewPoint: Double?
    var isDay: Int?
    var precipitation: Double?
    var weatherCode: Int?
    var cloudCover: Double?
    var pressure: Double?
    var windSpeed: Double?
    var windDirection: Double?
    var windGust: Double?
    var visibility: Double?
    var uvIndex: Double?
    var rain: Double?
    var snowfall: Double?
    var cloudCoverLow: Double?
    var cloudCoverMid: Double?
    var cloudCoverHigh: Double?

    enum CodingKeys: String, CodingKey {
      case time
      case temperature = "temperature_2m"
      case relativeHumidity = "relative_humidity_2m"
      case apparentTemperature = "apparent_temperature"
      case dewPoint = "dew_point_2m"
      case isDay = "is_day"
      case precipitation
      case rain
      case snowfall
      case weatherCode = "weather_code"
      case cloudCover = "cloud_cover"
      case cloudCoverLow = "cloud_cover_low"
      case cloudCoverMid = "cloud_cover_mid"
      case cloudCoverHigh = "cloud_cover_high"
      case pressure = "pressure_msl"
      case windSpeed = "wind_speed_10m"
      case windDirection = "wind_direction_10m"
      case windGust = "wind_gusts_10m"
      case visibility
      case uvIndex = "uv_index"
    }
  }

  struct HourlyPayload: Decodable {
    var time: [String]?
    var temperature: [Double]?
    var apparentTemperature: [Double]?
    var precipitationProbability: [Double]?
    var precipitation: [Double]?
    var snowfall: [Double]?
    var weatherCode: [Int]?
    var windSpeed: [Double]?
    var windDirection: [Double]?
    var windGust: [Double]?
    var visibility: [Double]?
    var uvIndex: [Double]?
    var isDay: [Int]?

    enum CodingKeys: String, CodingKey {
      case time
      case temperature = "temperature_2m"
      case apparentTemperature = "apparent_temperature"
      case precipitationProbability = "precipitation_probability"
      case precipitation
      case snowfall
      case weatherCode = "weather_code"
      case windSpeed = "wind_speed_10m"
      case windDirection = "wind_direction_10m"
      case windGust = "wind_gusts_10m"
      case visibility
      case uvIndex = "uv_index"
      case isDay = "is_day"
    }
  }

  struct DailyPayload: Decodable {
    var time: [String]?
    var temperatureMax: [Double]?
    var temperatureMin: [Double]?
    var weatherCode: [Int]?
    var precipitationProbabilityMax: [Double]?
    var precipitationSum: [Double]?
    var windSpeedMax: [Double]?
    var windGustMax: [Double]?
    var sunrise: [String?]?
    var sunset: [String?]?
    var moonrise: [String?]?
    var moonset: [String?]?
    // Polar regions and lunar edge cases legitimately return null entries.
    // Decode points independently so one absent event cannot discard the
    // complete live forecast response.
    var moonPhase: [Double?]?
    var uvIndexMax: [Double?]?
    var daylightDuration: [Double?]?

    enum CodingKeys: String, CodingKey {
      case time
      case temperatureMax = "temperature_2m_max"
      case temperatureMin = "temperature_2m_min"
      case weatherCode = "weather_code"
      case precipitationProbabilityMax = "precipitation_probability_max"
      case precipitationSum = "precipitation_sum"
      case windSpeedMax = "wind_speed_10m_max"
      case windGustMax = "wind_gusts_10m_max"
      case sunrise
      case sunset
      case moonrise
      case moonset
      case moonPhase = "moon_phase"
      case uvIndexMax = "uv_index_max"
      case daylightDuration = "daylight_duration"
    }
  }
}
