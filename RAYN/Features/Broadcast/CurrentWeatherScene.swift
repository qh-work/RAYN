import SwiftUI


struct CurrentWeatherScene: View {
    let snapshot: WeatherSnapshot
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        let clothing = ClothingAdviceBuilder.make(from: snapshot.current)
        let advisories = WeatherAdvisoryBuilder.make(from: snapshot)

        VStack(alignment: .leading, spacing: 18 * layoutScale) {
            HStack(alignment: .center, spacing: 46 * layoutScale) {
                VStack(alignment: .center, spacing: 7 * layoutScale) {
                    Text("Current Weather")
                        .font(.system(size: 18 * layoutScale, weight: .bold, design: .rounded))
                        .tracking(2.2 * layoutScale)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.62))

                    HStack(alignment: .center, spacing: 18 * layoutScale) {
                        TemperatureText(
                            value: snapshot.current.temperature,
                            unit: appState.settings.temperatureUnit,
                            fontSize: 154
                        )
                        WeatherSymbol(
                            code: snapshot.current.weatherCode,
                            isDay: snapshot.current.isDay,
                            size: 76
                        )
                    }

                    Text(WeatherCodeMapper.description(
                        for: snapshot.current.weatherCode,
                        isDay: snapshot.current.isDay,
                        visibility: snapshot.current.visibility
                    ))
                    .font(.system(size: 34 * layoutScale, weight: .semibold, design: .rounded))

                    Text("Feels like \(snapshot.current.feelsLike.formattedTemperature(unit: appState.settings.temperatureUnit))°  ·  Today \(snapshot.current.low.formattedTemperature(unit: appState.settings.temperatureUnit))° / \(snapshot.current.high.formattedTemperature(unit: appState.settings.temperatureUnit))°")
                        .font(.system(size: 23 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(verbatim: "\(snapshot.location.name), \(WeatherCodeMapper.description(for: snapshot.current.weatherCode, isDay: snapshot.current.isDay, visibility: snapshot.current.visibility)), \(snapshot.current.temperature.formattedTemperature(unit: appState.settings.temperatureUnit)) degrees"))

                VStack(spacing: 14 * layoutScale) {
                    if let advisory = advisories.first {
                        WeatherAdvisoryCard(advisory: advisory)
                    }

                    GlassCard(cornerRadius: 28) {
                        VStack(alignment: .leading, spacing: 18 * layoutScale) {
                            Text("Live Observations")
                                .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.86))
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 20 * layoutScale
                            ) {
                                MetricTile(symbol: "humidity.fill", title: String(localized: "Humidity"), value: "\(Int(snapshot.current.relativeHumidity.rounded()))%", accent: .cyan)
                                MetricTile(symbol: "wind", title: String(localized: "Wind Speed"), value: snapshot.current.windSpeed.formattedSpeed(system: appState.settings.measurementSystem), accent: .mint)
                                MetricTile(symbol: "eye.fill", title: String(localized: "Visibility"), value: snapshot.current.visibility.formattedDistance(system: appState.settings.measurementSystem), accent: .orange)
                                MetricTile(symbol: "drop.fill", title: String(localized: "Rain Chance"), value: "\(Int(snapshot.current.precipitationProbability.rounded()))%", accent: .cyan)
                            }
                        }
                    }
                }
                .frame(width: 710 * layoutScale)
            }

            HStack(alignment: .center, spacing: 18 * layoutScale) {
                ClothingAdviceCard(advice: clothing)
                    .frame(maxWidth: .infinity)
                CurrentWeatherFactsCard(snapshot: snapshot)
                    .frame(width: 780 * layoutScale)
            }
        }
        .padding(.top, 20 * layoutScale)
        .padding(.bottom, 16)
    }
}

private struct CurrentWeatherFactsCard: View {
    let snapshot: WeatherSnapshot
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 18 * layoutScale) {
                fact(symbol: "sunrise.fill", title: String(localized: "Sunrise"), value: snapshot.current.sunrise?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--", tint: .yellow)
                fact(symbol: "sunset.fill", title: String(localized: "Sunset"), value: snapshot.current.sunset?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--", tint: .orange)
                fact(symbol: "sun.max.fill", title: String(localized: "UV Index"), value: snapshot.current.uvIndex.formattedNumber(decimals: 1), tint: .yellow)
                fact(symbol: "gauge.with.dots.needle.33percent", title: String(localized: "Pressure"), value: "\(Int(snapshot.current.pressure.rounded())) hPa", tint: .mint)
            }
        }
    }

    private func fact(symbol: String, title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 5 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: 23 * layoutScale, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 15 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))
            Text(value)
                .font(.system(size: 21 * layoutScale, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
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

private struct WeatherAdvisoryCard: View {
    let advisory: WeatherAdvisory
    @Environment(\.raynLayoutScale) private var layoutScale

    private var tint: Color {
        switch advisory.level {
        case .warning: return .red
        case .caution: return .yellow
        }
    }

    var body: some View {
        GlassCard(cornerRadius: 22, tint: tint) {
            HStack(alignment: .top, spacing: 14 * layoutScale) {
                Image(systemName: advisory.symbolName)
                    .font(.system(size: 28 * layoutScale, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42 * layoutScale, height: 42 * layoutScale)
                    .background(tint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4 * layoutScale) {
                    Text(advisory.isOfficial ? String(localized: "Weather Alert") : String(localized: "Weather Notice"))
                        .font(.system(size: 14 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                    Text(advisory.title)
                        .font(.system(size: 20 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(advisory.detail)
                        .font(.system(size: 15 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.64))
                        .lineLimit(3)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
