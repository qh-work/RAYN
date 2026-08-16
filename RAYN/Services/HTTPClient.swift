import Foundation

/// Minimal transport boundary shared by network-backed providers.
///
/// Providers own URL construction and payload mapping; this client owns only
/// transport and HTTP status validation. Tests and downstream distributions can
/// inject a deterministic client without touching provider or view code.
protocol HTTPClient {
  func data(for request: URLRequest) async throws -> Data
}

struct URLSessionHTTPClient: HTTPClient {
  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  func data(for request: URLRequest) async throws -> Data {
    let (data, response) = try await session.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
      (200..<300).contains(httpResponse.statusCode)
    else {
      throw WeatherProviderError.invalidResponse
    }
    return data
  }
}
