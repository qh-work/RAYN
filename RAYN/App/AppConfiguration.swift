import Foundation

enum AppConfiguration {
    static let displayName = "RAYN"
    static let productName = "RAYN"
    static let weatherRefreshInterval: TimeInterval = 15 * 60
    static let airQualityRefreshInterval: TimeInterval = 45 * 60
    static let radarRefreshInterval: TimeInterval = 10 * 60

    static let allScenes = BroadcastScene.allCases

    // First launch is location-first. Existing installations can still use
    // their saved city as a fallback when location services are unavailable.
    static let defaultFavorites: [SavedLocation] = []

    static var defaultSettings: AppSettings {
        #if os(tvOS)
        return AppSettings()
        #else
        return AppSettings()
        #endif
    }

    #if DEBUG
    /// Public coordinates used only for reproducible screenshots, UI tests,
    /// and maintainer demos. Values still come from the live providers. A
    /// Release build ignores `RAYN_CAPTURE_LOCATION` entirely.
    static func captureLocation(named value: String?) -> SavedLocation? {
        switch value?.lowercased() {
        case "beijing":
            return SavedLocation(name: "北京市", administrativeArea: "北京市", country: "中国", latitude: 39.9042, longitude: 116.4074, timezoneIdentifier: "Asia/Shanghai")
        case "shanghai":
            return SavedLocation(name: "上海市", administrativeArea: "上海市", country: "中国", latitude: 31.2304, longitude: 121.4737, timezoneIdentifier: "Asia/Shanghai")
        case "new-york":
            return SavedLocation(name: "纽约市", administrativeArea: "纽约州", country: "美国", latitude: 40.7128, longitude: -74.0060, timezoneIdentifier: "America/New_York")
        case "shenzhen":
            return SavedLocation(name: "深圳市", administrativeArea: "广东省", country: "中国", latitude: 22.5431, longitude: 114.0579, timezoneIdentifier: "Asia/Shanghai")
        case "london":
            return SavedLocation(name: "伦敦", administrativeArea: "英格兰", country: "英国", latitude: 51.5074, longitude: -0.1278, timezoneIdentifier: "Europe/London")
        case "vancouver":
            return SavedLocation(name: "温哥华", administrativeArea: "不列颠哥伦比亚", country: "加拿大", latitude: 49.2827, longitude: -123.1207, timezoneIdentifier: "America/Vancouver")
        default:
            return nil
        }
    }
    #endif
}
