import Foundation

enum BroadcastScene: String, CaseIterable, Codable, Identifiable {
    case current
    case hourly
    case daily
    case radar
    case airQuality
    case astronomy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .current: return String(localized: "Now")
        case .hourly: return String(localized: "24 Hours")
        case .daily: return String(localized: "10-Day Forecast")
        case .radar: return String(localized: "Precipitation Radar")
        case .airQuality: return String(localized: "Air Quality")
        case .astronomy: return String(localized: "Sun & Moon")
        }
    }

    var symbolName: String {
        switch self {
        case .current: return "sun.max.fill"
        case .hourly: return "chart.xyaxis.line"
        case .daily: return "calendar"
        case .radar: return "dot.radiowaves.left.and.right"
        case .airQuality: return "aqi.medium"
        case .astronomy: return "moon.stars.fill"
        }
    }
}

enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius
    case fahrenheit

    var title: String {
        self == .celsius ? String(localized: "Celsius (°C)") : String(localized: "Fahrenheit (°F)")
    }
}

enum MeasurementSystem: String, Codable, CaseIterable {
    case metric
    case imperial

    var title: String { self == .metric ? String(localized: "Metric") : String(localized: "Imperial") }
}

enum ClockFormat: String, Codable, CaseIterable {
    case twentyFourHour
    case twelveHour

    var title: String {
        self == .twentyFourHour ? String(localized: "24-Hour") : String(localized: "12-Hour")
    }
}

enum DynamicIntensity: String, Codable, CaseIterable {
    case low
    case medium
    case high

    var title: String {
        switch self {
        case .low: return String(localized: "Low")
        case .medium: return String(localized: "Medium")
        case .high: return String(localized: "High")
        }
    }

    var particleCount: Int {
        switch self {
        case .low: return 18
        case .medium: return 34
        case .high: return 52
        }
    }
}

enum ViewingDistance: String, Codable, CaseIterable {
    case near
    case standard
    case far

    var title: String {
        switch self {
        case .near: return String(localized: "Near")
        case .standard: return String(localized: "Standard")
        case .far: return String(localized: "Far")
        }
    }

    var scale: Double {
        switch self {
        case .near: return 0.90
        case .standard: return 1.00
        case .far: return 1.16
        }
    }
}

struct AppSettings: Codable, Equatable {
    var useCurrentLocation = true
    var temperatureUnit: TemperatureUnit = .celsius
    var measurementSystem: MeasurementSystem = .metric
    var clockFormat: ClockFormat = .twentyFourHour
    // Manual navigation is the television-friendly default. Automatic scene
    // rotation remains available as an explicit opt-in in Settings.
    var automaticRotation = false
    var rotationSeconds = 15.0
    var hiddenScenes: Set<BroadcastScene> = []
    var dynamicIntensity: DynamicIntensity = .medium
    var viewingDistance: ViewingDistance = .standard
    var lightningEnabled = true
    var nightDimMode = false
    var keepScreenAwake = false
    var reduceMotion = false
}

struct SavedLocation: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var administrativeArea: String
    var country: String
    var latitude: Double
    var longitude: Double
    var timezoneIdentifier: String
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        name: String,
        administrativeArea: String,
        country: String,
        latitude: Double,
        longitude: Double,
        timezoneIdentifier: String,
        isFavorite: Bool = true
    ) {
        self.id = id
        self.name = name
        self.administrativeArea = administrativeArea
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.timezoneIdentifier = timezoneIdentifier
        self.isFavorite = isFavorite
    }

    var subtitle: String {
        [administrativeArea, country].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    static let currentPlaceholder = SavedLocation(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(),
        name: String(localized: "Locating…"),
        administrativeArea: "",
        country: "",
        latitude: 0,
        longitude: 0,
        timezoneIdentifier: TimeZone.current.identifier,
        isFavorite: false
    )
}

struct CurrentConditions: Codable, Equatable {
    var temperature: Double
    var feelsLike: Double
    var high: Double
    var low: Double
    var relativeHumidity: Double
    var dewPoint: Double
    var pressure: Double
    var visibility: Double
    var cloudCover: Double
    var windSpeed: Double
    var windDirection: Double
    var windGust: Double
    var uvIndex: Double
    var precipitationProbability: Double
    var precipitation: Double
    var weatherCode: Int
    var isDay: Bool
    var sunrise: Date?
    var sunset: Date?
    var rain: Double? = nil
    var snowfall: Double? = nil
    var cloudCoverLow: Double? = nil
    var cloudCoverMid: Double? = nil
    var cloudCoverHigh: Double? = nil
    var daylightDuration: Double? = nil
}

struct HourlyForecastPoint: Codable, Identifiable, Equatable {
    var id: Date { time }
    var time: Date
    var temperature: Double
    var apparentTemperature: Double
    var precipitationProbability: Double
    var precipitation: Double
    var snowfall: Double
    var windSpeed: Double
    var windDirection: Double
    var weatherCode: Int
    var isDay: Bool
    var windGust: Double? = nil
    var visibility: Double? = nil
    var uvIndex: Double? = nil
}

struct DailyForecastPoint: Codable, Identifiable, Equatable {
    var id: Date { date }
    var date: Date
    var high: Double
    var low: Double
    var weatherCode: Int
    var precipitationProbability: Double
    var precipitation: Double
    var windSpeed: Double
    var windGust: Double
    var sunrise: Date?
    var sunset: Date?
    var uvIndex: Double? = nil
    var daylightDuration: Double? = nil
}

struct PollutantValue: Codable, Identifiable, Equatable {
    var id: String { key }
    var key: String
    var title: String
    var value: Double
    var unit: String
    var reference: Double
}

struct AirQualitySnapshot: Codable, Equatable {
    var europeanAQI: Double
    var pm25: Double
    var pm10: Double
    var ozone: Double
    var nitrogenDioxide: Double
    var sulphurDioxide: Double
    var carbonMonoxide: Double
    var updatedAt: Date
    var hourlyAQI: [Double]

    var level: String {
        switch europeanAQI {
        case ..<20: return String(localized: "Excellent")
        case ..<40: return String(localized: "Good")
        case ..<60: return String(localized: "Moderate Pollution")
        case ..<80: return String(localized: "Poor")
        case ..<100: return String(localized: "Very Poor")
        default: return String(localized: "Extremely Poor")
        }
    }

    var advice: String {
        switch europeanAQI {
        case ..<40: return String(localized: "Air quality is suitable for outdoor activities. Sensitive groups can adjust as needed.")
        case ..<80: return String(localized: "Sensitive groups should reduce prolonged or intense outdoor activity.")
        default: return String(localized: "Reduce time outdoors and take precautions when necessary.")
        }
    }

    var pollutants: [PollutantValue] {
        [
            PollutantValue(key: "pm25", title: "PM2.5", value: pm25, unit: "μg/m³", reference: 35),
            PollutantValue(key: "pm10", title: "PM10", value: pm10, unit: "μg/m³", reference: 70),
            PollutantValue(key: "o3", title: "O₃", value: ozone, unit: "μg/m³", reference: 160),
            PollutantValue(key: "no2", title: "NO₂", value: nitrogenDioxide, unit: "μg/m³", reference: 200),
            PollutantValue(key: "so2", title: "SO₂", value: sulphurDioxide, unit: "μg/m³", reference: 125),
            PollutantValue(key: "co", title: "CO", value: carbonMonoxide, unit: "μg/m³", reference: 10000)
        ]
    }
}

struct RadarFrame: Codable, Identifiable, Equatable {
    var id: Int { timestamp }
    var timestamp: Int
    var tilePath: String?
    /// Full `{z}/{x}/{y}` tile template when a provider supplies one.
    /// Keeping this optional preserves compatibility with older snapshots.
    var tileURLTemplate: String?
    var source: String
    var isForecast: Bool

    var date: Date { Date(timeIntervalSince1970: TimeInterval(timestamp)) }

    init(
        timestamp: Int,
        tilePath: String? = nil,
        tileURLTemplate: String? = nil,
        source: String,
        isForecast: Bool = false
    ) {
        self.timestamp = timestamp
        self.tilePath = tilePath
        self.tileURLTemplate = tileURLTemplate
        self.source = source
        self.isForecast = isForecast
    }

    enum CodingKeys: String, CodingKey {
        case timestamp
        case tilePath
        case tileURLTemplate
        case source
        case isForecast
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        tilePath = try container.decodeIfPresent(String.self, forKey: .tilePath)
        tileURLTemplate = try container.decodeIfPresent(String.self, forKey: .tileURLTemplate)
        source = try container.decode(String.self, forKey: .source)
        isForecast = try container.decodeIfPresent(Bool.self, forKey: .isForecast) ?? false
    }
}

struct RadarSnapshot: Codable, Equatable {
    var frames: [RadarFrame]
    var selectedIndex: Int
    var isAvailable: Bool
    var message: String?

    static let unavailable = RadarSnapshot(
        frames: [], selectedIndex: 0, isAvailable: false,
        message: String(localized: "No radar imagery is available for this area.")
    )
}

struct MarineSnapshot: Codable, Equatable {
    var waveHeight: Double
    var waveDirection: Double
    var wavePeriod: Double
    var windWaveHeight: Double
    var swellWaveHeight: Double
    var updatedAt: Date
    var seaSurfaceTemperature: Double? = nil
    var oceanCurrentVelocity: Double? = nil
    var oceanCurrentDirection: Double? = nil
    var seaLevelHeight: Double? = nil
    var hourly: [MarineForecastPoint]? = nil
}

struct MarineForecastPoint: Codable, Identifiable, Equatable {
    var id: Date { time }
    var time: Date
    var waveHeight: Double
    var waveDirection: Double
    var wavePeriod: Double
    var windWaveHeight: Double
    var swellWaveHeight: Double
    var seaSurfaceTemperature: Double? = nil
    var oceanCurrentVelocity: Double? = nil
    var oceanCurrentDirection: Double? = nil
    var seaLevelHeight: Double? = nil
}

struct WeatherAlertItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var issuer: String
    var startDate: Date
    var endDate: Date
    var detailURL: String?

    init(id: UUID = UUID(), title: String, issuer: String, startDate: Date, endDate: Date, detailURL: String? = nil) {
        self.id = id
        self.title = title
        self.issuer = issuer
        self.startDate = startDate
        self.endDate = endDate
        self.detailURL = detailURL
    }
}

struct WeatherSummary: Codable, Equatable {
    var headline: String
    var detail: String
    var insights: [String]
    var hasAlert: Bool

    static let empty = WeatherSummary(
        headline: String(localized: "Preparing weather summary"),
        detail: String(localized: "Weather data is loading."),
        insights: [],
        hasAlert: false
    )
}

enum ClothingIndex: String, Equatable {
    case cool
    case comfortable
    case light
    case hot

    var title: String {
        switch self {
        case .cool: return String(localized: "Cool")
        case .comfortable: return String(localized: "Comfortable")
        case .light: return String(localized: "Mild")
        case .hot: return String(localized: "Hot")
        }
    }

    var symbolName: String {
        switch self {
        case .cool: return "tshirt.fill"
        case .comfortable: return "tshirt.fill"
        case .light: return "tshirt.fill"
        case .hot: return "sun.max.fill"
        }
    }
}

struct ClothingAdvice: Equatable {
    var index: ClothingIndex
    var outfit: String
    var detail: String
}

enum ClothingAdviceBuilder {
    static func make(from current: CurrentConditions) -> ClothingAdvice {
        let apparent = current.feelsLike
        let index: ClothingIndex
        let outfit: String
        let detail: String

        switch apparent {
        case ..<8:
            index = .cool
            outfit = String(localized: "Heavy coat or down jacket")
            detail = String(localized: "It feels cold. Keep warm, especially in the morning and evening.")
        case 8..<16:
            index = .cool
            outfit = String(localized: "Jacket or light coat")
            detail = String(localized: "Mornings and evenings feel cool. Bring a jacket.")
        case 16..<24:
            index = .comfortable
            outfit = String(localized: "Long sleeves or a light jacket")
            detail = String(localized: "Conditions feel comfortable. Layers make it easier to adjust.")
        case 24..<29:
            index = .light
            outfit = String(localized: "T-shirt or lightweight long sleeves")
            detail = String(localized: "Conditions feel mild. Choose light, breathable clothing.")
        default:
            index = .hot
            outfit = String(localized: "Light summer clothing")
            detail = String(localized: "It feels hot. Stay ventilated, hydrated, and protected from the sun.")
        }

        var extra = detail
        if current.precipitationProbability >= 60 {
            extra += " " + String(localized: "Rain is likely. Remember an umbrella.")
        }
        return ClothingAdvice(index: index, outfit: outfit, detail: extra)
    }
}

struct MoonPhaseInfo: Equatable {
    var title: String
    var symbolName: String
    var illumination: Double
    var age: Double
    var nextPhaseTitle: String
    var nextPhaseDate: Date
}

enum MoonPhaseCalculator {
    private static let synodicMonth = 29.530588
    private static let referenceNewMoon = Date(timeIntervalSince1970: 947182440)

    static func info(at date: Date) -> MoonPhaseInfo {
        let elapsedDays = date.timeIntervalSince(referenceNewMoon) / 86_400
        let age = ((elapsedDays.truncatingRemainder(dividingBy: synodicMonth)) + synodicMonth).truncatingRemainder(dividingBy: synodicMonth)
        let illumination = (1 - cos(2 * Double.pi * age / synodicMonth)) / 2
        let phase: (title: String, symbolName: String)
        switch age {
        case 1.85..<7.38: phase = (String(localized: "Waxing Crescent"), "moon.haze.fill")
        case 7.38..<9.23: phase = (String(localized: "First Quarter"), "moon.phase.first.quarter")
        case 9.23..<14.77: phase = (String(localized: "Waxing Gibbous"), "moon.circle.fill")
        case 14.77..<16.62: phase = (String(localized: "Full Moon"), "moon.fill")
        case 16.62..<22.15: phase = (String(localized: "Waning Gibbous"), "moon.circle.fill")
        case 22.15..<24.00: phase = (String(localized: "Last Quarter"), "moon.phase.last.quarter")
        case 24.00..<28.00: phase = (String(localized: "Waning Crescent"), "moon.haze.fill")
        default: phase = (String(localized: "New Moon"), "moon.zzz.fill")
        }
        let next = nextMajorPhase(after: age, date: date)
        return MoonPhaseInfo(title: phase.title, symbolName: phase.symbolName, illumination: illumination, age: age, nextPhaseTitle: next.title, nextPhaseDate: next.date)
    }

    private static func nextMajorPhase(after age: Double, date: Date) -> (title: String, date: Date) {
        let phases: [(age: Double, title: String)] = [
            (0, String(localized: "New Moon")),
            (7.38, String(localized: "First Quarter")),
            (14.77, String(localized: "Full Moon")),
            (22.15, String(localized: "Last Quarter"))
        ]
        let next = phases
            .map { phase in
                let delta = phase.age >= age ? phase.age - age : synodicMonth - age + phase.age
                return (phase.title, delta)
            }
            .min(by: { $0.1 < $1.1 }) ?? (String(localized: "New Moon"), synodicMonth - age)
        return (next.0, date.addingTimeInterval(next.1 * 86_400))
    }
}

struct WeatherSnapshot: Codable, Equatable {
    var location: SavedLocation
    var timezoneIdentifier: String
    var current: CurrentConditions
    var hourly: [HourlyForecastPoint]
    var daily: [DailyForecastPoint]
    var airQuality: AirQualitySnapshot?
    var radar: RadarSnapshot
    var marine: MarineSnapshot?
    var alerts: [WeatherAlertItem]
    var summary: WeatherSummary
    var updatedAt: Date
    var source: String
    var isOffline: Bool
    var theme: WeatherTheme

}

enum WeatherSummaryBuilder {
    static func make(from snapshot: WeatherSnapshot, unit: TemperatureUnit = .celsius) -> WeatherSummary {
        let current = snapshot.current
        let rainHours = snapshot.hourly.filter { $0.precipitationProbability >= 50 }
        let maxRain = snapshot.hourly.map(\.precipitationProbability).max() ?? current.precipitationProbability
        let maxGust = max(snapshot.hourly.map(\.windSpeed).max() ?? current.windGust, current.windGust)
        let range = current.high - current.low
        let condition = WeatherCodeMapper.description(for: current.weatherCode, isDay: current.isDay, visibility: current.visibility)
        let unitSymbol = unit == .celsius ? "℃" : "℉"
        let formattedHigh = current.high.formattedTemperature(unit: unit)
        let formattedCurrent = current.temperature.formattedTemperature(unit: unit)
        let formattedFeelsLike = current.feelsLike.formattedTemperature(unit: unit)
        var headline = String(localized: "Today will be mostly \(condition), with a high of \(formattedHigh)\(unitSymbol).")
        if maxRain >= 60 {
            let rainTime = rainHours.first.map { formatHour($0.time, timezone: snapshot.timezoneIdentifier) } ?? String(localized: "later")
            headline += " " + String(localized: "Rain chances rise around \(rainTime).")
        }

        var detailParts = [String(localized: "Currently \(formattedCurrent)\(unitSymbol), feels like \(formattedFeelsLike)\(unitSymbol).")]
        if let airQuality = snapshot.airQuality {
            detailParts.append(String(localized: "Air quality is \(airQuality.level), with an AQI of \(Int(airQuality.europeanAQI.rounded()))."))
        } else {
            detailParts.append(String(localized: "Air-quality data is currently unavailable."))
        }

        var insights = [String]()
        if current.temperature - current.low >= 6 {
            let displayRange = unit == .celsius ? range : range * 9 / 5
            let formattedRange = displayRange.formattedNumber(decimals: 0)
            insights.append(String(localized: "The day–night temperature range is about \(formattedRange)\(unitSymbol), so mornings and evenings will feel cooler."))
        }
        if maxRain >= 60 {
            insights.append(String(localized: "The highest rain chance in the next 24 hours is about \(Int(maxRain.rounded()))%. Carry an umbrella."))
        }
        if maxGust >= 30 {
            insights.append(String(localized: "Wind gusts may reach \(Int(maxGust.rounded())) km/h. Coastal areas should monitor changing winds."))
        }
        if current.uvIndex >= 6 {
            insights.append(String(localized: "Afternoon UV levels are high. Use sun protection for extended outdoor activity."))
        }
        let futureAverageHigh = snapshot.daily.map(\.high).average
        if let futureAverageHigh, current.high - futureAverageHigh >= 2 {
            let delta = unit == .celsius ? current.high - futureAverageHigh : (current.high - futureAverageHigh) * 9 / 5
            insights.append(String(localized: "Today's high is about \(Int(delta.rounded()))\(unitSymbol) above the 10-day average."))
        } else if let futureAverageHigh, futureAverageHigh - current.high >= 2 {
            let delta = unit == .celsius ? futureAverageHigh - current.high : (futureAverageHigh - current.high) * 9 / 5
            insights.append(String(localized: "Today's high is about \(Int(delta.rounded()))\(unitSymbol) below the 10-day average."))
        }
        if insights.isEmpty {
            insights.append(String(localized: "Weather conditions are stable, so planned activities can continue."))
        }

        return WeatherSummary(headline: headline, detail: detailParts.joined(separator: " "), insights: insights, hasAlert: !snapshot.alerts.isEmpty)
    }

    private static func formatHour(_ date: Date, timezone: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = TimeZone(identifier: timezone)
        formatter.setLocalizedDateFormatFromTemplate("j")
        return formatter.string(from: date)
    }
}

private extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
