import Foundation

/// One bounded, ephemeral pipeline for all visible MapKit tiles.
/// URL keys include source, frame time and tile coordinates.
actor RadarTileStore {
    static let shared = RadarTileStore()
    private struct Flight {
        var token: UUID
        var task: Task<Data, Error>
        var consumers: Set<UUID>
    }
    private var flights: [URL: Flight] = [:]
    private var nextStart: [String: Date] = [:]
    private var activeRequests = 0
    private let cache = NSCache<NSURL, NSData>()
    private let transport: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    init(transport: (@Sendable (URLRequest) async throws -> (Data, URLResponse))? = nil) {
        cache.totalCostLimit = 32 * 1_024 * 1_024
        if let transport {
            self.transport = transport
            return
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpMaximumConnectionsPerHost = 4
        configuration.timeoutIntervalForRequest = 12
        let session = URLSession(configuration: configuration)
        self.transport = { try await session.data(for: $0) }
    }

    func data(for url: URL) async throws -> Data {
        try Task.checkCancellation()
        if let data = cache.object(forKey: url as NSURL) { return data as Data }
        let consumer = UUID()
        let token: UUID
        let task: Task<Data, Error>
        if var flight = flights[url] {
            flight.consumers.insert(consumer)
            flights[url] = flight
            token = flight.token
            task = flight.task
        } else {
            token = UUID()
            task = Task { try await download(url) }
            flights[url] = Flight(token: token, task: task, consumers: [consumer])
        }
        return try await withTaskCancellationHandler {
            defer { release(url, token: token, consumer: consumer) }
            let data = try await task.value
            try Task.checkCancellation()
            return data
        } onCancel: {
            Task { await self.release(url, token: token, consumer: consumer) }
        }
    }

    private func release(_ url: URL, token: UUID, consumer: UUID) {
        guard var flight = flights[url], flight.token == token else { return }
        flight.consumers.remove(consumer)
        if flight.consumers.isEmpty {
            flight.task.cancel()
            flights[url] = nil
        } else { flights[url] = flight }
    }

    private func download(_ url: URL) async throws -> Data {
        let host = url.host ?? ""
        let isRainViewer = host == "rainviewer.com" || host.hasSuffix(".rainviewer.com")
        // At most ~90 starts/minute for this app, below the provider's
        // published 100/IP/minute limit. Other clients sharing an IP may
        // still exhaust it; Retry-After is therefore authoritative.
        let spacing: TimeInterval = isRainViewer ? 0.68 : 0.1
        while true {
            try Task.checkCancellation()
            let delay = (nextStart[host] ?? .distantPast).timeIntervalSinceNow
            if activeRequests < 4 && delay <= 0 {
                activeRequests += 1
                nextStart[host] = Date().addingTimeInterval(spacing)
                break
            }
            try await Task.sleep(nanoseconds: UInt64(max(0.05, min(delay, 0.2)) * 1_000_000_000))
        }
        defer { activeRequests -= 1 }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
        let (data, response) = try await transport(request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw WeatherProviderError.invalidResponse }
        if response.statusCode == 429 || response.statusCode == 503 {
            let retry = Self.retryDelay(response.value(forHTTPHeaderField: "Retry-After"), at: Date())
            nextStart[host] = Date().addingTimeInterval(min(max(retry, 1), 900))
        }
        guard (200..<300).contains(response.statusCode),
              data.count <= 2 * 1_024 * 1_024,
              Array(data.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10] else {
            throw WeatherProviderError.invalidResponse
        }
        cache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        return data
    }

    static func retryDelay(_ value: String?, at now: Date) -> TimeInterval {
        guard let value else { return 60 }
        if let seconds = Double(value), seconds.isFinite { return max(1, seconds) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: value).map { max(1, $0.timeIntervalSince(now)) } ?? 60
    }
}
