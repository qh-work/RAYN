import Foundation

enum RefreshSource: String, CaseIterable {
  case forecast = "天气"
  case airQuality = "空气质量"
  case radar = "雷达"
  case marine = "海洋"

  var refreshInterval: TimeInterval {
    switch self {
    case .forecast: return AppConfiguration.weatherRefreshInterval
    case .airQuality: return AppConfiguration.airQualityRefreshInterval
    case .radar: return AppConfiguration.radarRefreshInterval
    case .marine: return AppConfiguration.airQualityRefreshInterval
    }
  }
}

struct RetrySchedule: Equatable {
  static let delays: [TimeInterval] = [120, 300, 900]

  private(set) var failureCount = 0
  private(set) var retryAt: Date?

  mutating func recordFailure(at date: Date) -> Date {
    let index = min(failureCount, Self.delays.count - 1)
    failureCount += 1
    let next = date.addingTimeInterval(Self.delays[index])
    retryAt = next
    return next
  }

  mutating func recordSuccess() {
    failureCount = 0
    retryAt = nil
  }

  func isReady(at date: Date) -> Bool {
    guard let retryAt else { return true }
    return date >= retryAt
  }
}

struct RefreshResult {
  var snapshot: WeatherSnapshot?
  var failedSources: [String]
  var deferredSources: [String] = []
  var forecastAttempted: Bool
}

@MainActor
final class RefreshCoordinator {
  private let forecastProvider: ForecastProvider
  private let airQualityProvider: AirQualityProvider
  private let radarProvider: RadarProvider
  private let marineProvider: MarineWeatherProvider
  let dataAttributions: [DataAttribution]
  private var retrySchedules: [RefreshSource: RetrySchedule] = [:]
  private var nextEligibleAt: [RefreshSource: Date] = [:]

  init(providers: WeatherProviderSuite = RAYNProviderConfiguration.makeWeatherProviderSuite()) {
    self.forecastProvider = providers.forecast
    self.airQualityProvider = providers.airQuality
    self.radarProvider = providers.radar
    self.marineProvider = providers.marine
    self.dataAttributions = providers.dataAttributions
  }

  convenience init(
    forecastProvider: ForecastProvider,
    airQualityProvider: AirQualityProvider,
    radarProvider: RadarProvider,
    marineProvider: MarineWeatherProvider
  ) {
    self.init(
      providers: WeatherProviderSuite(
        forecast: forecastProvider,
        airQuality: airQualityProvider,
        radar: radarProvider,
        marine: marineProvider
      )
    )
  }

  func refresh(
    location: SavedLocation, fallback: WeatherSnapshot? = nil, force: Bool = false,
    now: Date = Date()
  ) async -> RefreshResult {
    var snapshot = fallback
    snapshot?.location = location
    snapshot?.timezoneIdentifier = location.timezoneIdentifier
    var failures: [String] = []
    var deferred: [String] = []

    let forecastAllowed = shouldAttempt(.forecast, force: force, now: now)
    let airQualityAllowed = shouldAttempt(.airQuality, force: force, now: now)
    let radarAllowed = shouldAttempt(.radar, force: force, now: now)
    let marineAllowed = shouldAttempt(.marine, force: force, now: now)

    async let forecastTask = fetchResult(shouldFetch: forecastAllowed) {
      try await self.forecastProvider.fetchForecast(for: location)
    }
    async let airQualityTask = fetchResult(shouldFetch: airQualityAllowed) {
      try await self.airQualityProvider.fetchAirQuality(for: location)
    }
    async let radarTask = fetchResult(shouldFetch: radarAllowed) {
      try await self.radarProvider.fetchRadar(for: location)
    }
    async let marineTask = fetchResult(shouldFetch: marineAllowed) {
      try await self.marineProvider.fetchMarineWeather(for: location)
    }

    if let result = await forecastTask {
      switch result {
      case .success(let value):
        snapshot = value
        recordSuccess(.forecast, at: now)
      case .failure:
        failures.append(RefreshSource.forecast.rawValue)
        recordFailure(.forecast, at: now)
        snapshot = nil
      }
    } else {
      deferred.append(RefreshSource.forecast.rawValue)
    }

    if let result = await airQualityTask {
      switch result {
      case .success(let value):
        snapshot?.airQuality = value
        recordSuccess(.airQuality, at: now)
      case .failure:
        failures.append(RefreshSource.airQuality.rawValue)
        recordFailure(.airQuality, at: now)
      }
    } else {
      deferred.append(RefreshSource.airQuality.rawValue)
    }

    if let result = await radarTask {
      switch result {
      case .success(let value):
        snapshot?.radar = value
        recordSuccess(.radar, at: now)
      case .failure:
        failures.append(RefreshSource.radar.rawValue)
        recordFailure(.radar, at: now)
        snapshot?.radar = .unavailable
      }
    } else {
      deferred.append(RefreshSource.radar.rawValue)
    }

    if let result = await marineTask {
      switch result {
      case .success(let value):
        snapshot?.marine = value
        recordSuccess(.marine, at: now)
      case .failure:
        failures.append(RefreshSource.marine.rawValue)
        recordFailure(.marine, at: now)
        snapshot?.marine = nil
      }
    } else {
      deferred.append(RefreshSource.marine.rawValue)
    }

    if var snapshot {
      snapshot.updatedAt = snapshot.updatedAt > now ? now : snapshot.updatedAt
      snapshot.summary = WeatherSummaryBuilder.make(from: snapshot)
      return RefreshResult(
        snapshot: snapshot, failedSources: failures, deferredSources: deferred,
        forecastAttempted: forecastAllowed)
    }
    return RefreshResult(
      snapshot: nil, failedSources: failures, deferredSources: deferred,
      forecastAttempted: forecastAllowed)
  }

  private func shouldAttempt(_ source: RefreshSource, force: Bool, now: Date) -> Bool {
    if force { return true }
    if let next = nextEligibleAt[source], next > now { return false }
    if let schedule = retrySchedules[source], !schedule.isReady(at: now) { return false }
    return true
  }

  private func recordSuccess(_ source: RefreshSource, at date: Date) {
    var schedule = retrySchedules[source] ?? RetrySchedule()
    schedule.recordSuccess()
    retrySchedules[source] = schedule
    nextEligibleAt[source] = date.addingTimeInterval(source.refreshInterval)
  }

  private func recordFailure(_ source: RefreshSource, at date: Date) {
    var schedule = retrySchedules[source] ?? RetrySchedule()
    let retryAt = schedule.recordFailure(at: date)
    retrySchedules[source] = schedule
    nextEligibleAt[source] = retryAt
  }

  private func fetchResult<T>(shouldFetch: Bool, operation: @escaping () async throws -> T) async
    -> Result<T, Error>?
  {
    guard shouldFetch else { return nil }
    do {
      return .success(try await operation())
    } catch {
      return .failure(error)
    }
  }
}
