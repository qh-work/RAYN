import Foundation

enum WeatherDateParser {
  static func date(from string: String?, timezone: TimeZone? = nil) -> Date? {
    guard let string, !string.isEmpty else { return nil }
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let value = isoFormatter.date(from: string) { return value }
    isoFormatter.formatOptions = [.withInternetDateTime]
    if let value = isoFormatter.date(from: string) { return value }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = timezone ?? TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
    return formatter.date(from: string)
  }
}

extension Array {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
