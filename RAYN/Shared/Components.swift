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
        return min(max(canvasScale * viewingDistance.scale, 0.92), 1.28)
    }
}

/// Night dimming is an intentional whole-screen overlay because tvOS exposes
/// no app-controlled backlight API. The value is kept small enough to preserve
/// text contrast while taking the edge off a bright broadcast at night.
enum RAYNNightDimming {
    static let maxOpacity = 0.32

    static func opacity(isDay: Bool, enabled: Bool) -> Double {
        enabled && !isDay ? maxOpacity : 0
    }
}

/// Shared visual roles for the broadcast interface. Page identity receives
/// its own prominent space; weather status and other single-purpose
/// information are centered; leading alignment is otherwise reserved for
/// prose, lists, and controls where a stable reading edge is useful.
enum RAYNDesign {
    enum Typography {
        static let locationTitle: CGFloat = 82
        static let pageEyebrow: CGFloat = 19
        static let pageTitle: CGFloat = 48
        static let pageDetail: CGFloat = 25
        static let metricTitle: CGFloat = 20
        static let metricValue: CGFloat = 29
    }

    enum Radius {
        static let card: CGFloat = 24
        static let heroCard: CGFloat = 28
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = RAYNDesign.Radius.card
    var tint: Color = .white
    /// A zero default avoids a large offscreen blur for every 4K card. A
    /// caller can opt in for a genuinely detached surface such as a modal.
    var shadowRadius: CGFloat = 0
    var shadowOffset: CGFloat = 0
    @ViewBuilder var content: Content
    @Environment(\.raynLayoutScale) private var layoutScale
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius * layoutScale, style: .continuous)
        content
            .padding(22 * layoutScale)
            .background {
                if reduceTransparency {
                    shape.fill(Color(hex: 0x142C45).opacity(0.98))
                } else {
                    // Backdrop materials sample and blur the full 4K scene.
                    // A tinted static fill preserves the glass hierarchy while
                    // keeping focus transitions on A12 out of an offscreen
                    // material pass.
                    shape.fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.16),
                                Color.white.opacity(0.055)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
            .overlay {
                shape.stroke(
                    tint.opacity(colorSchemeContrast == .increased ? 0.28 : 0.12),
                    lineWidth: colorSchemeContrast == .increased ? 2 : 1
                )
            }
            .modifier(
                ConditionalCardShadow(
                    color: .black.opacity(reduceTransparency ? 0.24 : 0.14),
                    radius: shadowRadius * layoutScale,
                    offset: shadowOffset * layoutScale
                )
            )
    }
}

private struct ConditionalCardShadow: ViewModifier {
    let color: Color
    let radius: CGFloat
    let offset: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if radius > 0 {
            content.shadow(color: color, radius: radius, y: offset)
        } else {
            content
        }
    }
}

struct PageHeader: View {
    let eyebrow: String
    let title: String
    var detail: String?
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .center, spacing: 6 * layoutScale) {
                Text(L10n.string(eyebrow).uppercased(with: .autoupdatingCurrent))
                    .font(.system(size: RAYNDesign.Typography.pageEyebrow * layoutScale, weight: .bold, design: .rounded))
                    .tracking(2.2)
                    .foregroundStyle(.white.opacity(0.68))
                Text(L10n.string(title))
                    .font(.system(size: RAYNDesign.Typography.pageTitle * layoutScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 880 * layoutScale)
            .frame(maxWidth: .infinity, alignment: .center)

            if let detail {
                Text(L10n.string(detail))
                    .font(.system(size: RAYNDesign.Typography.pageDetail * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 520 * layoutScale, alignment: .trailing)
                    .padding(.bottom, 6 * layoutScale)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Displays the provider/model timestamp separately from the time this app
/// received the response. This keeps a stale source observation from looking
/// like a fresh network response while avoiding provider names in the UI.
struct DataFreshnessLabel: View {
    let updatedAt: Date
    let fetchedAt: Date?
    let timezoneIdentifier: String
    var alignment: HorizontalAlignment = .trailing
    var fontSize: CGFloat = 18

    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        VStack(alignment: alignment, spacing: 3 * layoutScale) {
            Text("Updated \(updatedAt.formatted(.time, timezoneIdentifier: timezoneIdentifier))")
            if let fetchedAt {
                Text("Checked \(fetchedAt.formatted(.time, timezoneIdentifier: timezoneIdentifier))")
                    .foregroundStyle(.white.opacity(0.44))
            }
        }
        .font(.system(size: fontSize * layoutScale, weight: .medium, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.white.opacity(0.62))
        .lineLimit(1)
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
        VStack(alignment: .center, spacing: 6 * layoutScale) {
            HStack(spacing: 9 * layoutScale) {
                Image(systemName: symbol)
                    .font(.system(size: 23 * layoutScale, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 30 * layoutScale)
                Text(L10n.string(title))
                    .font(.system(size: RAYNDesign.Typography.metricTitle * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Text(value)
                .font(.system(size: RAYNDesign.Typography.metricValue * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
    }
}

struct FocusButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isFocused ? 1.018 : 1)
            .brightness(isFocused ? 0.03 : 0)
            // Native tvOS focus and glass effects already provide the halo.
            // A second animated shadow forces an offscreen render on every
            // focus step, which is disproportionately expensive on A12.
            .animation(.easeOut(duration: 0.10), value: isFocused)
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

struct TickerClock: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        TimelineView(.periodic(from: Calendar.current.nextDate(after: .now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? .now, by: 60)) { context in
            Text(timeString(context.date))
                .font(.system(size: 24 * layoutScale, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
    }

    private func timeString(_ date: Date) -> String {
        WeatherDateFormatterCache.string(
            from: date,
            template: appState.settings.clockFormat == .twentyFourHour ? "Hm" : "hm",
            timezone: appState.localTimeZone
        )
    }
}

struct TickerWeatherSummary: View {
    @EnvironmentObject private var appState: AppState
    let snapshot: WeatherSnapshot
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        HStack(spacing: 12 * layoutScale) {
            Image(systemName: WeatherCodeMapper.symbol(
                for: snapshot.current.weatherCode,
                isDay: snapshot.current.isDay
            ))
                .font(.system(size: 25 * layoutScale, weight: .semibold))
                .symbolRenderingMode(.hierarchical)

            Text(snapshot.current.temperature.formattedTemperature(unit: appState.settings.temperatureUnit) + (appState.settings.temperatureUnit == .celsius ? "℃" : "℉"))
                .monospacedDigit()

            Text(WeatherCodeMapper.description(
                for: snapshot.current.weatherCode,
                isDay: snapshot.current.isDay,
                visibility: snapshot.current.visibility
            ))
                .foregroundStyle(.white.opacity(0.68))
        }
        .font(.system(size: 23 * layoutScale, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .accessibilityElement(children: .combine)
    }
}

struct LiveIndicator: View {
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        HStack(spacing: 10 * layoutScale) {
            Circle()
                .fill(.green)
                .frame(width: 11 * layoutScale, height: 11 * layoutScale)
            Text("Live")
                .font(.system(size: 19 * layoutScale, weight: .black, design: .rounded))
                .tracking(1.1 * layoutScale)
        }
        .foregroundStyle(.white.opacity(0.85))
    }
}
