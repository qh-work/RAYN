import Foundation

struct OpenMeteoAirQualityProvider: AirQualityProvider {
  private let httpClient: HTTPClient

  init(httpClient: HTTPClient = URLSessionHTTPClient()) {
    self.httpClient = httpClient
  }
  let dataAttributions: [DataAttribution] = [.openMeteo]

  func fetchAirQuality(for location: SavedLocation) async throws -> AirQualitySnapshot {
    var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")
    components?.queryItems = [
      URLQueryItem(name: "latitude", value: String(location.latitude)),
      URLQueryItem(name: "longitude", value: String(location.longitude)),
      URLQueryItem(name: "timezone", value: "auto"),
      URLQueryItem(name: "forecast_days", value: "2"),
      URLQueryItem(
        name: "current",
        value: "european_aqi,pm2_5,pm10,ozone,nitrogen_dioxide,sulphur_dioxide,carbon_monoxide"),
      URLQueryItem(name: "hourly", value: "european_aqi"),
    ]
    guard let url = components?.url else { throw WeatherProviderError.invalidURL }
    var request = URLRequest(url: url)
    request.timeoutInterval = 12
    let data = try await httpClient.data(for: request)
    let payload = try JSONDecoder().decode(OpenMeteoAirQualityPayload.self, from: data)
    guard let current = payload.current,
      let europeanAQI = current.europeanAQI,
      let pm25 = current.pm25,
      let pm10 = current.pm10,
      let ozone = current.ozone,
      let nitrogenDioxide = current.nitrogenDioxide,
      let sulphurDioxide = current.sulphurDioxide,
      let carbonMonoxide = current.carbonMonoxide
    else {
      throw WeatherProviderError.invalidResponse
    }
    return AirQualitySnapshot(
      europeanAQI: europeanAQI,
      pm25: pm25,
      pm10: pm10,
      ozone: ozone,
      nitrogenDioxide: nitrogenDioxide,
      sulphurDioxide: sulphurDioxide,
      carbonMonoxide: carbonMonoxide,
      updatedAt: Date(),
      hourlyAQI: payload.hourly?.europeanAQI ?? []
    )
  }
}

private struct OpenMeteoAirQualityPayload: Decodable {
  var current: Current?
  var hourly: Hourly?

  struct Current: Decodable {
    var europeanAQI: Double?
    var pm25: Double?
    var pm10: Double?
    var ozone: Double?
    var nitrogenDioxide: Double?
    var sulphurDioxide: Double?
    var carbonMonoxide: Double?

    enum CodingKeys: String, CodingKey {
      case europeanAQI = "european_aqi"
      case pm25 = "pm2_5"
      case pm10
      case ozone
      case nitrogenDioxide = "nitrogen_dioxide"
      case sulphurDioxide = "sulphur_dioxide"
      case carbonMonoxide = "carbon_monoxide"
    }
  }

  struct Hourly: Decodable {
    var europeanAQI: [Double]?

    enum CodingKeys: String, CodingKey {
      case europeanAQI = "european_aqi"
    }
  }
}
