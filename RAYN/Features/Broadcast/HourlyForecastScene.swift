import Charts
import SwiftUI

struct HourlyForecastScene: View {
    let snapshot: WeatherSnapshot
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale
    @State private var selectedHourID: Date?
    @FocusState private var focusedHourID: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 18 * layoutScale) {
            PageHeader(
                eyebrow: String(localized: "Forecast"),
                title: String(localized: "Next 24 Hours"),
                detail: String(localized: "Temperature · Feels Like · Rain · Wind")
            )
            GlassCard(cornerRadius: 28, shadowRadius: 8, shadowOffset: 4) {
                VStack(alignment: .leading, spacing: 11 * layoutScale) {
                    Chart {
                        ForEach(Array(snapshot.hourly.prefix(24).enumerated()), id: \.offset) { index, point in
                            PointMark(x: .value(String(localized: "Time"), point.time), y: .value(String(localized: "Temperature"), point.temperature))
                                .foregroundStyle(.white)
                                .symbolSize(index.isMultiple(of: 3) ? 88 : 54)
                                .annotation(position: .top, spacing: 3 * layoutScale) {
                                    if index.isMultiple(of: 3) {
                                        Text("\(point.temperature.formattedTemperature(unit: appState.settings.temperatureUnit))° / \(point.apparentTemperature.formattedTemperature(unit: appState.settings.temperatureUnit))°")
                                            .font(.system(size: 15 * layoutScale, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.78))
                                    }
                                }
                            PointMark(x: .value(String(localized: "Time"), point.time), y: .value(String(localized: "Feels Like"), point.apparentTemperature))
                                .foregroundStyle(.orange.opacity(0.86))
                                .symbolSize(index.isMultiple(of: 3) ? 70 : 42)
                            BarMark(x: .value(String(localized: "Time"), point.time), y: .value(String(localized: "Rain Chance"), point.precipitationProbability / 3.0))
                                .foregroundStyle(.blue.opacity(0.42))
                                .annotation(position: .top, spacing: 2 * layoutScale) {
                                    if index.isMultiple(of: 3) {
                                        Text("\(Int(point.precipitationProbability.rounded()))%")
                                            .font(.system(size: 14 * layoutScale, weight: .semibold, design: .rounded))
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
                    .frame(height: 162 * layoutScale)

                    WindSpeedChart(
                        points: Array(snapshot.hourly.prefix(24)),
                        system: appState.settings.measurementSystem
                    )

                    HStack(spacing: 22 * layoutScale) {
                        ChartLegendItem(title: String(localized: "Temperature"), color: .white, style: .dot)
                        ChartLegendItem(title: String(localized: "Feels Like"), color: .orange, style: .dot)
                        ChartLegendItem(title: String(localized: "Rain Chance"), color: .blue, style: .bar)
                        ChartLegendItem(title: String(localized: "Wind Speed"), color: .mint, style: .bar)
                        Spacer()
                        Text("Blue bars = rain chance · Teal bars = wind speed")
                            .font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.46))
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14 * layoutScale) {
                    ForEach(Array(snapshot.hourly.prefix(24))) { point in
                        Button {
                            selectedHourID = point.id
                            appState.revealControls()
                        } label: {
                            HourlyCard(
                                point: point,
                                timezone: snapshot.timezoneIdentifier,
                                unit: appState.settings.temperatureUnit,
                                measurementSystem: appState.settings.measurementSystem,
                                isSelected: selectedHourID == point.id || focusedHourID == point.id
                            )
                        }
                        .buttonStyle(FocusButtonStyle())
                        .focused($focusedHourID, equals: point.id)
                        .foregroundStyle(.white)
                        .accessibilityLabel(hourAccessibilityLabel(point))
                        .accessibilityHint("Press Select to keep this hour highlighted")
                    }
                }
                .padding(.horizontal, 18 * layoutScale)
                .padding(.vertical, 12 * layoutScale)
            }
            .scrollClipDisabled()
            .clipShape(Rectangle().inset(by: -20 * layoutScale))
            .frame(height: 190 * layoutScale)
            .focusSection()
            .onChange(of: focusedHourID) { _, hourID in
                guard let hourID else { return }
                selectedHourID = hourID
                appState.revealControls()
            }
            if let selectedHour {
                Text("Selected \(selectedHour.time.formatted(.monthDayTime, timezoneIdentifier: snapshot.timezoneIdentifier)) · Feels like \(selectedHour.apparentTemperature.formattedTemperature(unit: appState.settings.temperatureUnit))° · Rain \(Int(selectedHour.precipitationProbability.rounded()))% · Wind Direction \(Int(selectedHour.windDirection.rounded()))°")
                    .font(.system(size: 20 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
            }
        }
        .padding(.top, 26 * layoutScale)
        .padding(.bottom, 16)
    }

    private var selectedHour: HourlyForecastPoint? {
        let hourID = selectedHourID ?? snapshot.hourly.first?.id
        return snapshot.hourly.first { $0.id == hourID }
    }

    private func hourAccessibilityLabel(_ point: HourlyForecastPoint) -> String {
        let condition = WeatherCodeMapper.description(for: point.weatherCode, isDay: point.isDay)
        let temperature = point.temperature.formattedTemperature(unit: appState.settings.temperatureUnit)
        let rain = Int(point.precipitationProbability.rounded())
        return "\(point.time.formatted(.monthDayTime, timezoneIdentifier: snapshot.timezoneIdentifier)), \(condition), \(temperature) degrees, rain \(rain) percent, wind \(point.windSpeed.formattedSpeed(system: appState.settings.measurementSystem))"
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
                .font(.system(size: 20 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.70))
            WeatherSymbol(code: point.weatherCode, isDay: point.isDay, size: 29)
            Text(point.temperature.formattedTemperature(unit: unit) + (unit == .celsius ? "℃" : "℉"))
                .font(.system(size: 27 * layoutScale, weight: .bold, design: .rounded))
            HStack(spacing: 3 * layoutScale) {
                Image(systemName: "drop.fill").font(.system(size: 14 * layoutScale))
                Text("\(Int(point.precipitationProbability.rounded()))%")
            }
            .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
            .foregroundStyle(.cyan)
            HStack(spacing: 4 * layoutScale) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 13 * layoutScale, weight: .bold))
                    .rotationEffect(.degrees(point.windDirection))
                Text(point.windSpeed.formattedSpeed(system: measurementSystem))
            }
            .font(.system(size: 16 * layoutScale, weight: .semibold, design: .rounded))
            .foregroundStyle(.mint.opacity(0.88))
        }
        .frame(width: 166 * layoutScale)
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
    @Environment(\.raynLayoutScale) private var layoutScale

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
                .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))
        }
    }
}

private struct WindSpeedChart: View {
    let points: [HourlyForecastPoint]
    let system: MeasurementSystem
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        HStack(spacing: 10 * layoutScale) {
            Label("Wind Speed", systemImage: "wind")
                .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.mint.opacity(0.86))
                .frame(width: 90 * layoutScale, alignment: .leading)

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
                                .font(.system(size: 14 * layoutScale, weight: .semibold, design: .rounded))
                                .foregroundStyle(.mint.opacity(0.9))
                        }
                    }
                }
            }
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .chartYScale(domain: 0...maximumSpeed)
            .frame(height: 58 * layoutScale)

            Text(system == .metric ? "km/h" : "mph")
                .font(.system(size: 16 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.48))
                .frame(width: 48 * layoutScale, alignment: .trailing)
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
