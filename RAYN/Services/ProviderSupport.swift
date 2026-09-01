import Foundation

enum WeatherDateParser {
  private static let isoLock = NSLock()
  private static let fractionalISOFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()
  private static let standardISOFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  static func date(from string: String?, timezone: TimeZone? = nil) -> Date? {
    guard let string, !string.isEmpty else { return nil }
    isoLock.lock()
    defer { isoLock.unlock() }
    let isoValue = fractionalISOFormatter.date(from: string) ?? standardISOFormatter.date(from: string)
    if let isoValue { return isoValue }

    if let localDateTime = WeatherDateFormatterCache.date(
      from: string,
      format: "yyyy-MM-dd'T'HH:mm",
      timezone: timezone ?? TimeZone(secondsFromGMT: 0)!
    ) {
      return localDateTime
    }

    return WeatherDateFormatterCache.date(
      from: string,
      format: "yyyy-MM-dd",
      timezone: timezone ?? TimeZone(secondsFromGMT: 0)!
    )
  }
}

extension Array {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
