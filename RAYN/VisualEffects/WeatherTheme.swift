import SwiftUI

enum WeatherTheme: String, Codable, CaseIterable {
    case clearDay
    case clearNight
    case cloudy
    case overcast
    case haze
    case drizzle
    case rain
    case freezingRain
    case showers
    case storm
    case snow
    case hail
    case fog

    var title: String {
        switch self {
        case .clearDay: return String(localized: "Clear Day")
        case .clearNight: return String(localized: "Clear Night")
        case .cloudy: return String(localized: "Cloudy")
        case .overcast: return String(localized: "Overcast")
        case .haze: return String(localized: "Haze / Low Visibility")
        case .drizzle: return String(localized: "Drizzle")
        case .rain: return String(localized: "Rain")
        case .freezingRain: return String(localized: "Freezing Rain")
        case .showers: return String(localized: "Showers")
        case .storm: return String(localized: "Thunderstorm")
        case .snow: return String(localized: "Snow")
        case .hail: return String(localized: "Hail")
        case .fog: return String(localized: "Fog")
        }
    }

    var colors: [Color] {
        colors(isDay: true)
    }

    func colors(isDay: Bool) -> [Color] {
        switch self {
        case .clearDay: return [Color(hex: 0x163765), Color(hex: 0x2B8EC7), Color(hex: 0xF0C978)]
        case .clearNight: return [Color(hex: 0x030917), Color(hex: 0x0B1C4D), Color(hex: 0x142D70)]
        case .cloudy: return isDay ? [Color(hex: 0x315876), Color(hex: 0x65869A), Color(hex: 0xB5B6A1)] : [Color(hex: 0x0B1A2D), Color(hex: 0x203A56), Color(hex: 0x42586C)]
        case .overcast: return [Color(hex: 0x202B38), Color(hex: 0x4C5B68), Color(hex: 0x84929A)]
        case .haze: return isDay ? [Color(hex: 0x5D473C), Color(hex: 0x9A725A), Color(hex: 0xD0AE79)] : [Color(hex: 0x17151C), Color(hex: 0x40333A), Color(hex: 0x71524A)]
        case .drizzle: return [Color(hex: 0x1B3549), Color(hex: 0x416B7D), Color(hex: 0x79939A)]
        case .rain: return [Color(hex: 0x071A32), Color(hex: 0x164D73), Color(hex: 0x356F8B)]
        case .freezingRain: return [Color(hex: 0x1C2E45), Color(hex: 0x4B6E86), Color(hex: 0xA5BFCA)]
        case .showers: return [Color(hex: 0x132B47), Color(hex: 0x2F5E7A), Color(hex: 0x6D9AA6)]
        case .storm: return [Color(hex: 0x080B18), Color(hex: 0x25294A), Color(hex: 0x463E67)]
        case .snow: return [Color(hex: 0x294A63), Color(hex: 0x73A0B9), Color(hex: 0xC7E0E9)]
        case .hail: return [Color(hex: 0x121827), Color(hex: 0x3B465E), Color(hex: 0x7D8EA5)]
        case .fog: return [Color(hex: 0x253D48), Color(hex: 0x627B83), Color(hex: 0xA6B5B2)]
        }
    }

    var hasRain: Bool { [.drizzle, .rain, .freezingRain, .showers, .storm].contains(self) }
    var hasSnow: Bool { self == .snow }
    var hasFog: Bool { self == .fog }
    var hasHaze: Bool { self == .haze }
    var hasHail: Bool { self == .hail }

    var cloudDensity: Double {
        switch self {
        case .clearDay, .clearNight, .haze: return 0
        case .cloudy: return 0.72
        case .overcast, .fog: return 1.08
        case .drizzle, .freezingRain, .showers: return 0.86
        case .rain, .snow: return 0.98
        case .storm, .hail: return 1.18
        }
    }

    var rainStrength: Double {
        switch self {
        case .drizzle: return 0.45
        case .freezingRain: return 0.72
        case .showers: return 0.85
        case .rain: return 1.0
        case .storm: return 1.15
        default: return 0
        }
    }

    static func from(
        weatherCode: Int,
        isDay: Bool,
        precipitation: Double,
        windSpeed: Double,
        visibility: Double = 100
    ) -> WeatherTheme {
        if weatherCode == 96 || weatherCode == 99 { return .hail }
        if weatherCode == 95 { return .storm }
        if weatherCode == 56 || weatherCode == 57 || weatherCode == 66 || weatherCode == 67 { return .freezingRain }
        if weatherCode == 51 || weatherCode == 53 || weatherCode == 55 { return .drizzle }
        if weatherCode == 80 || weatherCode == 81 || weatherCode == 82 { return .showers }
        if weatherCode == 71 || weatherCode == 73 || weatherCode == 75 || weatherCode == 77 || weatherCode == 85 || weatherCode == 86 { return .snow }
        if weatherCode >= 61 && weatherCode <= 65 || precipitation > 0.5 { return .rain }
        if weatherCode == 45 || weatherCode == 48 { return .fog }
        if visibility < 5 && weatherCode < 45 { return .haze }
        if weatherCode == 3 { return .overcast }
        if weatherCode == 1 || weatherCode == 2 { return .cloudy }
        return isDay ? .clearDay : .clearNight
    }
}

enum WeatherCodeMapper {
    static func description(for code: Int, isDay: Bool) -> String {
        switch code {
        case 0: return isDay ? String(localized: "Clear") : String(localized: "Clear Night Sky")
        case 1: return String(localized: "Mostly Clear")
        case 2: return String(localized: "Cloudy")
        case 3: return String(localized: "Overcast")
        case 45, 48: return String(localized: "Fog")
        case 51, 53, 55: return String(localized: "Drizzle")
        case 56, 57: return String(localized: "Freezing Drizzle")
        case 61, 63, 65: return String(localized: "Rain")
        case 66, 67: return String(localized: "Freezing Rain")
        case 71, 73, 75, 77: return String(localized: "Snow")
        case 80, 81, 82: return String(localized: "Showers")
        case 85, 86: return String(localized: "Snow Showers")
        case 95: return String(localized: "Thunderstorm")
        case 96, 99: return String(localized: "Thunderstorm with Hail")
        default: return String(localized: "Changing Weather")
        }
    }

    static func description(for code: Int, isDay: Bool, visibility: Double?) -> String {
        if let visibility, visibility < 5, code < 45 {
            return String(localized: "Haze / Low Visibility")
        }
        return description(for: code, isDay: isDay)
    }

    static func symbol(for code: Int, isDay: Bool) -> String {
        switch code {
        case 0: return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1: return isDay ? "sun.min.fill" : "moon.fill"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85...86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
