import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

enum RadarTileKind: String, Codable { case xyz, wms }
enum RadarPalette: String, Codable { case universalBlue, reflectivity }

/// Metadata belongs to the provider; the renderer only resolves a request.
struct RadarTileDescriptor: Codable, Equatable {
    var kind: RadarTileKind
    var urlTemplate: String
    var maximumZoom: Int
    var palette: RadarPalette
    var legendURLString: String? = nil
}

enum RadarTileURL {
    static func resolve(_ template: String, z: Int, x: Int, y: Int, scale: Int = 1) -> URL? {
        guard (0...20).contains(z), (0..<(1 << z)).contains(x), (0..<(1 << z)).contains(y) else { return nil }
        let halfWorld = 20_037_508.342789244
        let span = halfWorld * 2 / Double(1 << z)
        let west = -halfWorld + Double(x) * span
        let north = halfWorld - Double(y) * span
        // WMS 1.3 + EPSG:3857 uses x/y axis order, unlike EPSG:4326.
        let bbox = [west, north - span, west + span, north].map { String($0) }.joined(separator: ",")
        let result = template
            .replacingOccurrences(of: "{bbox}", with: bbox)
            .replacingOccurrences(of: "%7Bbbox%7D", with: bbox)
            .replacingOccurrences(of: "{z}", with: String(z))
            .replacingOccurrences(of: "{x}", with: String(x))
            .replacingOccurrences(of: "{y}", with: String(y))
            .replacingOccurrences(of: "{scale}", with: String(scale))
        guard let url = URL(string: result), url.scheme == "https", url.host != nil else { return nil }
        return url
    }
}

struct NOAARadarProvider: RadarProvider {
    static let endpoint = "https://opengeo.ncep.noaa.gov/geoserver/conus/conus_bref_qcd/ows"
    let httpClient: HTTPClient
    let now: () -> Date
    var dataAttributions: [DataAttribution] { [.nws] }

    init(httpClient: HTTPClient = URLSessionHTTPClient(), now: @escaping () -> Date = Date.init) {
        self.httpClient = httpClient
        self.now = now
    }

    func fetchRadar(for location: SavedLocation) async throws -> RadarSnapshot {
        guard USWeatherCoverage.includesCONUS(location) else { return .unavailable }
        let url = URL(string: Self.endpoint + "?service=WMS&request=GetCapabilities&version=1.3.0")!
        let data = try await httpClient.data(for: URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12))
        try Task.checkCancellation()
        return try Self.parseCapabilities(data, at: now())
    }

    static func parseCapabilities(_ data: Data, at now: Date) throws -> RadarSnapshot {
        guard data.count <= 4 * 1_024 * 1_024 else { throw WeatherProviderError.invalidResponse }
        let delegate = CapabilitiesParser()
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        guard parser.parse(), delegate.supportsMercator,
              let layer = delegate.layerNames.first(where: { $0.hasSuffix("conus_bref_qcd") }),
              let dimension = delegate.timeDimensions.last else { throw WeatherProviderError.invalidResponse }
        let dates = try advertisedTimes(dimension, at: now)
        let frames = dates.map { date -> RadarFrame in
            var components = URLComponents(string: endpoint)!
            components.queryItems = [
                URLQueryItem(name: "service", value: "WMS"),
                URLQueryItem(name: "request", value: "GetMap"),
                URLQueryItem(name: "version", value: "1.3.0"),
                URLQueryItem(name: "layers", value: layer),
                URLQueryItem(name: "styles", value: ""),
                URLQueryItem(name: "crs", value: "EPSG:3857"),
                URLQueryItem(name: "bbox", value: "{bbox}"),
                URLQueryItem(name: "width", value: "256"),
                URLQueryItem(name: "height", value: "256"),
                URLQueryItem(name: "format", value: "image/png"),
                URLQueryItem(name: "transparent", value: "true"),
                URLQueryItem(name: "time", value: ISO8601DateFormatter().string(from: date))
            ]
            let template = components.string!
            var frame = RadarFrame(timestamp: Int(date.timeIntervalSince1970),
                                   tileURLTemplate: template, source: "NOAA / NWS")
            frame.tileDescriptor = RadarTileDescriptor(kind: .wms, urlTemplate: template,
                                                       maximumZoom: 7, palette: .reflectivity,
                                                       legendURLString: endpoint + "?service=WMS&request=GetLegendGraphic&version=1.3.0&format=image/png&layer=conus_bref_qcd")
            return frame
        }
        guard !frames.isEmpty else { return .unavailable }
        return RadarSnapshot(frames: frames, selectedIndex: frames.count - 1, isAvailable: true, message: nil)
    }

    /// Only expands intervals explicitly advertised by the service. Never assigns
    /// synthetic frame timestamps to a "latest image" endpoint.
    static func advertisedTimes(_ value: String, at now: Date) throws -> [Date] {
        var dates = Set<Date>()
        let cutoff = now.addingTimeInterval(-2 * 60 * 60)
        for item in value.split(separator: ",") {
            let parts = item.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "/").map(String.init)
            if parts.count == 1, let date = ProviderDate.parse(parts[0]) {
                if date >= cutoff && date <= now { dates.insert(date) }
            } else if parts.count == 3, let start = ProviderDate.parse(parts[0]),
                      let end = ProviderDate.parse(parts[1]), start <= end,
                      let step = duration(parts[2]), step >= 1 {
                let first = max(0, ceil(cutoff.timeIntervalSince(start) / step))
                let count = floor(min(end, now).timeIntervalSince(start) / step)
                guard count >= first else { continue }
                // Keep the newest advertised frames; never expand an unbounded feed.
                for index in Int(max(first, count - 119))...Int(count) {
                    dates.insert(start.addingTimeInterval(Double(index) * step))
                }
            } else {
                throw WeatherProviderError.invalidResponse
            }
        }
        let sorted = dates.sorted()
        guard sorted.count > 13 else { return sorted }
        return (0..<13).map { sorted[Int((Double($0) * Double(sorted.count - 1) / 12).rounded())] }
    }

    private static func duration(_ value: String) -> TimeInterval? {
        guard value.hasPrefix("PT") else { return nil }
        var number = "", total = 0.0
        for character in value.dropFirst(2) {
            if character.isNumber || character == "." { number.append(character); continue }
            guard let amount = Double(number), amount.isFinite, amount >= 0 else { return nil }
            switch character {
            case "H": total += amount * 3600
            case "M": total += amount * 60
            case "S": total += amount
            default: return nil
            }
            number = ""
        }
        return number.isEmpty && total > 0 && total.isFinite ? total : nil
    }
}

private final class CapabilitiesParser: NSObject, XMLParserDelegate {
    var layerNames: [String] = []
    var timeDimensions: [String] = []
    var supportsMercator = false
    private var text = ""
    private var isTime = false
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes: [String: String]) {
        text = ""
        if elementName == "Dimension" || elementName == "Extent" {
            isTime = attributes["name"]?.lowercased() == "time"
        }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) { text += string }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if elementName == "Name" { layerNames.append(value) }
        if elementName == "CRS" && value == "EPSG:3857" { supportsMercator = true }
        if (elementName == "Dimension" || elementName == "Extent") && isTime {
            timeDimensions.append(value)
            isTime = false
        }
    }
}

struct RegionalRadarProvider: RadarProvider {
    let official: RadarProvider
    let global: RadarProvider
    init(official: RadarProvider = NOAARadarProvider(), global: RadarProvider = RainViewerRadarProvider()) {
        self.official = official
        self.global = global
    }
    var dataAttributions: [DataAttribution] { DataAttribution.unique(official.dataAttributions + global.dataAttributions) }
    func fetchRadar(for location: SavedLocation) async throws -> RadarSnapshot {
        if USWeatherCoverage.includesCONUS(location) {
            do {
                let result = try await official.fetchRadar(for: location)
                if result.isAvailable { return result }
            } catch is CancellationError { throw CancellationError() }
            catch { /* Whole-source fallback; frames are never blended. */ }
        }
        try Task.checkCancellation()
        return try await global.fetchRadar(for: location)
    }
}
