#if canImport(WeatherKit)
import CoreLocation
import Foundation
import WeatherKit

/// Adapts Apple's WeatherKit model to RAYN Weather's provider-neutral weather model.
///
/// The app does not embed credentials. A release build that selects this provider
/// must enable the WeatherKit capability for its own App ID in the Apple Developer
/// account. Keeping this adapter behind `ForecastProvider` lets the rest of the app
/// remain independent of WeatherKit and keeps tests network-free.
struct AppleWeatherKitProvider: ForecastProvider {
    private let weatherService: WeatherService

    init(weatherService: WeatherService = .shared) {
        self.weatherService = weatherService
    }

    func fetchForecast(for location: SavedLocation) async throws -> WeatherSnapshot {
        let coordinate = CLLocation(latitude: location.latitude, longitude: location.longitude)
        do {
            async let weatherRequest = weatherService.weather(for: coordinate)
            async let attributionRequest = weatherService.attribution
            let (weather, attribution) = try await (weatherRequest, attributionRequest)
            guard weather.dailyForecast.count >= 10 else {
                throw WeatherProviderError.invalidResponse
            }
            var snapshot = makeSnapshot(from: weather, location: location)
            snapshot.sourceAttributions = [
                DataAttribution(id: "apple-weather", title: attribution.serviceName,
                                detail: attribution.legalAttributionText,
                                urlString: attribution.legalPageURL.absoluteString,
                                logoURLString: attribution.combinedMarkDarkURL.absoluteString)
            ]
            return snapshot
        } catch {
            if let error = error as? WeatherProviderError {
                throw error
            }
            throw WeatherProviderError.unavailable(String(localized: "WeatherKit request failed: \(error.localizedDescription)"))
        }
    }

    func makeSnapshot(from weather: Weather, location: SavedLocation, now: Date = Date()) -> WeatherSnapshot {
        let currentWeather = weather.currentWeather
        let hourlyForecast = Array(weather.hourlyForecast.prefix(48))
        let dailyForecast = Array(weather.dailyForecast.prefix(10))
        let nearestHour = hourlyForecast.min {
            abs($0.date.timeIntervalSince(currentWeather.date)) < abs($1.date.timeIntervalSince(currentWeather.date))
        }
        let currentDay = dailyForecast.first
        let currentCode = WeatherKitConditionMapper.wmoCode(for: currentWeather.condition)
        let currentPrecipitation = nearestHour?.precipitationAmount.converted(to: .millimeters).value ?? 0
        let currentSnowfall = nearestHour?.snowfallAmount.converted(to: .millimeters).value ?? 0
        let currentProbability = (nearestHour?.precipitationChance ?? 0) * 100

        let current = CurrentConditions(
            temperature: currentWeather.temperature.converted(to: .celsius).value,
            feelsLike: currentWeather.apparentTemperature.converted(to: .celsius).value,
            high: currentDay?.highTemperature.converted(to: .celsius).value ?? currentWeather.temperature.converted(to: .celsius).value,
            low: currentDay?.lowTemperature.converted(to: .celsius).value ?? currentWeather.temperature.converted(to: .celsius).value,
            relativeHumidity: currentWeather.humidity * 100,
            dewPoint: currentWeather.dewPoint.converted(to: .celsius).value,
            pressure: currentWeather.pressure.converted(to: .hectopascals).value,
            visibility: currentWeather.visibility.converted(to: .kilometers).value,
            cloudCover: currentWeather.cloudCover * 100,
            windSpeed: Self.speedInKilometersPerHour(currentWeather.wind.speed),
            windDirection: currentWeather.wind.direction.converted(to: .degrees).value,
            windGust: currentWeather.wind.gust.map(Self.speedInKilometersPerHour) ?? Self.speedInKilometersPerHour(currentWeather.wind.speed),
            uvIndex: Double(currentWeather.uvIndex.value),
            precipitationProbability: currentProbability,
            precipitation: currentPrecipitation,
            weatherCode: currentCode,
            isDay: currentWeather.isDaylight,
            sunrise: currentDay?.sun.sunrise,
            sunset: currentDay?.sun.sunset,
            rain: currentPrecipitation > 0 ? currentPrecipitation : nil,
            snowfall: currentSnowfall > 0 ? currentSnowfall : nil,
            cloudCoverLow: nil,
            cloudCoverMid: nil,
            cloudCoverHigh: nil,
            daylightDuration: Self.daylightDuration(sunrise: currentDay?.sun.sunrise, sunset: currentDay?.sun.sunset),
            moonrise: currentDay?.moon.moonrise,
            moonset: currentDay?.moon.moonset
        )

        let hourly = hourlyForecast.map { hour in
            HourlyForecastPoint(
                time: hour.date,
                temperature: hour.temperature.converted(to: .celsius).value,
                apparentTemperature: hour.apparentTemperature.converted(to: .celsius).value,
                precipitationProbability: hour.precipitationChance * 100,
                precipitation: hour.precipitationAmount.converted(to: .millimeters).value,
                snowfall: hour.snowfallAmount.converted(to: .millimeters).value,
                windSpeed: Self.speedInKilometersPerHour(hour.wind.speed),
                windDirection: hour.wind.direction.converted(to: .degrees).value,
                weatherCode: WeatherKitConditionMapper.wmoCode(for: hour.condition),
                isDay: hour.isDaylight,
                windGust: hour.wind.gust.map(Self.speedInKilometersPerHour),
                visibility: hour.visibility.converted(to: .kilometers).value,
                uvIndex: Double(hour.uvIndex.value)
            )
        }

        let safeHourly = hourly.isEmpty
            ? [HourlyForecastPoint(
                time: currentWeather.date,
                temperature: current.temperature,
                apparentTemperature: current.feelsLike,
                precipitationProbability: current.precipitationProbability,
                precipitation: current.precipitation,
                snowfall: currentSnowfall,
                windSpeed: current.windSpeed,
                windDirection: current.windDirection,
                weatherCode: current.weatherCode,
                isDay: current.isDay,
                windGust: current.windGust,
                visibility: current.visibility,
                uvIndex: current.uvIndex
            )]
            : hourly

        let daily = dailyForecast.map { day in
            DailyForecastPoint(
                date: day.date,
                high: day.highTemperature.converted(to: .celsius).value,
                low: day.lowTemperature.converted(to: .celsius).value,
                weatherCode: WeatherKitConditionMapper.wmoCode(for: day.condition),
                precipitationProbability: day.precipitationChance * 100,
                precipitation: day.precipitationAmountByType.precipitation.converted(to: .millimeters).value,
                windSpeed: Self.speedInKilometersPerHour(day.wind.speed),
                windGust: day.highWindSpeed.map(Self.speedInKilometersPerHour) ?? Self.speedInKilometersPerHour(day.wind.speed),
                sunrise: day.sun.sunrise,
                sunset: day.sun.sunset,
                uvIndex: Double(day.uvIndex.value),
                daylightDuration: Self.daylightDuration(sunrise: day.sun.sunrise, sunset: day.sun.sunset)
            )
        }

        var snapshot = WeatherSnapshot(
            location: location,
            timezoneIdentifier: location.timezoneIdentifier,
            current: current,
            hourly: safeHourly,
            daily: daily,
            airQuality: nil,
            radar: .unavailable,
            marine: nil,
            alerts: (weather.weatherAlerts ?? []).map {
                WeatherAlertItem(
                    title: $0.summary,
                    issuer: $0.source,
                    startDate: $0.metadata.date,
                    endDate: $0.metadata.expirationDate,
                    detailURL: $0.detailsURL.absoluteString
                )
            },
            summary: .empty,
            updatedAt: currentWeather.date,
            fetchedAt: now,
            source: "WeatherKit",
            isOffline: false,
            theme: WeatherTheme.from(
                weatherCode: current.weatherCode,
                isDay: current.isDay,
                precipitation: current.precipitation,
                windSpeed: current.windSpeed,
                visibility: current.visibility
            )
        )
        switch weather.availability.alertAvailability {
        case .available: snapshot.alertAvailability = .available
        case .unsupported: snapshot.alertAvailability = .unsupported
        default: snapshot.alertAvailability = .unavailable
        }
        snapshot.alertsCheckedAt = now
        snapshot.summary = WeatherSummaryBuilder.make(from: snapshot)
        return snapshot
    }

    private static func speedInKilometersPerHour(_ speed: Measurement<UnitSpeed>) -> Double {
        speed.converted(to: .kilometersPerHour).value
    }

    private static func daylightDuration(sunrise: Date?, sunset: Date?) -> Double? {
        guard let sunrise, let sunset, sunset > sunrise else { return nil }
        return sunset.timeIntervalSince(sunrise)
    }
}

enum WeatherKitConditionMapper {
    static func wmoCode(for condition: WeatherCondition) -> Int {
        switch condition {
        case .clear: return 0
        case .mostlyClear: return 1
        case .partlyCloudy, .mostlyCloudy: return 2
        case .cloudy: return 3
        case .foggy: return 45
        case .haze, .smoky, .blowingDust: return 45
        case .drizzle: return 51
        case .freezingDrizzle: return 56
        case .rain, .sunShowers: return 61
        case .heavyRain: return 65
        case .freezingRain: return 66
        case .sleet, .wintryMix: return 67
        case .snow, .flurries, .sunFlurries: return 73
        case .heavySnow, .blizzard, .blowingSnow: return 75
        case .hail: return 96
        case .isolatedThunderstorms, .scatteredThunderstorms, .thunderstorms, .strongStorms, .tropicalStorm, .hurricane: return 95
        case .breezy, .windy, .frigid, .hot: return 1
        @unknown default: return 2
        }
    }
}
#else
import Foundation

/// Keeps the source-level provider switch readable on platforms where WeatherKit
/// is not linked. The tvOS target includes WeatherKit, so this branch mainly helps
/// shared source previews and non-Apple test environments.
struct AppleWeatherKitProvider: ForecastProvider {
    func fetchForecast(for location: SavedLocation) async throws -> WeatherSnapshot {
        throw WeatherProviderError.unavailable(String(localized: "WeatherKit is unavailable. Enable the WeatherKit capability."))
    }
}
#endif
