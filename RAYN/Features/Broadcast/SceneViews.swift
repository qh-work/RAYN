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
                eyebrow: "当前天气",
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
                    Text("体感 \(snapshot.current.feelsLike.formattedTemperature(unit: appState.settings.temperatureUnit))°  ·  今日 \(snapshot.current.low.formattedTemperature(unit: appState.settings.temperatureUnit))° / \(snapshot.current.high.formattedTemperature(unit: appState.settings.temperatureUnit))°")
                        .font(.system(size: 23 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                GlassCard(cornerRadius: 26) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("实时观测")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.84))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 22) {
                            MetricTile(symbol: "humidity.fill", title: "湿度", value: "\(Int(snapshot.current.relativeHumidity.rounded()))%", accent: .cyan)
                            MetricTile(symbol: "wind", title: "风速", value: snapshot.current.windSpeed.formattedSpeed(system: appState.settings.measurementSystem), accent: .mint)
                            MetricTile(symbol: "gauge.with.dots.needle.33percent", title: "气压", value: "\(Int(snapshot.current.pressure.rounded())) hPa", accent: .yellow)
                            MetricTile(symbol: "eye.fill", title: "能见度", value: snapshot.current.visibility.formattedDistance(system: appState.settings.measurementSystem), accent: .orange)
                            MetricTile(symbol: "thermometer.medium", title: "露点", value: snapshot.current.dewPoint.formattedTemperature(unit: appState.settings.temperatureUnit) + (appState.settings.temperatureUnit == .celsius ? "℃" : "℉"), accent: .blue)
                            MetricTile(symbol: "cloud.fill", title: "总云量", value: "\(Int(snapshot.current.cloudCover.rounded()))%", accent: .white)
                            MetricTile(symbol: "wind.circle.fill", title: "阵风", value: snapshot.current.windGust.formattedSpeed(system: appState.settings.measurementSystem), accent: .orange)
                            MetricTile(symbol: "drop.fill", title: "降水", value: "\(snapshot.current.precipitation.formattedNumber(decimals: 1)) mm", accent: .cyan)
                        }
                    }
                }
                .frame(width: 560 * layoutScale)
            }
            Spacer(minLength: 0)
            HStack(spacing: 36 * layoutScale) {
                miniFact(symbol: "sunrise.fill", title: "日出", value: snapshot.current.sunrise?.formatted("HH:mm", timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--", tint: .yellow)
                miniFact(symbol: "sunset.fill", title: "日落", value: snapshot.current.sunset?.formatted("HH:mm", timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--", tint: .orange)
                miniFact(symbol: "sun.max.fill", title: "紫外线", value: snapshot.current.uvIndex.formattedNumber(decimals: 1), tint: .yellow)
                miniFact(symbol: "drop.fill", title: "降水概率", value: "\(Int(snapshot.current.precipitationProbability.rounded()))%", tint: .cyan)
                miniFact(symbol: "location.north.line.fill", title: "风向", value: "\(Int(snapshot.current.windDirection.rounded()))°", tint: .mint)
                miniFact(symbol: "cloud.sun.fill", title: "低/中/高云", value: "\(Int(snapshot.current.cloudCoverLow?.rounded() ?? 0))/\(Int(snapshot.current.cloudCoverMid?.rounded() ?? 0))/\(Int(snapshot.current.cloudCoverHigh?.rounded() ?? 0))%", tint: .white)
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
                Text(title).font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.58))
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
                        Text("穿衣指数")
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
            PageHeader(eyebrow: "趋势预报", title: "未来24小时", detail: "温度 · 体感 · 降水 · 风速")
            GlassCard(cornerRadius: 28) {
                VStack(alignment: .leading, spacing: 14) {
                    Chart {
                        ForEach(Array(snapshot.hourly.prefix(24).enumerated()), id: \.offset) { index, point in
                            PointMark(x: .value("时间", point.time), y: .value("温度", point.temperature))
                                .foregroundStyle(.white)
                                .symbolSize(index.isMultiple(of: 3) ? 96 : 62)
                                .annotation(position: .top, spacing: 4) {
                                    if index.isMultiple(of: 3) {
                                        Text("\(point.temperature.formattedTemperature(unit: appState.settings.temperatureUnit))° / \(point.apparentTemperature.formattedTemperature(unit: appState.settings.temperatureUnit))°")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.78))
                                    }
                                }
                            PointMark(x: .value("时间", point.time), y: .value("体感", point.apparentTemperature))
                                .foregroundStyle(.orange.opacity(0.86))
                                .symbolSize(index.isMultiple(of: 3) ? 78 : 48)
                            BarMark(x: .value("时间", point.time), y: .value("降水概率", point.precipitationProbability / 3.0))
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
                            RuleMark(x: .value("当前选择", selected.time))
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
                        ChartLegendItem(title: "温度", color: .white, style: .dot)
                        ChartLegendItem(title: "体感", color: .orange, style: .dot)
                        ChartLegendItem(title: "降水概率", color: .blue, style: .bar)
                        ChartLegendItem(title: "风速", color: .mint, style: .bar)
                        Spacer()
                        Text("蓝柱=降水概率 · 青柱=风速")
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
                Text("已选 \(selectedHour.time.formatted("M月d日 HH:mm", timezoneIdentifier: snapshot.timezoneIdentifier)) · 体感 \(selectedHour.apparentTemperature.formattedTemperature(unit: appState.settings.temperatureUnit))° · 降水 \(Int(selectedHour.precipitationProbability.rounded()))% · 风向 \(Int(selectedHour.windDirection.rounded()))°")
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
            Text(point.time.formatted("HH:mm", timezoneIdentifier: timezone))
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
            Text(title)
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
            Label("风速", systemImage: "wind")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.mint.opacity(0.86))
                .frame(width: 72, alignment: .leading)

            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    BarMark(
                        x: .value("时间", point.time),
                        y: .value("风速", displayedSpeed(point.windSpeed))
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
            PageHeader(eyebrow: "延展预报", title: "未来10天", detail: "上下滑动选择日期 · 按确定查看详情")

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
                            .accessibilityLabel("第 \(index + 1) 天，\(point.date.formatted("M月d日", timezoneIdentifier: snapshot.timezoneIdentifier))")
                            .accessibilityHint("按下确定查看详细天气")
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

            Text("上下滑动浏览全部日期；确定键放大当天预报，返回键回到列表")
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
                Text(ordinal == 0 ? "今天" : point.date.formatted("EEEE", timezoneIdentifier: timezone))
                    .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                Text(point.date.formatted("M月d日", timezoneIdentifier: timezone))
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
                        Text(ordinal == 0 ? "今天详细天气" : "第 \(ordinal + 1) 天详细天气")
                            .font(.system(size: 31 * layoutScale, weight: .bold, design: .rounded))
                        Text(point.date.formatted("yyyy年M月d日 EEEE", timezoneIdentifier: timezone))
                            .font(.system(size: 19 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    Spacer()
                    Button(action: onClose) {
                        Label("收起", systemImage: "chevron.down")
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
                        Text("最高 \(point.high.formattedTemperature(unit: unit))°  ·  最低 \(point.low.formattedTemperature(unit: unit))°")
                            .font(.system(size: 25 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer()
                    detailMetric(symbol: "drop.fill", title: "降水概率", value: "\(Int(point.precipitationProbability.rounded()))%", tint: .cyan)
                    detailMetric(symbol: "wind", title: "最大风速", value: point.windSpeed.formattedSpeed(system: measurementSystem), tint: .mint)
                    detailMetric(symbol: "sun.max.fill", title: "紫外线", value: point.uvIndex?.formattedNumber(decimals: 1) ?? "--", tint: .yellow)
                }

                HStack(spacing: 42 * layoutScale) {
                    detailFact(symbol: "sunrise.fill", title: "日出", value: point.sunrise?.formatted("HH:mm", timezoneIdentifier: timezone) ?? "--:--", tint: .yellow)
                    detailFact(symbol: "sunset.fill", title: "日落", value: point.sunset?.formatted("HH:mm", timezoneIdentifier: timezone) ?? "--:--", tint: .orange)
                    detailFact(symbol: "clock.fill", title: "白昼", value: daylightText, tint: .cyan)
                    detailFact(symbol: "wind", title: "阵风", value: point.windGust.formattedSpeed(system: measurementSystem), tint: .orange)
                    detailFact(symbol: "drop", title: "预计降水", value: "\(point.precipitation.formattedNumber(decimals: 1)) mm", tint: .blue)
                }
                HStack(spacing: 16 * layoutScale) {
                    if let onPrevious {
                        Button(action: onPrevious) {
                            Label("上一天", systemImage: "chevron.left")
                                .frame(minWidth: 150 * layoutScale)
                                .foregroundStyle(focusedControl == .previous ? Color(hex: 0x082A3D) : .white)
                        }
                        .buttonStyle(.glass)
                        .focused($focusedControl, equals: .previous)
                    }
                    if let onNext {
                        Button(action: onNext) {
                            Label("下一天", systemImage: "chevron.right")
                                .frame(minWidth: 150 * layoutScale)
                                .foregroundStyle(focusedControl == .next ? Color(hex: 0x082A3D) : .white)
                        }
                        .buttonStyle(.glass)
                        .focused($focusedControl, equals: .next)
                    }
                    Spacer()
                    Text("返回键收起详情")
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
        return "\(minutes / 60)小时\(minutes % 60)分"
    }

    private func detailMetric(symbol: String, title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: 22 * layoutScale, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
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
                Text(title)
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
                eyebrow: "雷达监测",
                title: "降水雷达",
                detail: hasNowcast ? "观测回放 · 临近趋势" : "过去两小时回放"
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
                        Text(frameDate?.formatted("HH:mm", timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                        if requestedIndex != presentedIndex {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white.opacity(0.75))
                        }
                    }
                    Text(displayedFrame?.isForecast == true ? "临近趋势 · 周边天气系统" : "过去约2小时 · 周边天气系统")
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
                Text("动画控制").font(.system(size: 24, weight: .bold, design: .rounded))
                Button {
                    isPlaying.toggle()
                } label: {
                    Label(isPlaying ? "暂停雷达" : "播放雷达", systemImage: isPlaying ? "pause.fill" : "play.fill")
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
                    Text("第 \(snapshot.radar.frames.isEmpty ? 0 : presentedIndex + 1) / \(snapshot.radar.frames.count) 帧")
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
                    Text("较早").foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Text("较新").foregroundStyle(.white.opacity(0.55))
                }
                .font(.system(size: 17, weight: .medium, design: .rounded))
                RadarLegend()
                Text("覆盖范围以实际雷达数据为准")
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
                    Text("当前没有可用的实时雷达回波")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(snapshot.radar.message ?? "此位置暂时没有可用雷达覆盖；不会用演示图替代。")
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
                Text("降水回放")
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
                Text("实体 Apple TV 显示实时雷达地图")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(frame == nil ? "当前没有可用雷达帧" : "模拟器不渲染实时地图瓦片")
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
                Text("正在准备实时雷达")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                Text("天气页面已就绪，地图随后载入")
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
                Text("当前雷达帧没有可用地图瓦片")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                Text("保留真实时间，不显示替代回波")
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
            Text("降水强度").font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.68))
            HStack(spacing: 0) {
                ForEach([Color.blue, Color.cyan, Color.green, Color.yellow, Color.orange, Color.red], id: \.self) { color in
                    Rectangle().fill(color).frame(maxWidth: .infinity).frame(height: 10)
                }
            }
            HStack {
                Text("弱").foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text("强").foregroundStyle(.white.opacity(0.55))
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
            PageHeader(eyebrow: "环境", title: "空气质量", detail: "当前与未来趋势")
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
                            Text("空气质量暂时没有更新")
                                .font(.system(size: 27 * layoutScale, weight: .semibold, design: .rounded))
                            Text("实时天气仍可正常查看。")
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
                    Text("当前空气")
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
                        Text("更新于 \(air.updatedAt.formatted("HH:mm", timezoneIdentifier: timezone))")
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
                Text("污染物")
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
                    Text("未来24小时")
                        .font(.system(size: 23 * layoutScale, weight: .bold, design: .rounded))
                    Spacer()
                    Text("AQI")
                        .font(.system(size: 16 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.48))
                }
                if values.isEmpty {
                    Text("暂无逐小时数据")
                        .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, minHeight: 112 * layoutScale)
                } else {
                    Chart {
                        ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                            BarMark(x: .value("小时", index), y: .value("AQI", value))
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
        return date.formatted("HH:mm", timezoneIdentifier: timezone)
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
                Text("优")
                Spacer()
                Text("良")
                Spacer()
                Text("轻度")
                Spacer()
                Text("较差")
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
                eyebrow: snapshot.marine == nil ? "天文" : "天文与海况",
                title: snapshot.marine == nil ? "日照与月相" : "日照、月相与海况",
                detail: "此刻状态与未来变化"
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
                    Label("太阳", systemImage: "sun.max.fill")
                        .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                    Spacer()
                    Text(solarState)
                        .font(.system(size: 16 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(solarState == "白昼" ? .yellow : .indigo.opacity(0.95))
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
                        title: "今日白昼",
                        value: daylightText,
                        accent: .yellow
                    )
                    AstronomyMetric(
                        symbol: tomorrowChangeSymbol,
                        title: "明日变化",
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
            return "\(minutes / 60)小时\(minutes % 60)分"
        }
        guard let sunrise = snapshot.current.sunrise, let sunset = snapshot.current.sunset else { return "--" }
        let minutes = Int(sunset.timeIntervalSince(sunrise) / 60)
        return "\(minutes / 60)小时\(minutes % 60)分"
    }

    private var solarState: String {
        guard let sunrise = snapshot.current.sunrise, let sunset = snapshot.current.sunset else { return "天文数据缺失" }
        return Date() >= sunrise && Date() <= sunset ? "白昼" : "夜间"
    }

    private var tomorrowDaylightChange: String {
        guard snapshot.daily.count >= 2,
              let today = duration(for: snapshot.daily[0]),
              let tomorrow = duration(for: snapshot.daily[1]) else { return "--" }
        let minutes = Int(((tomorrow - today) / 60).rounded())
        if abs(minutes) < 1 { return "基本不变" }
        return minutes > 0 ? "增加 \(minutes) 分" : "减少 \(abs(minutes)) 分"
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
                Text(title)
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
            Text("未来10天日照变化")
                .font(.system(size: 16 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
            HStack(spacing: 8 * layoutScale) {
                ForEach(Array(daily.prefix(10).enumerated()), id: \.element.id) { index, point in
                    VStack(alignment: .leading, spacing: 6 * layoutScale) {
                        Text(index == 0 ? "今天" : point.date.formatted("E", timezoneIdentifier: timezone))
                            .font(.system(size: 14 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.76))
                        Text(point.date.formatted("M/d", timezoneIdentifier: timezone))
                            .font(.system(size: 12 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                        SunlightDayBar(point: point, timezone: timezone)
                            .frame(height: 24 * layoutScale)
                        HStack {
                            Text(point.sunrise?.formatted("HH:mm", timezoneIdentifier: timezone) ?? "--:--")
                            Spacer()
                            Text(point.sunset?.formatted("HH:mm", timezoneIdentifier: timezone) ?? "--:--")
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
                    Label("月相", systemImage: "moon.stars.fill")
                        .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                    Spacer()
                    Text("月龄 \(info.age.formattedNumber(decimals: 1)) 天")
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
                    Text("照明度 \(Int((info.illumination * 100).rounded()))%")
                        .font(.system(size: 17 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }

                HStack(spacing: 10 * layoutScale) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow.opacity(0.85))
                    VStack(alignment: .leading, spacing: 2 * layoutScale) {
                        Text("下一主要月相")
                            .font(.system(size: 13 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.48))
                        Text("\(info.nextPhaseTitle) · \(info.nextPhaseDate.formatted("M月d日", timezoneIdentifier: timezone))")
                            .font(.system(size: 17 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .padding(11 * layoutScale)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14 * layoutScale, style: .continuous))

                Text("未来7天月相")
                    .font(.system(size: 15 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.54))

                HStack(spacing: 6 * layoutScale) {
                    ForEach(Array(daily.prefix(7).enumerated()), id: \.element.id) { index, point in
                        let dayInfo = MoonPhaseCalculator.info(at: point.date)
                        VStack(spacing: 5 * layoutScale) {
                            Text(index == 0 ? "今" : point.date.formatted("E", timezoneIdentifier: timezone))
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
        .accessibilityLabel("\(info.title)，照明度 \(Int((info.illumination * 100).rounded()))%")
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
                        Text("海况 · \(waveState(marine.waveHeight))")
                            .font(.system(size: 15 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.60))
                        Text("\(marine.waveHeight.formattedNumber(decimals: 1)) m")
                            .font(.system(size: 35 * layoutScale, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("有效浪高 · \(marine.updatedAt.formatted("HH:mm", timezoneIdentifier: timezone)) 更新")
                            .font(.system(size: 12 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                    }
                }
                .frame(width: 285 * layoutScale, alignment: .leading)

                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 1, height: 90 * layoutScale)

                VStack(alignment: .leading, spacing: 4 * layoutScale) {
                    Text("未来24小时浪高")
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
                    MarineCompactMetric(symbol: "timer", title: "周期", value: "\(marine.wavePeriod.formattedNumber(decimals: 1)) s", accent: .yellow)
                    MarineCompactMetric(symbol: "location.north.line.fill", title: "浪向", value: "\(Int(marine.waveDirection.rounded()))° \(compassDirection(marine.waveDirection))", accent: .mint)
                    MarineCompactMetric(symbol: "wind", title: "风浪", value: "\(marine.windWaveHeight.formattedNumber(decimals: 1)) m", accent: .orange)
                    MarineCompactMetric(symbol: "water.waves", title: "涌浪", value: "\(marine.swellWaveHeight.formattedNumber(decimals: 1)) m", accent: .cyan)
                    MarineCompactMetric(symbol: "thermometer.medium", title: "海温", value: marine.seaSurfaceTemperature.map { "\($0.formattedNumber(decimals: 1))℃" } ?? "--", accent: .pink)
                    MarineCompactMetric(symbol: "arrow.trianglehead.branch", title: "海流", value: currentText(marine), accent: .blue)
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
        case ..<0.5: return "平缓"
        case ..<1.25: return "轻浪"
        case ..<2.5: return "中浪"
        default: return "大浪"
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
        let labels = ["北", "东北", "东", "东南", "南", "西南", "西", "西北"]
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return labels[Int((normalized / 45).rounded()) % labels.count]
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
                Text("短时趋势正在更新")
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
                        Text(point.time.formatted("HH时", timezoneIdentifier: timezone))
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
                Text(title)
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
                        Text("24小时日照时间线")
                            .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                        Spacer()
                        Text("现在 \(context.date.formatted("HH:mm", timezoneIdentifier: timezone))")
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
                        Label(sunrise.map { $0.formatted("HH:mm", timezoneIdentifier: timezone) } ?? "--:--", systemImage: "sunrise.fill")
                        Spacer()
                        Text("日出至日落")
                            .foregroundStyle(.white.opacity(0.50))
                        Spacer()
                        Label(sunset.map { $0.formatted("HH:mm", timezoneIdentifier: timezone) } ?? "--:--", systemImage: "sunset.fill")
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
