import Foundation
import CryptoKit

enum AlertAvailability: String, Codable, Equatable {
    case available, unsupported, unavailable
}

struct AlertSnapshot: Equatable {
    var alerts: [WeatherAlertItem]
    var availability: AlertAvailability
    var checkedAt: Date
}

protocol WeatherAlertProvider: DataAttributionProviding {
    func fetchAlerts(for location: SavedLocation) async throws -> AlertSnapshot
}

/// A no-op default preserves downstream suites that inject only the original providers.
struct UnsupportedAlertProvider: WeatherAlertProvider {
    var dataAttributions: [DataAttribution] { [] }
    func fetchAlerts(for location: SavedLocation) async throws -> AlertSnapshot {
        AlertSnapshot(alerts: [], availability: .unsupported, checkedAt: Date())
    }
}

enum USWeatherCoverage {
    static func includes(_ location: SavedLocation) -> Bool {
        let country = location.country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let names = ["US", "USA", "United States", "United States of America"] +
            ["en", "fr", "de", "es", "it", "ja", "ko", "zh-Hans", "zh-Hant"].compactMap {
                Locale(identifier: $0).localizedString(forRegionCode: "US")
            }
        return names.contains { $0.lowercased() == country }
    }

    static func includesCONUS(_ location: SavedLocation) -> Bool {
        includes(location) && (24...50).contains(location.latitude)
            && (-125 ... -66).contains(location.longitude)
    }
}

/// Official messages remain verbatim. UI labels are localized separately.
/// The response parser does not invent a title, expiry or "no warnings" result.
struct NWSAlertProvider: WeatherAlertProvider {
    let httpClient: HTTPClient
    let now: () -> Date
    var dataAttributions: [DataAttribution] { [.nws] }

    init(httpClient: HTTPClient = URLSessionHTTPClient(), now: @escaping () -> Date = Date.init) {
        self.httpClient = httpClient
        self.now = now
    }

    func fetchAlerts(for location: SavedLocation) async throws -> AlertSnapshot {
        let date = now()
        guard USWeatherCoverage.includes(location) else {
            return AlertSnapshot(alerts: [], availability: .unsupported, checkedAt: date)
        }
        var components = URLComponents(string: "https://api.weather.gov/alerts/active")!
        components.queryItems = [
            URLQueryItem(name: "point", value: "\(location.latitude),\(location.longitude)"),
            URLQueryItem(name: "status", value: "actual")
        ]
        guard let url = components.url else { throw WeatherProviderError.invalidURL }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
        request.setValue("RAYN Weather (https://github.com/qh-work/RAYN)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        let data = try await httpClient.data(for: request)
        try Task.checkCancellation()
        return try Self.parse(data, at: date)
    }

    static func parse(_ data: Data, at now: Date) throws -> AlertSnapshot {
        let payload = try JSONDecoder().decode(Collection.self, from: data)
        var seen = Set<String>()
        let items = try payload.features.compactMap { feature -> WeatherAlertItem? in
            let value = feature.properties
            guard value.status == "Actual", value.messageType != "Cancel" else { return nil }
            guard !feature.id.isEmpty,
                  let start = ProviderDate.parse(value.effective ?? value.sent),
                  let expiry = ProviderDate.parse(value.expires),
                  expiry > start,
                  let headline = value.headline ?? value.event,
                  !headline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                // A malformed official message must not become an all-clear.
                throw WeatherProviderError.invalidResponse
            }
            guard expiry > now, start <= now, seen.insert(feature.id).inserted else { return nil }
            // Stable UUIDs keep focus and SwiftUI identities stable on refresh.
            var bytes = Array(SHA256.hash(data: Data(feature.id.utf8)).prefix(16))
            bytes[6] = (bytes[6] & 0x0f) | 0x50
            bytes[8] = (bytes[8] & 0x3f) | 0x80
            let id = UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5],
                                 bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11],
                                 bytes[12], bytes[13], bytes[14], bytes[15]))
            var item = WeatherAlertItem(id: id, title: headline,
                                       issuer: value.senderName ?? "National Weather Service",
                                       startDate: start, endDate: expiry, detailURL: feature.id)
            item.providerIdentifier = feature.id
            item.severity = value.severity
            item.body = [value.description, value.instruction].compactMap { $0 }.joined(separator: "\n\n")
            return item
        }.sorted {
            let lhs = severityRank($0.severity), rhs = severityRank($1.severity)
            return lhs == rhs ? $0.startDate > $1.startDate : lhs > rhs
        }
        return AlertSnapshot(alerts: items, availability: .available, checkedAt: now)
    }

    private static func severityRank(_ value: String?) -> Int {
        ["Unknown": 0, "Minor": 1, "Moderate": 2, "Severe": 3, "Extreme": 4][value ?? ""] ?? 0
    }

    private struct Collection: Decodable { var features: [Feature] }
    private struct Feature: Decodable {
        var id: String
        var properties: Properties
    }
    private struct Properties: Decodable {
        var status: String?
        var messageType: String?
        var sent: String?
        var effective: String?
        var expires: String?
        var headline: String?
        var event: String?
        var senderName: String?
        var severity: String?
        var description: String?
        var instruction: String?
    }
}

enum ProviderDate {
    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }
}
