import XCTest
import Combine

@testable import RAYN

extension SavedLocation {
  fileprivate static let beijing = SavedLocation(
    name: "北京",
    administrativeArea: "北京市",
    country: "中国",
    latitude: 39.9042,
    longitude: 116.4074,
    timezoneIdentifier: "Asia/Shanghai"
  )
}

final class RAYNTests: XCTestCase {
  func testPublicNameExplainsTheProductWithoutRenamingInternalTargets() {
    XCTAssertEqual(AppConfiguration.displayName, "RAYN Weather")
    XCTAssertEqual(AppConfiguration.productName, "RAYN")
    XCTAssertEqual(
      Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
      AppConfiguration.displayName
    )
  }

  func testPublicCitySearchAliasesAreUnambiguous() {
    let newYork = OpenMeteoLocationSearchProvider.searchRequest(for: "纽约")
    XCTAssertEqual(newYork.name, "New York City")
    XCTAssertEqual(newYork.countryCode, "US")

    let london = OpenMeteoLocationSearchProvider.searchRequest(for: "伦敦")
    XCTAssertEqual(london.name, "London")
    XCTAssertEqual(london.countryCode, "GB")

    let vancouver = OpenMeteoLocationSearchProvider.searchRequest(for: "温哥华")
    XCTAssertEqual(vancouver.name, "Vancouver")
    XCTAssertEqual(vancouver.countryCode, "CA")
  }

  func testPublicCaptureLocationsContainNoPrivateAddress() {
    #if DEBUG
    let names = ["beijing", "shanghai", "new-york", "shenzhen", "london", "vancouver"]
    let locations = names.compactMap(AppConfiguration.captureLocation(named:))
    XCTAssertEqual(locations.count, names.count)
    XCTAssertEqual(locations.first?.name, String(localized: "Beijing"))
    XCTAssertEqual(locations[2].timezoneIdentifier, "America/New_York")
    XCTAssertNil(AppConfiguration.captureLocation(named: "private-location"))
    #endif
  }

  func testWeatherCodeMapping() {
    XCTAssertEqual(WeatherCodeMapper.description(for: 0, isDay: true), String(localized: "Clear"))
    XCTAssertEqual(
      WeatherCodeMapper.description(for: 95, isDay: true), String(localized: "Thunderstorm"))
    XCTAssertEqual(WeatherCodeMapper.symbol(for: 73, isDay: true), "cloud.snow.fill")
  }

  func testThemeMappingDistinguishesDayAndNight() {
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 0, isDay: true, precipitation: 0, windSpeed: 4), .clearDay)
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 0, isDay: false, precipitation: 0, windSpeed: 4), .clearNight)
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 95, isDay: true, precipitation: 3, windSpeed: 24), .storm)
  }

  func testWeatherThemeCoversDistinctForecastConditionFamilies() {
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 3, isDay: true, precipitation: 0, windSpeed: 4), .overcast)
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 45, isDay: true, precipitation: 0, windSpeed: 4), .fog)
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 51, isDay: true, precipitation: 0, windSpeed: 4), .drizzle)
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 66, isDay: true, precipitation: 0, windSpeed: 4), .freezingRain
    )
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 80, isDay: true, precipitation: 0, windSpeed: 4), .showers)
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 73, isDay: true, precipitation: 0, windSpeed: 4), .snow)
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 96, isDay: true, precipitation: 0, windSpeed: 4), .hail)
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 0, isDay: true, precipitation: 0, windSpeed: 4, visibility: 2),
      .haze)
  }

  func testWeatherThemePreservesSnowAndDoesNotInventHail() {
    XCTAssertEqual(
      WeatherTheme.from(weatherCode: 85, isDay: true, precipitation: 4, windSpeed: 42), .snow)
    XCTAssertFalse(WeatherTheme.storm.hasHail)
  }

  func testTemperatureConversion() {
    XCTAssertEqual(0.0.formattedTemperature(unit: .celsius), "0")
    XCTAssertEqual(0.0.formattedTemperature(unit: .fahrenheit), "32")
    XCTAssertEqual(25.0.formattedTemperature(unit: .fahrenheit), "77")
  }

  func testSummaryRuleDetectsRainAndTemperatureRange() {
    var snapshot = WeatherSnapshot.testFixture
    snapshot.current.high = 32
    snapshot.current.low = 21
    var drySnapshot = snapshot
    drySnapshot.hourly = drySnapshot.hourly.map {
      var point = $0
      point.precipitationProbability = 0
      return point
    }
    snapshot.hourly[3].precipitationProbability = 86
    snapshot.summary = WeatherSummaryBuilder.make(from: snapshot)
    let drySummary = WeatherSummaryBuilder.make(from: drySnapshot)
    XCTAssertNotEqual(snapshot.summary.headline, drySummary.headline)
    XCTAssertGreaterThan(snapshot.summary.insights.count, drySummary.insights.count)
  }

  func testSolarPositionAddsDaylightGeometryAndGoldenHours() throws {
    let formatter = ISO8601DateFormatter()
    let midday = try XCTUnwrap(formatter.date(from: "2026-03-20T04:00:00Z"))
    let middayInfo = SolarPositionCalculator.info(at: midday, location: .beijing)

    XCTAssertGreaterThan(middayInfo.elevation, 30)
    XCTAssertLessThan(middayInfo.elevation, 90)
    XCTAssertGreaterThan(middayInfo.azimuth, 120)
    XCTAssertLessThan(middayInfo.azimuth, 240)

    let nearSunrise = try XCTUnwrap(formatter.date(from: "2026-08-16T21:27:00Z"))
    let sunriseInfo = SolarPositionCalculator.info(at: nearSunrise, location: .beijing)
    XCTAssertLessThan(abs(sunriseInfo.elevation), 5)
    XCTAssertGreaterThan(sunriseInfo.azimuth, 30)
    XCTAssertLessThan(sunriseInfo.azimuth, 120)
    XCTAssertNotNil(sunriseInfo.morningGoldenHourStart)
    XCTAssertNotNil(sunriseInfo.morningGoldenHourEnd)
    XCTAssertNotNil(sunriseInfo.eveningGoldenHourStart)
    XCTAssertNotNil(sunriseInfo.eveningGoldenHourEnd)
  }

  func testWeatherAdvisoryBuilderSurfacesLiveConditionNotices() {
    var snapshot = WeatherSnapshot.testFixture
    snapshot.current.weatherCode = 95
    let stormAdvisories = WeatherAdvisoryBuilder.make(from: snapshot)
    XCTAssertTrue(stormAdvisories.contains { $0.id == "thunderstorm" && $0.level == .warning })
    XCTAssertTrue(stormAdvisories.contains { !$0.isOfficial })

    snapshot.current.weatherCode = 2
    snapshot.current.windGust = 72
    snapshot.hourly = []
    let windAdvisories = WeatherAdvisoryBuilder.make(from: snapshot)
    XCTAssertTrue(windAdvisories.contains { $0.id == "strong-wind" && $0.level == .caution })
  }

  func testWeatherAdvisoryBuilderKeepsOfficialAlertDistinct() {
    var snapshot = WeatherSnapshot.testFixture
    snapshot.alerts = [
      WeatherAlertItem(
        title: "Official test alert",
        issuer: "Test issuer",
        startDate: snapshot.updatedAt,
        endDate: snapshot.updatedAt.addingTimeInterval(3_600)
      )
    ]

    let advisories = WeatherAdvisoryBuilder.make(from: snapshot)
    XCTAssertTrue(advisories.contains { $0.isOfficial && $0.id.hasPrefix("official-") })
  }

  func testAQILevelsAndAdvice() {
    var air = WeatherSnapshot.testFixture.airQuality!
    air.europeanAQI = 18
    XCTAssertEqual(air.level, String(localized: "Excellent"))
    XCTAssertEqual(
      air.advice,
      String(localized: "Air quality is suitable for outdoor activities. Sensitive groups can adjust as needed."))
    air.europeanAQI = 92
    XCTAssertEqual(air.level, String(localized: "Very Poor"))
  }

  func testOptionalFieldsSurviveRoundTrip() throws {
    var snapshot = WeatherSnapshot.testFixture
    snapshot.fetchedAt = snapshot.updatedAt.addingTimeInterval(45)
    snapshot.airQuality?.fetchedAt = snapshot.updatedAt.addingTimeInterval(46)
    snapshot.marine?.fetchedAt = snapshot.updatedAt.addingTimeInterval(47)
    snapshot.marine = nil
    snapshot.airQuality = nil
    snapshot.radar = .unavailable
    let encoded = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(WeatherSnapshot.self, from: encoded)
    XCTAssertNil(decoded.marine)
    XCTAssertNil(decoded.airQuality)
    XCTAssertEqual(decoded.fetchedAt, snapshot.fetchedAt)
    XCTAssertFalse(decoded.radar.isAvailable)
  }

  func testRadarFrameSupportsProviderTileTemplatesAndLegacyDecoding() throws {
    let frame = RadarFrame(
      timestamp: 1_755_000_000,
      tilePath: "/v2/radar/1755000000",
      tileURLTemplate: "https://example.test/{z}/{x}/{y}.png",
      source: "test",
      isForecast: true
    )
    let encoded = try JSONEncoder().encode(frame)
    let decoded = try JSONDecoder().decode(RadarFrame.self, from: encoded)
    XCTAssertEqual(decoded.tileURLTemplate, frame.tileURLTemplate)
    XCTAssertTrue(decoded.isForecast)

    let legacy = Data(#"{"timestamp":1755000000,"tilePath":null,"source":"test"}"#.utf8)
    let legacyFrame = try JSONDecoder().decode(RadarFrame.self, from: legacy)
    XCTAssertFalse(legacyFrame.isForecast)
  }

  func testOpenMeteoJSONParsingWithMissingOptionalFields() throws {
    let data = Data(
      #"{"timezone":"Asia/Shanghai","current":{"time":"2026-08-16T12:00","temperature_2m":30.5,"weather_code":61,"is_day":1},"hourly":{"time":["2026-08-16T12:00"],"temperature_2m":[30.5],"weather_code":[61]}}"#
        .utf8)
    let payload = try JSONDecoder().decode(OpenMeteoForecastPayload.self, from: data)
    let snapshot = OpenMeteoForecastProvider().makeSnapshot(from: payload, location: .beijing)
    XCTAssertEqual(snapshot.current.temperature, 30.5)
    XCTAssertEqual(snapshot.current.weatherCode, 61)
    XCTAssertEqual(snapshot.hourly.count, 1)
    XCTAssertEqual(snapshot.daily.count, 0)
    XCTAssertEqual(
      snapshot.updatedAt,
      WeatherDateParser.date(from: "2026-08-16T12:00", timezone: TimeZone(identifier: "Asia/Shanghai")!)
    )
    XCTAssertNotNil(snapshot.fetchedAt)
  }

  func testOpenMeteoFieldsAndCurrentProbabilityAreMapped() throws {
    let json = #"""
      {
        "timezone":"Asia/Shanghai",
        "current":{
          "time":"2026-08-16T12:00",
          "temperature_2m":30.5,
          "apparent_temperature":33.0,
          "dew_point_2m":23.1,
          "rain":0.6,
          "snowfall":0.0,
          "cloud_cover":64,
          "cloud_cover_low":20,
          "cloud_cover_mid":55,
          "cloud_cover_high":80,
          "weather_code":61,
          "is_day":1
        },
        "hourly":{
          "time":["2026-08-16T12:00"],
          "temperature_2m":[30.5],
          "apparent_temperature":[33.0],
          "precipitation_probability":[82],
          "wind_gusts_10m":[35],
          "visibility":[12000],
          "uv_index":[5.2],
          "weather_code":[61]
        },
        "daily":{
          "time":["2026-08-16"],
          "temperature_2m_max":[31.0],
          "temperature_2m_min":[24.0],
          "daylight_duration":[45000]
        }
      }
      """#
    let payload = try JSONDecoder().decode(OpenMeteoForecastPayload.self, from: Data(json.utf8))
    let snapshot = OpenMeteoForecastProvider().makeSnapshot(from: payload, location: .beijing)
    XCTAssertEqual(snapshot.current.dewPoint, 23.1)
    XCTAssertEqual(snapshot.current.cloudCoverLow, 20)
    XCTAssertEqual(snapshot.current.cloudCoverMid, 55)
    XCTAssertEqual(snapshot.current.cloudCoverHigh, 80)
    XCTAssertEqual(snapshot.current.precipitationProbability, 82)
    XCTAssertEqual(snapshot.current.daylightDuration, 45000)
    XCTAssertEqual(snapshot.hourly.first?.windGust, 35)
    XCTAssertEqual(snapshot.hourly.first?.visibility, 12)
    XCTAssertEqual(snapshot.hourly.first?.uvIndex, 5.2)
  }

  func testAirQualityProviderKeepsSourceTimeAndReceiptTime() async throws {
    let json = #"{"timezone":"Asia/Shanghai","current":{"time":"2026-08-16T12:00","european_aqi":32,"pm2_5":18,"pm10":42,"ozone":96,"nitrogen_dioxide":22,"sulphur_dioxide":6,"carbon_monoxide":310},"hourly":{"european_aqi":[32]}}"#
    let sourceDate = try XCTUnwrap(
      WeatherDateParser.date(from: "2026-08-16T12:00", timezone: TimeZone(identifier: "Asia/Shanghai")!)
    )
    let before = Date()
    let snapshot = try await OpenMeteoAirQualityProvider(
      httpClient: StaticHTTPClient(response: Data(json.utf8))
    ).fetchAirQuality(for: .beijing)
    let after = Date()

    XCTAssertEqual(snapshot.updatedAt, sourceDate)
    XCTAssertNotNil(snapshot.fetchedAt)
    XCTAssertGreaterThanOrEqual(snapshot.fetchedAt!, before)
    XCTAssertLessThanOrEqual(snapshot.fetchedAt!, after)
  }

  func testMarineProviderKeepsSourceTimeAndReceiptTime() async throws {
    let json = #"{"timezone":"Asia/Shanghai","current":{"time":"2026-08-16T12:00","wave_height":0.8},"hourly":{"time":["2026-08-16T12:00"],"wave_height":[0.8]}}"#
    let sourceDate = try XCTUnwrap(
      WeatherDateParser.date(from: "2026-08-16T12:00", timezone: TimeZone(identifier: "Asia/Shanghai")!)
    )
    let before = Date()
    let result = try await OpenMeteoMarineProvider(
      httpClient: StaticHTTPClient(response: Data(json.utf8))
    ).fetchMarineWeather(for: .beijing)
    let snapshot = try XCTUnwrap(
      result
    )
    let after = Date()

    XCTAssertEqual(snapshot.updatedAt, sourceDate)
    XCTAssertNotNil(snapshot.fetchedAt)
    XCTAssertGreaterThanOrEqual(snapshot.fetchedAt!, before)
    XCTAssertLessThanOrEqual(snapshot.fetchedAt!, after)
  }

  func testForecastProviderKeepsAllTenDailyPoints() throws {
    let dates = (0..<11).map { offset in
      let date = String(format: "2026-08-%02d", 16 + offset)
      return "\"\(date)\""
    }.joined(separator: ",")
    let temperatures = Array(repeating: "30", count: 11).joined(separator: ",")
    let lows = Array(repeating: "24", count: 11).joined(separator: ",")
    let codes = Array(repeating: "2", count: 11).joined(separator: ",")
    let json = """
      {
        "timezone":"Asia/Shanghai",
        "current":{"time":"2026-08-16T12:00","temperature_2m":30,"weather_code":2,"is_day":1},
        "daily":{
          "time":[\(dates)],
          "temperature_2m_max":[\(temperatures)],
          "temperature_2m_min":[\(lows)],
          "weather_code":[\(codes)]
        }
      }
      """
    let payload = try JSONDecoder().decode(OpenMeteoForecastPayload.self, from: Data(json.utf8))
    let snapshot = OpenMeteoForecastProvider().makeSnapshot(from: payload, location: .beijing)
    XCTAssertEqual(snapshot.daily.count, 10)
    XCTAssertEqual(snapshot.daily.first?.high, 30)
    XCTAssertEqual(snapshot.daily.last?.low, 24)
  }

  @MainActor
  func testRefreshCoordinatorDoesNotReturnFallbackWhenNetworkFails() async {
    let fallback = WeatherSnapshot.testFixture
    let coordinator = RefreshCoordinator(
      forecastProvider: FailingForecastProvider(),
      airQualityProvider: FailingAirQualityProvider(),
      radarProvider: FailingRadarProvider(),
      marineProvider: FailingMarineProvider()
    )
    let result = await coordinator.refresh(location: .beijing, fallback: fallback)
    XCTAssertNil(result.snapshot)
    XCTAssertTrue(result.forecastAttempted)
    XCTAssertEqual(Set(result.failedSources), Set(["forecast", "airQuality", "radar", "marine"]))
  }

  func testWeatherKitProviderExplicitlyFallsBack() async {
    do {
      _ = try await AppleWeatherKitProvider().fetchForecast(for: .beijing)
      XCTFail("WeatherKit capability is intentionally absent in this unsigned build")
    } catch {
      XCTAssertTrue(
        error.localizedDescription.contains("Open-Meteo")
          || error.localizedDescription.contains("WeatherKit"))
    }
  }

  func testProviderSelectionHasOneReadableSwitchPoint() {
    XCTAssertEqual(RAYNProviderConfiguration.forecastSource, .openMeteo)
    XCTAssertEqual(RAYNProviderConfiguration.airQualitySource, .openMeteo)
    XCTAssertEqual(RAYNProviderConfiguration.radarSource, .rainViewer)
    XCTAssertEqual(RAYNProviderConfiguration.marineSource, .openMeteo)
    XCTAssertEqual(RAYNProviderConfiguration.locationSearchSource, .openMeteo)
  }

  func testLocationProviderAcceptsInjectedTransport() async throws {
    let response = Data(
      #"{"results":[{"name":"测试城市","latitude":31.2,"longitude":121.5,"timezone":"Asia/Shanghai","country":"中国","admin1":"测试省"}]}"#
        .utf8)
    let provider = OpenMeteoLocationSearchProvider(
      httpClient: StaticHTTPClient(response: response)
    )

    let results = try await provider.search(query: "测试")

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.name, "测试城市")
    XCTAssertEqual(results.first?.latitude, 31.2)
  }

  func testRetryScheduleUsesTwoFiveFifteenMinuteBackoff() {
    let base = Date(timeIntervalSince1970: 10_000)
    var schedule = RetrySchedule()
    XCTAssertEqual(schedule.recordFailure(at: base).timeIntervalSince(base), 120)
    XCTAssertEqual(schedule.recordFailure(at: base).timeIntervalSince(base), 300)
    XCTAssertEqual(schedule.recordFailure(at: base).timeIntervalSince(base), 900)
    XCTAssertFalse(schedule.isReady(at: base.addingTimeInterval(899)))
    XCTAssertTrue(schedule.isReady(at: base.addingTimeInterval(900)))
    schedule.recordSuccess()
    XCTAssertEqual(schedule.failureCount, 0)
    XCTAssertNil(schedule.retryAt)
  }

  func testRadarNoCoverageModelIsSafe() {
    XCTAssertFalse(RadarSnapshot.unavailable.isAvailable)
    XCTAssertTrue(RadarSnapshot.unavailable.frames.isEmpty)
    XCTAssertEqual(
      RadarSnapshot.unavailable.message,
      String(localized: "No radar imagery is available for this area."))
  }

  func testHeavySceneHandoffAndRadarWarmupAreSerialized() {
    let sceneHandoffDelay =
      Double(ScenePerformancePolicy.sceneHandoffDelayNanoseconds) / 1_000_000_000
    let mapActivationDelay =
      Double(RadarPerformancePolicy.mapActivationDelayNanoseconds) / 1_000_000_000
    XCTAssertGreaterThan(mapActivationDelay, sceneHandoffDelay)
    XCTAssertLessThan(ScenePerformancePolicy.fadeOutDuration, ScenePerformancePolicy.fadeInDuration)
    XCTAssertLessThanOrEqual(RadarPerformancePolicy.tileMemoryLimit, 32 * 1_024 * 1_024)
    XCTAssertEqual(RadarPerformancePolicy.tilePrefetchLimit, 34)
    XCTAssertLessThan(
      RadarPerformancePolicy.staleOverlayRemovalDelayNanoseconds,
      RadarPerformancePolicy.playbackIntervalNanoseconds
    )
  }

  func testSceneOrderMatchesRemoteDirectionOrder() {
    XCTAssertEqual(
      BroadcastScene.allCases, [.current, .hourly, .daily, .radar, .airQuality, .astronomy])
  }

  func testSettingsDecodeFromOlderReleaseAddsSceneOrder() throws {
    let legacyJSON = Data(#"{"automaticRotation":false,"hiddenScenes":["radar"]}"#.utf8)
    let settings = try JSONDecoder().decode(AppSettings.self, from: legacyJSON)

    XCTAssertEqual(settings.orderedScenes, BroadcastScene.allCases)
    XCTAssertEqual(settings.hiddenScenes, [.radar])
    XCTAssertFalse(settings.automaticRotation)
  }

  func testSceneOrderRemovesDuplicatesAndAppendsNewScenes() {
    let proposed: [BroadcastScene] = [.daily, .current, .daily, .hourly]
    XCTAssertEqual(
      AppSettings.sanitizedSceneOrder(proposed),
      [.daily, .current, .hourly, .radar, .airQuality, .astronomy]
    )
  }

  func testNightDimmingAppliesOnlyWhenEnabledAtNight() {
    XCTAssertEqual(RAYNNightDimming.opacity(isDay: true, enabled: true), 0)
    XCTAssertEqual(RAYNNightDimming.opacity(isDay: false, enabled: false), 0)
    XCTAssertEqual(
      RAYNNightDimming.opacity(isDay: false, enabled: true),
      RAYNNightDimming.maxOpacity
    )
    XCTAssertGreaterThan(RAYNNightDimming.maxOpacity, 0)
    XCTAssertLessThanOrEqual(RAYNNightDimming.maxOpacity, 0.5)
  }

  func testClothingAdviceIsCompactAndWeatherAware() {
    var current = WeatherSnapshot.testFixture.current
    current.feelsLike = 27
    current.precipitationProbability = 75
    let advice = ClothingAdviceBuilder.make(from: current)
    XCTAssertEqual(advice.index, .light)
    XCTAssertEqual(advice.outfit, String(localized: "T-shirt or lightweight long sleeves"))
    XCTAssertTrue(advice.detail.contains(String(localized: "Rain is likely. Remember an umbrella.")))
  }

  @MainActor
  func testSceneNavigationSkipsHiddenScenes() {
    let state = AppState()
    var settings = state.settings
    settings.hiddenScenes = [.hourly, .radar]
    state.applySettings(settings)
    state.select(scene: .current)
    state.nextScene()
    XCTAssertEqual(state.currentScene, .daily)
    state.applySettings(AppConfiguration.defaultSettings)
  }

  @MainActor
  func testRemoteNavigationAndPauseState() {
    let state = AppState()
    var settings = state.settings
    settings.automaticRotation = false
    settings.hiddenScenes = [.radar]
    state.applySettings(settings)
    state.select(scene: .current)
    state.handleMove(.right)
    XCTAssertEqual(state.currentScene, .hourly)
    state.handleMove(.left)
    XCTAssertEqual(state.currentScene, .current)
    XCTAssertFalse(state.isPaused)
    state.togglePause()
    XCTAssertTrue(state.isPaused)
    state.togglePause()
    XCTAssertFalse(state.isPaused)
    state.applySettings(AppConfiguration.defaultSettings)
  }

  @MainActor
  func testFocusInteractionDoesNotPublishAWholeSceneUpdate() {
    let state = AppState()
    var publications = 0
    let subscription = state.objectWillChange.sink { _ in publications += 1 }

    state.noteFocusInteraction()
    state.noteFocusInteraction()

    XCTAssertEqual(publications, 0)
    withExtendedLifetime(subscription) {}
  }

  func testBeijingUsesItsOwnTimezoneAndAllThemesExist() {
    XCTAssertEqual(SavedLocation.beijing.timezoneIdentifier, "Asia/Shanghai")
    XCTAssertGreaterThanOrEqual(WeatherTheme.allCases.count, 8)
  }

  func testSummaryCanRenderFahrenheit() {
    let summary = WeatherSummaryBuilder.make(from: .testFixture, unit: .fahrenheit)
    XCTAssertTrue(summary.headline.contains("℉"))
    XCTAssertFalse(summary.headline.contains("℃"))
  }

  func testEverySupportedLocalizationBundleIsPackaged() throws {
    XCTAssertEqual(
      Set(L10n.supportedLanguageCodes),
      Set(["en", "fr", "de", "es", "it", "ja", "ko", "zh-Hans", "zh-Hant"])
    )
    for languageCode in L10n.supportedLanguageCodes {
      XCTAssertNotNil(
        L10n.bundle(for: languageCode),
        "Missing packaged localization for \(languageCode)"
      )
    }
  }

  func testRepresentativeTranslationsAreCompleteAndDistinct() throws {
    let expected = [
      "en": "Air Quality",
      "fr": "Qualité de l’air",
      "de": "Luftqualität",
      "es": "Calidad del aire",
      "it": "Qualità dell’aria",
      "ja": "大気質",
      "ko": "대기질",
      "zh-Hans": "空气质量",
      "zh-Hant": "空氣品質",
    ]

    for languageCode in L10n.supportedLanguageCodes {
      let bundle = try XCTUnwrap(L10n.bundle(for: languageCode))
      XCTAssertEqual(L10n.string("Air Quality", bundle: bundle), expected[languageCode])
      XCTAssertNotEqual(L10n.string("Settings", bundle: bundle), "")
      XCTAssertNotEqual(L10n.string("Precipitation Radar", bundle: bundle), "")
    }
  }

  func testChineseScriptBundlesRemainDistinct() throws {
    let simplified = try XCTUnwrap(L10n.bundle(for: "zh-CN"))
    let traditional = try XCTUnwrap(L10n.bundle(for: "zh-TW"))
    XCTAssertEqual(L10n.string("Settings", bundle: simplified), "设置")
    XCTAssertEqual(L10n.string("Settings", bundle: traditional), "設定")
  }

  func testLocationSearchUsesSupportedSystemLanguageOrEnglishFallback() {
    let expected = [
      "en_US": "en", "fr_FR": "fr", "de_DE": "de", "es_ES": "es",
      "it_IT": "it", "ja_JP": "ja", "ko_KR": "ko", "zh_Hant_TW": "zh",
      "pt_BR": "en",
    ]
    for (identifier, languageCode) in expected {
      XCTAssertEqual(
        OpenMeteoLocationSearchProvider.requestLanguageCode(for: Locale(identifier: identifier)),
        languageCode
      )
    }
  }
}

extension WeatherSnapshot {
  fileprivate static var testFixture: WeatherSnapshot {
    let location = SavedLocation.beijing
    let now = Date(timeIntervalSince1970: 1_755_000_000)
    let calendar = Calendar(identifier: .gregorian)
    let current = CurrentConditions(
      temperature: 28.4,
      feelsLike: 30.1,
      high: 31.2,
      low: 23.8,
      relativeHumidity: 68,
      dewPoint: 21.7,
      pressure: 1008.6,
      visibility: 18.0,
      cloudCover: 48,
      windSpeed: 16.0,
      windDirection: 135,
      windGust: 28.0,
      uvIndex: 6.4,
      precipitationProbability: 38,
      precipitation: 0.0,
      weatherCode: 2,
      isDay: true,
      sunrise: now.addingTimeInterval(-18_000),
      sunset: now.addingTimeInterval(28_800)
    )
    let hourly = (0..<24).map { offset in
      let date = calendar.date(byAdding: .hour, value: offset, to: now) ?? now
      return HourlyForecastPoint(
        time: date,
        temperature: 27 + sin(Double(offset) / 24 * Double.pi * 2) * 4,
        apparentTemperature: 29,
        precipitationProbability: offset == 3 ? 72 : 20,
        precipitation: offset == 3 ? 1.2 : 0,
        snowfall: 0,
        windSpeed: 12,
        windDirection: 135,
        weatherCode: offset == 3 ? 61 : 2,
        isDay: offset < 13
      )
    }
    let daily = [
      DailyForecastPoint(
        date: now,
        high: 31,
        low: 24,
        weatherCode: 2,
        precipitationProbability: 20,
        precipitation: 0,
        windSpeed: 12,
        windGust: 20,
        sunrise: current.sunrise,
        sunset: current.sunset
      )
    ]
    let air = AirQualitySnapshot(
      europeanAQI: 32,
      pm25: 18,
      pm10: 42,
      ozone: 96,
      nitrogenDioxide: 22,
      sulphurDioxide: 6,
      carbonMonoxide: 310,
      updatedAt: now,
      hourlyAQI: (0..<24).map { 28 + Double(($0 * 7) % 13) }
    )
    let frames = (0..<2).map { index in
      RadarFrame(
        timestamp: Int(now.timeIntervalSince1970) + index * 600, tilePath: nil, source: "test")
    }
    var snapshot = WeatherSnapshot(
      location: location,
      timezoneIdentifier: location.timezoneIdentifier,
      current: current,
      hourly: hourly,
      daily: daily,
      airQuality: air,
      radar: RadarSnapshot(frames: frames, selectedIndex: 1, isAvailable: true, message: nil),
      marine: MarineSnapshot(
        waveHeight: 0.8, waveDirection: 112, wavePeriod: 5.6, windWaveHeight: 0.5,
        swellWaveHeight: 0.4, updatedAt: now),
      alerts: [],
      summary: .empty,
      updatedAt: now,
      source: "test",
      isOffline: false,
      theme: .clearDay
    )
    snapshot.summary = WeatherSummaryBuilder.make(from: snapshot)
    return snapshot
  }
}

private struct FailingForecastProvider: ForecastProvider {
  func fetchForecast(for location: SavedLocation) async throws -> WeatherSnapshot {
    throw WeatherProviderError.unavailable("offline")
  }
}

private struct FailingAirQualityProvider: AirQualityProvider {
  func fetchAirQuality(for location: SavedLocation) async throws -> AirQualitySnapshot {
    throw WeatherProviderError.unavailable("offline")
  }
}

private struct FailingRadarProvider: RadarProvider {
  func fetchRadar(for location: SavedLocation) async throws -> RadarSnapshot {
    throw WeatherProviderError.unavailable("offline")
  }
}

private struct FailingMarineProvider: MarineWeatherProvider {
  func fetchMarineWeather(for location: SavedLocation) async throws -> MarineSnapshot? {
    throw WeatherProviderError.unavailable("offline")
  }
}

private struct StaticHTTPClient: HTTPClient {
  let response: Data

  func data(for request: URLRequest) async throws -> Data {
    response
  }
}
