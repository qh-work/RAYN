import SwiftUI


struct CurrentWeatherScene: View {
    let snapshot: WeatherSnapshot
    let onOpenAirQuality: () -> Void
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        let clothing = ClothingAdviceBuilder.make(from: snapshot.current)
        let advisories = WeatherAdvisoryBuilder.make(from: snapshot)

        VStack(alignment: .center, spacing: 24 * layoutScale) {
            HStack(alignment: .center, spacing: 24 * layoutScale) {
                CurrentWeatherHeroCard(snapshot: snapshot)
                    .frame(maxWidth: .infinity)
                CurrentWeatherObservationsCard(
                    snapshot: snapshot,
                    advisory: advisories.first,
                    onOpenAirQuality: onOpenAirQuality
                )
                    .frame(maxWidth: .infinity)
            }
            .frame(minHeight: (advisories.isEmpty ? 310 : 360) * layoutScale)
            .accessibilityElement(children: .contain)

            HStack(alignment: .center, spacing: 24 * layoutScale) {
                ClothingAdviceCard(advice: clothing)
                    .frame(maxWidth: .infinity)
                CurrentWeatherFactsCard(snapshot: snapshot)
                    .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 176 * layoutScale)
        }
        .padding(.top, 18 * layoutScale)
        .padding(.bottom, 16)
    }
}

private struct CurrentWeatherHeroCard: View {
    let snapshot: WeatherSnapshot
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: RAYNDesign.Radius.heroCard) {
            HStack(spacing: 64 * layoutScale) {
                VStack(spacing: 8 * layoutScale) {
                    Text("Temperature")
                        .font(.system(size: 22 * layoutScale, weight: .bold, design: .rounded))
                        .tracking(1.5 * layoutScale)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.54))

                    TemperatureText(
                        value: snapshot.current.temperature,
                        unit: appState.settings.temperatureUnit,
                        fontSize: 136
                    )

                    HStack(spacing: 8 * layoutScale) {
                        Text("Feels Like")
                        Text(verbatim: "\(snapshot.current.feelsLike.formattedTemperature(unit: appState.settings.temperatureUnit))°")
                            .foregroundStyle(.white)
                    }
                    .font(.system(size: 25 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 7 * layoutScale) {
                    Text("Today")
                        .font(.system(size: 22 * layoutScale, weight: .bold, design: .rounded))
                        .tracking(1.5 * layoutScale)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.54))

                    WeatherSymbol(
                        code: snapshot.current.weatherCode,
                        isDay: snapshot.current.isDay,
                        size: 84
                    )

                    Text(WeatherCodeMapper.description(
                        for: snapshot.current.weatherCode,
                        isDay: snapshot.current.isDay,
                        visibility: snapshot.current.visibility
                    ))
                    .font(.system(size: 33 * layoutScale, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                    Text(verbatim: "\(snapshot.current.low.formattedTemperature(unit: appState.settings.temperatureUnit))°  /  \(snapshot.current.high.formattedTemperature(unit: appState.settings.temperatureUnit))°")
                        .font(.system(size: 25 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(snapshot.location.name), \(WeatherCodeMapper.description(for: snapshot.current.weatherCode, isDay: snapshot.current.isDay, visibility: snapshot.current.visibility)), \(snapshot.current.temperature.formattedTemperature(unit: appState.settings.temperatureUnit)) degrees"))
    }
}

private struct CurrentWeatherObservationsCard: View {
    let snapshot: WeatherSnapshot
    let advisory: WeatherAdvisory?
    let onOpenAirQuality: () -> Void
    @EnvironmentObject private var appState: AppState
    @Environment(\.raynLayoutScale) private var layoutScale
    @State private var showsAlerts = false

    var body: some View {
        GlassCard(cornerRadius: RAYNDesign.Radius.heroCard) {
            VStack(spacing: advisory == nil ? 20 * layoutScale : 12 * layoutScale) {
                Text("Current Conditions")
                    .font(.system(size: 26 * layoutScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .frame(maxWidth: .infinity, alignment: .center)

                if let advisory {
                    WeatherAdvisoryRow(advisory: advisory)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: advisory == nil ? 22 * layoutScale : 14 * layoutScale
                ) {
                    MetricTile(symbol: "humidity.fill", title: String(localized: "Humidity"), value: "\(Int(snapshot.current.relativeHumidity.rounded()))%", accent: .cyan)
                    MetricTile(symbol: "wind", title: String(localized: "Wind Speed"), value: snapshot.current.windSpeed.formattedSpeed(system: appState.settings.measurementSystem), accent: .mint)
                    MetricTile(symbol: "eye.fill", title: String(localized: "Visibility"), value: snapshot.current.visibility.formattedDistance(system: appState.settings.measurementSystem), accent: .orange)
                    MetricTile(symbol: "drop.fill", title: String(localized: "Rain Chance"), value: "\(Int(snapshot.current.precipitationProbability.rounded()))%", accent: .cyan)
                }

                AirQualitySummaryButton(
                    air: snapshot.airQuality,
                    timezone: snapshot.timezoneIdentifier,
                    onOpen: onOpenAirQuality
                )
                if (snapshot.alertAvailability != nil && snapshot.alertAvailability != .unsupported) || !snapshot.alerts.isEmpty {
                    Button {
                        showsAlerts = true
                    } label: {
                        Label("Official Alerts", systemImage: "exclamationmark.shield")
                            .font(.system(size: 23 * layoutScale, weight: .semibold))
                    }
                    .buttonStyle(.glass)
                    .focusAdaptiveGlassForeground()
                    .accessibilityIdentifier("official-alerts")
                }
            }
            .frame(maxHeight: .infinity)
        }
        .fullScreenCover(isPresented: $showsAlerts) {
            OfficialAlertsView(snapshot: snapshot)
        }
    }
}

private struct OfficialAlertsView: View {
    let snapshot: WeatherSnapshot
    @Environment(\.dismiss) private var dismiss
    private var activeAlerts: [WeatherAlertItem] {
        snapshot.alerts.filter { $0.startDate <= Date() && $0.endDate > Date() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack {
                Text("Official Alerts").font(.largeTitle.bold())
                Spacer()
                Button("Close") { dismiss() }.buttonStyle(.glass)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if snapshot.alertAvailability == .unavailable {
                        Text("Alert updates unavailable").foregroundStyle(.yellow)
                    } else if snapshot.alertAvailability == .unsupported && snapshot.alerts.isEmpty {
                        Text("Official alerts are not supported for this location.")
                    } else if activeAlerts.isEmpty {
                        Text("No active official alerts.")
                    }
                    ForEach(activeAlerts) { alert in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 18) {
                                Text(alert.title).font(.title2.bold())
                                Text(alert.issuer).foregroundStyle(.secondary)
                                Text(alert.endDate.formatted(.monthDayTime, timezoneIdentifier: snapshot.timezoneIdentifier))
                                    .monospacedDigit()
                                if let body = alert.body, !body.isEmpty { Text(body) }
                                if let url = alert.detailURL.flatMap(URL.init(string:)), url.scheme == "https" {
                                    Link("Source Details", destination: url)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .font(.system(size: 28))
                .padding(20)
            }
            .scrollClipDisabled()
        }
        .padding(70)
        .background(Color(hex: 0x102136))
        .onExitCommand { dismiss() }
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
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
    }

    private func fact(symbol: String, title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 5 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: 25 * layoutScale, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 19 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))
            Text(value)
                .font(.system(size: 23 * layoutScale, weight: .bold, design: .rounded))
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
            HStack(spacing: 28 * layoutScale) {
                VStack(alignment: .center, spacing: 6 * layoutScale) {
                    Image(systemName: advice.index.symbolName)
                        .font(.system(size: 37 * layoutScale, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 62 * layoutScale, height: 62 * layoutScale)
                        .background(tint.opacity(0.16), in: Circle())

                    Text("Clothing Index")
                        .font(.system(size: 20 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                    Text(advice.index.title)
                        .font(.system(size: 29 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .center, spacing: 6 * layoutScale) {
                    Text(advice.outfit)
                        .font(.system(size: 29 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    Text(advice.detail)
                        .font(.system(size: 23 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct WeatherAdvisoryRow: View {
    let advisory: WeatherAdvisory
    @Environment(\.raynLayoutScale) private var layoutScale

    private var tint: Color {
        switch advisory.level {
        case .warning: return .red
        case .caution: return .yellow
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12 * layoutScale) {
            Image(systemName: advisory.symbolName)
                .font(.system(size: 25 * layoutScale, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38 * layoutScale, height: 38 * layoutScale)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2 * layoutScale) {
                HStack(spacing: 8 * layoutScale) {
                    Text(advisory.isOfficial ? String(localized: "Weather Alert") : String(localized: "Weather Notice"))
                        .font(.system(size: 19 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                    Text(advisory.title)
                        .font(.system(size: 20 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Text(advisory.detail)
                    .font(.system(size: 20 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12 * layoutScale)
        .padding(.vertical, 8 * layoutScale)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16 * layoutScale, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16 * layoutScale, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
