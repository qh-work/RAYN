import Foundation
import CoreLocation
import MapKit
import SwiftUI

enum WeatherDataState: Equatable {
    case waiting
    case locating
    case loading
    case live
    case unavailable
}

enum AppFailureSource {
    static let locationSearch = "locationSearch"
    static let currentLocation = "currentLocation"
}

@MainActor
final class AppState: ObservableObject {
    @Published var snapshot: WeatherSnapshot?
    @Published var selectedLocation: SavedLocation
    @Published var savedLocations: [SavedLocation]
    @Published var settings: AppSettings
    @Published var dataState: WeatherDataState = .waiting
    @Published var currentScene: BroadcastScene = .current
    @Published var isPaused = false
    @Published var controlsVisible = true
    @Published var isRefreshing = false
    @Published var failedSources: [String] = []
    @Published var searchResults: [SavedLocation] = []
    @Published var isSearching = false
    @Published var showSettings = false
    @Published var lastInteraction = Date()

    private let refreshCoordinator: RefreshCoordinator
    private let locationSearchProvider: LocationSearchProvider
    private let locationService = LocationService()
    private var rotationTask: Task<Void, Never>?
    private var refreshMonitorTask: Task<Void, Never>?
    private var controlsTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    #if DEBUG
    private var captureTourTask: Task<Void, Never>?
    #endif
    private var hasStarted = false
    private var isAppActive = true

    private enum Keys {
        static let settings = "RAYN.settings"
        static let locations = "RAYN.savedLocations"
        static let locationPriorityMigration = "RAYN.locationPriorityMigration"
        static let automaticRotationOptInMigration = "RAYN.automaticRotationOptInMigration"
    }

    init(
        refreshCoordinator: RefreshCoordinator? = nil,
        locationSearchProvider: LocationSearchProvider = RAYNProviderConfiguration.makeLocationSearchProvider()
    ) {
        let coordinator = refreshCoordinator ?? RefreshCoordinator()
        self.refreshCoordinator = coordinator
        self.locationSearchProvider = locationSearchProvider
        let defaults = UserDefaults.standard
        var storedSettings = (try? defaults.data(forKey: Keys.settings).flatMap { try JSONDecoder().decode(AppSettings.self, from: $0) }) ?? AppConfiguration.defaultSettings
        var storedLocations = (try? defaults.data(forKey: Keys.locations).flatMap { try JSONDecoder().decode([SavedLocation].self, from: $0) }) ?? AppConfiguration.defaultFavorites
        if !defaults.bool(forKey: Keys.locationPriorityMigration) {
            storedSettings.useCurrentLocation = true
            defaults.set(true, forKey: Keys.locationPriorityMigration)
            if let data = try? JSONEncoder().encode(storedSettings) {
                defaults.set(data, forKey: Keys.settings)
            }
        }
        // Previous builds silently enabled scene rotation. Make it opt-in once
        // so a manual radar selection cannot unexpectedly advance to Air
        // Quality on an already-installed Apple TV.
        if !defaults.bool(forKey: Keys.automaticRotationOptInMigration) {
            storedSettings.automaticRotation = false
            defaults.set(true, forKey: Keys.automaticRotationOptInMigration)
            if let data = try? JSONEncoder().encode(storedSettings) {
                defaults.set(data, forKey: Keys.settings)
            }
        }
        let captureLocation: SavedLocation?
        #if DEBUG
        captureLocation = AppConfiguration.captureLocation(
            named: ProcessInfo.processInfo.environment["RAYN_CAPTURE_LOCATION"]
        )
        let captureFavorites = AppConfiguration.captureLocations(
            namedList: ProcessInfo.processInfo.environment["RAYN_CAPTURE_FAVORITES"]
        )
        if !captureFavorites.isEmpty {
            storedLocations = captureFavorites
        }
        if captureLocation != nil {
            storedSettings.useCurrentLocation = false
        }
        #else
        captureLocation = nil
        #endif
        self.settings = storedSettings
        self.savedLocations = storedLocations
        self.selectedLocation = captureLocation ?? (storedSettings.useCurrentLocation
            ? .currentPlaceholder
            : (storedLocations.first ?? .currentPlaceholder))
        self.snapshot = nil
        let launchArgumentScene = CommandLine.arguments
            .first(where: { $0.hasPrefix("--rayn-scene=") })?
            .split(separator: "=", maxSplits: 1)
            .last
            .map(String.init)
        let initialSceneValue = ProcessInfo.processInfo.environment["RAYN_INITIAL_SCENE"] ?? launchArgumentScene
        if let initialScene = initialSceneValue.flatMap(BroadcastScene.init(rawValue:)), !settings.hiddenScenes.contains(initialScene) {
            self.currentScene = initialScene
        }
        applyScreenAwakeSetting()
    }

    deinit {
        rotationTask?.cancel()
        refreshMonitorTask?.cancel()
        controlsTask?.cancel()
        searchTask?.cancel()
        #if DEBUG
        captureTourTask?.cancel()
        #endif
    }

    var visibleScenes: [BroadcastScene] {
        settings.orderedScenes.filter { !settings.hiddenScenes.contains($0) }
    }

    var localTimeZone: TimeZone {
        TimeZone(identifier: snapshot?.timezoneIdentifier ?? selectedLocation.timezoneIdentifier) ?? .current
    }

    var dataAttributions: [DataAttribution] {
        DataAttribution.unique(refreshCoordinator.dataAttributions + locationSearchProvider.dataAttributions)
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        if settings.useCurrentLocation {
            dataState = .locating
            updateCurrentLocation()
        } else if selectedLocation.id == SavedLocation.currentPlaceholder.id {
            dataState = .unavailable
            failedSources = [AppFailureSource.locationSearch]
        } else {
            refresh(force: true)
        }
        restartRotationTask()
        restartRefreshMonitor()
        #if DEBUG
        startCaptureTourIfRequested()
        #endif
    }

    func refresh(force: Bool = false) {
        guard !isRefreshing else { return }
        if selectedLocation.id == SavedLocation.currentPlaceholder.id {
            if settings.useCurrentLocation {
                dataState = .locating
                updateCurrentLocation()
            } else {
                dataState = .unavailable
                failedSources = [AppFailureSource.locationSearch]
            }
            return
        }
        isRefreshing = true
        if snapshot == nil {
            dataState = .loading
        }
        let location = selectedLocation
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await refreshCoordinator.refresh(location: location, fallback: snapshot, force: force)
            // A city may be changed while the previous request is in flight.
            // Never publish the old city's response under the new title; start
            // one fresh request for the latest selection instead.
            guard selectedLocation.id == location.id else {
                isRefreshing = false
                refresh(force: true)
                return
            }
            if result.forecastAttempted {
                snapshot = result.snapshot
                dataState = result.snapshot == nil ? .unavailable : .live
            } else if result.snapshot != nil {
                dataState = .live
            }
            failedSources = result.failedSources
            isRefreshing = false
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isAppActive = true
            if snapshot == nil {
                if settings.useCurrentLocation && selectedLocation.id == SavedLocation.currentPlaceholder.id {
                    dataState = .locating
                    updateCurrentLocation()
                } else if selectedLocation.id == SavedLocation.currentPlaceholder.id {
                    dataState = .unavailable
                    failedSources = [AppFailureSource.locationSearch]
                } else {
                    refresh()
                }
            }
            restartRefreshMonitor()
        case .inactive, .background:
            isAppActive = false
            refreshMonitorTask?.cancel()
        @unknown default:
            break
        }
    }

    func nextScene() {
        let scenes = visibleScenes
        guard !scenes.isEmpty else { return }
        let currentIndex = scenes.firstIndex(of: currentScene) ?? 0
        currentScene = scenes[(currentIndex + 1) % scenes.count]
        revealControls()
    }

    func previousScene() {
        let scenes = visibleScenes
        guard !scenes.isEmpty else { return }
        let currentIndex = scenes.firstIndex(of: currentScene) ?? 0
        currentScene = scenes[(currentIndex - 1 + scenes.count) % scenes.count]
        revealControls()
    }

    func select(scene: BroadcastScene) {
        guard !settings.hiddenScenes.contains(scene) else { return }
        currentScene = scene
        revealControls()
    }

    func togglePause() {
        isPaused.toggle()
        revealControls()
    }

    func revealControls() {
        controlsVisible = true
        lastInteraction = Date()
        // A manual interaction starts a fresh dwell period. Without this,
        // selecting Radar near the old timer deadline immediately advanced to
        // Air Quality, which looked like an incorrect intermediate scene.
        restartRotationTask()
        controlsTask?.cancel()
        #if DEBUG
        // Accessibility queries are deliberately slower than a real remote.
        // Keep navigation visible only for deterministic UI automation; the
        // release app still hides it after the normal five-second dwell.
        if ProcessInfo.processInfo.environment["RAYN_KEEP_CONTROLS_VISIBLE"] == "1" {
            return
        }
        #endif
        controlsTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard let self, Date().timeIntervalSince(lastInteraction) >= 4.8 else { return }
            controlsVisible = false
        }
    }

    func applySettings(_ newSettings: AppSettings) {
        let shouldRequestLocation = newSettings.useCurrentLocation && !settings.useCurrentLocation
        let shouldReturnToSavedLocation = !newSettings.useCurrentLocation && settings.useCurrentLocation
        var normalizedSettings = newSettings
        normalizedSettings.normalizeSceneOrder()
        settings = normalizedSettings
        persistSettings()
        applyScreenAwakeSetting()
        if settings.hiddenScenes.contains(currentScene) {
            currentScene = visibleScenes.first ?? .current
        }
        restartRotationTask()
        revealControls()
        if shouldRequestLocation {
            selectedLocation = .currentPlaceholder
            snapshot = nil
            dataState = .locating
            updateCurrentLocation()
        } else if shouldReturnToSavedLocation {
            snapshot = nil
            dataState = .waiting
            if let savedLocation = savedLocations.first {
                selectedLocation = savedLocation
                refresh(force: true)
            } else {
                selectedLocation = .currentPlaceholder
                dataState = .unavailable
                failedSources = [AppFailureSource.locationSearch]
            }
        }
    }

    func setRotationSeconds(_ seconds: Double) {
        settings.rotationSeconds = min(max(seconds, 8), 30)
        persistSettings()
        restartRotationTask()
    }

    func chooseLocation(_ location: SavedLocation) {
        setLocation(location, usingCurrentLocation: false)
    }

    func chooseCurrentLocation() {
        guard !settings.useCurrentLocation else { return }
        var updatedSettings = settings
        updatedSettings.useCurrentLocation = true
        applySettings(updatedSettings)
    }

    private func setLocation(_ location: SavedLocation, usingCurrentLocation: Bool) {
        selectedLocation = location
        settings.useCurrentLocation = usingCurrentLocation
        persistSettings()
        if !usingCurrentLocation && !savedLocations.contains(where: { $0.id == location.id }) {
            savedLocations.append(location)
        }
        persistLocations()
        snapshot = nil
        dataState = .waiting
        refresh(force: true)
        showSettings = false
    }

    func searchLocations(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let results = try await locationSearchProvider.search(query: trimmed)
                guard !Task.isCancelled else { return }
                searchResults = results
                isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                searchResults = []
                isSearching = false
            }
        }
    }

    func toggleFavorite(_ location: SavedLocation) {
        if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
            savedLocations[index].isFavorite.toggle()
            if !savedLocations[index].isFavorite && savedLocations.count > 1 {
                savedLocations.remove(at: index)
            }
        } else {
            var favorite = location
            favorite.isFavorite = true
            savedLocations.append(favorite)
        }
        persistLocations()
    }

    func removeFavorite(_ location: SavedLocation) {
        savedLocations.removeAll { $0.id == location.id }
        persistLocations()
    }

    func handleMove(_ direction: MoveCommandDirection) {
        switch direction {
        case .left: previousScene()
        case .right: nextScene()
        case .up, .down: revealControls()
        @unknown default: revealControls()
        }
    }

    private func restartRotationTask() {
        rotationTask?.cancel()
        guard settings.automaticRotation else { return }
        rotationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let nanos = UInt64(max(8, settings.rotationSeconds) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                guard !Task.isCancelled, settings.automaticRotation, !isPaused else { continue }
                let scenes = visibleScenes
                guard !scenes.isEmpty else { continue }
                let index = scenes.firstIndex(of: currentScene) ?? 0
                currentScene = scenes[(index + 1) % scenes.count]
            }
        }
    }

    #if DEBUG
    /// Drives a short, repeatable scene tour for repository media. It changes
    /// presentation only and waits for the same live snapshot used by normal
    /// interaction; no fixture or synthetic weather enters the app.
    private func startCaptureTourIfRequested() {
        guard CommandLine.arguments.contains("--rayn-capture-tour") else { return }
        captureTourTask?.cancel()
        captureTourTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for _ in 0..<80 where snapshot == nil {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }
            }
            guard snapshot != nil else { return }
            // Give the capture process time to attach after live data has
            // arrived. This exists only in Debug builds and never affects the
            // normal application experience.
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            let tour: [(BroadcastScene, UInt64)] = [
                (.current, 4_000_000_000),
                (.hourly, 4_000_000_000),
                (.daily, 4_000_000_000),
                (.radar, 8_000_000_000),
                (.airQuality, 4_000_000_000),
                (.astronomy, 5_000_000_000),
            ]
            for (scene, dwell) in tour {
                guard !Task.isCancelled else { return }
                currentScene = scene
                controlsVisible = true
                try? await Task.sleep(nanoseconds: dwell)
            }
        }
    }
    #endif

    private func restartRefreshMonitor() {
        refreshMonitorTask?.cancel()
        refreshMonitorTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 60_000_000_000)
                } catch {
                    return
                }
                guard let self, isAppActive, !isRefreshing else { continue }
                refresh()
            }
        }
    }

    private func persistSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Keys.settings)
    }

    private func persistLocations() {
        guard let data = try? JSONEncoder().encode(savedLocations) else { return }
        UserDefaults.standard.set(data, forKey: Keys.locations)
    }

    private func applyScreenAwakeSetting() {
        #if os(tvOS)
        UIApplication.shared.isIdleTimerDisabled = settings.keepScreenAwake
        #endif
    }

    private func updateCurrentLocation() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let coordinate = try await locationService.requestCurrentLocation()
                guard settings.useCurrentLocation else { return }
                let mapItem = await reverseGeocode(coordinate)
                guard settings.useCurrentLocation else { return }
                let address = mapItem?.addressRepresentations
                let locality = address?.cityName ?? mapItem?.name
                let cityContext = address?.cityWithContext ?? ""
                let administrativeArea = cityContext == locality ? "" : cityContext
                let country = address?.regionName ?? ""
                let location = SavedLocation(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
                    name: locality ?? String(localized: "Current Location"),
                    administrativeArea: administrativeArea == locality ? "" : administrativeArea,
                    country: country,
                    latitude: coordinate.coordinate.latitude,
                    longitude: coordinate.coordinate.longitude,
                    timezoneIdentifier: TimeZone.current.identifier,
                    isFavorite: false
                )
                setLocation(location, usingCurrentLocation: true)
            } catch {
                guard settings.useCurrentLocation else { return }
                failedSources = Array(Set(failedSources + [AppFailureSource.currentLocation]))
                if let savedLocation = savedLocations.first {
                    selectedLocation = savedLocation
                    snapshot = nil
                    dataState = .loading
                    refresh(force: true)
                } else {
                    dataState = .unavailable
                }
            }
        }
    }

    /// Uses the tvOS 26+ MapKit reverse-geocoding API instead of the deprecated
    /// CLGeocoder API, keeping the current-location path aligned with the latest
    /// Apple SDK while retaining coordinate-only fallback when no place is found.
    private func reverseGeocode(_ location: CLLocation) async -> MKMapItem? {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        let mapItems = try? await request.mapItems
        return mapItems?.first
    }
}
