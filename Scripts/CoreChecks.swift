import Foundation

@main
struct CoreChecks {
    struct Failed: Error { let message: String }
    static var count = 0
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw Failed(message: message) }
        count += 1
        print("PASS \(message)")
    }

    @MainActor
    static func main() async throws {
        let now = ProviderDate.parse("2026-08-30T12:00:00Z")!
        let location = SavedLocation(name: "New York", administrativeArea: "NY", country: "United States",
                                     latitude: 40.7128, longitude: -74.006, timezoneIdentifier: "America/New_York")
        var canada = location
        canada.country = "Canada"
        try expect(USWeatherCoverage.includesCONUS(location), "US mainland coverage")
        try expect(!USWeatherCoverage.includesCONUS(canada), "country boundary excludes Canada")
        let properties: [String: Any] = [
            "status": "Actual", "messageType": "Alert", "headline": "Fixture warning",
            "senderName": "Fixture NWS office", "severity": "Severe",
            "effective": "2026-08-30T10:00:00Z", "expires": "2026-08-30T14:00:00Z",
            "description": "This is a test fixture, never app weather."
        ]
        func alertData(_ values: [[String: Any]]) throws -> Data {
            try JSONSerialization.data(withJSONObject: ["features": values.enumerated().map {
                ["id": "https://api.weather.gov/alerts/fixture-\($0.offset)", "properties": $0.element]
            }])
        }
        var expired = properties
        expired["expires"] = "2026-08-30T11:00:00Z"
        var exercise = properties
        exercise["status"] = "Test"
        var cancelled = properties
        cancelled["messageType"] = "Cancel"
        let alerts = try NWSAlertProvider.parse(alertData([properties, expired, exercise, cancelled]), at: now)
        try expect(alerts.alerts.count == 1, "expired, exercise and cancelled alerts excluded")
        let second = try NWSAlertProvider.parse(alertData([properties]), at: now)
        try expect(alerts.alerts.first?.id == second.alerts.first?.id, "alert identity stable across refresh")
        let empty = try NWSAlertProvider.parse(Data(#"{"features":[]}"#.utf8), at: now)
        try expect(empty.availability == .available && empty.alerts.isEmpty, "empty official response distinct from unsupported")
        var malformedAlert = properties
        malformedAlert["expires"] = "not-a-date"
        do {
            _ = try NWSAlertProvider.parse(alertData([malformedAlert]), at: now)
            throw Failed(message: "malformed official message became all-clear")
        } catch is WeatherProviderError { count += 1; print("PASS malformed warning cannot become all-clear") }
        let capabilities = Data("""
        <WMS_Capabilities><Capability><Layer><CRS>EPSG:3857</CRS>
        <Layer><Name>conus:conus_bref_qcd</Name>
        <Dimension name="time">2026-08-30T09:00:00Z/2026-08-30T12:00:00Z/PT2M</Dimension>
        </Layer></Layer></Capability></WMS_Capabilities>
        """.utf8)
        let radar = try NOAARadarProvider.parseCapabilities(capabilities, at: now)
        try expect(radar.frames.count == 13, "advertised WMS timeline bounded")
        try expect(radar.frames.first!.date >= now.addingTimeInterval(-7200), "old radar times excluded")
        try expect(radar.frames.last!.date == now, "latest advertised radar time retained")
        try expect(radar.frames.last!.tileDescriptor?.legendURLString?.contains("GetLegendGraphic") == true,
                   "radar legend supplied by provider, not view")
        let url = RadarTileURL.resolve(radar.frames.last!.tileURLTemplate!, z: 0, x: 0, y: 0)!
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        let bbox = query.first { $0.name == "bbox" }!.value!.split(separator: ",").compactMap { Double($0) }
        try expect(bbox.count == 4 && bbox[0] < 0 && bbox[1] < 0 && bbox[2] > 0 && bbox[3] > 0, "WMS EPSG:3857 axis order")
        try expect(query.first { $0.name == "time" }!.value == "2026-08-30T12:00:00Z", "WMS request pins real frame time")
        try expect(RadarTileURL.resolve("https://example.org/{z}/{x}/{y}", z: 2, x: 4, y: 0) == nil, "invalid tiles rejected")
        let oldFrame = try JSONDecoder().decode(RadarFrame.self, from: Data(#"{"timestamp":123,"source":"Example"}"#.utf8))
        try expect(oldFrame.tileDescriptor == nil && !oldFrame.isForecast, "old radar models decode")
        do {
            _ = try NOAARadarProvider.advertisedTimes("2026-08-30T10:00:00Z/2026-08-30T12:00:00Z/PT0M", at: now)
            throw Failed(message: "zero duration accepted")
        } catch is WeatherProviderError { count += 1; print("PASS invalid WMS interval rejected") }
        let lunarJSON = Data(#"{"timezone":"America/New_York","current":{"time":"2026-08-30T08:00","temperature_2m":20},"daily":{"time":["2026-08-30"],"sunrise":[null],"sunset":[null],"moonrise":[null],"moonset":["2026-08-30T10:00"]}}"#.utf8)
        let payload = try JSONDecoder().decode(OpenMeteoForecastPayload.self, from: lunarJSON)
        let fixture = OpenMeteoForecastProvider().makeSnapshot(from: payload, location: location)
        try expect(fixture.current.moonrise == nil && fixture.current.moonset != nil, "null moon event does not erase valid event")
        let restored = try JSONDecoder().decode(WeatherSnapshot.self, from: JSONEncoder().encode(fixture))
        try expect(restored == fixture, "snapshot compatibility round trip")
        let malformed = OpenMeteoForecastProvider(httpClient: StaticClient(data: lunarJSON))
        do {
            _ = try await malformed.fetchForecast(for: location)
            throw Failed(message: "incomplete live response accepted")
        } catch is WeatherProviderError { count += 1; print("PASS incomplete production forecast rejected") }
        let coordinator = RefreshCoordinator(forecastProvider: FailingForecast(),
                                            airQualityProvider: FailingAir(), radarProvider: FailingRadar(),
                                            marineProvider: FailingMarine())
        let stale = await coordinator.refresh(location: location, fallback: fixture, sources: [.forecast])
        try expect(stale.snapshot?.isOffline == true, "same-city session retains explicitly stale values")
        var other = location
        other.id = UUID()
        other.latitude = 34
        let switched = await coordinator.refresh(location: other, fallback: fixture, sources: [.forecast])
        try expect(switched.forecastAttempted && switched.snapshot == nil, "city switch resets throttling and rejects old values")
        let startup = await coordinator.refresh(location: other, force: true, sources: [.forecast])
        try expect(startup.snapshot == nil, "failed startup has no fallback weather")
        let merger = RefreshCoordinator(forecastProvider: FixtureForecast(snapshot: fixture), airQualityProvider: FailingAir(),
                                        radarProvider: FailingRadar(), marineProvider: FailingMarine())
        var previous = fixture
        previous.radar = radar
        let merged = await merger.refresh(location: location, fallback: previous, force: true, sources: [.forecast])
        try expect(merged.snapshot?.radar == radar, "forecast-only refresh preserves supplementary data")
        previous.alerts = alerts.alerts
        var allClear = fixture
        allClear.alertAvailability = .available
        let clearer = RefreshCoordinator(forecastProvider: FixtureForecast(snapshot: allClear),
                                         airQualityProvider: FailingAir(), radarProvider: FailingRadar(),
                                         marineProvider: FailingMarine())
        let cleared = await clearer.refresh(location: location, fallback: previous, force: true, sources: [.forecast])
        try expect(cleared.snapshot?.alerts.isEmpty == true, "explicit official all-clear removes previous alerts")
        try await checkTilePipeline(at: now)
        print("Completed \(count) deterministic core checks.")
    }

    @MainActor
    static func checkTilePipeline(at now: Date) async throws {
        let transport = TileTransport()
        let store = RadarTileStore(transport: { try await transport.fetch($0) })
        let url = URL(string: "https://tiles.example.org/shared.png")!
        let values = try await withThrowingTaskGroup(of: Data.self) { group in
            for _ in 0..<12 { group.addTask { try await store.data(for: url) } }
            var results: [Data] = []
            for try await data in group { results.append(data) }
            return results
        }
        let firstCount = await transport.requests
        try expect(firstCount == 1 && values.count == 12, "12 simultaneous tile consumers share one request")
        _ = try await store.data(for: url)
        let cachedCount = await transport.requests
        try expect(cachedCount == 1, "completed tile reused from bounded in-memory cache")

        let cancelURL = URL(string: "https://tiles.example.org/cancellation.png")!
        let first = Task { try await store.data(for: cancelURL) }
        let second = Task { try await store.data(for: cancelURL) }
        try await Task.sleep(nanoseconds: 50_000_000)
        first.cancel()
        let survivor = try await second.value
        do {
            _ = try await first.value
            throw Failed(message: "cancelled consumer returned data")
        } catch is CancellationError { count += 1; print("PASS cancelled tile consumer exits without publishing") }
        let sharedCount = await transport.requests
        try expect(!survivor.isEmpty && sharedCount == 2, "one cancellation preserves another tile consumer")

        let boundedTransport = TileTransport(delay: 450_000_000)
        let boundedStore = RadarTileStore(transport: { try await boundedTransport.fetch($0) })
        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 0..<8 {
                group.addTask { _ = try await boundedStore.data(for: URL(string: "https://tiles.example.org/\(i).png")!) }
            }
            try await group.waitForAll()
        }
        let peak = await boundedTransport.peak
        let total = await boundedTransport.requests
        try expect(peak <= 4 && total == 8, "tile downloads respect four-request concurrency bound")
        try expect(RadarTileStore.retryDelay("120", at: now) == 120, "numeric Retry-After honored")
        try expect(RadarTileStore.retryDelay("Sun, 30 Aug 2026 12:02:00 GMT", at: now) == 120,
                   "HTTP-date Retry-After honored")
        let badTransport = TileTransport(validPNG: false)
        let badStore = RadarTileStore(transport: { try await badTransport.fetch($0) })
        for _ in 0..<2 {
            do {
                _ = try await badStore.data(for: url)
                throw Failed(message: "HTML error cached as radar")
            } catch is WeatherProviderError { }
        }
        let badCount = await badTransport.requests
        try expect(badCount == 2, "non-image responses rejected and not cached")
    }
}

private actor TileTransport {
    private(set) var requests = 0
    private(set) var peak = 0
    private var active = 0
    let delay: UInt64
    let validPNG: Bool
    init(delay: UInt64 = 150_000_000, validPNG: Bool = true) {
        self.delay = delay
        self.validPNG = validPNG
    }
    func fetch(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests += 1
        active += 1
        peak = max(peak, active)
        defer { active -= 1 }
        try await Task.sleep(nanoseconds: delay)
        let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=")!
        return (validPNG ? png : Data("<html>unavailable</html>".utf8),
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}
private struct StaticClient: HTTPClient {
    let data: Data
    func data(for request: URLRequest) async throws -> Data { data }
}
private struct FailingForecast: ForecastProvider {
    func fetchForecast(for location: SavedLocation) async throws -> WeatherSnapshot { throw WeatherProviderError.invalidResponse }
}
private struct FixtureForecast: ForecastProvider {
    let snapshot: WeatherSnapshot
    func fetchForecast(for location: SavedLocation) async throws -> WeatherSnapshot { snapshot }
}
private struct FailingAir: AirQualityProvider {
    func fetchAirQuality(for location: SavedLocation) async throws -> AirQualitySnapshot { throw WeatherProviderError.invalidResponse }
}
private struct FailingRadar: RadarProvider {
    func fetchRadar(for location: SavedLocation) async throws -> RadarSnapshot { throw WeatherProviderError.invalidResponse }
}
private struct FailingMarine: MarineWeatherProvider {
    func fetchMarineWeather(for location: SavedLocation) async throws -> MarineSnapshot? { throw WeatherProviderError.invalidResponse }
}
