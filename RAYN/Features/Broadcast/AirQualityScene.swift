import Charts
import SwiftUI

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
                        .frame(width: 620 * layoutScale, height: 298 * layoutScale)
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

/// The home screen shows air quality as an environmental sub-panel. Selecting
/// it opens this scene's full pollutant and hourly trend view without keeping
/// a separate top-level navigation tab on the broadcast header.
struct AirQualitySummaryButton: View {
    let air: AirQualitySnapshot?
    let timezone: String
    let onOpen: () -> Void
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        if let air {
            Button(action: onOpen) {
                HStack(spacing: 12 * layoutScale) {
                    Image(systemName: "aqi.medium")
                        .font(.system(size: 25 * layoutScale, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(aqiColor(air.europeanAQI))

                    VStack(alignment: .leading, spacing: 2 * layoutScale) {
                        Text("Air Quality")
                            .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.58))
                        Text(air.level)
                            .font(.system(size: 22 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(aqiColor(air.europeanAQI))
                    }

                    Spacer(minLength: 8 * layoutScale)

                    VStack(alignment: .trailing, spacing: 2 * layoutScale) {
                        Text(verbatim: "AQI \(Int(air.europeanAQI.rounded()))")
                            .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("Updated \(air.updatedAt.formatted(.time, timezoneIdentifier: timezone))")
                            .font(.system(size: 14 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.46))
                            .monospacedDigit()
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16 * layoutScale, weight: .bold))
                        .foregroundStyle(.white.opacity(0.42))
                }
                .padding(.horizontal, 16 * layoutScale)
                .padding(.vertical, 10 * layoutScale)
                .background(
                    aqiColor(air.europeanAQI).opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 17 * layoutScale, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 17 * layoutScale, style: .continuous)
                        .stroke(aqiColor(air.europeanAQI).opacity(0.28), lineWidth: 1)
                }
            }
            .buttonStyle(FocusButtonStyle())
            .foregroundStyle(.white)
            .accessibilityLabel(
                Text(verbatim: "Air quality, AQI \(Int(air.europeanAQI.rounded())), \(air.level)")
            )
        } else {
            HStack(spacing: 12 * layoutScale) {
                Image(systemName: "aqi.medium")
                    .font(.system(size: 25 * layoutScale, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.48))
                Text("Air-quality data is currently unavailable.")
                    .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.54))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16 * layoutScale)
            .padding(.vertical, 12 * layoutScale)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 17 * layoutScale, style: .continuous))
        }
    }
}

private func aqiColor(_ value: Double) -> Color {
    switch value {
    case ..<20: return .green
    case ..<40: return .mint
    case ..<60: return .yellow
    case ..<80: return .orange
    case ..<100: return .red
    default: return .purple
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
            VStack(alignment: .leading, spacing: 13 * layoutScale) {
                HStack(alignment: .center, spacing: 20 * layoutScale) {
                    Text("\(Int(air.europeanAQI.rounded()))")
                        .font(.system(size: 78 * layoutScale, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 2 * layoutScale) {
                        Text("European AQI")
                            .font(.system(size: 19 * layoutScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.54))
                        Text(air.level)
                            .font(.system(size: 32 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(aqiColor(air.europeanAQI))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "aqi.medium")
                        .font(.system(size: 48 * layoutScale, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(aqiColor(air.europeanAQI))
                }

                AQIGradientScale(value: air.europeanAQI, showsLabels: true)

                Text(air.advice)
                    .font(.system(size: 20 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                DataFreshnessLabel(
                    updatedAt: air.updatedAt,
                    fetchedAt: air.fetchedAt,
                    timezoneIdentifier: timezone,
                    alignment: .leading
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "European AQI \(Int(air.europeanAQI.rounded())), \(air.level). \(air.advice)"))
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
                    .font(.system(size: 19 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
            }
            Text(pollutant.value.formattedNumber(decimals: pollutant.value < 10 ? 1 : 0))
                .font(.system(size: 27 * layoutScale, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(pollutant.unit)
                .font(.system(size: 16 * layoutScale, weight: .medium, design: .rounded))
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
                        .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.48))
                }
                if values.isEmpty {
                    Text("No hourly data is available")
                        .font(.system(size: 20 * layoutScale, weight: .medium, design: .rounded))
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
                                            .font(.system(size: 14 * layoutScale, weight: .semibold, design: .rounded))
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
                                        .font(.system(size: 14 * layoutScale, weight: .medium, design: .rounded))
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
                                        .font(.system(size: 16 * layoutScale, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.48))
                                }
                            }
                        }
                    }
                    .chartYScale(domain: 0...max(values.max() ?? 80, 80))
                    .frame(height: 142 * layoutScale)
                }
                AQIGradientScale(value: nil, showsLabels: true)
            }
        }
    }

    private func hourLabel(_ index: Int) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(bySettingHour: index % 24, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.time, timezoneIdentifier: timezone)
    }
}

private struct AQIGradientScale: View {
    let value: Double?
    let showsLabels: Bool
    @Environment(\.raynLayoutScale) private var layoutScale

    private let colors: [Color] = [.green, .mint, .yellow, .orange, .red, .purple]

    var body: some View {
        VStack(alignment: .leading, spacing: 6 * layoutScale) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    HStack(spacing: 3 * layoutScale) {
                        ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                            Capsule()
                                .fill(color.opacity(0.86))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    if let value {
                        Circle()
                            .fill(.white)
                            .frame(width: 18 * layoutScale, height: 18 * layoutScale)
                            .overlay(Circle().stroke(.black.opacity(0.25), lineWidth: 2 * layoutScale))
                            .shadow(color: .black.opacity(0.35), radius: 5 * layoutScale, y: 2 * layoutScale)
                            .offset(x: markerOffset(for: value, width: geometry.size.width))
                    }
                }
            }
            .frame(height: 18 * layoutScale)

            if showsLabels {
                HStack {
                    Text(verbatim: "0")
                    Spacer()
                    Text(verbatim: "20")
                    Spacer()
                    Text(verbatim: "40")
                    Spacer()
                    Text(verbatim: "60")
                    Spacer()
                    Text(verbatim: "80")
                    Spacer()
                    Text(verbatim: "100+")
                }
                .font(.system(size: 15 * layoutScale, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.48))
            }
        }
    }

    private func markerOffset(for value: Double, width: CGFloat) -> CGFloat {
        let markerWidth = 18 * layoutScale
        let fraction = min(max(value / 120, 0), 1)
        return (width - markerWidth) * fraction
    }
}
