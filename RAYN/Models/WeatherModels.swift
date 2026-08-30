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
        case .near: return 0.98
        case .standard: return 1.10
        case .far: return 1.22
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
    /// User-defined navigation order. New scenes are appended automatically
    /// so settings saved by an older release remain forward-compatible.
    var sceneOrder: [BroadcastScene] = BroadcastScene.allCases
    var dynamicIntensity: DynamicIntensity = .medium
    var viewingDistance: ViewingDistance = .standard
    var lightningEnabled = true
    var nightDimMode = false
    var keepScreenAwake = false
    var reduceMotion = false

    init() {}

    var orderedScenes: [BroadcastScene] {
        Self.sanitizedSceneOrder(sceneOrder)
    }

    mutating func normalizeSceneOrder() {
        sceneOrder = orderedScenes
    }

    static func sanitizedSceneOrder(_ proposedOrder: [BroadcastScene]) -> [BroadcastScene] {
        var seen = Set<BroadcastScene>()
        let validOrder = proposedOrder.filter { seen.insert($0).inserted }
        return validOrder + BroadcastScene.allCases.filter { !seen.contains($0) }
    }

    private enum CodingKeys: String, CodingKey {
        case useCurrentLocation
        case temperatureUnit
        case measurementSystem
        case clockFormat
        case automaticRotation
        case rotationSeconds
        case hiddenScenes
        case sceneOrder
        case dynamicIntensity
        case viewingDistance
        case lightningEnabled
        case nightDimMode
        case keepScreenAwake
        case reduceMotion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        useCurrentLocation = try container.decodeIfPresent(Bool.self, forKey: .useCurrentLocation) ?? true
        temperatureUnit = try container.decodeIfPresent(TemperatureUnit.self, forKey: .temperatureUnit) ?? .celsius
        measurementSystem = try container.decodeIfPresent(MeasurementSystem.self, forKey: .measurementSystem) ?? .metric
        clockFormat = try container.decodeIfPresent(ClockFormat.self, forKey: .clockFormat) ?? .twentyFourHour
        automaticRotation = try container.decodeIfPresent(Bool.self, forKey: .automaticRotation) ?? false
        rotationSeconds = try container.decodeIfPresent(Double.self, forKey: .rotationSeconds) ?? 15
        hiddenScenes = try container.decodeIfPresent(Set<BroadcastScene>.self, forKey: .hiddenScenes) ?? []
        sceneOrder = Self.sanitizedSceneOrder(
            try container.decodeIfPresent([BroadcastScene].self, forKey: .sceneOrder) ?? []
        )
        dynamicIntensity = try container.decodeIfPresent(DynamicIntensity.self, forKey: .dynamicIntensity) ?? .medium
        viewingDistance = try container.decodeIfPresent(ViewingDistance.self, forKey: .viewingDistance) ?? .standard
        lightningEnabled = try container.decodeIfPresent(Bool.self, forKey: .lightningEnabled) ?? true
        nightDimMode = try container.decodeIfPresent(Bool.self, forKey: .nightDimMode) ?? false
        keepScreenAwake = try container.decodeIfPresent(Bool.self, forKey: .keepScreenAwake) ?? false
        reduceMotion = try container.decodeIfPresent(Bool.self, forKey: .reduceMotion) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(useCurrentLocation, forKey: .useCurrentLocation)
        try container.encode(temperatureUnit, forKey: .temperatureUnit)
        try container.encode(measurementSystem, forKey: .measurementSystem)
        try container.encode(clockFormat, forKey: .clockFormat)
        try container.encode(automaticRotation, forKey: .automaticRotation)
        try container.encode(rotationSeconds, forKey: .rotationSeconds)
        try container.encode(hiddenScenes, forKey: .hiddenScenes)
        try container.encode(orderedScenes, forKey: .sceneOrder)
        try container.encode(dynamicIntensity, forKey: .dynamicIntensity)
        try container.encode(viewingDistance, forKey: .viewingDistance)
        try container.encode(lightningEnabled, forKey: .lightningEnabled)
        try container.encode(nightDimMode, forKey: .nightDimMode)
        try container.encode(keepScreenAwake, forKey: .keepScreenAwake)
        try container.encode(reduceMotion, forKey: .reduceMotion)
    }
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
    var moonrise: Date? = nil
    var moonset: Date? = nil
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
    /// Time at which the provider response was received by the app.
    var fetchedAt: Date? = nil
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
    var tileDescriptor: RadarTileDescriptor? = nil
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
        case tileDescriptor
        case source
        case isForecast
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        tilePath = try container.decodeIfPresent(String.self, forKey: .tilePath)
        tileURLTemplate = try container.decodeIfPresent(String.self, forKey: .tileURLTemplate)
        tileDescriptor = try container.decodeIfPresent(RadarTileDescriptor.self, forKey: .tileDescriptor)
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
    /// Time at which the provider response was received by the app.
    var fetchedAt: Date? = nil
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
    var providerIdentifier: String? = nil
    var severity: String? = nil
    var body: String? = nil

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

/// A calculated solar position. The calculation uses the selected location's
/// coordinates and the current time; it is not presented as a provider
/// observation. Sunrise and sunset remain provider-backed fields.
struct SolarPositionInfo: Equatable {
    var elevation: Double
    var azimuth: Double
    var morningGoldenHourStart: Date?
    var morningGoldenHourEnd: Date?
    var eveningGoldenHourStart: Date?
    var eveningGoldenHourEnd: Date?
}

enum SolarPositionCalculator {
    private static let degreesToRadians = Double.pi / 180
    private static let radiansToDegrees = 180 / Double.pi

    static func info(at date: Date, location: SavedLocation) -> SolarPositionInfo {
        let position = solarPosition(at: date, location: location)
        let goldenHours = goldenHours(for: date, location: location)
        return SolarPositionInfo(
            elevation: position.elevation,
            azimuth: position.azimuth,
            morningGoldenHourStart: goldenHours.morningStart,
            morningGoldenHourEnd: goldenHours.morningEnd,
            eveningGoldenHourStart: goldenHours.eveningStart,
            eveningGoldenHourEnd: goldenHours.eveningEnd
        )
    }

    private static func solarPosition(at date: Date, location: SavedLocation) -> (elevation: Double, azimuth: Double) {
        let julianDate = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let daysSinceJ2000 = julianDate - 2_451_545.0
        let meanLongitude = normalizedDegrees(280.460 + 0.9856474 * daysSinceJ2000)
        let meanAnomaly = normalizedDegrees(357.528 + 0.9856003 * daysSinceJ2000) * degreesToRadians
        let eclipticLongitude = normalizedDegrees(
            meanLongitude + 1.915 * sin(meanAnomaly) + 0.020 * sin(2 * meanAnomaly)
        ) * degreesToRadians
        let obliquity = (23.439 - 0.0000004 * daysSinceJ2000) * degreesToRadians

        let rightAscension = atan2(cos(obliquity) * sin(eclipticLongitude), cos(eclipticLongitude)) * radiansToDegrees
        let declination = asin(sin(obliquity) * sin(eclipticLongitude)) * radiansToDegrees
        let siderealHours = normalizedHours(18.697374558 + 24.06570982441908 * daysSinceJ2000)
        let localSiderealDegrees = normalizedDegrees(siderealHours * 15 + location.longitude)
        // `rightAscension` is already expressed in degrees. Multiplying it by
        // 15 a second time moves the Sun to the wrong part of the sky.
        let hourAngle = normalizedDegrees(localSiderealDegrees - rightAscension) * degreesToRadians
        let latitude = location.latitude * degreesToRadians
        let declinationRadians = declination * degreesToRadians

        let elevation = asin(
            sin(latitude) * sin(declinationRadians)
                + cos(latitude) * cos(declinationRadians) * cos(hourAngle)
        ) * radiansToDegrees
        let azimuth = normalizedDegrees(
            atan2(
                sin(hourAngle),
                cos(hourAngle) * sin(latitude) - tan(declinationRadians) * cos(latitude)
            ) * radiansToDegrees + 180
        )
        return (elevation, azimuth)
    }

    private static func goldenHours(for date: Date, location: SavedLocation) -> (
        morningStart: Date?, morningEnd: Date?, eveningStart: Date?, eveningEnd: Date?
    ) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: location.timezoneIdentifier) ?? .current
        let startOfDay = calendar.startOfDay(for: date)
        let step: TimeInterval = 300
        var previousDate = startOfDay
        var previousElevation = solarPosition(at: previousDate, location: location).elevation
        var morningStart: Date?
        var morningEnd: Date?
        var eveningStart: Date?
        var eveningEnd: Date?

        for stepIndex in 1...288 {
            let currentDate = startOfDay.addingTimeInterval(Double(stepIndex) * step)
            let currentElevation = solarPosition(at: currentDate, location: location).elevation

            if morningStart == nil, previousElevation < -4, currentElevation >= -4 {
                morningStart = crossingDate(
                    previousDate: previousDate,
                    previousElevation: previousElevation,
                    currentDate: currentDate,
                    currentElevation: currentElevation,
                    threshold: -4
                )
            }
            if morningEnd == nil, previousElevation < 6, currentElevation >= 6 {
                morningEnd = crossingDate(
                    previousDate: previousDate,
                    previousElevation: previousElevation,
                    currentDate: currentDate,
                    currentElevation: currentElevation,
                    threshold: 6
                )
            }
            if eveningStart == nil, previousElevation >= 6, currentElevation < 6 {
                eveningStart = crossingDate(
                    previousDate: previousDate,
                    previousElevation: previousElevation,
                    currentDate: currentDate,
                    currentElevation: currentElevation,
                    threshold: 6
                )
            }
            if eveningEnd == nil, previousElevation >= -4, currentElevation < -4 {
                eveningEnd = crossingDate(
                    previousDate: previousDate,
                    previousElevation: previousElevation,
                    currentDate: currentDate,
                    currentElevation: currentElevation,
                    threshold: -4
                )
            }

            previousDate = currentDate
            previousElevation = currentElevation
        }
        return (morningStart, morningEnd, eveningStart, eveningEnd)
    }

    private static func crossingDate(
        previousDate: Date,
        previousElevation: Double,
        currentDate: Date,
        currentElevation: Double,
        threshold: Double
    ) -> Date {
        let span = currentElevation - previousElevation
        guard abs(span) > 0.0001 else { return currentDate }
        let fraction = min(max((threshold - previousElevation) / span, 0), 1)
        return previousDate.addingTimeInterval(currentDate.timeIntervalSince(previousDate) * fraction)
    }

    private static func normalizedDegrees(_ value: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: 360)
        return result >= 0 ? result : result + 360
    }

    private static func normalizedHours(_ value: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: 24)
        return result >= 0 ? result : result + 24
    }
}

enum WeatherAdvisoryLevel: String, Codable, Equatable {
    case warning
    case caution
}

struct WeatherAdvisory: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var detail: String
    var symbolName: String
    var level: WeatherAdvisoryLevel
    var isOfficial: Bool
}

enum WeatherAdvisoryBuilder {
    static func make(from snapshot: WeatherSnapshot, at now: Date = Date()) -> [WeatherAdvisory] {
        var advisories = snapshot.alerts.filter { $0.startDate <= now && $0.endDate > now }.map { alert in
            WeatherAdvisory(
                id: "official-\(alert.id.uuidString)",
                title: alert.title,
                detail: String(localized: "Official Alert"),
                symbolName: "exclamationmark.triangle.fill",
                level: .warning,
                isOfficial: true
            )
        }

        let current = snapshot.current
        let condition = WeatherCodeMapper.description(
            for: current.weatherCode,
            isDay: current.isDay,
            visibility: current.visibility
        )
        switch current.weatherCode {
        case 95:
            advisories.append(
                WeatherAdvisory(
                    id: "thunderstorm",
                    title: condition,
                    detail: String(localized: "Thunderstorms are present in the current forecast. Seek shelter and avoid exposed areas."),
                    symbolName: "cloud.bolt.rain.fill",
                    level: .warning,
                    isOfficial: false
                )
            )
        case 96, 99:
            advisories.append(
                WeatherAdvisory(
                    id: "hail",
                    title: condition,
                    detail: String(localized: "Thunderstorms or hail are present in the current forecast. Seek shelter and avoid exposed areas."),
                    symbolName: "cloud.bolt.rain.fill",
                    level: .warning,
                    isOfficial: false
                )
            )
        case 56, 57, 66, 67:
            advisories.append(
                WeatherAdvisory(
                    id: "freezing-precipitation",
                    title: condition,
                    detail: String(localized: "Freezing precipitation may make roads and walkways slippery."),
                    symbolName: "thermometer.snowflake",
                    level: .warning,
                    isOfficial: false
                )
            )
        case 71, 73, 75, 77, 85, 86:
            advisories.append(
                WeatherAdvisory(
                    id: "snow",
                    title: condition,
                    detail: String(localized: "Snowfall may reduce visibility and travel safety."),
                    symbolName: "cloud.snow.fill",
                    level: .caution,
                    isOfficial: false
                )
            )
        default:
            break
        }

        let maximumGust = max(
            current.windGust,
            snapshot.hourly.compactMap(\.windGust).max() ?? current.windGust
        )
        if maximumGust >= 60 {
            advisories.append(
                WeatherAdvisory(
                    id: "strong-wind",
                    title: String(localized: "Wind Gusts"),
                    detail: String(localized: "Wind gusts may reach \(Int(maximumGust.rounded())) km/h. Coastal areas should monitor changing winds."),
                    symbolName: "wind",
                    level: .caution,
                    isOfficial: false
                )
            )
        }

        let maximumRainChance = max(
            current.precipitationProbability,
            snapshot.hourly.prefix(24).map(\.precipitationProbability).max() ?? current.precipitationProbability
        )
        if maximumRainChance >= 80 {
            advisories.append(
                WeatherAdvisory(
                    id: "heavy-rain-chance",
                    title: String(localized: "Rain Chance"),
                    detail: String(localized: "The highest rain chance in the next 24 hours is about \(Int(maximumRainChance.rounded()))%. Carry an umbrella."),
                    symbolName: "cloud.rain.fill",
                    level: .caution,
                    isOfficial: false
                )
            )
        }

        if current.visibility < 1 {
            advisories.append(
                WeatherAdvisory(
                    id: "low-visibility",
                    title: String(localized: "Haze / Low Visibility"),
                    detail: String(localized: "Visibility is reduced to \(current.visibility.formattedNumber(decimals: 1)) km. Use extra caution when traveling."),
                    symbolName: "eye.slash.fill",
                    level: .caution,
                    isOfficial: false
                )
            )
        }

        var unique = [WeatherAdvisory]()
        var seen = Set<String>()
        for advisory in advisories where seen.insert(advisory.id).inserted {
            unique.append(advisory)
        }
        return Array(unique.prefix(3))
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
    var alertAvailability: AlertAvailability? = nil
    var alertsCheckedAt: Date? = nil
    var sourceAttributions: [DataAttribution]? = nil
    var summary: WeatherSummary
    var updatedAt: Date
    /// Time at which this provider response was received by the app.
    /// `updatedAt` remains the source/model time when the provider exposes it.
    var fetchedAt: Date? = nil
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

        return WeatherSummary(
            headline: headline,
            detail: detailParts.joined(separator: " "),
            insights: insights,
            hasAlert: !WeatherAdvisoryBuilder.make(from: snapshot).isEmpty
        )
    }

    private static func formatHour(_ date: Date, timezone: String) -> String {
        WeatherDateFormatterCache.string(
            from: date,
            template: "j",
            timezone: TimeZone(identifier: timezone) ?? .autoupdatingCurrent
        )
    }
}

private extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
