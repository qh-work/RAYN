import Foundation

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
