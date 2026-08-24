import Foundation

enum AppConfiguration {
    // The public name explains the product at a glance while the shorter
    // internal name keeps targets, modules, paths, and icon artwork stable.
    static let displayName = "RAYN Weather"
    static let productName = "RAYN"
    static let marketingVersion = "1.2.4"
    static let buildNumber = "8"
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

    // These public screenshot/test locations are compiled only as display
    // labels. Keeping each key explicit lets Xcode include them in every
    // String Catalog even though capture mode itself is DEBUG-only.
    private enum PublicLocationLabels {
        static let beijing = String(localized: "Beijing")
        static let shanghai = String(localized: "Shanghai")
        static let china = String(localized: "China")
        static let newYorkCity = String(localized: "New York City")
        static let newYork = String(localized: "New York")
        static let unitedStates = String(localized: "United States")
        static let shenzhen = String(localized: "Shenzhen")
        static let guangdong = String(localized: "Guangdong")
        static let london = String(localized: "London")
        static let england = String(localized: "England")
        static let unitedKingdom = String(localized: "United Kingdom")
        static let vancouver = String(localized: "Vancouver")
        static let britishColumbia = String(localized: "British Columbia")
        static let canada = String(localized: "Canada")
    }

    #if DEBUG
    /// Public coordinates used only for reproducible screenshots, UI tests,
    /// and maintainer demos. Values still come from the live providers. A
    /// Release build ignores `RAYN_CAPTURE_LOCATION` entirely.
    static func captureLocation(named value: String?) -> SavedLocation? {
        switch value?.lowercased() {
        case "beijing":
            return SavedLocation(name: PublicLocationLabels.beijing, administrativeArea: PublicLocationLabels.beijing, country: PublicLocationLabels.china, latitude: 39.9042, longitude: 116.4074, timezoneIdentifier: "Asia/Shanghai")
        case "shanghai":
            return SavedLocation(name: PublicLocationLabels.shanghai, administrativeArea: PublicLocationLabels.shanghai, country: PublicLocationLabels.china, latitude: 31.2304, longitude: 121.4737, timezoneIdentifier: "Asia/Shanghai")
        case "new-york":
            return SavedLocation(name: PublicLocationLabels.newYorkCity, administrativeArea: PublicLocationLabels.newYork, country: PublicLocationLabels.unitedStates, latitude: 40.7128, longitude: -74.0060, timezoneIdentifier: "America/New_York")
        case "shenzhen":
            return SavedLocation(name: PublicLocationLabels.shenzhen, administrativeArea: PublicLocationLabels.guangdong, country: PublicLocationLabels.china, latitude: 22.5431, longitude: 114.0579, timezoneIdentifier: "Asia/Shanghai")
        case "london":
            return SavedLocation(name: PublicLocationLabels.london, administrativeArea: PublicLocationLabels.england, country: PublicLocationLabels.unitedKingdom, latitude: 51.5074, longitude: -0.1278, timezoneIdentifier: "Europe/London")
        case "vancouver":
            return SavedLocation(name: PublicLocationLabels.vancouver, administrativeArea: PublicLocationLabels.britishColumbia, country: PublicLocationLabels.canada, latitude: 49.2827, longitude: -123.1207, timezoneIdentifier: "America/Vancouver")
        default:
            return nil
        }
    }

    static func captureLocations(namedList value: String?) -> [SavedLocation] {
        value?
            .split(separator: ",")
            .compactMap { captureLocation(named: String($0)) } ?? []
    }
    #endif
}
