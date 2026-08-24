import SwiftUI

struct DailyForecastScene: View {
    let snapshot: WeatherSnapshot
    @Binding var selectedDayID: Date?
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale
    @State private var lastFocusedDayID: Date?

    var body: some View {
        Group {
            if let dayID = selectedDayID,
               let day = days.first(where: { $0.id == dayID }),
               let index = days.firstIndex(where: { $0.id == dayID }) {
                DailyDetailCard(
                    point: day,
                    ordinal: index,
                    timezone: snapshot.timezoneIdentifier,
                    unit: appState.settings.temperatureUnit,
                    measurementSystem: appState.settings.measurementSystem,
                    onPrevious: index > 0 ? { selectedDayID = days[index - 1].id } : nil,
                    onNext: index + 1 < days.count ? { selectedDayID = days[index + 1].id } : nil,
                    onClose: closeDetail
                )
                .frame(maxWidth: 1480 * layoutScale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 28 * layoutScale)
                .padding(.bottom, 18 * layoutScale)
            } else {
                DailyForecastList(
                    snapshot: snapshot,
                    selectedDayID: $selectedDayID,
                    lastFocusedDayID: $lastFocusedDayID
                )
            }
        }
    }

    private var days: [DailyForecastPoint] {
        Array(snapshot.daily.prefix(10))
    }

    private func closeDetail() {
        guard let selectedDayID else { return }
        lastFocusedDayID = selectedDayID
        self.selectedDayID = nil
    }
}

private struct DailyForecastList: View {
    let snapshot: WeatherSnapshot
    @Binding var selectedDayID: Date?
    @Binding var lastFocusedDayID: Date?
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale
    @Environment(\.resetFocus) private var resetFocus
    @FocusState private var focusedDayID: Date?
    @Namespace private var dayFocusScope

    var body: some View {
        VStack(alignment: .leading, spacing: 20 * layoutScale) {
            PageHeader(
                eyebrow: String(localized: "Extended Forecast"),
                title: String(localized: "10-Day Forecast"),
                detail: String(localized: "Swipe up or down to choose a date · Press Select for details")
            )

            GlassCard(cornerRadius: 28, shadowRadius: 8, shadowOffset: 4) {
                ScrollView(.vertical, showsIndicators: false) {
                    // Ten rows are deliberately kept alive. A LazyVStack can
                    // recycle the next focus target while tvOS is scrolling,
                    // which makes fast Siri Remote movement skip or lose rows.
                    VStack(spacing: 4 * layoutScale) {
                        ForEach(Array(days.enumerated()), id: \.element.id) { index, point in
                            Button {
                                lastFocusedDayID = point.id
                                selectedDayID = point.id
                                appState.revealControls()
                            } label: {
                                DailyForecastRow(
                                    point: point,
                                    ordinal: index,
                                    timezone: snapshot.timezoneIdentifier,
                                    unit: appState.settings.temperatureUnit,
                                    measurementSystem: appState.settings.measurementSystem,
                                    overallLow: overallLow,
                                    overallHigh: overallHigh
                                )
                            }
                            .buttonStyle(DailyForecastRowButtonStyle())
                            .focused($focusedDayID, equals: point.id)
                            .accessibilityLabel("Day \(index + 1), \(point.date.formatted(.monthDay, timezoneIdentifier: snapshot.timezoneIdentifier))")
                            .accessibilityHint("Press Select to view detailed weather")
                            .foregroundStyle(.white)
                            .id(point.id)

                            if index < days.count - 1 {
                                Rectangle()
                                    .fill(.white.opacity(0.10))
                                    .frame(height: 1)
                                    .padding(.horizontal, 22 * layoutScale)
                            }
                        }
                    }
                    // This inset is the focus-effect safe area inside the
                    // outer glass card, so scale and glow never touch an edge.
                    .padding(.horizontal, 14 * layoutScale)
                    .padding(.vertical, 16 * layoutScale)
                }
                .scrollClipDisabled()
                // Preserve a small focus-effect overscan while clipping rows
                // that have actually scrolled beyond the list viewport.
                .clipShape(Rectangle().inset(by: -20 * layoutScale))
            // Keep the live ticker inside the 16:9 safe area when the
            // television typography scale is increased. The list remains
            // fully navigable with the remote, so a shorter viewport is a
            // better tradeoff than shrinking the forecast text.
            .frame(height: 426 * layoutScale)
            }
            .focusSection()

            Text("Swipe up or down through all dates. Press Select to open a forecast, and Menu to return to the list.")
                .font(.system(size: 20 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
        }
        .padding(.top, 30 * layoutScale)
        .padding(.bottom, 16 * layoutScale)
        .focusScope(dayFocusScope)
        .defaultFocus($focusedDayID, preferredListFocusID, priority: .userInitiated)
        .onAppear(perform: restoreListFocus)
    }

    private var days: [DailyForecastPoint] {
        Array(snapshot.daily.prefix(10))
    }

    private var overallLow: Double {
        days.map(\.low).min() ?? 0
    }

    private var overallHigh: Double {
        days.map(\.high).max() ?? 1
    }

    private var preferredListFocusID: Date? {
        let availableIDs = Set(days.map(\.id))
        return lastFocusedDayID.flatMap { availableIDs.contains($0) ? $0 : nil } ?? days.first?.id
    }

    private func restoreListFocus() {
        let target = preferredListFocusID
        Task { @MainActor in
            await Task.yield()
            focusedDayID = target
            resetFocus(in: dayFocusScope)
            await Task.yield()
            focusedDayID = target
        }
    }

}
private struct DailyForecastRow: View {
    let point: DailyForecastPoint
    let ordinal: Int
    let timezone: String
    let unit: TemperatureUnit
    let measurementSystem: MeasurementSystem
    let overallLow: Double
    let overallHigh: Double
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        HStack(spacing: 22 * layoutScale) {
            VStack(alignment: .leading, spacing: 4 * layoutScale) {
                Text(ordinal == 0 ? String(localized: "Today") : point.date.formatted(.weekday, timezoneIdentifier: timezone))
                    .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                Text(point.date.formatted(.monthDay, timezoneIdentifier: timezone))
                    .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .frame(width: 220 * layoutScale, alignment: .leading)

            HStack(spacing: 12 * layoutScale) {
                WeatherSymbol(code: point.weatherCode, isDay: true, size: 38)
                Text(WeatherCodeMapper.description(for: point.weatherCode, isDay: true, visibility: nil))
                    .font(.system(size: 20 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
            }
            .frame(width: 300 * layoutScale, alignment: .leading)

            Label("\(Int(point.precipitationProbability.rounded()))%", systemImage: "drop.fill")
                .font(.system(size: 20 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.cyan)
                .frame(width: 130 * layoutScale, alignment: .leading)

            Label(point.windSpeed.formattedSpeed(system: measurementSystem), systemImage: "wind")
                .font(.system(size: 20 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.mint.opacity(0.88))
                .frame(width: 180 * layoutScale, alignment: .leading)

            Spacer(minLength: 8 * layoutScale)

            Text("\(point.low.formattedTemperature(unit: unit))°")
                .font(.system(size: 22 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .frame(width: 66 * layoutScale, alignment: .trailing)

            DailyTemperatureRange(
                low: point.low,
                high: point.high,
                overallLow: overallLow,
                overallHigh: overallHigh
            )
            .frame(width: 180 * layoutScale)

            Text("\(point.high.formattedTemperature(unit: unit))°")
                .font(.system(size: 25 * layoutScale, weight: .bold, design: .rounded))
                .frame(width: 66 * layoutScale, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 18 * layoutScale, weight: .bold))
                .foregroundStyle(.white.opacity(0.38))
        }
        .padding(.horizontal, 22 * layoutScale)
        .padding(.vertical, 15 * layoutScale)
        .contentShape(RoundedRectangle(cornerRadius: 18 * layoutScale, style: .continuous))
    }
}

private struct DailyTemperatureRange: View {
    let low: Double
    let high: Double
    let overallLow: Double
    let overallHigh: Double

    var body: some View {
        GeometryReader { geometry in
            let span = max(overallHigh - overallLow, 1)
            let leading = max(0, min(1, (low - overallLow) / span)) * geometry.size.width
            let trailing = max(0, min(1, (high - overallLow) / span)) * geometry.size.width

            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.13))
                Capsule()
                    .fill(LinearGradient(colors: [.cyan, .yellow, .orange], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(trailing - leading, 16))
                    .offset(x: leading)
            }
        }
        .frame(height: 8)
    }
}

private struct DailyForecastRowButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.raynLayoutScale) private var layoutScale

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                isFocused ? Color.white.opacity(0.17) : Color.clear,
                in: RoundedRectangle(cornerRadius: 18 * layoutScale, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18 * layoutScale, style: .continuous)
                    .stroke(isFocused ? Color.white.opacity(0.32) : .clear, lineWidth: 1.2 * layoutScale)
            }
            .scaleEffect(isFocused ? 1.018 : 1)
            .brightness(isFocused ? 0.05 : 0)
            .zIndex(isFocused ? 1 : 0)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.14), value: isFocused)
    }
}

private struct DailyDetailCard: View {
    private enum FocusTarget: Hashable {
        case close
        case previous
        case next
    }

    let point: DailyForecastPoint
    let ordinal: Int
    let timezone: String
    let unit: TemperatureUnit
    let measurementSystem: MeasurementSystem
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
    let onClose: () -> Void
    @Environment(\.raynLayoutScale) private var layoutScale
    @Environment(\.resetFocus) private var resetFocus
    @FocusState private var focusedControl: FocusTarget?
    @Namespace private var detailFocusScope

    var body: some View {
        GlassCard(cornerRadius: 34, tint: .cyan) {
            VStack(alignment: .leading, spacing: 24 * layoutScale) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5 * layoutScale) {
                        Text(ordinal == 0 ? String(localized: "Today’s Detailed Forecast") : String(localized: "Day \(ordinal + 1) Details"))
                            .font(.system(size: 31 * layoutScale, weight: .bold, design: .rounded))
                        Text(point.date.formatted(.fullDate, timezoneIdentifier: timezone))
                            .font(.system(size: 19 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    Spacer()
                    Button(action: onClose) {
                        Label("Collapse", systemImage: "chevron.down")
                        .font(.system(size: 20 * layoutScale, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16 * layoutScale)
                            .padding(.vertical, 10 * layoutScale)
                            .foregroundStyle(focusedControl == .close ? Color(hex: 0x082A3D) : .white)
                    }
                    .buttonStyle(.glass)
                    .focused($focusedControl, equals: .close)
                }

                HStack(alignment: .center, spacing: 34 * layoutScale) {
                    WeatherSymbol(code: point.weatherCode, isDay: true, size: 86)
                    VStack(alignment: .leading, spacing: 7 * layoutScale) {
                        Text(WeatherCodeMapper.description(for: point.weatherCode, isDay: true, visibility: nil))
                            .font(.system(size: 34 * layoutScale, weight: .semibold, design: .rounded))
                        Text("High \(point.high.formattedTemperature(unit: unit))°  ·  Low \(point.low.formattedTemperature(unit: unit))°")
                            .font(.system(size: 25 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer()
                    detailMetric(symbol: "drop.fill", title: String(localized: "Rain Chance"), value: "\(Int(point.precipitationProbability.rounded()))%", tint: .cyan)
                    detailMetric(symbol: "wind", title: String(localized: "Max Wind"), value: point.windSpeed.formattedSpeed(system: measurementSystem), tint: .mint)
                    detailMetric(symbol: "sun.max.fill", title: String(localized: "UV Index"), value: point.uvIndex?.formattedNumber(decimals: 1) ?? "--", tint: .yellow)
                }

                HStack(spacing: 42 * layoutScale) {
                    detailFact(symbol: "sunrise.fill", title: String(localized: "Sunrise"), value: point.sunrise?.formatted(.time, timezoneIdentifier: timezone) ?? "--:--", tint: .yellow)
                    detailFact(symbol: "sunset.fill", title: String(localized: "Sunset"), value: point.sunset?.formatted(.time, timezoneIdentifier: timezone) ?? "--:--", tint: .orange)
                    detailFact(symbol: "clock.fill", title: String(localized: "Daylight"), value: daylightText, tint: .cyan)
                    detailFact(symbol: "wind", title: String(localized: "Wind Gusts"), value: point.windGust.formattedSpeed(system: measurementSystem), tint: .orange)
                    detailFact(symbol: "drop", title: String(localized: "Expected Rain"), value: "\(point.precipitation.formattedNumber(decimals: 1)) mm", tint: .blue)
                }
                HStack(spacing: 16 * layoutScale) {
                    if let onPrevious {
                        Button(action: onPrevious) {
                            Label("Previous Day", systemImage: "chevron.left")
                                .frame(minWidth: 150 * layoutScale)
                                .foregroundStyle(focusedControl == .previous ? Color(hex: 0x082A3D) : .white)
                        }
                        .buttonStyle(.glass)
                        .focused($focusedControl, equals: .previous)
                    }
                    if let onNext {
                        Button(action: onNext) {
                            Label("Next Day", systemImage: "chevron.right")
                                .frame(minWidth: 150 * layoutScale)
                                .foregroundStyle(focusedControl == .next ? Color(hex: 0x082A3D) : .white)
                        }
                        .buttonStyle(.glass)
                        .focused($focusedControl, equals: .next)
                    }
                    Spacer()
                    Text("Press Menu to close details")
                        .font(.system(size: 19 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.48))
                }
            }
        }
        .focusScope(detailFocusScope)
        .defaultFocus($focusedControl, .close, priority: .userInitiated)
        .onAppear(perform: restoreDetailFocus)
        .onExitCommand(perform: onClose)
    }

    private func restoreDetailFocus() {
        Task { @MainActor in
            await Task.yield()
            focusedControl = .close
            resetFocus(in: detailFocusScope)
        }
    }

    private var daylightText: String {
        guard let duration = point.daylightDuration else { return "--" }
        let minutes = Int(duration / 60)
        return String(localized: "\(minutes / 60) hr \(minutes % 60) min")
    }

    private func detailMetric(symbol: String, title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: 22 * layoutScale, weight: .semibold))
                .foregroundStyle(tint)
            Text(L10n.string(title))
                .font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 22 * layoutScale, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func detailFact(symbol: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 10 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: 22 * layoutScale, weight: .semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 3 * layoutScale) {
                Text(L10n.string(title))
                    .font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                Text(value)
                    .font(.system(size: 21 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}
