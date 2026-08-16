import Foundation

struct OpenMeteoLocationSearchProvider: LocationSearchProvider {
  private let httpClient: HTTPClient

  init(httpClient: HTTPClient = URLSessionHTTPClient()) {
    self.httpClient = httpClient
  }
  let dataAttributions: [DataAttribution] = [.openMeteo]

  func search(query: String) async throws -> [SavedLocation] {
    let searchPlan = Self.searchRequest(for: query)
    guard !searchPlan.name.isEmpty else { return [] }
    var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
    var queryItems = [
      URLQueryItem(name: "name", value: searchPlan.name),
      URLQueryItem(name: "count", value: "8"),
      URLQueryItem(name: "language", value: Self.requestLanguageCode(for: .autoupdatingCurrent)),
      URLQueryItem(name: "format", value: "json"),
    ]
    if let countryCode = searchPlan.countryCode {
      queryItems.append(URLQueryItem(name: "countryCode", value: countryCode))
    }
    components?.queryItems = queryItems
    guard let url = components?.url else { throw WeatherProviderError.invalidURL }
    var urlRequest = URLRequest(url: url)
    urlRequest.timeoutInterval = 12
    let data = try await httpClient.data(for: urlRequest)
    let payload = try JSONDecoder().decode(GeocodingPayload.self, from: data)
    return (payload.results ?? []).map {
      SavedLocation(
        name: $0.name ?? query, administrativeArea: $0.admin1 ?? "", country: $0.country ?? "",
        latitude: $0.latitude ?? 0, longitude: $0.longitude ?? 0,
        timezoneIdentifier: $0.timezone ?? "Asia/Shanghai", isFavorite: false)
    }
  }

  /// Open-Meteo searches globally, but a few common Chinese exonyms are not
  /// consistently resolved by its underlying place-name index. Normalize the
  /// public city name, and use a country filter for genuinely ambiguous names.
  /// This affects explicit search only; it never selects a startup city.
  static func searchRequest(for query: String) -> (name: String, countryCode: String?) {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    switch trimmed.lowercased() {
    case "北京", "beijing":
      return ("Beijing", "CN")
    case "上海", "shanghai":
      return ("Shanghai", "CN")
    case "深圳", "shenzhen":
      return ("Shenzhen", "CN")
    case "纽约", "紐約", "new york", "new york city", "nyc":
      return ("New York City", "US")
    case "伦敦", "倫敦", "london":
      return ("London", "GB")
    case "温哥华", "溫哥華", "vancouver":
      return ("Vancouver", "CA")
    default:
      return (trimmed, nil)
    }
  }

  static func requestLanguageCode(for locale: Locale) -> String {
    let code = locale.language.languageCode?.identifier.lowercased() ?? "en"
    if code == "zh" { return "zh" }
    return ["en", "fr", "de", "es", "it", "ja", "ko"].contains(code) ? code : "en"
  }
}

private struct GeocodingPayload: Decodable {
  var results: [ResultItem]?

  struct ResultItem: Decodable {
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var timezone: String?
    var country: String?
    var admin1: String?
  }
}
