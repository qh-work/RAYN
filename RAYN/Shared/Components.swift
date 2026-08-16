import SwiftUI

private struct RAYNLayoutScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var raynLayoutScale: CGFloat {
        get { self[RAYNLayoutScaleKey.self] }
        set { self[RAYNLayoutScaleKey.self] = newValue }
    }
}

enum RAYNLayout {
    static func scale(for size: CGSize, viewingDistance: ViewingDistance) -> CGFloat {
        let widthScale = size.width / 1920
        let heightScale = size.height / 1080
        let canvasScale = min(max(min(widthScale, heightScale), 0.92), 1.08)
        return min(max(canvasScale * viewingDistance.scale, 0.86), 1.22)
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var tint: Color = .white
    var shadowRadius: CGFloat = 12
    var shadowOffset: CGFloat = 5
    @ViewBuilder var content: Content
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        content
            .padding(22 * layoutScale)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius * layoutScale, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius * layoutScale, style: .continuous)
                    .stroke(tint.opacity(0.10), lineWidth: 1)
            }
            .shadow(
                color: .black.opacity(0.14),
                radius: shadowRadius * layoutScale,
                y: shadowOffset * layoutScale
            )
    }
}

struct PageHeader: View {
    let eyebrow: String
    let title: String
    var detail: String?
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        HStack(alignment: .bottom, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.string(eyebrow).uppercased(with: .autoupdatingCurrent))
                    .font(.system(size: 17 * layoutScale, weight: .bold, design: .rounded))
                    .tracking(2.2)
                    .foregroundStyle(.white.opacity(0.68))
                Text(L10n.string(title))
                    .font(.system(size: 48 * layoutScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            if let detail {
                Text(L10n.string(detail))
                    .font(.system(size: 23 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.bottom, 6)
            }
            Spacer()
        }
    }
}

struct WeatherSymbol: View {
    let code: Int
    let isDay: Bool
    var size: CGFloat = 38
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        Image(systemName: WeatherCodeMapper.symbol(for: code, isDay: isDay))
            .font(.system(size: size * layoutScale, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.white)
            .frame(width: (size + 18) * layoutScale, height: (size + 18) * layoutScale)
    }
}

struct MetricTile: View {
    let symbol: String
    let title: String
    let value: String
    var accent: Color = .white
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        HStack(spacing: 14 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: 23 * layoutScale, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 30 * layoutScale)
            VStack(alignment: .leading, spacing: 3 * layoutScale) {
                Text(L10n.string(title))
                    .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                Text(value)
                    .font(.system(size: 27 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
    }
}

struct FocusButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isFocused ? 1.04 : 1)
            .brightness(isFocused ? 0.08 : 0)
            .shadow(color: .white.opacity(isFocused ? 0.24 : 0), radius: 18)
            .animation(.easeOut(duration: 0.18), value: isFocused)
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private struct FocusAdaptiveGlassForeground: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            // Native tvOS glass becomes almost white while focused. A dark
            // ink color keeps both SF Symbols and text readable on that
            // highlight, while unfocused controls remain white on the sky.
            .foregroundStyle(isFocused ? Color(hex: 0x082A3D) : .white)
            // Read focus from the control itself. The surrounding environment
            // does not reliably publish a glass button's focus state to an
            // exterior modifier on tvOS.
            .focused($isFocused)
            .animation(.easeOut(duration: 0.12), value: isFocused)
    }
}

extension View {
    func focusAdaptiveGlassForeground() -> some View {
        modifier(FocusAdaptiveGlassForeground())
    }
}

struct TemperatureText: View {
    let value: Double
    let unit: TemperatureUnit
    var fontSize: CGFloat = 190
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        HStack(alignment: .top, spacing: 5 * layoutScale) {
            Text(value.formattedTemperature(unit: unit, decimals: 0))
                .font(.system(size: fontSize * layoutScale, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(unit == .celsius ? "℃" : "℉")
                .font(.system(size: fontSize * 0.28 * layoutScale, weight: .light, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .padding(.top, fontSize * 0.17 * layoutScale)
        }
    }
}

struct ForecastProgressBar: View {
    let value: Double
    var maximum: Double = 100
    var color: Color = .cyan

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.12))
                Capsule()
                    .fill(color.gradient)
                    .frame(width: geometry.size.width * min(max(value / maximum, 0), 1))
            }
        }
        .frame(height: 9)
    }
}

struct TickerText: View {
    @EnvironmentObject private var appState: AppState
    let snapshot: WeatherSnapshot
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 12) {
                Text(timeString(context.date))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("·")
                    .foregroundStyle(.white.opacity(0.38))
                Text(snapshot.current.temperature.formattedTemperature(unit: appState.settings.temperatureUnit) + (appState.settings.temperatureUnit == .celsius ? "℃" : "℉"))
                    .foregroundStyle(.white)
                Text(WeatherCodeMapper.description(for: snapshot.current.weatherCode, isDay: snapshot.current.isDay, visibility: snapshot.current.visibility))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .font(.system(size: 20 * layoutScale, weight: .semibold, design: .rounded))
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = appState.localTimeZone
        formatter.setLocalizedDateFormatFromTemplate(
            appState.settings.clockFormat == .twentyFourHour ? "Hm" : "hm"
        )
        return formatter.string(from: date)
    }
}

struct LiveIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(.green).frame(width: 9, height: 9)
            Text("Live")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .tracking(1)
        }
        .foregroundStyle(.white.opacity(0.85))
    }
}

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
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(identifier: timezoneIdentifier)
        formatter.setLocalizedDateFormatFromTemplate(template.formatTemplate)
        return formatter.string(from: self)
    }
}
