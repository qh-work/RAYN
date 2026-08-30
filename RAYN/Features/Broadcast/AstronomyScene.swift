import SwiftUI

private enum AstronomyDetail {
    case sun
    case moon
}

struct AstronomyScene: View {
    let snapshot: WeatherSnapshot
    @Environment(\.raynLayoutScale) private var layoutScale
    @State private var selectedDetail: AstronomyDetail?

    var body: some View {
        Group {
            switch selectedDetail {
            case .sun:
                SunDetailView(snapshot: snapshot) { selectedDetail = nil }
            case .moon:
                MoonDetailView(snapshot: snapshot) { selectedDetail = nil }
            case nil:
                overview
            }
        }
        .onExitCommand(perform: selectedDetail == nil ? nil : { selectedDetail = nil })
        .onAppear {
#if DEBUG
            switch ProcessInfo.processInfo.environment["RAYN_ASTRONOMY_DETAIL"] {
            case "sun": selectedDetail = .sun
            case "moon": selectedDetail = .moon
            default: break
            }
#endif
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 24 * layoutScale) {
            PageHeader(
                eyebrow: snapshot.marine == nil
                    ? String(localized: "Astronomy")
                    : String(localized: "Astronomy & Marine"),
                title: snapshot.marine == nil
                    ? String(localized: "Sun & Moon")
                    : String(localized: "Sun, Moon & Marine"),
                detail: String(localized: "Current Conditions and Trends")
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .bottom)
            .padding(.bottom, 20 * layoutScale)
            GeometryReader { geometry in
                let spacing = 20 * layoutScale
                let hasMarine = snapshot.marine != nil
                let marineHeight = hasMarine ? 168 * layoutScale : 0
                let sunMoonHeight = max(0, geometry.size.height - marineHeight - (hasMarine ? spacing : 0))
                let availableWidth = max(0, geometry.size.width - spacing)

                VStack(spacing: spacing) {
                    HStack(alignment: .top, spacing: spacing) {
                        Button {
                            selectedDetail = .sun
                        } label: {
                            SolarConditionCard(snapshot: snapshot, compact: hasMarine)
                        }
                        .buttonStyle(FocusButtonStyle())
                        .foregroundStyle(.white)
                        .accessibilityLabel("Sun details")
                        .accessibilityHint("Press Select to view the solar path and daylight details")
                            .frame(width: availableWidth * (hasMarine ? 0.58 : 0.56))

                        Button {
                            selectedDetail = .moon
                        } label: {
                            MoonPhaseCard(
                                info: MoonPhaseCalculator.info(at: Date()),
                                daily: snapshot.daily,
                                timezone: snapshot.timezoneIdentifier,
                                moonrise: snapshot.current.moonrise,
                                moonset: snapshot.current.moonset,
                                // The overview keeps the moon composition
                                // concise so its phase strip clears the live
                                // ticker. The full-size moon remains available
                                // in the selectable detail view.
                                compact: true
                            )
                        }
                        .buttonStyle(FocusButtonStyle())
                        .foregroundStyle(.white)
                        .accessibilityLabel("Moon details")
                        .accessibilityHint("Press Select to view the lunar calendar")
                        .frame(width: availableWidth * (hasMarine ? 0.42 : 0.44))
                    }
                    .frame(height: sunMoonHeight)

                    if let marine = snapshot.marine {
                        MarineConditionCard(marine: marine, timezone: snapshot.timezoneIdentifier)
                            .frame(height: marineHeight)
                    }
                }
            }
            // Keep the title on its own visual row. A fixed content height
            // prevents the lower cards from climbing into the title when the
            // tvOS window proposes a smaller height or a different viewing
            // distance is selected.
            .frame(height: 480 * layoutScale)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 28 * layoutScale)
        .padding(.bottom, 8 * layoutScale)
    }
}

private struct SunDetailView: View {
    let snapshot: WeatherSnapshot
    let onClose: () -> Void
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        VStack(alignment: .leading, spacing: 18 * layoutScale) {
            detailHeader(
                eyebrow: String(localized: "Astronomy"),
                title: String(localized: "Sun"),
                detail: snapshot.current.daylightDuration.map(daylightText) ?? String(localized: "Solar path and daylight")
            )

            HStack(alignment: .center, spacing: 20 * layoutScale) {
                SunPathDetailCard(snapshot: snapshot)
                    .frame(maxWidth: .infinity)

                GlassCard(cornerRadius: 28) {
                    VStack(alignment: .leading, spacing: 15 * layoutScale) {
                        Label("Today", systemImage: "calendar")
                            .font(.system(size: 23 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.86))
                        sunEvent(
                            symbol: "sunrise.fill",
                            title: String(localized: "Sunrise"),
                            value: snapshot.current.sunrise?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--",
                            tint: .yellow
                        )
                        sunEvent(
                            symbol: "sunset.fill",
                            title: String(localized: "Sunset"),
                            value: snapshot.current.sunset?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--",
                            tint: .orange
                        )
                        sunEvent(
                            symbol: "timer",
                            title: String(localized: "Today’s Daylight"),
                            value: snapshot.current.daylightDuration.map(daylightText) ?? fallbackDaylight,
                            tint: .cyan
                        )
                        SolarPositionPanel(
                            info: SolarPositionCalculator.info(at: Date(), location: snapshot.location),
                            timezone: snapshot.timezoneIdentifier,
                            compact: false
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 460 * layoutScale)

            SunDaylightForecast(
                days: Array(snapshot.daily.prefix(10)),
                timezone: snapshot.timezoneIdentifier
            )
            .frame(height: 152 * layoutScale)
        }
        .padding(.top, 24 * layoutScale)
        .padding(.bottom, 14 * layoutScale)
    }

    private func detailHeader(eyebrow: String, title: String, detail: String) -> some View {
        HStack(alignment: .bottom, spacing: 24 * layoutScale) {
            PageHeader(eyebrow: eyebrow, title: title, detail: detail)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 22 * layoutScale, weight: .bold))
                    .frame(width: 50 * layoutScale, height: 50 * layoutScale)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .focusAdaptiveGlassForeground()
            .accessibilityLabel("Close")
        }
    }

    private func sunEvent(symbol: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 13 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: 22 * layoutScale, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30 * layoutScale)
            Text(title)
                .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
            Spacer(minLength: 12 * layoutScale)
            Text(value)
                .font(.system(size: 23 * layoutScale, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
    }

    private var fallbackDaylight: String {
        guard let sunrise = snapshot.current.sunrise, let sunset = snapshot.current.sunset else { return "--" }
        return daylightText(sunset.timeIntervalSince(sunrise))
    }

    private func daylightText(_ duration: TimeInterval) -> String {
        let minutes = max(0, Int((duration / 60).rounded()))
        return String(localized: "\(minutes / 60) hr \(minutes % 60) min")
    }
}

private struct SunPathDetailCard: View {
    let snapshot: WeatherSnapshot
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 28) {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                VStack(alignment: .leading, spacing: 9 * layoutScale) {
                    HStack(alignment: .firstTextBaseline) {
                        Label(nextEventTitle(at: context.date), systemImage: nextEventSymbol(at: context.date))
                            .font(.system(size: 23 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.84))
                        Spacer()
                        Text(remainingDaylight(at: context.date))
                            .font(.system(size: 18 * layoutScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.56))
                    }

                    Text(nextEventDate(at: context.date)?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--")
                        .font(.system(size: 48 * layoutScale, weight: .semibold, design: .rounded))
                        .monospacedDigit()

                    SunArcGraph(
                        sunrise: snapshot.current.sunrise,
                        sunset: snapshot.current.sunset,
                        date: context.date,
                        timezone: snapshot.timezoneIdentifier
                    )
                    .frame(height: 340 * layoutScale)
                }
            }
        }
    }

    private func nextEventTitle(at date: Date) -> String {
        if let sunrise = snapshot.current.sunrise, date < sunrise { return String(localized: "Sunrise") }
        if let sunset = snapshot.current.sunset, date < sunset { return String(localized: "Sunset") }
        return String(localized: "Sunrise")
    }

    private func nextEventDate(at date: Date) -> Date? {
        if let sunrise = snapshot.current.sunrise, date < sunrise { return sunrise }
        if let sunset = snapshot.current.sunset, date < sunset { return sunset }
        return snapshot.daily.dropFirst().first?.sunrise ?? snapshot.current.sunrise
    }

    private func nextEventSymbol(at date: Date) -> String {
        nextEventTitle(at: date) == String(localized: "Sunset") ? "sunset.fill" : "sunrise.fill"
    }

    private func remainingDaylight(at date: Date) -> String {
        guard let sunrise = snapshot.current.sunrise, let sunset = snapshot.current.sunset, sunset > sunrise else { return "--" }
        let remaining = max(0, sunset.timeIntervalSince(max(date, sunrise)))
        let minutes = Int((remaining / 60).rounded())
        return String(localized: "\(minutes / 60) hr \(minutes % 60) min remaining")
    }
}

private struct SunDaylightForecast: View {
    let days: [DailyForecastPoint]
    let timezone: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 10 * layoutScale) {
                Text("Daylight (hours)")
                    .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                HStack(alignment: .bottom, spacing: 10 * layoutScale) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        VStack(spacing: 5 * layoutScale) {
                            Text(daylightValue(day).map { $0.formattedNumber(decimals: 1) } ?? "—")
                                .font(.system(size: 22 * layoutScale, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.68))
                            ZStack(alignment: .bottom) {
                                Capsule().fill(.white.opacity(0.05))
                                if daylightValue(day) != nil {
                                    Capsule()
                                        .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top))
                                        .frame(height: barHeight(for: day))
                                }
                            }
                            .frame(height: 64 * layoutScale)
                            Text(index == 0 ? String(localized: "Today") : day.date.formatted(.shortWeekday, timezoneIdentifier: timezone))
                                .font(.system(size: 20 * layoutScale, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.54))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func daylightValue(_ day: DailyForecastPoint) -> Double? {
        if let duration = day.daylightDuration { return duration / 3_600 }
        guard let sunrise = day.sunrise, let sunset = day.sunset else { return nil }
        return max(0, sunset.timeIntervalSince(sunrise) / 3_600)
    }

    private func barHeight(for day: DailyForecastPoint) -> CGFloat {
        // Absolute 0–24 h scale: a two-minute change must not look like a
        // doubling of daylight. Missing events remain absent, not zero hours.
        let fraction = min(max((daylightValue(day) ?? 0) / 24, 0), 1)
        return 64 * fraction * layoutScale
    }
}

private struct MoonDetailView: View {
    let snapshot: WeatherSnapshot
    let onClose: () -> Void
    @Environment(\.raynLayoutScale) private var layoutScale
    @State private var selectedDate: Date

    init(snapshot: WeatherSnapshot, onClose: @escaping () -> Void) {
        self.snapshot = snapshot
        self.onClose = onClose
        _selectedDate = State(initialValue: Calendar.autoupdatingCurrent.startOfDay(for: Date()))
    }

    var body: some View {
        let info = MoonPhaseCalculator.info(at: selectedDate)
        VStack(alignment: .leading, spacing: 18 * layoutScale) {
            HStack(alignment: .bottom, spacing: 24 * layoutScale) {
                PageHeader(
                    eyebrow: String(localized: "Astronomy"),
                    title: String(localized: "Moon Phase"),
                    detail: selectedDate.formatted(.monthDay, timezoneIdentifier: snapshot.timezoneIdentifier)
                )
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22 * layoutScale, weight: .bold))
                        .frame(width: 50 * layoutScale, height: 50 * layoutScale)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .focusAdaptiveGlassForeground()
                .accessibilityLabel("Close")
            }

            HStack(alignment: .center, spacing: 20 * layoutScale) {
                GlassCard(cornerRadius: 28) {
                    HStack(spacing: 38 * layoutScale) {
                        MoonDiskView(info: info)
                            .frame(width: 260 * layoutScale, height: 260 * layoutScale)
                        VStack(alignment: .leading, spacing: 8 * layoutScale) {
                            Text(info.title)
                                .font(.system(size: 43 * layoutScale, weight: .bold, design: .rounded))
                            Text(selectedDate.formatted(.monthDay, timezoneIdentifier: snapshot.timezoneIdentifier))
                                .font(.system(size: 20 * layoutScale, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.54))
                            HStack(spacing: 22 * layoutScale) {
                                moonValue(title: String(localized: "Illumination"), value: "\(Int((info.illumination * 100).rounded()))%")
                                moonValue(title: String(localized: "Moon Age"), value: "\(info.age.formattedNumber(decimals: 1)) d")
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)

                GlassCard(cornerRadius: 28) {
                    VStack(alignment: .leading, spacing: 14 * layoutScale) {
                        Label("Today", systemImage: "clock")
                            .font(.system(size: 23 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.86))
                        moonEvent(symbol: "moonrise.fill", title: String(localized: "Moonrise"), value: snapshot.current.moonrise?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--", tint: .indigo)
                        moonEvent(symbol: "moonset.fill", title: String(localized: "Moonset"), value: snapshot.current.moonset?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--", tint: .purple)
                        Rectangle().fill(.white.opacity(0.10)).frame(height: 1)
                        Text("Next Major Phase")
                            .font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.52))
                        Text("\(info.nextPhaseTitle) · \(info.nextPhaseDate.formatted(.monthDay, timezoneIdentifier: snapshot.timezoneIdentifier))")
                            .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 500 * layoutScale)
            }
            .frame(height: 330 * layoutScale)

            MoonPhaseCalendar(
                selectedDate: $selectedDate,
                timezone: snapshot.timezoneIdentifier
            )
            .frame(height: 192 * layoutScale)
        }
        .padding(.top, 24 * layoutScale)
        .padding(.bottom, 14 * layoutScale)
    }

    private func moonValue(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2 * layoutScale) {
            Text(title)
                .font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
            Text(value)
                .font(.system(size: 27 * layoutScale, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }

    private func moonEvent(symbol: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 13 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: 22 * layoutScale, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30 * layoutScale)
            Text(title)
                .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
            Spacer()
            Text(value)
                .font(.system(size: 23 * layoutScale, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }
}

private struct MoonPhaseCalendar: View {
    @Binding var selectedDate: Date
    let timezone: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 10 * layoutScale) {
                Text("Next 14 Days")
                    .font(.system(size: 20 * layoutScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10 * layoutScale) {
                        ForEach(calendarDates, id: \.self) { date in
                            let info = MoonPhaseCalculator.info(at: date)
                            Button {
                                selectedDate = date
                            } label: {
                                VStack(spacing: 5 * layoutScale) {
                                    Text(date.formatted(.shortWeekday, timezoneIdentifier: timezone))
                                        .font(.system(size: 15 * layoutScale, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.58))
                                    MoonDiskView(info: info)
                                        .frame(width: 48 * layoutScale, height: 48 * layoutScale)
                                    Text(date.formatted(.monthDay, timezoneIdentifier: timezone))
                                        .font(.system(size: 14 * layoutScale, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.54))
                                }
                                .frame(width: 102 * layoutScale)
                                .padding(.vertical, 7 * layoutScale)
                                .background(
                                    Calendar.autoupdatingCurrent.isDate(date, inSameDayAs: selectedDate)
                                        ? Color.white.opacity(0.14)
                                        : Color.white.opacity(0.05),
                                    in: RoundedRectangle(cornerRadius: 16 * layoutScale, style: .continuous)
                                )
                            }
                            .buttonStyle(FocusButtonStyle())
                            .foregroundStyle(.white)
                            .accessibilityLabel(Text(verbatim: "\(date.formatted(.monthDay, timezoneIdentifier: timezone)), \(info.title), illumination \(Int((info.illumination * 100).rounded())) percent"))
                        }
                    }
                    .padding(.horizontal, 14 * layoutScale)
                    .padding(.vertical, 8 * layoutScale)
                }
                .scrollClipDisabled()
                .clipShape(Rectangle().inset(by: -18 * layoutScale))
            }
        }
        .focusSection()
    }

    private var calendarDates: [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current
        let today = calendar.startOfDay(for: Date())
        return (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
}

private struct SolarConditionCard: View {
    let snapshot: WeatherSnapshot
    let compact: Bool
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: (compact ? 9 : 12) * layoutScale) {
                HStack {
                    Label("Sun", systemImage: "sun.max.fill")
                        .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                    Spacer()
                    Text(solarState)
                        .font(.system(size: 18 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(isCurrentlyDaylight ? .yellow : .indigo.opacity(0.95))
                }

                SunlightTimeline(
                    sunrise: snapshot.current.sunrise,
                    sunset: snapshot.current.sunset,
                    nextSunrise: snapshot.daily.dropFirst().first?.sunrise,
                    timezone: snapshot.timezoneIdentifier,
                    compact: compact
                )
                .frame(height: (compact ? 160 : 210) * layoutScale)

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

                if !compact {
                    SolarPositionPanel(
                        info: SolarPositionCalculator.info(at: Date(), location: snapshot.location),
                        timezone: snapshot.timezoneIdentifier,
                        compact: false
                    )
                }
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

private struct SolarPositionPanel: View {
    let info: SolarPositionInfo
    let timezone: String
    let compact: Bool
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        VStack(alignment: .leading, spacing: (compact ? 6 : 8) * layoutScale) {
            Text("Solar Position")
                .font(.system(size: 16 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))

            HStack(spacing: 9 * layoutScale) {
                solarMetric(symbol: "sun.max.fill", title: String(localized: "Sun Elevation"), value: signedDegrees(info.elevation), accent: .yellow)
                solarMetric(symbol: "location.north.line.fill", title: String(localized: "Sun Azimuth"), value: degrees(info.azimuth), accent: .mint)
            }

            HStack(alignment: .top, spacing: 10 * layoutScale) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 18 * layoutScale, weight: .semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 22 * layoutScale)
                VStack(alignment: .leading, spacing: 2 * layoutScale) {
                    Text("Golden Hour")
                        .font(.system(size: 14 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.48))
                    Text(goldenHourText)
                        .font(.system(size: 16 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }
            }
        }
        .padding(.horizontal, 11 * layoutScale)
        .padding(.vertical, (compact ? 7 : 9) * layoutScale)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14 * layoutScale, style: .continuous))
    }

    private func solarMetric(symbol: String, title: String, value: String, accent: Color) -> some View {
        HStack(spacing: 6 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: 17 * layoutScale, weight: .semibold))
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 1 * layoutScale) {
                Text(title)
                    .font(.system(size: 14 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.46))
                Text(value)
                    .font(.system(size: 17 * layoutScale, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8 * layoutScale)
        .padding(.vertical, 6 * layoutScale)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 11 * layoutScale, style: .continuous))
    }

    private var goldenHourText: String {
        let morning = goldenRange(start: info.morningGoldenHourStart, end: info.morningGoldenHourEnd)
        let evening = goldenRange(start: info.eveningGoldenHourStart, end: info.eveningGoldenHourEnd)
        guard morning != nil || evening != nil else { return "--" }
        let morningText = morning ?? "--"
        let eveningText = evening ?? "--"
        return String(localized: "Morning \(morningText) · Evening \(eveningText)")
    }

    private func goldenRange(start: Date?, end: Date?) -> String? {
        guard let start, let end else { return nil }
        return "\(start.formatted(.time, timezoneIdentifier: timezone))–\(end.formatted(.time, timezoneIdentifier: timezone))"
    }

    private func signedDegrees(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(value.formattedNumber(decimals: 1))°"
    }

    private func degrees(_ value: Double) -> String {
        "\(value.formattedNumber(decimals: 0))°"
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
                    .font(.system(size: 16 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
                Text(value)
                    .font(.system(size: 20 * layoutScale, weight: .bold, design: .rounded))
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

private struct MoonPhaseCard: View {
    let info: MoonPhaseInfo
    let daily: [DailyForecastPoint]
    let timezone: String
    let moonrise: Date?
    let moonset: Date?
    let compact: Bool
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: (compact ? 8 : 9) * layoutScale) {
                HStack {
                    Label("Moon Phase", systemImage: "moon.stars.fill")
                        .font(.system(size: 24 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                    Spacer()
                    Text("Moon age \(info.age.formattedNumber(decimals: 1)) days")
                        .font(.system(size: 16 * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.50))
                }

                VStack(spacing: 6 * layoutScale) {
                    MoonDiskView(info: info)
                        .frame(
                            width: (compact ? 116 : 156) * layoutScale,
                            height: (compact ? 116 : 156) * layoutScale
                        )
                    Text(info.title)
                        .font(.system(size: (compact ? 27 : 32) * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Illumination \(Int((info.illumination * 100).rounded()))%")
                        .font(.system(size: (compact ? 18 : 21) * layoutScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, compact ? 0 : 3 * layoutScale)

                HStack(spacing: 10 * layoutScale) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow.opacity(0.85))
                    VStack(alignment: .leading, spacing: 2 * layoutScale) {
                        Text("Next Major Phase")
                            .font(.system(size: 15 * layoutScale, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.48))
                        Text("\(info.nextPhaseTitle) · \(info.nextPhaseDate.formatted(.monthDay, timezoneIdentifier: timezone))")
                            .font(.system(size: 19 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .padding(9 * layoutScale)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14 * layoutScale, style: .continuous))

                HStack(spacing: 10 * layoutScale) {
                    AstronomyMetric(
                        symbol: "moonrise.fill",
                        title: String(localized: "Moonrise"),
                        value: moonrise?.formatted(.time, timezoneIdentifier: timezone) ?? "--:--",
                        accent: .indigo
                    )
                    AstronomyMetric(
                        symbol: "moonset.fill",
                        title: String(localized: "Moonset"),
                        value: moonset?.formatted(.time, timezoneIdentifier: timezone) ?? "--:--",
                        accent: .purple
                    )
                }

                Text("7-Day Moon Phases")
                    .font(.system(size: 16 * layoutScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.54))

                HStack(spacing: 5 * layoutScale) {
                    ForEach(Array(daily.prefix(7).enumerated()), id: \.element.id) { index, point in
                        let dayInfo = MoonPhaseCalculator.info(at: point.date)
                        VStack(spacing: 5 * layoutScale) {
                            Text(index == 0 ? String(localized: "Today") : point.date.formatted(.shortWeekday, timezoneIdentifier: timezone))
                                .font(.system(size: 14 * layoutScale, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.58))
                            MoonDiskView(info: dayInfo)
                                .frame(width: (compact ? 36 : 40) * layoutScale, height: (compact ? 36 : 40) * layoutScale)
                            Text("\(Int((dayInfo.illumination * 100).rounded()))")
                                .font(.system(size: 14 * layoutScale, weight: .semibold, design: .rounded))
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
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let phaseAngle = 2 * Double.pi * info.age / 29.530588
            let waxing = phaseAngle < Double.pi
            let lightCenter = UnitPoint(
                x: waxing ? 0.73 : 0.27,
                y: 0.28
            )

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xA3B0B8).opacity(0.64),
                                Color(hex: 0x65747E).opacity(0.82),
                                Color(hex: 0x2C3944).opacity(0.96)
                            ],
                            center: UnitPoint(x: 0.30, y: 0.24),
                            startRadius: 0,
                            endRadius: diameter * 0.60
                        )
                    )

                Image("MoonSurface")
                    .resizable()
                    .scaledToFit()
                    .colorMultiply(Color(hex: 0x77838A))
                    .opacity(0.14)
                    .mask(Circle().fill(.white))

                Image("MoonSurface")
                    .resizable()
                    .scaledToFit()
                    .colorMultiply(Color(hex: 0xD8DAD5))
                    .opacity(info.illumination > 0.01 ? 0.92 : 0)
                    .mask(MoonIlluminationShape(age: info.age).fill(.white))

                MoonIlluminationShape(age: info.age)
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.08),
                                Color(hex: 0xDDE2E0).opacity(0.04),
                                .clear
                            ],
                            center: lightCenter,
                            startRadius: 0,
                            endRadius: diameter * 0.70
                        )
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.clear, .black.opacity(0.42)],
                            center: lightCenter,
                            startRadius: diameter * 0.20,
                            endRadius: diameter * 0.76
                        )
                    )

                MoonIlluminationShape(age: info.age)
                    // The radial light layer above already softens the
                    // terminator. Avoiding a blur here keeps the small phase
                    // calendar out of an offscreen render pass.
                    .fill(.white.opacity(0.035))

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear],
                            startPoint: lightCenter,
                            endPoint: UnitPoint(x: waxing ? 0.05 : 0.95, y: 0.72)
                        ),
                        lineWidth: max(0.5, diameter * 0.003)
                    )
            }
            .frame(width: diameter, height: diameter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(info.title), illumination \(Int((info.illumination * 100).rounded())) percent"))
    }
}

private struct MoonIlluminationShape: Shape {
    let age: Double

    func path(in rect: CGRect) -> Path {
        let synodicMonth = 29.530588
        let phaseAngle = 2 * Double.pi * age / synodicMonth
        let waxing = phaseAngle < Double.pi
        let terminatorFactor = CGFloat(cos(phaseAngle))
        let diameter = min(rect.width, rect.height)
        let moonRect = CGRect(
            x: rect.midX - diameter / 2,
            y: rect.midY - diameter / 2,
            width: diameter,
            height: diameter
        )
        let radius = moonRect.width / 2
        let center = CGPoint(x: moonRect.midX, y: moonRect.midY)
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
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 20 * layoutScale) {
                HStack(spacing: 13 * layoutScale) {
                    Image(systemName: "water.waves")
                        .font(.system(size: 39 * layoutScale, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.cyan)
                    VStack(alignment: .leading, spacing: 1 * layoutScale) {
                        Text("Marine Conditions · \(waveState(marine.waveHeight))")
                            .font(.system(size: 17 * layoutScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.60))
                        Text("\(marine.waveHeight.formattedNumber(decimals: 1)) m")
                            .font(.system(size: 35 * layoutScale, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        DataFreshnessLabel(
                            updatedAt: marine.updatedAt,
                            fetchedAt: marine.fetchedAt,
                            timezoneIdentifier: timezone,
                            alignment: .leading,
                            fontSize: 16
                        )
                        .foregroundStyle(.white.opacity(0.42))
                    }
                }
                .frame(width: 285 * layoutScale, alignment: .leading)

                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 1, height: 90 * layoutScale)

                VStack(alignment: .leading, spacing: 4 * layoutScale) {
                    Text("24-Hour Wave Height")
                        .font(.system(size: 15 * layoutScale, weight: .semibold, design: .rounded))
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
            .font(.system(size: 18 * layoutScale, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.50))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16 * layoutScale, style: .continuous))
        } else {
            HStack(alignment: .bottom, spacing: 8 * layoutScale) {
                ForEach(points) { point in
                    VStack(spacing: 2 * layoutScale) {
                        Text(point.waveHeight.formattedNumber(decimals: 1))
                            .font(.system(size: 13 * layoutScale, weight: .bold, design: .rounded))
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
                            .font(.system(size: 12 * layoutScale, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 13 * layoutScale, weight: .semibold))
                    .foregroundStyle(accent)
                Text(L10n.string(title))
                    .font(.system(size: 13 * layoutScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
            }
            Text(value)
                .font(.system(size: 16 * layoutScale, weight: .bold, design: .rounded))
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
    let nextSunrise: Date?
    let timezone: String
    let compact: Bool
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: (compact ? 6 : 8) * layoutScale) {
                HStack(alignment: .center, spacing: 10 * layoutScale) {
                    HStack(spacing: 8 * layoutScale) {
                        Image(systemName: nextEventSymbol(at: context.date))
                            .font(.system(size: (compact ? 18 : 21) * layoutScale, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(nextEventAccent(at: context.date))
                        Text(nextEventTitle(at: context.date))
                            .font(.system(size: (compact ? 18 : 21) * layoutScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    Spacer(minLength: 10 * layoutScale)
                    Text(nextEventDate(at: context.date)?.formatted(.time, timezoneIdentifier: timezone) ?? "--:--")
                        .font(.system(size: (compact ? 29 : 36) * layoutScale, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }

                HStack(spacing: 7 * layoutScale) {
                    Text("Daylight Remaining")
                        .foregroundStyle(.white.opacity(0.55))
                    Text(remainingDaylight(at: context.date))
                        .foregroundStyle(.white.opacity(0.68))
                        .monospacedDigit()
                }
                .font(.system(size: (compact ? 15 : 18) * layoutScale, weight: .semibold, design: .rounded))

                SunArcGraph(
                    sunrise: sunrise,
                    sunset: sunset,
                    date: context.date,
                    timezone: timezone
                )
                .frame(height: (compact ? 68 : 92) * layoutScale)

                HStack(alignment: .top, spacing: 16 * layoutScale) {
                    solarEventLabel(
                        title: String(localized: "Sunrise"),
                        value: sunrise?.formatted(.time, timezoneIdentifier: timezone) ?? "--:--",
                        symbol: "sunrise.fill",
                        tint: .yellow
                    )
                    Spacer(minLength: 0)
                    solarEventLabel(
                        title: String(localized: "Sunset"),
                        value: sunset?.formatted(.time, timezoneIdentifier: timezone) ?? "--:--",
                        symbol: "sunset.fill",
                        tint: .orange
                    )
                }
            }
        }
    }

    private func solarEventLabel(
        title: String,
        value: String,
        symbol: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 7 * layoutScale) {
            Image(systemName: symbol)
                .font(.system(size: (compact ? 15 : 17) * layoutScale, weight: .semibold))
                .foregroundStyle(tint.opacity(0.82))
            Text(title)
                .font(.system(size: (compact ? 15 : 17) * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
            Text(value)
                .font(.system(size: (compact ? 19 : 21) * layoutScale, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
    }

    private func nextEventTitle(at date: Date) -> String {
        if let sunrise, date < sunrise { return String(localized: "Sunrise") }
        if let sunset, date < sunset { return String(localized: "Sunset") }
        return String(localized: "Sunrise")
    }

    private func nextEventDate(at date: Date) -> Date? {
        if let sunrise, date < sunrise { return sunrise }
        if let sunset, date < sunset { return sunset }
        return nextSunrise ?? sunrise
    }

    private func nextEventSymbol(at date: Date) -> String {
        nextEventTitle(at: date) == String(localized: "Sunset") ? "sunset.fill" : "sunrise.fill"
    }

    private func nextEventAccent(at date: Date) -> Color {
        nextEventTitle(at: date) == String(localized: "Sunset") ? .orange : .yellow
    }

    private func remainingDaylight(at date: Date) -> String {
        guard let sunrise, let sunset, sunset > sunrise else { return "--" }
        let start = max(date, sunrise)
        let seconds = max(0, sunset.timeIntervalSince(start))
        let minutes = Int((seconds / 60).rounded())
        return String(localized: "\(minutes / 60) hr \(minutes % 60) min")
    }
}

private struct SunArcGraph: View {
    let sunrise: Date?
    let sunset: Date?
    let date: Date
    let timezone: String
    @Environment(\.raynLayoutScale) private var layoutScale

    var body: some View {
        GeometryReader { geometry in
            let metrics = pathMetrics(width: geometry.size.width, height: geometry.size.height)
            if metrics.isValid {
                let line = sunCurvePath(width: geometry.size.width, height: geometry.size.height, metrics: metrics)
                let area = sunCurveAreaPath(width: geometry.size.width, height: geometry.size.height, metrics: metrics)
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 14 * layoutScale, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: 0x4E88C9).opacity(0.74),
                                    Color(hex: 0x1263B0).opacity(0.88)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    gridPath(width: geometry.size.width, height: geometry.size.height)
                        .stroke(.white.opacity(0.16), lineWidth: 1 * layoutScale)

                    area
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.16), .cyan.opacity(0.06), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    line
                        // A translucent wide stroke gives the trajectory a
                        // soft halo without forcing SwiftUI to blur the full
                        // graph offscreen on every minute tick.
                        .stroke(.white.opacity(0.18), style: StrokeStyle(lineWidth: 9 * layoutScale, lineCap: .round, lineJoin: .round))
                    line
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.92), .white.opacity(0.88), .cyan.opacity(0.66)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3.2 * layoutScale, lineCap: .round, lineJoin: .round)
                        )

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: metrics.baseline))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: metrics.baseline))
                    }
                    .stroke(.black.opacity(0.34), lineWidth: 2.2 * layoutScale)

                    ForEach(1...3, id: \.self) { index in
                        Circle()
                            .fill(.white.opacity(0.54))
                            .frame(width: 7 * layoutScale, height: 7 * layoutScale)
                            .position(
                                point(
                                    at: metrics.sunriseFraction - CGFloat(index) * 0.018,
                                    width: geometry.size.width,
                                    height: geometry.size.height,
                                    metrics: metrics
                                )
                            )
                    }
                    ForEach(1...3, id: \.self) { index in
                        Circle()
                            .fill(.white.opacity(0.54))
                            .frame(width: 7 * layoutScale, height: 7 * layoutScale)
                            .position(
                                point(
                                    at: metrics.sunsetFraction + CGFloat(index) * 0.018,
                                    width: geometry.size.width,
                                    height: geometry.size.height,
                                    metrics: metrics
                                )
                            )
                    }

                    Circle()
                        .fill(.white.opacity(0.78))
                        .frame(width: 7 * layoutScale, height: 7 * layoutScale)
                        .position(metrics.sunrisePoint)
                    Circle()
                        .fill(.white.opacity(0.78))
                        .frame(width: 7 * layoutScale, height: 7 * layoutScale)
                        .position(metrics.sunsetPoint)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.38), .white.opacity(0.12), .clear],
                                center: .center,
                                startRadius: 1,
                                endRadius: 23 * layoutScale
                            )
                        )
                        .frame(width: 42 * layoutScale, height: 42 * layoutScale)
                        .position(metrics.currentPoint)
                    Circle()
                        .fill(.white)
                        .frame(width: 18 * layoutScale, height: 18 * layoutScale)
                        .position(metrics.currentPoint)

                    HStack {
                        Text(verbatim: "0")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(verbatim: "6")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(verbatim: "12")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(verbatim: "18")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(verbatim: "24")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.system(size: 14 * layoutScale, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.74))
                    .padding(.horizontal, 10 * layoutScale)
                    .padding(.bottom, 7 * layoutScale)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14 * layoutScale, style: .continuous))
            } else {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 24 * layoutScale, weight: .medium))
                    .foregroundStyle(.white.opacity(0.36))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private struct PathMetrics {
        var sunriseFraction: CGFloat
        var sunsetFraction: CGFloat
        var currentFraction: CGFloat
        var baseline: CGFloat
        var peak: CGFloat
        var sunrisePoint: CGPoint
        var sunsetPoint: CGPoint
        var currentPoint: CGPoint
        var isValid: Bool
    }

    private func pathMetrics(width: CGFloat, height: CGFloat) -> PathMetrics {
        guard let sunrise, let sunset, sunset > sunrise else {
            return PathMetrics(
                sunriseFraction: 0.25,
                sunsetFraction: 0.75,
                currentFraction: 0.5,
                baseline: height * 0.78,
                peak: height * 0.14,
                sunrisePoint: CGPoint(x: width * 0.25, y: height * 0.78),
                sunsetPoint: CGPoint(x: width * 0.75, y: height * 0.78),
                currentPoint: CGPoint(x: width / 2, y: height * 0.78),
                isValid: false
            )
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current
        let startOfDay = calendar.startOfDay(for: date)
        let daySeconds = calendar.date(byAdding: .day, value: 1, to: startOfDay)?
            .timeIntervalSince(startOfDay) ?? 86_400.0
        let sunriseFraction = CGFloat(min(max(sunrise.timeIntervalSince(startOfDay) / daySeconds, 0), 1))
        let sunsetFraction = CGFloat(min(max(sunset.timeIntervalSince(startOfDay) / daySeconds, sunriseFraction), 1))
        let currentFraction = CGFloat(min(max(date.timeIntervalSince(startOfDay) / daySeconds, 0), 1))
        let baseline = height * 0.60
        let peak = height * 0.10
        let metrics = PathMetrics(
            sunriseFraction: sunriseFraction,
            sunsetFraction: sunsetFraction,
            currentFraction: currentFraction,
            baseline: baseline,
            peak: peak,
            sunrisePoint: .zero,
            sunsetPoint: .zero,
            currentPoint: .zero,
            isValid: true
        )
        return PathMetrics(
            sunriseFraction: sunriseFraction,
            sunsetFraction: sunsetFraction,
            currentFraction: currentFraction,
            baseline: baseline,
            peak: peak,
            sunrisePoint: point(at: sunriseFraction, width: width, height: height, metrics: metrics),
            sunsetPoint: point(at: sunsetFraction, width: width, height: height, metrics: metrics),
            currentPoint: point(at: currentFraction, width: width, height: height, metrics: metrics),
            isValid: true
        )
    }

    private func solarLift(at fraction: CGFloat, sunrise: CGFloat, sunset: CGFloat) -> CGFloat {
        let daylightSpan = max(sunset - sunrise, 0.001)
        if fraction < sunrise {
            let progress = min(max(fraction / max(sunrise, 0.001), 0), 1)
            let eased = progress * progress * (3 - 2 * progress)
            return -0.48 * (1 - eased)
        }
        if fraction > sunset {
            let progress = min(max((fraction - sunset) / max(1 - sunset, 0.001), 0), 1)
            let eased = progress * progress * (3 - 2 * progress)
            return -0.48 * eased
        }
        let progress = (fraction - sunrise) / daylightSpan
        return CGFloat(sin(Double.pi * Double(progress)))
    }

    private func point(at fraction: CGFloat, width: CGFloat, height: CGFloat, metrics: PathMetrics) -> CGPoint {
        let clampedFraction = min(max(fraction, 0), 1)
        let lift = solarLift(
            at: clampedFraction,
            sunrise: metrics.sunriseFraction,
            sunset: metrics.sunsetFraction
        )
        return CGPoint(
            x: width * clampedFraction,
            y: metrics.baseline - (metrics.baseline - metrics.peak) * lift
        )
    }

    private func sunCurvePath(width: CGFloat, height: CGFloat, metrics: PathMetrics) -> Path {
        let sampleCount = 48
        let points = (0...sampleCount).map { index in
            point(
                at: CGFloat(index) / CGFloat(sampleCount),
                width: width,
                height: height,
                metrics: metrics
            )
        }

        var path = Path()
        path.move(to: points[0])
        for index in 0..<(points.count - 1) {
            let previous = index > 0 ? points[index - 1] : points[index]
            let start = points[index]
            let end = points[index + 1]
            let next = index + 2 < points.count ? points[index + 2] : end
            let control1 = CGPoint(
                x: start.x + (end.x - previous.x) / 6,
                y: start.y + (end.y - previous.y) / 6
            )
            let control2 = CGPoint(
                x: end.x - (next.x - start.x) / 6,
                y: end.y - (next.y - start.y) / 6
            )
            path.addCurve(to: end, control1: control1, control2: control2)
        }
        return path
    }

    private func sunCurveAreaPath(width: CGFloat, height: CGFloat, metrics: PathMetrics) -> Path {
        var path = sunCurvePath(width: width, height: height, metrics: metrics)
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }

    private func gridPath(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        for index in 0...4 {
            let x = width * CGFloat(index) / 4
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: height))
        }
        for index in 1...3 {
            let y = height * CGFloat(index) / 4
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }
        return path
    }
}
