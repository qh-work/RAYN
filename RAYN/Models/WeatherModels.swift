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
        case .current: return "此刻"
        case .hourly: return "24小时"
        case .daily: return "未来10天"
        case .radar: return "降水雷达"
        case .airQuality: return "空气质量"
        case .astronomy: return "日照月相"
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

    var title: String { self == .celsius ? "摄氏度（℃）" : "华氏度（℉）" }
}

enum MeasurementSystem: String, Codable, CaseIterable {
    case metric
    case imperial

    var title: String { self == .metric ? "公制" : "英制" }
}

enum ClockFormat: String, Codable, CaseIterable {
    case twentyFourHour
    case twelveHour

    var title: String { self == .twentyFourHour ? "24小时制" : "12小时制" }
}

enum DynamicIntensity: String, Codable, CaseIterable {
    case low
    case medium
    case high

    var title: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
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
        case .near: return "近距离"
        case .standard: return "标准观看"
        case .far: return "远距离"
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
        name: "正在定位",
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
        case ..<20: return "优"
        case ..<40: return "良"
        case ..<60: return "轻度污染"
        case ..<80: return "中度污染"
        case ..<100: return "重度污染"
        default: return "严重污染"
        }
    }

    var advice: String {
        switch europeanAQI {
        case ..<40: return "空气状况适宜户外活动，敏感人群可按需调整。"
        case ..<80: return "建议敏感人群减少长时间、高强度户外活动。"
        default: return "建议减少户外停留时间，必要时做好防护。"
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

    static let unavailable = RadarSnapshot(frames: [], selectedIndex: 0, isAvailable: false, message: "当前区域暂无可用雷达图像")
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

    static let empty = WeatherSummary(headline: "正在生成天气播报", detail: "天气数据准备中。", insights: [], hasAlert: false)
}

enum ClothingIndex: String, Equatable {
    case cool
    case comfortable
    case light
    case hot

    var title: String {
        switch self {
        case .cool: return "偏凉"
        case .comfortable: return "舒适"
        case .light: return "清爽"
        case .hot: return "炎热"
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
            outfit = "厚外套或羽绒服"
            detail = "体感偏冷，早晚注意保暖。"
        case 8..<16:
            index = .cool
            outfit = "夹克或薄外套"
            detail = "早晚偏凉，建议准备一件外套。"
        case 16..<24:
            index = .comfortable
            outfit = "长袖或薄外套"
            detail = "体感舒适，分层穿着更方便。"
        case 24..<29:
            index = .light
            outfit = "短袖或轻薄长袖"
            detail = "体感温和，选择轻便透气的衣物。"
        default:
            index = .hot
            outfit = "短袖等清凉夏装"
            detail = "体感偏热，注意通风、补水与防晒。"
        }

        var extra = detail
        if current.precipitationProbability >= 60 {
            extra += " 降水概率较高，出门记得带伞。"
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
        case 1.85..<7.38: phase = ("蛾眉月", "moon.haze.fill")
        case 7.38..<9.23: phase = ("上弦月", "moon.phase.first.quarter")
        case 9.23..<14.77: phase = ("盈凸月", "moon.circle.fill")
        case 14.77..<16.62: phase = ("满月", "moon.fill")
        case 16.62..<22.15: phase = ("亏凸月", "moon.circle.fill")
        case 22.15..<24.00: phase = ("下弦月", "moon.phase.last.quarter")
        case 24.00..<28.00: phase = ("残月", "moon.haze.fill")
        default: phase = ("新月", "moon.zzz.fill")
        }
        let next = nextMajorPhase(after: age, date: date)
        return MoonPhaseInfo(title: phase.title, symbolName: phase.symbolName, illumination: illumination, age: age, nextPhaseTitle: next.title, nextPhaseDate: next.date)
    }

    private static func nextMajorPhase(after age: Double, date: Date) -> (title: String, date: Date) {
        let phases: [(age: Double, title: String)] = [
            (0, "新月"),
            (7.38, "上弦月"),
            (14.77, "满月"),
            (22.15, "下弦月")
        ]
        let next = phases
            .map { phase in
                let delta = phase.age >= age ? phase.age - age : synodicMonth - age + phase.age
                return (phase.title, delta)
            }
            .min(by: { $0.1 < $1.1 }) ?? ("新月", synodicMonth - age)
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
        var headline = "今天以\(condition)为主，最高气温\(formattedHigh)\(unitSymbol)。"
        if maxRain >= 60 {
            headline += "\(rainHours.first.map { formatHour($0.time, timezone: snapshot.timezoneIdentifier) } ?? "稍后")前后降水概率升高。"
        }

        var details = "当前\(formattedCurrent)\(unitSymbol)，体感\(formattedFeelsLike)\(unitSymbol)；"
        if let airQuality = snapshot.airQuality {
            details += "空气质量\(airQuality.level)，AQI \(Int(airQuality.europeanAQI.rounded()))。"
        } else {
            details += "空气质量数据暂不可用。"
        }

        var insights = [String]()
        if current.temperature - current.low >= 6 {
            let displayRange = unit == .celsius ? range : range * 9 / 5
            let formattedRange = displayRange.formattedNumber(decimals: 0)
            insights.append("昼夜温差约\(formattedRange)\(unitSymbol)，早晚体感更凉。")
        }
        if maxRain >= 60 {
            insights.append("未来24小时最大降水概率约\(Int(maxRain.rounded()))%，建议随身携带雨具。")
        }
        if maxGust >= 30 {
            insights.append("阵风可能达到\(Int(maxGust.rounded())) km/h，沿海区域注意风力变化。")
        }
        if current.uvIndex >= 6 {
            insights.append("午后紫外线较强，长时间户外活动建议做好防晒。")
        }
        let futureAverageHigh = snapshot.daily.map(\.high).average
        if let futureAverageHigh, current.high - futureAverageHigh >= 2 {
            let delta = unit == .celsius ? current.high - futureAverageHigh : (current.high - futureAverageHigh) * 9 / 5
            insights.append("今天最高气温高于未来10天平均约\(Int(delta.rounded()))\(unitSymbol)。")
        } else if let futureAverageHigh, futureAverageHigh - current.high >= 2 {
            let delta = unit == .celsius ? futureAverageHigh - current.high : (futureAverageHigh - current.high) * 9 / 5
            insights.append("今天最高气温低于未来10天平均约\(Int(delta.rounded()))\(unitSymbol)。")
        }
        if insights.isEmpty {
            insights.append("天气变化平稳，适合按照原计划安排活动。")
        }

        return WeatherSummary(headline: headline, detail: details, insights: insights, hasAlert: !snapshot.alerts.isEmpty)
    }

    private static func formatHour(_ date: Date, timezone: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: timezone)
        formatter.dateFormat = "HH时"
        return formatter.string(from: date)
    }
}

private extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
