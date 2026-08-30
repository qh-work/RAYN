import Foundation

extension Double {
    func formattedTemperature(unit: TemperatureUnit, decimals: Int = 0) -> String {
        let converted = unit == .celsius ? self : (self * 9 / 5) + 32
        return converted.formatted(.number.precision(.fractionLength(decimals)))
    }

    func formattedNumber(decimals: Int = 0) -> String {
        formatted(.number.precision(.fractionLength(decimals)))
    }

    func formattedSpeed(system: MeasurementSystem) -> String {
        let value = system == .metric ? self : self * 0.621371
        return "\(value.formattedNumber()) \(system == .metric ? "km/h" : "mph")"
    }

    func formattedDistance(system: MeasurementSystem, decimals: Int = 1) -> String {
        let value = system == .metric ? self : self * 0.621371
        return "\(value.formattedNumber(decimals: decimals)) \(system == .metric ? "km" : "mi")"
    }
}

enum WeatherDateTemplate {
    case time
    case monthDayTime
    case monthDay
    case weekday
    case fullDate
    case shortWeekday
    case hour

    var formatTemplate: String {
        switch self {
        case .time: return "Hm"
        case .monthDayTime: return "MdHm"
        case .monthDay: return "Md"
        case .weekday: return "EEEE"
        case .fullDate: return "yyyyMdEEEE"
        case .shortWeekday: return "EEE"
        case .hour: return "j"
        }
    }
}

extension Date {
    func formatted(
        _ template: WeatherDateTemplate,
        timezoneIdentifier: String,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        WeatherDateFormatterCache.string(
            from: self,
            template: template.formatTemplate,
            timezone: TimeZone(identifier: timezoneIdentifier) ?? .autoupdatingCurrent,
            locale: locale
        )
    }
}

/// Reuses the small, stable set of localized date formatters used by the UI.
/// DateFormatter is not thread-safe, so lookup and formatting remain behind
/// one lock instead of returning shared formatter instances to callers.
enum WeatherDateFormatterCache {
    private struct Key: Hashable {
        let localeIdentifier: String
        let timezoneIdentifier: String
        let format: String
        let usesLocalizedTemplate: Bool
    }

    private static let lock = NSLock()
    private static var formatters = [Key: DateFormatter]()

    static func string(
        from date: Date,
        template: String,
        timezone: TimeZone,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        withFormatter(
            format: template,
            timezone: timezone,
            locale: locale,
            usesLocalizedTemplate: true
        ) { formatter in
            formatter.string(from: date)
        }
    }

    static func date(
        from value: String,
        format: String,
        timezone: TimeZone,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> Date? {
        withFormatter(
            format: format,
            timezone: timezone,
            locale: locale,
            usesLocalizedTemplate: false
        ) { formatter in
            formatter.date(from: value)
        }
    }

    private static func withFormatter<Result>(
        format: String,
        timezone: TimeZone,
        locale: Locale,
        usesLocalizedTemplate: Bool,
        operation: (DateFormatter) -> Result
    ) -> Result {
        let key = Key(
            localeIdentifier: locale.identifier,
            timezoneIdentifier: timezone.identifier,
            format: format,
            usesLocalizedTemplate: usesLocalizedTemplate
        )

        lock.lock()
        defer { lock.unlock() }

        let formatter: DateFormatter
        if let cached = formatters[key] {
            formatter = cached
        } else {
            let created = DateFormatter()
            created.locale = locale
            created.timeZone = timezone
            if usesLocalizedTemplate {
                created.setLocalizedDateFormatFromTemplate(format)
            } else {
                created.dateFormat = format
            }
            formatters[key] = created
            formatter = created
        }
        return operation(formatter)
    }
}
