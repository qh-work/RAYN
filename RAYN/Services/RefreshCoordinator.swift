import Foundation

enum RefreshSource: String, CaseIterable {
  case forecast
  case airQuality
  case radar
  case marine
  case alerts

  var refreshInterval: TimeInterval {
    switch self {
    case .forecast: return AppConfiguration.weatherRefreshInterval
    case .airQuality: return AppConfiguration.airQualityRefreshInterval
    case .radar: return AppConfiguration.radarRefreshInterval
    case .marine: return AppConfiguration.airQualityRefreshInterval
    case .alerts: return 5 * 60
    }
  }
}

enum RefreshPlan {
  /// The first render only needs the forecast and the homepage air-quality
  /// summary. Radar tiles and marine observations are loaded when their page
  /// is actually opened, so launch and focus interaction do not compete with
  /// four independent network pipelines.
  static let initial: Set<RefreshSource> = [.forecast, .airQuality, .alerts]
  static let all: Set<RefreshSource> = Set(RefreshSource.allCases)
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
  private let alertProvider: WeatherAlertProvider
  let dataAttributions: [DataAttribution]
  private var retrySchedules: [RefreshSource: RetrySchedule] = [:]
  private var nextEligibleAt: [RefreshSource: Date] = [:]
  private var locationKey: String?

  init(providers: WeatherProviderSuite = RAYNProviderConfiguration.makeWeatherProviderSuite()) {
    self.forecastProvider = providers.forecast
    self.airQualityProvider = providers.airQuality
    self.radarProvider = providers.radar
    self.marineProvider = providers.marine
    self.alertProvider = providers.alerts
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
    now: Date = Date(), sources: Set<RefreshSource> = RefreshPlan.all
  ) async -> RefreshResult {
    let performanceInterval = RAYNPerformance.beginRefresh(force: force)
    defer { RAYNPerformance.endRefresh(performanceInterval) }
    let key = "\(location.id)|\(location.latitude)|\(location.longitude)"
    if locationKey != key {
      retrySchedules.removeAll()
      nextEligibleAt.removeAll()
      locationKey = key
    }
    // Never relabel another city's snapshot. Coordinates can change even
    // when the persistent "current location" identity stays the same.
    var snapshot = fallback.flatMap {
      $0.location.id == location.id && $0.location.latitude == location.latitude
        && $0.location.longitude == location.longitude ? $0 : nil
    }
    let previous = snapshot
    var failures: [String] = []
    var deferred: [String] = []

    let forecastAllowed = sources.contains(.forecast)
      && shouldAttempt(.forecast, force: force, now: now)
    let airQualityAllowed = sources.contains(.airQuality)
      && shouldAttempt(.airQuality, force: force, now: now)
    let radarAllowed = sources.contains(.radar)
      && shouldAttempt(.radar, force: force, now: now)
    let marineAllowed = sources.contains(.marine)
      && shouldAttempt(.marine, force: force, now: now)
    let alertsAllowed = sources.contains(.alerts)
      && shouldAttempt(.alerts, force: force, now: now)

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
    async let alertsTask = fetchResult(shouldFetch: alertsAllowed) {
      try await self.alertProvider.fetchAlerts(for: location)
    }

    let results = await (forecastTask, airQualityTask, radarTask, marineTask, alertsTask)
    guard locationKey == key, !Task.isCancelled else {
      return RefreshResult(snapshot: nil, failedSources: [], forecastAttempted: false)
    }
    if let result = results.0 {
      switch result {
      case .success(let value):
        snapshot = value
        snapshot?.airQuality = previous?.airQuality
        snapshot?.radar = previous?.radar ?? .unavailable
        snapshot?.marine = previous?.marine
        snapshot?.alertAvailability = value.alertAvailability ?? previous?.alertAvailability
        snapshot?.alertsCheckedAt = value.alertsCheckedAt ?? previous?.alertsCheckedAt
        if let oldAlerts = previous?.alerts, !oldAlerts.isEmpty, value.alerts.isEmpty,
           value.alertAvailability != .available {
          snapshot?.alerts = oldAlerts.filter { $0.endDate > now }
        }
        recordSuccess(.forecast, at: now)
      case .failure:
        failures.append(RefreshSource.forecast.rawValue)
        recordFailure(.forecast, at: now)
        snapshot?.isOffline = true
      }
    } else {
      deferred.append(RefreshSource.forecast.rawValue)
    }

    if let result = results.1 {
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

    if let result = results.2 {
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

    if let result = results.3 {
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

    if let result = results.4 {
      switch result {
      case .success(let value):
        // Outside NWS coverage, retain any alerts provided by WeatherKit.
        if value.availability != .unsupported {
          snapshot?.alerts = value.alerts
          snapshot?.alertAvailability = value.availability
        } else if snapshot?.alertAvailability == nil {
          snapshot?.alertAvailability = .unsupported
        }
        snapshot?.alertsCheckedAt = value.checkedAt
        recordSuccess(.alerts, at: now)
      case .failure:
        snapshot?.alertAvailability = .unavailable
        failures.append(RefreshSource.alerts.rawValue)
        recordFailure(.alerts, at: now)
      }
    } else { deferred.append(RefreshSource.alerts.rawValue) }

    if var snapshot {
      snapshot.alerts.removeAll { $0.endDate <= now }
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
