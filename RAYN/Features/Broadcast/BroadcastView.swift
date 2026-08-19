import SwiftUI

enum ScenePerformancePolicy {
    // Heavy SwiftUI scenes are handed over serially. The outgoing scene is
    // already invisible before the next scene builds, so Charts, material
    // cards, and MapKit never compete for the same 4K frame.
    static let fadeOutDuration = 0.08
    static let sceneHandoffDelayNanoseconds: UInt64 = 90_000_000
    static let sceneLayoutDelayNanoseconds: UInt64 = 45_000_000
    static let fadeInDuration = 0.14
}

struct BroadcastView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.resetFocus) private var resetFocus
    @State private var presentedScene: BroadcastScene = .current
    @State private var sceneOpacity = 1.0
    @State private var sceneTransitionTask: Task<Void, Never>?
    @State private var selectedDailyDayID: Date?
    @State private var hasAssignedInitialFocus = false
    @Namespace private var broadcastFocusScope

    var body: some View {
        GeometryReader { geometry in
            let layoutScale = RAYNLayout.scale(for: geometry.size, viewingDistance: appState.settings.viewingDistance)

            ZStack {
                DynamicSkyView(
                    theme: appState.snapshot?.theme ?? .clearNight,
                    isDay: appState.snapshot?.current.isDay ?? false,
                    intensity: appState.settings.dynamicIntensity,
                    reduceMotion: appState.settings.reduceMotion,
                    lightningEnabled: appState.settings.lightningEnabled
                )

                if let snapshot = appState.snapshot {
                    VStack(spacing: 0) {
                        topNavigation(snapshot: snapshot, layoutScale: layoutScale)
                        sceneContent(scene: presentedScene, snapshot: snapshot)
                            .opacity(sceneOpacity)
                            .allowsHitTesting(sceneOpacity > 0.99)
                        bottomTicker(snapshot: snapshot, layoutScale: layoutScale)
                    }
                    .focusScope(broadcastFocusScope)
                    .padding(.horizontal, max(80, 58 * layoutScale))
                    .padding(.top, max(60, 36 * layoutScale))
                    .padding(.bottom, max(60, 30 * layoutScale))
                } else {
                    liveDataPlaceholder(layoutScale: layoutScale)
                }
            }
            .environment(\.raynLayoutScale, layoutScale)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onMoveCommand { _ in
            // Directional input belongs to the tvOS focus engine. Mutating the
            // scene here made one swipe both move tab focus and change pages,
            // so Radar could briefly or permanently land on Air Quality.
            appState.revealControls()
        }
        .onPlayPauseCommand {
            appState.togglePause()
        }
        // Supplying nil on the root scene leaves the Menu/Back command to
        // tvOS, so a press exits to the Home Screen. Secondary weather scenes
        // still consume one press to return here first.
        .onExitCommand(perform: shouldInterceptExitCommand ? handleExitCommand : nil)
        .task {
            presentedScene = appState.currentScene
            appState.start()
        }
        .task(id: appState.snapshot != nil) {
            guard appState.snapshot != nil,
                  !hasAssignedInitialFocus,
                  appState.currentScene == .current else { return }
            // The live hierarchy replaces a non-focusable loading view. Ask
            // for focus after that replacement has completed; a preference
            // alone is not reevaluated consistently by tvOS in this case.
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            hasAssignedInitialFocus = true
            resetFocus(in: broadcastFocusScope)
        }
        .onChange(of: appState.currentScene) { _, nextScene in
            present(nextScene)
        }
        .onDisappear {
            sceneTransitionTask?.cancel()
        }
        .fullScreenCover(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
    }

    private var shouldInterceptExitCommand: Bool {
        appState.currentScene != .current
    }

    private func handleExitCommand() {
        if selectedDailyDayID != nil {
            selectedDailyDayID = nil
        } else {
            appState.select(scene: .current)
        }
    }

    private func topNavigation(snapshot: WeatherSnapshot, layoutScale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12 * layoutScale) {
            HStack(spacing: 22 * layoutScale) {
                Text(snapshot.location.name)
                    .font(.system(size: 30 * layoutScale, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                Spacer()
                Button {
                    appState.showSettings = true
                    appState.revealControls()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24 * layoutScale, weight: .semibold))
                        .frame(width: 50 * layoutScale, height: 50 * layoutScale)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .focusAdaptiveGlassForeground()
                .accessibilityLabel("Settings")
            }
            // The full header acts as a directional focus guide to the gear.
            // Otherwise the small top-right target is unreachable from most
            // tab positions on a 16:9 television layout.
            .focusSection()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10 * layoutScale) {
                    ForEach(appState.visibleScenes) { scene in
                        Button {
                            appState.select(scene: scene)
                        } label: {
                            Label(navigationTitle(for: scene, snapshot: snapshot), systemImage: scene.symbolName)
                                .font(.system(size: 17 * layoutScale, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 14 * layoutScale)
                                .padding(.vertical, 9 * layoutScale)
                        }
                        .buttonStyle(.glass)
                        .tint(scene == appState.currentScene ? .cyan : .white)
                        .focusAdaptiveGlassForeground()
                        // All scenes except the 10-day list have no primary
                        // content control. Keep their active tab available as
                        // tvOS's deterministic recovery target if a scene
                        // handoff temporarily leaves the focus system empty.
                        .prefersDefaultFocus(
                            scene == appState.currentScene && scene != .daily,
                            in: broadcastFocusScope
                        )
                    }
                }
                // Native glass buttons expand and cast a wider shadow while
                // focused. Keep a small horizontal focus gutter at both ends.
                .padding(.horizontal, 10 * layoutScale)
                .opacity(appState.controlsVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: appState.controlsVisible)
            }
            // Scroll views clip to their bounds by default, which visibly cut
            // the native tvOS focus halo above and below the navigation row.
            .scrollClipDisabled()
            // Allow only the focus halo overscan; do not let scrolled content
            // paint across the rest of the header.
            .clipShape(Rectangle().inset(by: -20 * layoutScale))
            .focusSection()
        }
        .frame(height: 118 * layoutScale)
    }

    private func navigationTitle(for scene: BroadcastScene, snapshot: WeatherSnapshot) -> String {
        guard scene == .astronomy, snapshot.marine != nil else { return scene.title }
        return String(localized: "Sun, Moon & Marine")
    }

    @ViewBuilder
    private func sceneContent(scene: BroadcastScene, snapshot: WeatherSnapshot) -> some View {
        switch scene {
        case .current:
            CurrentWeatherScene(snapshot: snapshot)
        case .hourly:
            HourlyForecastScene(snapshot: snapshot)
        case .daily:
            DailyForecastScene(snapshot: snapshot, selectedDayID: $selectedDailyDayID)
        case .radar:
            RadarScene(snapshot: snapshot)
        case .airQuality:
            AirQualityScene(snapshot: snapshot)
        case .astronomy:
            AstronomyScene(snapshot: snapshot)
        }
    }

    private func present(_ nextScene: BroadcastScene) {
        sceneTransitionTask?.cancel()
        if nextScene != .daily {
            selectedDailyDayID = nil
        }

        guard nextScene != presentedScene else {
            withAnimation(.easeOut(duration: ScenePerformancePolicy.fadeInDuration)) {
                sceneOpacity = 1
            }
            return
        }

        let previousScene = presentedScene
        sceneTransitionTask = Task { @MainActor in
            let performanceInterval = RAYNPerformance.beginSceneTransition(
                from: previousScene,
                to: nextScene
            )
            defer { RAYNPerformance.endSceneTransition(performanceInterval) }
            withAnimation(.easeOut(duration: ScenePerformancePolicy.fadeOutDuration)) {
                sceneOpacity = 0
            }
            try? await Task.sleep(nanoseconds: ScenePerformancePolicy.sceneHandoffDelayNanoseconds)
            guard !Task.isCancelled else { return }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                presentedScene = nextScene
            }

            // Give the new hierarchy one render pass to lay itself out while
            // transparent. This prevents the first visible frame from paying
            // the construction cost of Charts or MapKit.
            try? await Task.sleep(nanoseconds: ScenePerformancePolicy.sceneLayoutDelayNanoseconds)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: ScenePerformancePolicy.fadeInDuration)) {
                sceneOpacity = 1
            }
        }
    }

    private func bottomTicker(snapshot: WeatherSnapshot, layoutScale: CGFloat) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 16 * layoutScale) {
                LiveIndicator()
                Rectangle()
                    .fill(.white.opacity(0.20))
                    .frame(width: 1, height: 24 * layoutScale)
                TickerClock()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TickerWeatherSummary(snapshot: snapshot)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 18 * layoutScale) {
                if appState.isPaused {
                    Label("Paused", systemImage: "pause.fill")
                        .font(.system(size: 17 * layoutScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                }
                DataFreshnessLabel(
                    updatedAt: snapshot.updatedAt,
                    fetchedAt: snapshot.fetchedAt,
                    timezoneIdentifier: snapshot.timezoneIdentifier
                )
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 28 * layoutScale)
        .frame(height: 60 * layoutScale)
        .background(.regularMaterial, in: Capsule())
        .padding(.top, 18 * layoutScale)
    }

    private func liveDataPlaceholder(layoutScale: CGFloat) -> some View {
        VStack(spacing: 24 * layoutScale) {
            Image(systemName: appState.dataState == .unavailable ? "wifi.exclamationmark" : "cloud.sun.fill")
                .font(.system(size: 72 * layoutScale, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                .symbolEffect(.pulse, options: .repeating, isActive: appState.dataState == .loading)
            Text(
                appState.dataState == .unavailable
                    ? String(localized: "Live weather is temporarily unavailable")
                    : String(localized: "Loading live weather")
            )
                .font(.system(size: 34 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(placeholderDetail)
                .font(.system(size: 21 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
            if appState.dataState == .unavailable {
                Button("Try Again") {
                    appState.refresh(force: true)
                }
                .buttonStyle(.glass)
                .tint(.cyan)
                .focusAdaptiveGlassForeground()
            }
        }
    }

    private var placeholderDetail: String {
        switch appState.dataState {
        case .locating:
            return String(localized: "Reading the Apple TV's current location")
        case .loading:
            return appState.selectedLocation.id == SavedLocation.currentPlaceholder.id
                ? String(localized: "Preparing weather services")
                : String(localized: "Loading live weather for \(appState.selectedLocation.name)")
        case .unavailable:
            if appState.failedSources.contains(AppFailureSource.locationSearch) {
                return String(localized: "Search for and select a location in Settings.")
            }
            return appState.failedSources.contains(AppFailureSource.currentLocation)
                ? String(localized: "Location was unavailable, so the saved location was used.")
                : String(localized: "Check the Apple TV's network connection.")
        case .waiting, .live:
            return String(localized: "Preparing…")
        }
    }
}
