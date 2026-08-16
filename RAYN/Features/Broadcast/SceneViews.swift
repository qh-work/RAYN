import Charts
import MapKit
import SwiftUI

struct CurrentWeatherScene: View {
    let snapshot: WeatherSnapshot
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        let clothing = ClothingAdviceBuilder.make(from: snapshot.current)

        VStack(alignment: .leading, spacing: 26 * layoutScale) {
            PageHeader(
                eyebrow: String(localized: "Current Weather"),
                title: snapshot.location.name,
                detail: snapshot.location.subtitle
            )
            HStack(alignment: .center, spacing: 56 * layoutScale) {
                VStack(alignment: .leading, spacing: 8 * layoutScale) {
                    HStack(alignment: .center, spacing: 20 * layoutScale) {
                        TemperatureText(value: snapshot.current.temperature, unit: appState.settings.temperatureUnit)
                        VStack(alignment: .leading, spacing: 10) {
                            WeatherSymbol(code: snapshot.current.weatherCode, isDay: snapshot.current.isDay, size: 68)
                            Text(WeatherCodeMapper.description(for: snapshot.current.weatherCode, isDay: snapshot.current.isDay, visibility: snapshot.current.visibility))
                                .font(.system(size: 30 * layoutScale, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    Text("Feels like \(snapshot.current.feelsLike.formattedTemperature(unit: appState.settings.temperatureUnit))°  ·  Today \(snapshot.current.low.formattedTemperature(unit: appState.settings.temperatureUnit))° / \(snapshot.current.high.formattedTemperature(unit: appState.settings.temperatureUnit))°")
                        .font(.system(size: 23 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                GlassCard(cornerRadius: 26) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Live Observations")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.84))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 22) {
                            MetricTile(symbol: "humidity.fill", title: String(localized: "Humidity"), value: "\(Int(snapshot.current.relativeHumidity.rounded()))%", accent: .cyan)
                            MetricTile(symbol: "wind", title: String(localized: "Wind Speed"), value: snapshot.current.windSpeed.formattedSpeed(system: appState.settings.measurementSystem), accent: .mint)
                            MetricTile(symbol: "gauge.with.dots.needle.33percent", title: String(localized: "Pressure"), value: "\(Int(snapshot.current.pressure.rounded())) hPa", accent: .yellow)
                            MetricTile(symbol: "eye.fill", title: String(localized: "Visibility"), value: snapshot.current.visibility.formattedDistance(system: appState.settings.measurementSystem), accent: .orange)
                            MetricTile(symbol: "thermometer.medium", title: String(localized: "Dew Point"), value: snapshot.current.dewPoint.formattedTemperature(unit: appState.settings.temperatureUnit) + (appState.settings.temperatureUnit == .celsius ? "℃" : "℉"), accent: .blue)
                            MetricTile(symbol: "cloud.fill", title: String(localized: "Total Cloud Cover"), value: "\(Int(snapshot.current.cloudCover.rounded()))%", accent: .white)
                            MetricTile(symbol: "wind.circle.fill", title: String(localized: "Wind Gusts"), value: snapshot.current.windGust.formattedSpeed(system: appState.settings.measurementSystem), accent: .orange)
                            MetricTile(symbol: "drop.fill", title: String(localized: "Precipitation"), value: "\(snapshot.current.precipitation.formattedNumber(decimals: 1)) mm", accent: .cyan)
                        }
                    }
                }
                .frame(width: 560 * layoutScale)
            }
            Spacer(minLength: 0)
            HStack(spacing: 36 * layoutScale) {
                miniFact(symbol: "sunrise.fill", title: String(localized: "Sunrise"), value: snapshot.current.sunrise?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--", tint: .yellow)
                miniFact(symbol: "sunset.fill", title: String(localized: "Sunset"), value: snapshot.current.sunset?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--", tint: .orange)
                miniFact(symbol: "sun.max.fill", title: String(localized: "UV Index"), value: snapshot.current.uvIndex.formattedNumber(decimals: 1), tint: .yellow)
                miniFact(symbol: "drop.fill", title: String(localized: "Rain Chance"), value: "\(Int(snapshot.current.precipitationProbability.rounded()))%", tint: .cyan)
                miniFact(symbol: "location.north.line.fill", title: String(localized: "Wind Direction"), value: "\(Int(snapshot.current.windDirection.rounded()))°", tint: .mint)
                miniFact(symbol: "cloud.sun.fill", title: String(localized: "Low / Mid / High Cloud"), value: "\(Int(snapshot.current.cloudCoverLow?.rounded() ?? 0))/\(Int(snapshot.current.cloudCoverMid?.rounded() ?? 0))/\(Int(snapshot.current.cloudCoverHigh?.rounded() ?? 0))%", tint: .white)
            }
            ClothingAdviceCard(advice: clothing)
        }
        .padding(.top, 30)
        .padding(.bottom, 16)
    }

    private func miniFact(symbol: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12 * layoutScale) {
            Image(systemName: symbol).font(.system(size: 24 * layoutScale, weight: .semibold)).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 3 * layoutScale) {
                Text(L10n.string(title)).font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.58))
                Text(value).font(.system(size: 24 * layoutScale, weight: .semibold, design: .rounded)).foregroundStyle(.white)
            }
        }
    }
}

private struct ClothingAdviceCard: View {
    let advice: ClothingAdvice
    @Environment(\.raynLayoutScale) private var layoutScale

    private var tint: Color {
        switch advice.index {
        case .cool: return .cyan
        case .comfortable: return .green
        case .light: return .yellow
        case .hot: return .orange
        }
    }

    var body: some View {
        GlassCard(cornerRadius: 24, tint: tint) {
            HStack(spacing: 18 * layoutScale) {
                Image(systemName: advice.index.symbolName)
                    .font(.system(size: 34 * layoutScale, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 54 * layoutScale, height: 54 * layoutScale)
                    .background(tint.opacity(0.16), in: Circle())
                VStack(alignment: .leading, spacing: 5 * layoutScale) {
                    HStack(spacing: 12 * layoutScale) {
                        Text("Clothing Index")
                            .font(.system(size: 21 * layoutScale, weight: .bold, design: .rounded))
                        Text(advice.index.title)
                            .font(.system(size: 17 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(tint)
                    }
                    Text(advice.outfit)
                        .font(.system(size: 26 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(advice.detail)
                        .font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct HourlyForecastScene: View {
    let snapshot: WeatherSnapshot
    @EnvironmentObject private var appState: AppState
    @State private var selectedHourID: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageHeader(
                eyebrow: String(localized: "Forecast"),
                title: String(localized: "Next 24 Hours"),
                detail: String(localized: "Temperature · Feels Like · Rain · Wind")
            )
            GlassCard(cornerRadius: 28) {
                VStack(alignment: .leading, spacing: 14) {
                    Chart {
                        ForEach(Array(snapshot.hourly.prefix(24).enumerated()), id: \.offset) { index, point in
                            PointMark(x: .value(String(localized: "Time"), point.time), y: .value(String(localized: "Temperature"), point.temperature))
                                .foregroundStyle(.white)
                                .symbolSize(index.isMultiple(of: 3) ? 96 : 62)
                                .annotation(position: .top, spacing: 4) {
                                    if index.isMultiple(of: 3) {
                                        Text("\(point.temperature.formattedTemperature(unit: appState.settings.temperatureUnit))° / \(point.apparentTemperature.formattedTemperature(unit: appState.settings.temperatureUnit))°")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.78))
                                    }
                                }
                            PointMark(x: .value(String(localized: "Time"), point.time), y: .value(String(localized: "Feels Like"), point.apparentTemperature))
                                .foregroundStyle(.orange.opacity(0.86))
                                .symbolSize(index.isMultiple(of: 3) ? 78 : 48)
                            BarMark(x: .value(String(localized: "Time"), point.time), y: .value(String(localized: "Rain Chance"), point.precipitationProbability / 3.0))
                                .foregroundStyle(.blue.opacity(0.42))
                                .annotation(position: .top, spacing: 2) {
                                    if index.isMultiple(of: 3) {
                                        Text("\(Int(point.precipitationProbability.rounded()))%")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.blue.opacity(0.92))
                                    }
                                }
                        }
                        if let selected = selectedHour {
                            RuleMark(x: .value(String(localized: "Current Selection"), selected.time))
                                .foregroundStyle(.yellow.opacity(0.80))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(height: 200)

                    WindSpeedChart(
                        points: Array(snapshot.hourly.prefix(24)),
                        system: appState.settings.measurementSystem
                    )

                    HStack(spacing: 22) {
                        ChartLegendItem(title: String(localized: "Temperature"), color: .white, style: .dot)
                        ChartLegendItem(title: String(localized: "Feels Like"), color: .orange, style: .dot)
                        ChartLegendItem(title: String(localized: "Rain Chance"), color: .blue, style: .bar)
                        ChartLegendItem(title: String(localized: "Wind Speed"), color: .mint, style: .bar)
                        Spacer()
                        Text("Blue bars = rain chance · Teal bars = wind speed")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.46))
                    }
                }
            }
            HStack(spacing: 14) {
                ForEach(Array(snapshot.hourly.prefix(8))) { point in
                    Button {
                        selectedHourID = point.id
                        appState.revealControls()
                    } label: {
                        HourlyCard(
                            point: point,
                            timezone: snapshot.timezoneIdentifier,
                            unit: appState.settings.temperatureUnit,
                            measurementSystem: appState.settings.measurementSystem,
                            isSelected: selectedHourID == point.id
                        )
                    }
                    .buttonStyle(FocusButtonStyle())
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            if let selectedHour {
                Text("Selected \(selectedHour.time.formatted(.monthDayTime, timezoneIdentifier: snapshot.timezoneIdentifier)) · Feels like \(selectedHour.apparentTemperature.formattedTemperature(unit: appState.settings.temperatureUnit))° · Rain \(Int(selectedHour.precipitationProbability.rounded()))% · Wind Direction \(Int(selectedHour.windDirection.rounded()))°")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 16)
    }

    private var selectedHour: HourlyForecastPoint? {
        guard let selectedHourID else { return nil }
        return snapshot.hourly.first { $0.id == selectedHourID }
    }
}

private struct HourlyCard: View {
    let point: HourlyForecastPoint
    let timezone: String
    let unit: TemperatureUnit
    let measurementSystem: MeasurementSystem
    let isSelected: Bool
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        VStack(spacing: 9 * layoutScale) {
            Text(point.time.formatted(.time, timezoneIdentifier: timezone))
                .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.70))
            WeatherSymbol(code: point.weatherCode, isDay: point.isDay, size: 29)
            Text(point.temperature.formattedTemperature(unit: unit) + (unit == .celsius ? "℃" : "℉"))
                .font(.system(size: 25 * layoutScale, weight: .bold, design: .rounded))
            HStack(spacing: 3 * layoutScale) {
                Image(systemName: "drop.fill").font(.system(size: 12 * layoutScale))
                Text("\(Int(point.precipitationProbability.rounded()))%")
            }
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(.cyan)
            HStack(spacing: 4 * layoutScale) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 11 * layoutScale, weight: .bold))
                    .rotationEffect(.degrees(point.windDirection))
                Text(point.windSpeed.formattedSpeed(system: measurementSystem))
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.mint.opacity(0.88))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15 * layoutScale)
        .background((isSelected ? Color.cyan.opacity(0.24) : Color.white.opacity(0.09)), in: RoundedRectangle(cornerRadius: 18 * layoutScale, style: .continuous))
    }
}

private struct ChartLegendItem: View {
    enum LineStyle {
        case solid
        case dashed
        case dot
        case bar
    }

    let title: String
    let color: Color
    let style: LineStyle

    var body: some View {
        HStack(spacing: 7) {
            switch style {
            case .solid:
                Capsule().fill(color).frame(width: 24, height: 4)
            case .dashed:
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { _ in
                        Capsule().fill(color).frame(width: 5, height: 2)
                    }
                }
                .frame(width: 24, height: 4)
            case .dot:
                Circle().fill(color).frame(width: 10, height: 10)
            case .bar:
                RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.72)).frame(width: 10, height: 12)
            }
            Text(L10n.string(title))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))
        }
    }
}

private struct WindSpeedChart: View {
    let points: [HourlyForecastPoint]
    let system: MeasurementSystem

    var body: some View {
        HStack(spacing: 10) {
            Label("Wind Speed", systemImage: "wind")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.mint.opacity(0.86))
                .frame(width: 72, alignment: .leading)

            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    BarMark(
                        x: .value(String(localized: "Time"), point.time),
                        y: .value(String(localized: "Wind Speed"), displayedSpeed(point.windSpeed))
                    )
                    .foregroundStyle(.mint.opacity(index.isMultiple(of: 3) ? 0.95 : 0.68))
                    .annotation(position: .top, spacing: 2) {
                        if index.isMultiple(of: 3) {
                            Text(displayedSpeed(point.windSpeed).formattedNumber(decimals: 0))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.mint.opacity(0.9))
                        }
                    }
                }
            }
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .chartYScale(domain: 0...maximumSpeed)
            .frame(height: 70)

            Text(system == .metric ? "km/h" : "mph")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.48))
                .frame(width: 48, alignment: .trailing)
        }
    }

    private var maximumSpeed: Double {
        let maximum = points.map { displayedSpeed($0.windSpeed) }.max() ?? 0
        return max(maximum * 1.25, 10)
    }

    private func displayedSpeed(_ value: Double) -> Double {
        system == .metric ? value : value * 0.621371
    }
}

struct DailyForecastScene: View {
    let snapshot: WeatherSnapshot
    @Binding var selectedDayID: Date?
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale
    @Environment(\.resetFocus) private var resetFocus
    @State private var lastFocusedDayID: Date?
    @FocusState private var focusedDayID: Date?
    @Namespace private var dayFocusScope

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
                forecastList
            }
        }
    }

    private var forecastList: some View {
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
                .frame(height: 520 * layoutScale)
                .onChange(of: focusedDayID) { _, nextID in
                    guard let nextID else { return }
                    lastFocusedDayID = nextID
                    appState.revealControls()
                }
            }
            .focusSection()

            Text("Swipe up or down through all dates. Press Select to open a forecast, and Menu to return to the list.")
                .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
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

    private func closeDetail() {
        guard let selectedDayID else { return }
        lastFocusedDayID = selectedDayID
        self.selectedDayID = nil
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
                    .font(.system(size: 16 * layoutScale, weight: .medium, design: .rounded))
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
                .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.cyan)
                .frame(width: 130 * layoutScale, alignment: .leading)

            Label(point.windSpeed.formattedSpeed(system: measurementSystem), systemImage: "wind")
                .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
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
                .font(.system(size: 16 * layoutScale, weight: .bold))
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
            .shadow(
                color: .white.opacity(isFocused ? 0.18 : 0),
                radius: 13 * layoutScale,
                y: 2 * layoutScale
            )
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
                            .font(.system(size: 18 * layoutScale, weight: .bold, design: .rounded))
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
                        .font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded))
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
                .font(.system(size: 15 * layoutScale, weight: .medium, design: .rounded))
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
                    .font(.system(size: 15 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                Text(value)
                    .font(.system(size: 21 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}

enum RadarPerformancePolicy {
    static let mapActivationDelayNanoseconds: UInt64 = 280_000_000
    static let initialPlaybackDelayNanoseconds: UInt64 = 900_000_000
    static let playbackIntervalNanoseconds: UInt64 = 1_100_000_000
    static let staleOverlayRemovalDelayNanoseconds: UInt64 = 80_000_000
    static let mapReadyFallbackDelayNanoseconds: UInt64 = 1_200_000_000
    static let tileMemoryLimit = 32 * 1_024 * 1_024
    static let tilePrefetchLimit = 34
}

struct RadarScene: View {
    let snapshot: WeatherSnapshot
    @State private var isPlaying = true
    @State private var requestedIndex = 0
    @State private var presentedIndex = 0
    @State private var shouldLoadMap = false
    @State private var isMapVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageHeader(
                eyebrow: String(localized: "Radar"),
                title: String(localized: "Precipitation Radar"),
                detail: hasNowcast
                    ? String(localized: "Observation Playback · Nowcast")
                    : String(localized: "Past Two Hours")
            )
            if snapshot.radar.isAvailable && !snapshot.radar.frames.isEmpty {
                radarPlayback
            } else {
                radarUnavailable
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 16)
        .task {
            guard snapshot.radar.isAvailable, !snapshot.radar.frames.isEmpty else { return }
            let initialIndex = min(
                max(snapshot.radar.selectedIndex, 0),
                snapshot.radar.frames.count - 1
            )
            requestedIndex = initialIndex
            presentedIndex = initialIndex
            try? await Task.sleep(nanoseconds: RadarPerformancePolicy.mapActivationDelayNanoseconds)
            guard !Task.isCancelled else { return }
            shouldLoadMap = true
        }
        .task(id: playbackTaskID) {
            guard isPlaying,
                  isMapVisible,
                  requestedIndex == presentedIndex,
                  snapshot.radar.frames.count > 1 else { return }
            try? await Task.sleep(nanoseconds: RadarPerformancePolicy.initialPlaybackDelayNanoseconds)
            guard !Task.isCancelled,
                  isPlaying,
                  requestedIndex == presentedIndex else { return }
            requestedIndex = (presentedIndex + 1) % snapshot.radar.frames.count
        }
        .onDisappear {
            shouldLoadMap = false
            isMapVisible = false
        }
    }

    private var radarPlayback: some View {
        HStack(spacing: 24) {
            ZStack(alignment: .bottomLeading) {
                RadarMapPreparingView()
                    .opacity(isMapVisible ? 0 : 1)

                if shouldLoadMap {
                    RadarMap(
                        location: snapshot.location,
                        frame: requestedFrame,
                        onMapReady: {
                            withAnimation(.easeOut(duration: 0.16)) {
                                isMapVisible = true
                            }
                        },
                        onFramePresented: { frameID in
                            guard let index = snapshot.radar.frames.firstIndex(where: { $0.id == frameID }) else { return }
                            presentedIndex = index
                        }
                    )
                    .opacity(isMapVisible ? 1 : 0)
                }
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 10) {
                        Text(frameDate?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                        if requestedIndex != presentedIndex {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white.opacity(0.75))
                        }
                    }
                    Text(
                        displayedFrame?.isForecast == true
                            ? String(localized: "Nowcast · Nearby Weather Systems")
                            : String(localized: "Past Two Hours · Nearby Weather Systems")
                    )
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.66))
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 415)
            .background(Color.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.14), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 18) {
                Text("Animation Controls").font(.system(size: 24, weight: .bold, design: .rounded))
                Button {
                    isPlaying.toggle()
                } label: {
                    Label(
                        isPlaying ? String(localized: "Pause Radar") : String(localized: "Play Radar"),
                        systemImage: isPlaying ? "pause.fill" : "play.fill"
                    )
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(FocusButtonStyle())
                .foregroundStyle(.white)
                HStack(spacing: 12) {
                    Button {
                        requestedIndex = max(0, presentedIndex - 1)
                        isPlaying = false
                    } label: {
                        Image(systemName: "backward.fill")
                            .frame(width: 54, height: 44)
                    }
                    .buttonStyle(FocusButtonStyle())
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text("Frame \(snapshot.radar.frames.isEmpty ? 0 : presentedIndex + 1) of \(snapshot.radar.frames.count)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(maxWidth: .infinity)
                    Button {
                        requestedIndex = min(max(snapshot.radar.frames.count - 1, 0), presentedIndex + 1)
                        isPlaying = false
                    } label: {
                        Image(systemName: "forward.fill")
                            .frame(width: 54, height: 44)
                    }
                    .buttonStyle(FocusButtonStyle())
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .foregroundStyle(.white)
                HStack {
                    Text("Earlier").foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Text("Later").foregroundStyle(.white.opacity(0.55))
                }
                .font(.system(size: 17, weight: .medium, design: .rounded))
                RadarLegend()
                Text("Coverage reflects available radar data")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(16)
            .frame(width: 280)
        }
    }

    private var radarUnavailable: some View {
        GlassCard(cornerRadius: 28, tint: .cyan) {
            HStack(spacing: 22) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 8) {
                    Text("No live radar echoes are available")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(snapshot.radar.message ?? String(localized: "Radar coverage is temporarily unavailable for this location. Demo imagery will not be substituted."))
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var displayedIndex: Int {
        guard !snapshot.radar.frames.isEmpty else { return 0 }
        return min(max(presentedIndex, 0), snapshot.radar.frames.count - 1)
    }

    private var frameDate: Date? {
        guard snapshot.radar.frames.indices.contains(displayedIndex) else { return nil }
        return snapshot.radar.frames[displayedIndex].date
    }

    private var displayedFrame: RadarFrame? {
        guard snapshot.radar.frames.indices.contains(displayedIndex) else { return nil }
        return snapshot.radar.frames[displayedIndex]
    }

    private var requestedFrame: RadarFrame? {
        guard snapshot.radar.frames.indices.contains(requestedIndex) else { return nil }
        return snapshot.radar.frames[requestedIndex]
    }

    private var hasNowcast: Bool {
        snapshot.radar.frames.contains(where: \.isForecast)
    }

    private var playbackTaskID: String {
        "\(isPlaying)-\(isMapVisible)-\(requestedIndex)-\(presentedIndex)-\(snapshot.radar.frames.count)"
    }
}

private struct RadarMap: View {
    let location: SavedLocation
    let frame: RadarFrame?
    let onMapReady: () -> Void
    let onFramePresented: (Int) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
#if targetEnvironment(simulator)
            #if DEBUG
            if ProcessInfo.processInfo.environment["RAYN_SIMULATOR_RADAR"] == "1",
               let tileURLTemplate = frame?.tileURLTemplate,
               !tileURLTemplate.isEmpty {
                RadarTileMapView(
                    location: location,
                    frameID: frame?.id ?? 0,
                    tileURLTemplate: tileURLTemplate,
                    onMapReady: onMapReady,
                    onFramePresented: onFramePresented
                )
            } else {
                simulatorUnavailableView
            }
            #else
            simulatorUnavailableView
            #endif
#else
            if let tileURLTemplate = frame?.tileURLTemplate, !tileURLTemplate.isEmpty {
                RadarTileMapView(
                    location: location,
                    frameID: frame?.id ?? 0,
                    tileURLTemplate: tileURLTemplate,
                    onMapReady: onMapReady,
                    onFramePresented: onFramePresented
                )
            } else {
                RadarTileUnavailableView()
            }
#endif
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                Text("Precipitation Playback")
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.42), in: Capsule())
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var simulatorUnavailableView: some View {
        // Live provider tiles can be opted into for maintainer captures, but
        // the default simulator path remains deterministic and never invents
        // precipitation echoes as a visual substitute.
        RadarSimulatorUnavailableView(frame: frame)
            .task(id: frame?.id) {
                onMapReady()
                if let frame {
                    onFramePresented(frame.id)
                }
            }
    }
}

private struct RadarSimulatorUnavailableView: View {
    let frame: RadarFrame?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B1A2B), Color(hex: 0x172D42)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 12) {
                Image(systemName: "tv.and.hifispeaker.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("Live radar maps appear on Apple TV hardware")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(
                    frame == nil
                        ? String(localized: "No radar frame is currently available")
                        : String(localized: "The simulator does not render live map tiles")
                )
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .multilineTextAlignment(.center)
        }
    }
}

private struct RadarMapPreparingView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0B1A2B), Color(hex: 0x172D42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.cyan)
                Text("Preparing Live Radar")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                Text("Weather is ready. The map will load next.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}

private struct RadarTileUnavailableView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B1A2B), Color(hex: 0x172D42)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 10) {
                Image(systemName: "map.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("No map tiles are available for this radar frame")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                Text("The real timestamp is preserved without substitute echoes")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .multilineTextAlignment(.center)
        }
    }
}

private struct RadarTileMapView: UIViewRepresentable {
    let location: SavedLocation
    let frameID: Int
    let tileURLTemplate: String
    let onMapReady: () -> Void
    let onFramePresented: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onMapReady: onMapReady, onFramePresented: onFramePresented)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.pointOfInterestFilter = MKPointOfInterestFilter(including: [])
        mapView.showsBuildings = false
        mapView.showsScale = false
        mapView.showsTraffic = false
        context.coordinator.install(
            mapView: mapView,
            location: location,
            frameID: frameID,
            tileURLTemplate: tileURLTemplate
        )
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.updateCallbacks(
            onMapReady: onMapReady,
            onFramePresented: onFramePresented
        )
        context.coordinator.update(
            mapView: mapView,
            location: location,
            frameID: frameID,
            tileURLTemplate: tileURLTemplate
        )
    }

    static func dismantleUIView(_ mapView: MKMapView, coordinator: Coordinator) {
        coordinator.prepareForRemoval(from: mapView)
        mapView.delegate = nil
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private var currentLocation: SavedLocation?
        private var currentFrameID: Int?
        private var desiredFrameID: Int?
        private var currentTileURLTemplate: String?
        private var radarOverlay: RadarTileOverlay?
        private var locationAnnotation: MKPointAnnotation?
        private var frameLoadTask: Task<Void, Never>?
        private var mapReadyFallbackTask: Task<Void, Never>?
        private var baseMapRendered = false
        private var initialRadarTileRendered = false
        private var didReportMapReady = false
        private var onMapReady: () -> Void
        private var onFramePresented: (Int) -> Void

        init(onMapReady: @escaping () -> Void, onFramePresented: @escaping (Int) -> Void) {
            self.onMapReady = onMapReady
            self.onFramePresented = onFramePresented
        }

        func updateCallbacks(
            onMapReady: @escaping () -> Void,
            onFramePresented: @escaping (Int) -> Void
        ) {
            self.onMapReady = onMapReady
            self.onFramePresented = onFramePresented
        }

        func install(
            mapView: MKMapView,
            location: SavedLocation,
            frameID: Int,
            tileURLTemplate: String
        ) {
            updateLocation(location, on: mapView)
            currentLocation = location
            desiredFrameID = frameID
            installInitialRadarFrame(
                frameID: frameID,
                tileURLTemplate: tileURLTemplate,
                on: mapView
            )
        }

        func update(
            mapView: MKMapView,
            location: SavedLocation,
            frameID: Int,
            tileURLTemplate: String
        ) {
            if currentLocation != location {
                updateLocation(location, on: mapView)
                currentLocation = location
            }

            guard desiredFrameID != frameID || currentTileURLTemplate != tileURLTemplate else { return }
            desiredFrameID = frameID
            prepareRadarFrame(
                frameID: frameID,
                tileURLTemplate: tileURLTemplate,
                location: location,
                on: mapView
            )
        }

        func prepareForRemoval(from mapView: MKMapView) {
            frameLoadTask?.cancel()
            mapReadyFallbackTask?.cancel()
            let radarOverlays = mapView.overlays.compactMap { $0 as? RadarTileOverlay }
            radarOverlays.forEach { $0.cancelPendingRequests() }
            if !radarOverlays.isEmpty {
                mapView.removeOverlays(radarOverlays)
            }
            if let locationAnnotation {
                mapView.removeAnnotation(locationAnnotation)
            }
            radarOverlay = nil
            locationAnnotation = nil
            currentLocation = nil
            currentFrameID = nil
            desiredFrameID = nil
            currentTileURLTemplate = nil
        }

        private func updateLocation(_ location: SavedLocation, on mapView: MKMapView) {
            let coordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 8.0)
            )
            mapView.setRegion(region, animated: false)

            if let locationAnnotation {
                locationAnnotation.coordinate = coordinate
                locationAnnotation.title = location.name
            } else {
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = location.name
                locationAnnotation = annotation
                mapView.addAnnotation(annotation)
            }
        }

        private func installInitialRadarFrame(
            frameID: Int,
            tileURLTemplate: String,
            on mapView: MKMapView
        ) {
            let overlay = RadarTileOverlay(urlTemplate: tileURLTemplate)
            overlay.onFirstTileLoaded = { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    initialRadarTileRendered = true
                    onFramePresented(frameID)
                    reportMapReadyIfPossible()
                }
            }
            radarOverlay = overlay
            currentFrameID = frameID
            currentTileURLTemplate = tileURLTemplate
            mapView.addOverlay(overlay, level: .aboveLabels)

            mapReadyFallbackTask?.cancel()
            mapReadyFallbackTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: RadarPerformancePolicy.mapReadyFallbackDelayNanoseconds)
                guard let self, !Task.isCancelled, !didReportMapReady else { return }
                didReportMapReady = true
                onMapReady()
            }
        }

        private func prepareRadarFrame(
            frameID: Int,
            tileURLTemplate: String,
            location: SavedLocation,
            on mapView: MKMapView
        ) {
            frameLoadTask?.cancel()
            frameLoadTask = Task { @MainActor [weak self, weak mapView] in
                let loadedTileCount = await RadarTileOverlay.prefetch(
                    urlTemplate: tileURLTemplate,
                    around: location
                )
                guard let self,
                      let mapView,
                      !Task.isCancelled,
                      desiredFrameID == frameID,
                      loadedTileCount > 0 else { return }
                commitRadarFrame(
                    frameID: frameID,
                    tileURLTemplate: tileURLTemplate,
                    on: mapView
                )
            }
        }

        private func commitRadarFrame(
            frameID: Int,
            tileURLTemplate: String,
            on mapView: MKMapView
        ) {
            let staleOverlay = radarOverlay
            let nextOverlay = RadarTileOverlay(urlTemplate: tileURLTemplate)
            radarOverlay = nextOverlay
            currentFrameID = frameID
            currentTileURLTemplate = tileURLTemplate
            mapView.addOverlay(nextOverlay, level: .aboveLabels)

            // Core visible tiles are already in the bounded memory cache. Keep
            // the old overlay underneath for a few display frames so MapKit can
            // draw the new renderer without ever exposing an empty frame.
            Task { @MainActor [weak self, weak mapView] in
                try? await Task.sleep(nanoseconds: RadarPerformancePolicy.staleOverlayRemovalDelayNanoseconds)
                guard let self, let mapView, let staleOverlay, staleOverlay !== radarOverlay else { return }
                staleOverlay.cancelPendingRequests()
                mapView.removeOverlay(staleOverlay)
            }
            onFramePresented(frameID)
        }

        private func reportMapReadyIfPossible() {
            guard !didReportMapReady, baseMapRendered, initialRadarTileRendered else { return }
            didReportMapReady = true
            mapReadyFallbackTask?.cancel()
            onMapReady()
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? RadarTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tileOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
            guard fullyRendered else { return }
            baseMapRendered = true
            reportMapReadyIfPossible()
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "RAYNLocationPin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.displayPriority = .required
            return view
        }
    }
}

private final class RadarTileOverlay: MKTileOverlay {
    private static let tileCache: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 160
        cache.totalCostLimit = RadarPerformancePolicy.tileMemoryLimit
        return cache
    }()

    private static let tileSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpMaximumConnectionsPerHost = 4
        configuration.timeoutIntervalForRequest = 8
        return URLSession(configuration: configuration)
    }()

    private let resolvedTileURLTemplate: String
    private let taskLock = NSLock()
    private var pendingTasks: [UUID: URLSessionDataTask] = [:]
    private var didReportFirstTile = false
    var onFirstTileLoaded: (() -> Void)?

    init(urlTemplate: String) {
        resolvedTileURLTemplate = urlTemplate
        super.init(urlTemplate: urlTemplate)
        tileSize = CGSize(width: 256, height: 256)
        minimumZ = 1
        maximumZ = 7
        canReplaceMapContent = false
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        guard let url = Self.tileURL(
            from: resolvedTileURLTemplate,
            z: path.z,
            x: path.x,
            y: path.y,
            scale: path.contentScaleFactor > 1 ? 2 : 1
        ) else {
            result(nil, WeatherProviderError.invalidURL)
            return
        }

        // Every provider frame has its timestamp in the URL. A small in-memory
        // cache therefore reuses only identical tiles during playback loops and
        // can never surface a previous-launch or different-frame image.
        let cacheKey = url.absoluteString as NSString
        if let cachedData = Self.tileCache.object(forKey: cacheKey) {
            reportFirstTileLoaded()
            result(cachedData as Data, nil)
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let taskID = UUID()
        let task = Self.tileSession.dataTask(with: request) { [weak self] data, response, error in
            self?.removePendingTask(taskID)
            if let error {
                result(nil, error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode), let data else {
                result(nil, WeatherProviderError.invalidResponse)
                return
            }
            Self.tileCache.setObject(data as NSData, forKey: cacheKey, cost: data.count)
            self?.reportFirstTileLoaded()
            result(data, nil)
        }
        taskLock.lock()
        pendingTasks[taskID] = task
        taskLock.unlock()
        task.resume()
    }

    static func prefetch(urlTemplate: String, around location: SavedLocation) async -> Int {
        let urls = prefetchURLs(urlTemplate: urlTemplate, around: location)
        return await withTaskGroup(of: Bool.self, returning: Int.self) { group in
            for url in urls {
                group.addTask {
                    await fetchAndCache(url)
                }
            }

            var loadedCount = 0
            for await didLoad in group where didLoad {
                loadedCount += 1
            }
            return loadedCount
        }
    }

    func cancelPendingRequests() {
        taskLock.lock()
        let tasks = Array(pendingTasks.values)
        pendingTasks.removeAll(keepingCapacity: false)
        taskLock.unlock()
        tasks.forEach { $0.cancel() }
    }

    private func removePendingTask(_ taskID: UUID) {
        taskLock.lock()
        pendingTasks[taskID] = nil
        taskLock.unlock()
    }

    private func reportFirstTileLoaded() {
        taskLock.lock()
        guard !didReportFirstTile else {
            taskLock.unlock()
            return
        }
        didReportFirstTile = true
        let callback = onFirstTileLoaded
        taskLock.unlock()
        if let callback {
            DispatchQueue.main.async(execute: callback)
        }
    }

    private static func fetchAndCache(_ url: URL) async -> Bool {
        guard !Task.isCancelled else { return false }
        let cacheKey = url.absoluteString as NSString
        if tileCache.object(forKey: cacheKey) != nil {
            return true
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, response) = try await tileSession.data(for: request)
            guard !Task.isCancelled,
                  let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else { return false }
            tileCache.setObject(data as NSData, forKey: cacheKey, cost: data.count)
            return true
        } catch {
            return false
        }
    }

    private static func prefetchURLs(urlTemplate: String, around location: SavedLocation) -> [URL] {
        var urls: [URL] = []
        var seen = Set<URL>()

        for (zoom, radius) in [(6, 1), (7, 2)] {
            let center = tileCoordinate(
                latitude: location.latitude,
                longitude: location.longitude,
                zoom: zoom
            )
            let tileCount = 1 << zoom
            let offsets = (-radius...radius).flatMap { x in
                (-radius...radius).map { y in (x: x, y: y) }
            }
            .sorted {
                (abs($0.x) + abs($0.y)) < (abs($1.x) + abs($1.y))
            }

            for offset in offsets {
                let x = ((center.x + offset.x) % tileCount + tileCount) % tileCount
                let y = min(max(center.y + offset.y, 0), tileCount - 1)
                guard let url = tileURL(from: urlTemplate, z: zoom, x: x, y: y, scale: 1),
                      seen.insert(url).inserted else { continue }
                urls.append(url)
            }
        }

        return Array(urls.prefix(RadarPerformancePolicy.tilePrefetchLimit))
    }

    private static func tileCoordinate(latitude: Double, longitude: Double, zoom: Int) -> (x: Int, y: Int) {
        let clampedLatitude = min(max(latitude, -85.051_128_78), 85.051_128_78)
        let latitudeRadians = clampedLatitude * .pi / 180
        let scale = pow(2, Double(zoom))
        let x = Int(floor((longitude + 180) / 360 * scale))
        let y = Int(floor((1 - log(tan(latitudeRadians) + 1 / cos(latitudeRadians)) / .pi) / 2 * scale))
        return (x, y)
    }

    private static func tileURL(
        from template: String,
        z: Int,
        x: Int,
        y: Int,
        scale: Int
    ) -> URL? {
        let urlString = template
            .replacingOccurrences(of: "{z}", with: String(z))
            .replacingOccurrences(of: "{x}", with: String(x))
            .replacingOccurrences(of: "{y}", with: String(y))
            .replacingOccurrences(of: "{scale}", with: String(scale))
        return URL(string: urlString)
    }

    deinit {
        cancelPendingRequests()
    }
}

private struct RadarLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Precipitation Intensity").font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.68))
            HStack(spacing: 0) {
                ForEach([Color.blue, Color.cyan, Color.green, Color.yellow, Color.orange, Color.red], id: \.self) { color in
                    Rectangle().fill(color).frame(maxWidth: .infinity).frame(height: 10)
                }
            }
            HStack {
                Text("Light").foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text("Heavy").foregroundStyle(.white.opacity(0.55))
            }
            .font(.system(size: 15, weight: .medium, design: .rounded))
        }
    }
}

struct AirQualityScene: View {
    let snapshot: WeatherSnapshot
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        VStack(alignment: .leading, spacing: 24 * layoutScale) {
            PageHeader(
                eyebrow: String(localized: "Environment"),
                title: String(localized: "Air Quality"),
                detail: String(localized: "Current and Future Trends")
            )
            if let air = snapshot.airQuality {
                HStack(alignment: .top, spacing: 24 * layoutScale) {
                    AirQualityHero(air: air, timezone: snapshot.timezoneIdentifier)
                        .frame(width: 510 * layoutScale, height: 298 * layoutScale)
                    AirQualityPollutants(air: air)
                        .frame(maxWidth: .infinity, minHeight: 298 * layoutScale)
                }
                AQIHourlyTrend(values: Array(air.hourlyAQI.prefix(24)), timezone: snapshot.timezoneIdentifier)
            } else {
                GlassCard(cornerRadius: 28) {
                    HStack(spacing: 18 * layoutScale) {
                        Image(systemName: "aqi.medium")
                            .font(.system(size: 52 * layoutScale, weight: .medium))
                            .foregroundStyle(.white.opacity(0.78))
                        VStack(alignment: .leading, spacing: 7 * layoutScale) {
                            Text("Air quality has not updated yet")
                                .font(.system(size: 27 * layoutScale, weight: .semibold, design: .rounded))
                            Text("Live weather remains available.")
                                .font(.system(size: 20 * layoutScale, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.58))
                        }
                    }
                }
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 16)
    }

}

private func aqiColor(_ value: Double) -> Color {
    switch value {
    case ..<40: return .green
    case ..<60: return .yellow
    case ..<80: return .orange
    default: return .red
    }
}

private func pollutantColor(_ pollutant: PollutantValue) -> Color {
    let ratio = pollutant.value / max(pollutant.reference, 1)
    return ratio < 0.5 ? .green : (ratio < 0.85 ? .yellow : .orange)
}

private struct AirQualityHero: View {
    let air: AirQualitySnapshot
    let timezone: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 30) {
            HStack(spacing: 26 * layoutScale) {
                AQIGauge(value: air.europeanAQI, level: air.level)
                VStack(alignment: .leading, spacing: 12 * layoutScale) {
                    Text("Current Air")
                        .font(.system(size: 20 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                    Text(air.level)
                        .font(.system(size: 42 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(aqiColor(air.europeanAQI))
                    Text(air.advice)
                        .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 7 * layoutScale) {
                        Circle()
                            .fill(aqiColor(air.europeanAQI))
                            .frame(width: 8 * layoutScale, height: 8 * layoutScale)
                        Text("Updated \(air.updatedAt.formatted(.time, timezoneIdentifier: timezone))")
                    }
                    .font(.system(size: 16 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
                }
            }
        }
    }
}

private struct AirQualityPollutants: View {
    let air: AirQualitySnapshot
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 16 * layoutScale) {
                Text("Pollutants")
                    .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14 * layoutScale), GridItem(.flexible(), spacing: 14 * layoutScale), GridItem(.flexible(), spacing: 14 * layoutScale)], spacing: 14 * layoutScale) {
                    ForEach(air.pollutants) { pollutant in
                        PollutantTile(pollutant: pollutant)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct PollutantTile: View {
    let pollutant: PollutantValue
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        VStack(alignment: .leading, spacing: 7 * layoutScale) {
            HStack(spacing: 7 * layoutScale) {
                Circle()
                    .fill(pollutantColor(pollutant))
                    .frame(width: 8 * layoutScale, height: 8 * layoutScale)
                Text(pollutant.title)
                    .font(.system(size: 17 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
            }
            Text(pollutant.value.formattedNumber(decimals: pollutant.value < 10 ? 1 : 0))
                .font(.system(size: 27 * layoutScale, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(pollutant.unit)
                .font(.system(size: 14 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14 * layoutScale)
        .padding(.vertical, 12 * layoutScale)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18 * layoutScale, style: .continuous))
    }
}

private struct AQIHourlyTrend: View {
    let values: [Double]
    let timezone: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 12 * layoutScale) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Next 24 Hours")
                        .font(.system(size: 23 * layoutScale, weight: .bold, design: .rounded))
                    Spacer()
                    Text("AQI")
                        .font(.system(size: 16 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.48))
                }
                if values.isEmpty {
                    Text("No hourly data is available")
                        .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, minHeight: 112 * layoutScale)
                } else {
                    Chart {
                        ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                            BarMark(x: .value(String(localized: "Hour"), index), y: .value("AQI", value))
                                .foregroundStyle(aqiColor(value).gradient)
                                .cornerRadius(5 * layoutScale)
                                .annotation(position: .top, spacing: 3 * layoutScale) {
                                    if index.isMultiple(of: 3) {
                                        Text(value.formattedNumber(decimals: 0))
                                            .font(.system(size: 12 * layoutScale, weight: .semibold, design: .rounded))
                                            .monospacedDigit()
                                            .foregroundStyle(.white.opacity(0.64))
                                    }
                                }
                        }
                    }
                    .chartLegend(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 5]))
                                .foregroundStyle(.white.opacity(0.10))
                            AxisValueLabel {
                                if let aqi = value.as(Double.self) {
                                    Text(aqi.formattedNumber(decimals: 0))
                                        .font(.system(size: 12 * layoutScale, weight: .medium, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundStyle(.white.opacity(0.42))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 6)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 5]))
                                .foregroundStyle(.white.opacity(0.10))
                            AxisValueLabel {
                                if let index = value.as(Int.self) {
                                    Text(hourLabel(index))
                                        .font(.system(size: 14 * layoutScale, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.48))
                                }
                            }
                        }
                    }
                    .chartYScale(domain: 0...max(values.max() ?? 80, 80))
                    .frame(height: 142 * layoutScale)
                }
                AQIThresholdScale()
            }
        }
    }

    private func hourLabel(_ index: Int) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(bySettingHour: index % 24, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.time, timezoneIdentifier: timezone)
    }
}

private struct AQIThresholdScale: View {
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        VStack(alignment: .leading, spacing: 7 * layoutScale) {
            HStack(spacing: 3 * layoutScale) {
                ForEach([Color.green, .yellow, .orange, .red], id: \.self) { color in
                    Capsule().fill(color.opacity(0.78)).frame(maxWidth: .infinity).frame(height: 6 * layoutScale)
                }
            }
            HStack {
                Text("Excellent")
                Spacer()
                Text("Good")
                Spacer()
                Text("Moderate")
                Spacer()
                Text("Poor")
            }
            .font(.system(size: 13 * layoutScale, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.46))
        }
    }
}

private struct AQIGauge: View {
    let value: Double
    let level: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.12), lineWidth: 18 * layoutScale)
            Circle().trim(from: 0, to: min(max(value / 100, 0.02), 1))
                .stroke(
                    AngularGradient(
                        colors: [aqiColor(value).opacity(0.60), aqiColor(value)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 18 * layoutScale, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(value.rounded()))")
                    .font(.system(size: 58 * layoutScale, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("AQI")
                    .font(.system(size: 16 * layoutScale, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .frame(width: 190 * layoutScale, height: 190 * layoutScale)
        .animation(.snappy(duration: 0.45), value: value)
    }
}

struct AstronomyScene: View {
    let snapshot: WeatherSnapshot
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        VStack(alignment: .leading, spacing: 22 * layoutScale) {
            PageHeader(
                eyebrow: snapshot.marine == nil
                    ? String(localized: "Astronomy")
                    : String(localized: "Astronomy & Marine"),
                title: snapshot.marine == nil
                    ? String(localized: "Sun & Moon")
                    : String(localized: "Sun, Moon & Marine"),
                detail: String(localized: "Current Conditions and Trends")
            )
            GeometryReader { geometry in
                let spacing = 20 * layoutScale
                let hasMarine = snapshot.marine != nil
                let marineHeight = hasMarine ? 168 * layoutScale : 0
                let sunMoonHeight = max(0, geometry.size.height - marineHeight - (hasMarine ? spacing : 0))
                let availableWidth = max(0, geometry.size.width - spacing)

                VStack(spacing: spacing) {
                    HStack(alignment: .top, spacing: spacing) {
                        SolarConditionCard(snapshot: snapshot, compact: hasMarine)
                            .frame(width: availableWidth * 0.59)
                        MoonPhaseCard(
                            info: MoonPhaseCalculator.info(at: Date()),
                            daily: snapshot.daily,
                            timezone: snapshot.timezoneIdentifier,
                            compact: hasMarine
                        )
                        .frame(width: availableWidth * 0.41)
                    }
                    .frame(height: sunMoonHeight)

                    if let marine = snapshot.marine {
                        MarineConditionCard(marine: marine, timezone: snapshot.timezoneIdentifier)
                            .frame(height: marineHeight)
                    }
                }
            }
            .frame(height: 610 * layoutScale)
        }
        .padding(.top, 30 * layoutScale)
        .padding(.bottom, 16 * layoutScale)
    }
}

private struct SolarConditionCard: View {
    let snapshot: WeatherSnapshot
    let compact: Bool
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: (compact ? 11 : 17) * layoutScale) {
                HStack {
                    Label("Sun", systemImage: "sun.max.fill")
                        .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                    Spacer()
                    Text(solarState)
                        .font(.system(size: 16 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(isCurrentlyDaylight ? .yellow : .indigo.opacity(0.95))
                }

                SunlightTimeline(
                    sunrise: snapshot.current.sunrise,
                    sunset: snapshot.current.sunset,
                    timezone: snapshot.timezoneIdentifier
                )
                .frame(height: (compact ? 150 : 210) * layoutScale)

                HStack(spacing: 12 * layoutScale) {
                    AstronomyMetric(
                        symbol: "clock.fill",
                        title: String(localized: "Today’s Daylight"),
                        value: daylightText,
                        accent: .yellow
                    )
                    AstronomyMetric(
                        symbol: tomorrowChangeSymbol,
                        title: String(localized: "Tomorrow’s Change"),
                        value: tomorrowDaylightChange,
                        accent: .cyan
                    )
                }

                SunlightForecastStrip(daily: snapshot.daily, timezone: snapshot.timezoneIdentifier)
                    .frame(height: (compact ? 104 : 150) * layoutScale)
            }
        }
    }

    private var daylightText: String {
        if let duration = snapshot.current.daylightDuration {
            let minutes = Int(duration / 60)
            return String(localized: "\(minutes / 60) hr \(minutes % 60) min")
        }
        guard let sunrise = snapshot.current.sunrise, let sunset = snapshot.current.sunset else { return "--" }
        let minutes = Int(sunset.timeIntervalSince(sunrise) / 60)
        return String(localized: "\(minutes / 60) hr \(minutes % 60) min")
    }

    private var solarState: String {
        guard snapshot.current.sunrise != nil, snapshot.current.sunset != nil else {
            return String(localized: "Astronomical data unavailable")
        }
        return isCurrentlyDaylight ? String(localized: "Daylight") : String(localized: "Night")
    }

    private var isCurrentlyDaylight: Bool {
        guard let sunrise = snapshot.current.sunrise, let sunset = snapshot.current.sunset else { return false }
        let now = Date()
        return now >= sunrise && now <= sunset
    }

    private var tomorrowDaylightChange: String {
        guard snapshot.daily.count >= 2,
              let today = duration(for: snapshot.daily[0]),
              let tomorrow = duration(for: snapshot.daily[1]) else { return "--" }
        let minutes = Int(((tomorrow - today) / 60).rounded())
        if abs(minutes) < 1 { return String(localized: "No Change") }
        return minutes > 0
            ? String(localized: "\(minutes) min longer")
            : String(localized: "\(abs(minutes)) min shorter")
    }

    private var tomorrowChangeSymbol: String {
        guard snapshot.daily.count >= 2,
              let today = duration(for: snapshot.daily[0]),
              let tomorrow = duration(for: snapshot.daily[1]) else { return "minus" }
        if abs(tomorrow - today) < 60 { return "equal" }
        return tomorrow > today ? "arrow.up.right" : "arrow.down.right"
    }

    private func duration(for point: DailyForecastPoint) -> TimeInterval? {
        if let duration = point.daylightDuration { return duration }
        guard let sunrise = point.sunrise, let sunset = point.sunset, sunset > sunrise else { return nil }
        return sunset.timeIntervalSince(sunrise)
    }
}

private struct AstronomyMetric: View {
    let symbol: String
    let title: String
    let value: String
    let accent: Color
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        HStack(spacing: 10 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: 19 * layoutScale, weight: .semibold))
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 2 * layoutScale) {
                Text(L10n.string(title))
                    .font(.system(size: 14 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
                Text(value)
                    .font(.system(size: 18 * layoutScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12 * layoutScale)
        .padding(.vertical, 10 * layoutScale)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14 * layoutScale, style: .continuous))
    }
}

private struct SunlightForecastStrip: View {
    let daily: [DailyForecastPoint]
    let timezone: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * layoutScale) {
            Text("10-Day Daylight Trend")
                .font(.system(size: 16 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
            HStack(spacing: 8 * layoutScale) {
                ForEach(Array(daily.prefix(10).enumerated()), id: \.element.id) { index, point in
                    VStack(alignment: .leading, spacing: 6 * layoutScale) {
                        Text(index == 0 ? String(localized: "Today") : point.date.formatted(.shortWeekday, timezoneIdentifier: timezone))
                            .font(.system(size: 14 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.76))
                        Text(point.date.formatted(.monthDay, timezoneIdentifier: timezone))
                            .font(.system(size: 12 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                        SunlightDayBar(point: point, timezone: timezone)
                            .frame(height: 24 * layoutScale)
                        HStack {
                            Text(point.sunrise?.formatted(.time, timezoneIdentifier: timezone) ?? "--:--")
                            Spacer()
                            Text(point.sunset?.formatted(.time, timezoneIdentifier: timezone) ?? "--:--")
                        }
                        .font(.system(size: 11 * layoutScale, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.48))
                    }
                    .padding(.horizontal, 8 * layoutScale)
                    .padding(.vertical, 7 * layoutScale)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(index == 0 ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 12 * layoutScale, style: .continuous))
                }
            }
        }
    }
}

private struct SunlightDayBar: View {
    let point: DailyForecastPoint
    let timezone: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GeometryReader { geometry in
            let metrics = metrics(width: geometry.size.width)
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.10)).frame(height: 6 * layoutScale)
                Capsule()
                    .fill(LinearGradient(colors: [.orange.opacity(0.72), .yellow, .cyan.opacity(0.72)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: metrics.width, height: 6 * layoutScale)
                    .offset(x: metrics.start)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func metrics(width: CGFloat) -> (start: CGFloat, width: CGFloat) {
        guard let sunrise = point.sunrise, let sunset = point.sunset, sunset > sunrise else { return (0, 0) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current
        let startOfDay = calendar.startOfDay(for: point.date)
        let start = min(max(sunrise.timeIntervalSince(startOfDay) / 86_400, 0), 1)
        let end = min(max(sunset.timeIntervalSince(startOfDay) / 86_400, start), 1)
        return (width * CGFloat(start), width * CGFloat(end - start))
    }
}

private struct MoonPhaseCard: View {
    let info: MoonPhaseInfo
    let daily: [DailyForecastPoint]
    let timezone: String
    let compact: Bool
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: (compact ? 9 : 14) * layoutScale) {
                HStack {
                    Label("Moon Phase", systemImage: "moon.stars.fill")
                        .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                    Spacer()
                    Text("Moon age \(info.age.formattedNumber(decimals: 1)) days")
                        .font(.system(size: 14 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.50))
                }

                VStack(spacing: 8 * layoutScale) {
                    MoonDiskView(info: info)
                        .frame(
                            width: (compact ? 104 : 142) * layoutScale,
                            height: (compact ? 104 : 142) * layoutScale
                        )
                    Text(info.title)
                        .font(.system(size: 29 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Illumination \(Int((info.illumination * 100).rounded()))%")
                        .font(.system(size: 17 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }

                HStack(spacing: 10 * layoutScale) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow.opacity(0.85))
                    VStack(alignment: .leading, spacing: 2 * layoutScale) {
                        Text("Next Major Phase")
                            .font(.system(size: 13 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.48))
                        Text("\(info.nextPhaseTitle) · \(info.nextPhaseDate.formatted(.monthDay, timezoneIdentifier: timezone))")
                            .font(.system(size: 17 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .padding(11 * layoutScale)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14 * layoutScale, style: .continuous))

                Text("7-Day Moon Phases")
                    .font(.system(size: 15 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.54))

                HStack(spacing: 6 * layoutScale) {
                    ForEach(Array(daily.prefix(7).enumerated()), id: \.element.id) { index, point in
                        let dayInfo = MoonPhaseCalculator.info(at: point.date)
                        VStack(spacing: 5 * layoutScale) {
                            Text(index == 0 ? String(localized: "Today") : point.date.formatted(.shortWeekday, timezoneIdentifier: timezone))
                                .font(.system(size: 12 * layoutScale, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.58))
                            MoonDiskView(info: dayInfo)
                                .frame(width: 34 * layoutScale, height: 34 * layoutScale)
                            Text("\(Int((dayInfo.illumination * 100).rounded()))")
                                .font(.system(size: 11 * layoutScale, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.48))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

private struct MoonDiskView: View {
    let info: MoonPhaseInfo

    var body: some View {
        Canvas { context, size in
            let diameter = min(size.width, size.height)
            let rect = CGRect(
                x: (size.width - diameter) / 2,
                y: (size.height - diameter) / 2,
                width: diameter,
                height: diameter
            )
            let disk = Path(ellipseIn: rect)
            context.fill(disk, with: .color(.white.opacity(0.08)))

            if info.illumination > 0.998 {
                context.addFilter(.shadow(color: .white.opacity(0.22), radius: diameter * 0.08))
                context.fill(disk, with: .color(.white.opacity(0.94)))
            } else if info.illumination > 0.002 {
                let lit = illuminatedPath(in: rect)
                context.addFilter(.shadow(color: .white.opacity(0.16), radius: diameter * 0.06))
                context.fill(lit, with: .color(.white.opacity(0.92)))
            }
            context.stroke(disk, with: .color(.white.opacity(0.22)), lineWidth: max(1, diameter * 0.012))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(info.title), illumination \(Int((info.illumination * 100).rounded())) percent")
    }

    private func illuminatedPath(in rect: CGRect) -> Path {
        let synodicMonth = 29.530588
        let phaseAngle = 2 * Double.pi * info.age / synodicMonth
        let waxing = phaseAngle < Double.pi
        let terminatorFactor = CGFloat(cos(phaseAngle))
        let radius = rect.width / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let steps = 72
        var path = Path()

        for step in 0...steps {
            let y = -radius + (2 * radius * CGFloat(step) / CGFloat(steps))
            let halfWidth = sqrt(max(0, radius * radius - y * y))
            let x = waxing ? halfWidth : -halfWidth
            let point = CGPoint(x: center.x + x, y: center.y + y)
            step == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        for step in stride(from: steps, through: 0, by: -1) {
            let y = -radius + (2 * radius * CGFloat(step) / CGFloat(steps))
            let halfWidth = sqrt(max(0, radius * radius - y * y))
            let x = waxing ? halfWidth * terminatorFactor : -halfWidth * terminatorFactor
            path.addLine(to: CGPoint(x: center.x + x, y: center.y + y))
        }
        path.closeSubpath()
        return path
    }
}

private struct MarineConditionCard: View {
    let marine: MarineSnapshot
    let timezone: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 24, shadowRadius: 8, shadowOffset: 3) {
            HStack(spacing: 20 * layoutScale) {
                HStack(spacing: 13 * layoutScale) {
                    Image(systemName: "water.waves")
                        .font(.system(size: 39 * layoutScale, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.cyan)
                    VStack(alignment: .leading, spacing: 1 * layoutScale) {
                        Text("Marine Conditions · \(waveState(marine.waveHeight))")
                            .font(.system(size: 15 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.60))
                        Text("\(marine.waveHeight.formattedNumber(decimals: 1)) m")
                            .font(.system(size: 35 * layoutScale, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("Significant wave height · Updated \(marine.updatedAt.formatted(.time, timezoneIdentifier: timezone))")
                            .font(.system(size: 12 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                    }
                }
                .frame(width: 285 * layoutScale, alignment: .leading)

                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 1, height: 90 * layoutScale)

                VStack(alignment: .leading, spacing: 4 * layoutScale) {
                    Text("24-Hour Wave Height")
                        .font(.system(size: 13 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.52))
                    MarineForecastStrip(points: forecastPoints(for: marine), timezone: timezone)
                        .frame(height: 82 * layoutScale)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 1, height: 90 * layoutScale)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 7 * layoutScale), count: 3),
                    spacing: 7 * layoutScale
                ) {
                    MarineCompactMetric(symbol: "timer", title: String(localized: "Period"), value: "\(marine.wavePeriod.formattedNumber(decimals: 1)) s", accent: .yellow)
                    MarineCompactMetric(symbol: "location.north.line.fill", title: String(localized: "Direction"), value: "\(Int(marine.waveDirection.rounded()))° \(compassDirection(marine.waveDirection))", accent: .mint)
                    MarineCompactMetric(symbol: "wind", title: String(localized: "Wind Waves"), value: "\(marine.windWaveHeight.formattedNumber(decimals: 1)) m", accent: .orange)
                    MarineCompactMetric(symbol: "water.waves", title: String(localized: "Swell"), value: "\(marine.swellWaveHeight.formattedNumber(decimals: 1)) m", accent: .cyan)
                    MarineCompactMetric(symbol: "thermometer.medium", title: String(localized: "Sea Temp"), value: marine.seaSurfaceTemperature.map { "\($0.formattedNumber(decimals: 1))℃" } ?? "--", accent: .pink)
                    MarineCompactMetric(symbol: "arrow.trianglehead.branch", title: String(localized: "Current"), value: currentText(marine), accent: .blue)
                }
                .frame(width: 590 * layoutScale)
            }
        }
    }

    private func forecastPoints(for marine: MarineSnapshot) -> [MarineForecastPoint] {
        let points = (marine.hourly ?? []).filter { $0.time >= marine.updatedAt.addingTimeInterval(-3_600) }
        guard points.count > 6 else { return points }
        let step = max(1, Int(ceil(Double(points.count) / 6.0)))
        return Array(stride(from: 0, to: points.count, by: step).prefix(6).map { points[$0] })
    }

    private func waveState(_ height: Double) -> String {
        switch height {
        case ..<0.5: return String(localized: "Calm")
        case ..<1.25: return String(localized: "Light")
        case ..<2.5: return String(localized: "Moderate")
        default: return String(localized: "High")
        }
    }

    private func currentText(_ marine: MarineSnapshot) -> String {
        guard let speed = marine.oceanCurrentVelocity else { return "--" }
        if let direction = marine.oceanCurrentDirection {
            return "\(speed.formattedNumber(decimals: 1)) · \(compassDirection(direction))"
        }
        return "\(speed.formattedNumber(decimals: 1)) km/h"
    }

    private func compassDirection(_ degrees: Double) -> String {
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        switch Int((normalized / 45).rounded()) % 8 {
        case 0: return String(localized: "N")
        case 1: return String(localized: "NE")
        case 2: return String(localized: "E")
        case 3: return String(localized: "SE")
        case 4: return String(localized: "S")
        case 5: return String(localized: "SW")
        case 6: return String(localized: "W")
        default: return String(localized: "NW")
        }
    }
}

private struct MarineForecastStrip: View {
    let points: [MarineForecastPoint]
    let timezone: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        if points.isEmpty {
            HStack {
                Image(systemName: "clock.badge.questionmark")
                Text("Short-Term Trend Is Updating")
            }
            .font(.system(size: 16 * layoutScale, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.50))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16 * layoutScale, style: .continuous))
        } else {
            HStack(alignment: .bottom, spacing: 8 * layoutScale) {
                ForEach(points) { point in
                    VStack(spacing: 2 * layoutScale) {
                        Text(point.waveHeight.formattedNumber(decimals: 1))
                            .font(.system(size: 11 * layoutScale, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.74))
                        ZStack(alignment: .bottom) {
                            Capsule().fill(.white.opacity(0.07))
                            Capsule()
                                .fill(LinearGradient(colors: [.blue.opacity(0.72), .cyan], startPoint: .bottom, endPoint: .top))
                                .frame(height: max(6 * layoutScale, 34 * layoutScale * point.waveHeight / maximumWaveHeight))
                        }
                        .frame(height: 38 * layoutScale)
                        Text(point.time.formatted(.hour, timezoneIdentifier: timezone))
                            .font(.system(size: 10 * layoutScale, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var maximumWaveHeight: Double {
        max(points.map(\.waveHeight).max() ?? 0, 0.2)
    }
}

private struct MarineCompactMetric: View {
    let symbol: String
    let title: String
    let value: String
    let accent: Color
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        VStack(alignment: .leading, spacing: 3 * layoutScale) {
            HStack(spacing: 5 * layoutScale) {
                Image(systemName: symbol)
                    .font(.system(size: 11 * layoutScale, weight: .semibold))
                    .foregroundStyle(accent)
                Text(L10n.string(title))
                    .font(.system(size: 11 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
            }
            Text(value)
                .font(.system(size: 14 * layoutScale, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(5 * layoutScale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12 * layoutScale, style: .continuous))
    }
}

private struct SunlightTimeline: View {
    let sunrise: Date?
    let sunset: Date?
    let timezone: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            GeometryReader { geometry in
                let metrics = timelineMetrics(at: context.date, width: geometry.size.width)
                VStack(alignment: .leading, spacing: 18 * layoutScale) {
                    HStack {
                        Text("24-Hour Daylight Timeline")
                            .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                        Spacer()
                        Text("Now \(context.date.formatted(.time, timezoneIdentifier: timezone))")
                            .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.10))
                            .frame(height: 14 * layoutScale)
                        if metrics.daylightWidth > 0 {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.72), .yellow, .cyan.opacity(0.72)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: metrics.daylightWidth, height: 14 * layoutScale)
                                .offset(x: metrics.daylightStart)
                        }
                        Circle()
                            .fill(.white)
                            .frame(width: 22 * layoutScale, height: 22 * layoutScale)
                            .shadow(color: .white.opacity(0.36), radius: 12 * layoutScale)
                            .offset(x: metrics.currentX - 11 * layoutScale)
                            .animation(.easeInOut(duration: 0.35), value: metrics.currentX)
                    }
                    .frame(height: 24 * layoutScale)

                    HStack {
                        Text("00:00")
                        Spacer()
                        Text("06:00")
                        Spacer()
                        Text("12:00")
                        Spacer()
                        Text("18:00")
                        Spacer()
                        Text("24:00")
                    }
                    .font(.system(size: 14 * layoutScale, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.45))

                    HStack {
                        Label(sunrise.map { $0.formatted(.time, timezoneIdentifier: timezone) } ?? "--:--", systemImage: "sunrise.fill")
                        Spacer()
                        Text("Sunrise to Sunset")
                            .foregroundStyle(.white.opacity(0.50))
                        Spacer()
                        Label(sunset.map { $0.formatted(.time, timezoneIdentifier: timezone) } ?? "--:--", systemImage: "sunset.fill")
                    }
                    .font(.system(size: 17 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                }
            }
        }
    }

    private struct TimelineMetrics {
        var daylightStart: CGFloat
        var daylightWidth: CGFloat
        var currentX: CGFloat
    }

    private func timelineMetrics(at date: Date, width: CGFloat) -> TimelineMetrics {
        guard let sunrise, let sunset, sunset > sunrise else {
            return TimelineMetrics(daylightStart: 0, daylightWidth: 0, currentX: width / 2)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current
        let startOfDay = calendar.startOfDay(for: date)
        let daySeconds = 86_400.0
        let start = min(max(sunrise.timeIntervalSince(startOfDay) / daySeconds, 0), 1)
        let end = min(max(sunset.timeIntervalSince(startOfDay) / daySeconds, start), 1)
        let current = min(max(date.timeIntervalSince(startOfDay) / daySeconds, 0), 1)
        return TimelineMetrics(
            daylightStart: width * CGFloat(start),
            daylightWidth: width * CGFloat(end - start),
            currentX: width * CGFloat(current)
        )
    }
}
