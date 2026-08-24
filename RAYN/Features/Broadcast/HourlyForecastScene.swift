import SwiftUI

struct HourlyForecastScene: View {
    let snapshot: WeatherSnapshot
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale
    @State private var selectedHourID: Date?
    @Namespace private var hourlyFocusScope

    var body: some View {
        VStack(alignment: .leading, spacing: 18 * layoutScale) {
            PageHeader(
                eyebrow: String(localized: "Forecast"),
                title: String(localized: "Next 24 Hours"),
                detail: String(localized: "Temperature · Feels Like · Rain · Wind")
            )
            GlassCard(cornerRadius: 28) {
                VStack(alignment: .leading, spacing: 11 * layoutScale) {
                    HourlyWeatherCanvas(
                        points: Array(snapshot.hourly.prefix(24)),
                        unit: appState.settings.temperatureUnit,
                        selectedPoint: selectedHour
                    )
                    .frame(height: 162 * layoutScale)

                    WindSpeedBarsCanvas(
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
                                isSelected: selectedHourID == point.id
                            )
                        }
                        .buttonStyle(HourlyForecastCardButtonStyle())
                        .foregroundStyle(.white)
                        .prefersDefaultFocus(
                            point.id == snapshot.hourly.first?.id,
                            in: hourlyFocusScope
                        )
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
            .focusScope(hourlyFocusScope)
            if let selectedHour {
                Text("Selected \(selectedHour.time.formatted(.monthDayTime, timezoneIdentifier: snapshot.timezoneIdentifier)) · Feels like \(selectedHour.apparentTemperature.formattedTemperature(unit: appState.settings.temperatureUnit))° · Rain \(Int(selectedHour.precipitationProbability.rounded()))% · Wind Direction \(Int(selectedHour.windDirection.rounded()))°")
                    .font(.system(size: 20 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
            }
        }
        // Preserve the larger television type while keeping the persistent
        // live ticker inside the safe area beneath the taller location header.
        .padding(.top, 22 * layoutScale)
    }

    private var selectedHour: HourlyForecastPoint? {
        guard let selectedHourID else { return nil }
        return snapshot.hourly.first { $0.id == selectedHourID }
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

private struct HourlyForecastCardButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.raynLayoutScale) private var layoutScale

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                RoundedRectangle(cornerRadius: 18 * layoutScale, style: .continuous)
                    .stroke(
                        isFocused ? Color.white.opacity(0.42) : .clear,
                        lineWidth: 1.5 * layoutScale
                    )
            }
            .scaleEffect(isFocused ? 1.025 : 1)
            .brightness(isFocused ? 0.05 : 0)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.12), value: isFocused)
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

private struct HourlyWeatherCanvas: View {
    let points: [HourlyForecastPoint]
    let unit: TemperatureUnit
    let selectedPoint: HourlyForecastPoint?
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            guard !points.isEmpty else { return }
            let top = 12 * layoutScale
            let bottom = size.height - 24 * layoutScale
            let temperatureValues = points.flatMap { [$0.temperature, $0.apparentTemperature] }
            let minimum = (temperatureValues.min() ?? 0) - 1
            let maximum = (temperatureValues.max() ?? 1) + 1
            let span = max(maximum - minimum, 1)
            let step = points.count == 1 ? size.width : size.width / CGFloat(points.count - 1)
            let rainBarWidth = max(4 * layoutScale, min(16 * layoutScale, step * 0.34))

            for fraction in stride(from: 0.0, through: 1.0, by: 0.5) {
                let y = top + (bottom - top) * CGFloat(fraction)
                var grid = Path()
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    grid,
                    with: .color(.white.opacity(0.12)),
                    style: StrokeStyle(lineWidth: 1, dash: [4 * layoutScale, 6 * layoutScale])
                )
            }

            for (index, point) in points.enumerated() {
                let x = points.count == 1 ? size.width / 2 : CGFloat(index) * step
                let rainFraction = min(max(point.precipitationProbability / 100, 0), 1)
                let rainHeight = (bottom - top) * rainFraction * 0.36
                let barRect = CGRect(
                    x: x - rainBarWidth / 2,
                    y: bottom - rainHeight,
                    width: rainBarWidth,
                    height: max(2 * layoutScale, rainHeight)
                )
                context.fill(
                    Path(roundedRect: barRect, cornerRadius: 3 * layoutScale),
                    with: .color(.blue.opacity(0.48))
                )

                let temperatureY = top + (maximum - point.temperature) / span * (bottom - top)
                let apparentY = top + (maximum - point.apparentTemperature) / span * (bottom - top)
                fillPoint(
                    &context,
                    at: CGPoint(x: x, y: temperatureY),
                    radius: index.isMultiple(of: 3) ? 5 * layoutScale : 3.5 * layoutScale,
                    color: .white
                )
                fillPoint(
                    &context,
                    at: CGPoint(x: x, y: apparentY),
                    radius: index.isMultiple(of: 3) ? 4.5 * layoutScale : 3 * layoutScale,
                    color: .orange.opacity(0.90)
                )

                guard index.isMultiple(of: 3) else { continue }
                context.draw(
                    Text("\(point.temperature.formattedTemperature(unit: unit))° / \(point.apparentTemperature.formattedTemperature(unit: unit))°")
                        .font(.system(size: 13 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78)),
                    at: CGPoint(x: x, y: max(8 * layoutScale, min(temperatureY, apparentY) - 13 * layoutScale))
                )
                context.draw(
                    Text("\(Int(point.precipitationProbability.rounded()))%")
                        .font(.system(size: 12 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.cyan.opacity(0.92)),
                    at: CGPoint(x: x, y: max(8 * layoutScale, bottom - rainHeight - 12 * layoutScale))
                )
            }

            if let selectedPoint,
               let selectedIndex = points.firstIndex(where: { $0.id == selectedPoint.id }) {
                let x = points.count == 1 ? size.width / 2 : CGFloat(selectedIndex) * step
                var selection = Path()
                selection.move(to: CGPoint(x: x, y: top))
                selection.addLine(to: CGPoint(x: x, y: bottom))
                context.stroke(
                    selection,
                    with: .color(.yellow.opacity(0.82)),
                    style: StrokeStyle(lineWidth: 2 * layoutScale, dash: [5 * layoutScale, 5 * layoutScale])
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("24-hour temperature, feels-like, rain probability, and wind chart")
    }

    private func fillPoint(
        _ context: inout GraphicsContext,
        at point: CGPoint,
        radius: CGFloat,
        color: Color
    ) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: .color(color))
    }
}

private struct WindSpeedBarsCanvas: View {
    let points: [HourlyForecastPoint]
    let system: MeasurementSystem
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        HStack(spacing: 10 * layoutScale) {
            Label("Wind Speed", systemImage: "wind")
                .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.mint.opacity(0.86))
                .frame(width: 90 * layoutScale, alignment: .leading)

            Canvas(rendersAsynchronously: true) { context, size in
                guard !points.isEmpty else { return }
                let maximum = maximumSpeed
                let step = size.width / CGFloat(max(points.count, 1))
                let barWidth = max(3 * layoutScale, step * 0.58)
                for (index, point) in points.enumerated() {
                    let value = displayedSpeed(point.windSpeed)
                    let height = max(2 * layoutScale, size.height * CGFloat(value / maximum))
                    let x = step * (CGFloat(index) + 0.5) - barWidth / 2
                    let rect = CGRect(x: x, y: size.height - height, width: barWidth, height: height)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2 * layoutScale),
                        with: .color(.mint.opacity(index.isMultiple(of: 3) ? 0.95 : 0.68))
                    )
                    if index.isMultiple(of: 3) {
                        context.draw(
                            Text(value.formattedNumber(decimals: 0))
                                .font(.system(size: 12 * layoutScale, weight: .semibold, design: .rounded))
                                .foregroundStyle(.mint.opacity(0.90)),
                            at: CGPoint(x: x + barWidth / 2, y: max(7 * layoutScale, size.height - height - 8 * layoutScale))
                        )
                    }
                }
            }
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
