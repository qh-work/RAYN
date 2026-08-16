import Foundation

enum L10n {
    static let supportedLanguageCodes = [
        "en", "fr", "de", "es", "it", "ja", "ko", "zh-Hans", "zh-Hant",
    ]

    static func string(_ key: String, bundle: Bundle = .main) -> String {
        bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    static func format(
        _ key: String,
        _ arguments: CVarArg...,
        bundle: Bundle = .main,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let template = string(key, bundle: bundle)
        return String(format: template, locale: locale, arguments: arguments)
    }

    static func bundle(for languageCode: String, in bundle: Bundle = .main) -> Bundle? {
        let candidates: [String]
        switch languageCode.lowercased() {
        case let code where code.contains("hant") || code.hasPrefix("zh-tw") || code.hasPrefix("zh-hk") || code.hasPrefix("zh-mo"):
            candidates = ["zh-Hant", "zh-Hans", "zh"]
        case let code where code.hasPrefix("zh"):
            candidates = ["zh-Hans", "zh-Hant", "zh"]
        default:
            candidates = [languageCode]
        }
        for candidate in candidates {
            if let path = bundle.path(forResource: candidate, ofType: "lproj"),
               let localizedBundle = Bundle(path: path) {
                return localizedBundle
            }
        }
        return nil
    }
}
