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
    @State private var presentedScene: BroadcastScene = .current
    @State private var sceneOpacity = 1.0
    @State private var sceneTransitionTask: Task<Void, Never>?
    @State private var selectedDailyDayID: Date?

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
        .onExitCommand {
            if appState.showSettings {
                appState.showSettings = false
            } else if selectedDailyDayID != nil {
                selectedDailyDayID = nil
            } else if appState.currentScene != .current {
                // A second-level weather scene should return to the main
                // weather scene with one Menu press, matching tvOS back
                // navigation instead of trapping the user in the tab.
                appState.select(scene: .current)
            } else {
                appState.revealControls()
            }
        }
        .task {
            presentedScene = appState.currentScene
            appState.start()
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

    private func topNavigation(snapshot: WeatherSnapshot, layoutScale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12 * layoutScale) {
            HStack(spacing: 22 * layoutScale) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(snapshot.location.name)
                        .font(.system(size: 30 * layoutScale, weight: .bold, design: .rounded))
                    Text("RAYN · 天气演播室")
                        .font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                }
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
                .accessibilityLabel("设置")
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
        return "日月海况"
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

        sceneTransitionTask = Task { @MainActor in
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
        HStack(spacing: 24 * layoutScale) {
            LiveIndicator()
            Rectangle().fill(.white.opacity(0.22)).frame(width: 1, height: 24 * layoutScale)
            TickerText(snapshot: snapshot)
            Spacer()
            if appState.isPaused {
                Label("已暂停", systemImage: "pause.fill")
                    .font(.system(size: 18 * layoutScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)
            }
            Text("更新 \(snapshot.updatedAt.formatted("HH:mm", timezoneIdentifier: snapshot.timezoneIdentifier))")
                .font(.system(size: 17 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.54))
        }
        .padding(.horizontal, 22 * layoutScale)
        .frame(height: 54 * layoutScale)
        .background(.regularMaterial, in: Capsule())
        .padding(.top, 12 * layoutScale)
    }

    private func liveDataPlaceholder(layoutScale: CGFloat) -> some View {
        VStack(spacing: 24 * layoutScale) {
            Image(systemName: appState.dataState == .unavailable ? "wifi.exclamationmark" : "cloud.sun.fill")
                .font(.system(size: 72 * layoutScale, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                .symbolEffect(.pulse, options: .repeating, isActive: appState.dataState == .loading)
            Text(appState.dataState == .unavailable ? "暂时无法获取实时天气" : "正在获取实时天气")
                .font(.system(size: 34 * layoutScale, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(placeholderDetail)
                .font(.system(size: 21 * layoutScale, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
            if appState.dataState == .unavailable {
                Button("重新获取") {
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
            return "正在读取 Apple TV 的当前位置"
        case .loading:
            return appState.selectedLocation.id == SavedLocation.currentPlaceholder.id
                ? "正在准备天气服务"
                : "正在获取 \(appState.selectedLocation.name) 的实时天气"
        case .unavailable:
            if appState.failedSources.contains("地址") {
                return "请在设置中搜索并选择一个地址"
            }
            return appState.failedSources.contains("当前位置")
                ? "无法定位，已尝试使用设定地址"
                : "请检查 Apple TV 的网络连接"
        case .waiting, .live:
            return "准备中"
        }
    }
}
