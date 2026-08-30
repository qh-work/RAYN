import Foundation

struct RainViewerRadarProvider: RadarProvider {
  private let httpClient: HTTPClient

  init(httpClient: HTTPClient = URLSessionHTTPClient()) {
    self.httpClient = httpClient
  }
  let dataAttributions: [DataAttribution] = [.rainViewer]

  func fetchRadar(for location: SavedLocation) async throws -> RadarSnapshot {
    guard let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json") else {
      throw WeatherProviderError.invalidURL
    }
    var request = URLRequest(url: url)
    request.timeoutInterval = 12
    let data = try await httpClient.data(for: request)
    let payload = try JSONDecoder().decode(RainViewerPayload.self, from: data)
    guard let host = payload.host, !host.isEmpty else {
      throw WeatherProviderError.invalidResponse
    }
    let pastFrames = (payload.radar?.past ?? []).compactMap {
      makeFrame($0, host: host, isForecast: false)
    }
    let frames = pastFrames.sorted { $0.timestamp < $1.timestamp }
    guard !frames.isEmpty else { return .unavailable }
    return RadarSnapshot(
      frames: frames, selectedIndex: frames.count - 1, isAvailable: true, message: nil)
  }

  private func makeFrame(_ item: RainViewerPayload.Frame, host: String, isForecast: Bool)
    -> RadarFrame?
  {
    guard let timestamp = item.time, let path = item.path, !path.isEmpty else { return nil }
    let normalizedHost = host.hasSuffix("/") ? String(host.dropLast()) : host
    let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
    let tileURLTemplate = "\(normalizedHost)\(normalizedPath)/256/{z}/{x}/{y}/2/1_0.png"
    var frame = RadarFrame(
      timestamp: timestamp,
      tilePath: path,
      tileURLTemplate: tileURLTemplate,
      source: "RainViewer",
      isForecast: isForecast
    )
    frame.tileDescriptor = RadarTileDescriptor(kind: .xyz, urlTemplate: tileURLTemplate,
                                               maximumZoom: 7, palette: .universalBlue)
    return frame
  }
}

private struct RainViewerPayload: Decodable {
  var host: String?
  var radar: Radar?

  struct Radar: Decodable {
    var past: [Frame]?
    var nowcast: [Frame]?
  }

  struct Frame: Decodable {
    var time: Int?
    var path: String?
  }
}
