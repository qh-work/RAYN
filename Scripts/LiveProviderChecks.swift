import Foundation

@main
struct LiveProviderChecks {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw WeatherProviderError.invalidResponse }
        FileHandle.standardOutput.write(Data("PASS \(message)\n".utf8))
    }

    static func main() async throws {
        let newYork = SavedLocation(
            name: "New York", administrativeArea: "NY", country: "United States",
            latitude: 40.7128, longitude: -74.006,
            timezoneIdentifier: "America/New_York"
        )
        let alerts = try await NWSAlertProvider().fetchAlerts(for: newYork)
        try require(alerts.availability == .available, "NWS public New York request parsed")
        try require(alerts.alerts.allSatisfy { $0.endDate > alerts.checkedAt },
                    "NWS response contains only active official messages")

        let forecast = try await OpenMeteoForecastProvider().fetchForecast(for: newYork)
        try require(forecast.daily.count == 10 && forecast.hourly.count >= 24,
                    "Open-Meteo production forecast parsed with 10 days and 24+ hours")
        try require(forecast.location.latitude == newYork.latitude && !forecast.isOffline,
                    "live forecast remains attached to the requested public city")

        let radar = try await NOAARadarProvider().fetchRadar(for: newYork)
        try require(radar.isAvailable && !radar.frames.isEmpty,
                    "NOAA advertised timeline parsed by production provider")
        try require(radar.frames.count <= 13 && radar.frames.allSatisfy { $0.date <= Date() },
                    "NOAA frames are bounded and not future-dated")
        guard let descriptor = radar.frames.last?.tileDescriptor else {
            throw WeatherProviderError.invalidResponse
        }
        let tile = tileCoordinate(latitude: newYork.latitude, longitude: newYork.longitude, zoom: 6)
        guard let tileURL = RadarTileURL.resolve(descriptor.urlTemplate, z: 6, x: tile.x, y: tile.y) else {
            throw WeatherProviderError.invalidURL
        }
        let tileData = try await RadarTileStore().data(for: tileURL)
        try require(tileData.count > 8, "NOAA real New York radar PNG downloaded")

        let london = SavedLocation(
            name: "London", administrativeArea: "England", country: "United Kingdom",
            latitude: 51.5072, longitude: -0.1276,
            timezoneIdentifier: "Europe/London"
        )
        let fallback = try await RegionalRadarProvider().fetchRadar(for: london)
        try require(fallback.isAvailable && !fallback.frames.isEmpty,
                    "outside-US regional adapter returns real RainViewer history")
        try require(fallback.frames.allSatisfy {
            $0.source == "RainViewer" && !$0.isForecast
                && $0.tileDescriptor?.palette == .universalBlue
                && $0.tileDescriptor?.maximumZoom == 7
        }, "RainViewer 2026 history-only contract preserved")
        FileHandle.standardOutput.write(
            Data("Completed live provider acceptance with public city coordinates.\n".utf8)
        )
    }

    private static func tileCoordinate(latitude: Double, longitude: Double, zoom: Int) -> (x: Int, y: Int) {
        let latitude = min(max(latitude, -85.051_128_78), 85.051_128_78)
        let radians = latitude * .pi / 180
        let scale = pow(2, Double(zoom))
        return (
            Int(floor((longitude + 180) / 360 * scale)),
            Int(floor((1 - log(tan(radians) + 1 / cos(radians)) / .pi) / 2 * scale))
        )
    }
}
