import MapKit
import SwiftUI

enum RadarPerformancePolicy {
    static let mapActivationDelayNanoseconds: UInt64 = 280_000_000
    static let initialPlaybackDelayNanoseconds: UInt64 = 900_000_000
    static let loadTimeoutNanoseconds: UInt64 = 20_000_000_000
}

struct RadarScene: View {
    let snapshot: WeatherSnapshot
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPlaying = true
    @State private var requestedIndex = 0
    @State private var presentedIndex = 0
    @State private var shouldLoadMap = false
    @State private var isMapVisible = false
    @State private var loadFailed = false
    @State private var mapReloadGeneration = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageHeader(
                eyebrow: String(localized: "Radar"),
                title: String(localized: "Precipitation Radar"),
                detail: hasNowcast
                    ? String(localized: "Observation Playback · Nowcast")
                    : String(localized: "Past Two Hours")
            )
            if snapshot.radar.isAvailable && !snapshot.radar.frames.isEmpty {
                radarPlayback
            } else {
                radarUnavailable
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 16)
        .task(id: snapshot.radar.frames.map(\.tileURLTemplate)) {
            guard snapshot.radar.isAvailable, !snapshot.radar.frames.isEmpty else { return }
            let initialIndex = min(
                max(snapshot.radar.selectedIndex, 0),
                snapshot.radar.frames.count - 1
            )
            requestedIndex = initialIndex
            presentedIndex = initialIndex
            try? await Task.sleep(nanoseconds: RadarPerformancePolicy.mapActivationDelayNanoseconds)
            guard !Task.isCancelled else { return }
            shouldLoadMap = true
        }
        .task(id: playbackTaskID) {
            guard isPlaying,
                  !loadFailed,
                  scenePhase == .active,
                  isMapVisible,
                  requestedIndex == presentedIndex,
                  snapshot.radar.frames.count > 1 else { return }
            try? await Task.sleep(nanoseconds: RadarPerformancePolicy.initialPlaybackDelayNanoseconds)
            guard !Task.isCancelled,
                  isPlaying,
                  requestedIndex == presentedIndex else { return }
            requestedIndex = (presentedIndex + 1) % snapshot.radar.frames.count
        }
        .task(id: "\(requestedFrame?.tileURLTemplate ?? "")-\(mapReloadGeneration)-\(isMapVisible)-\(presentedIndex)") {
            guard shouldLoadMap || snapshot.radar.isAvailable else { return }
            loadFailed = false
            guard !isMapVisible || requestedIndex != presentedIndex else { return }
            try? await Task.sleep(nanoseconds: RadarPerformancePolicy.loadTimeoutNanoseconds)
            guard !Task.isCancelled else { return }
            loadFailed = true
            isPlaying = false
        }
        .onDisappear {
            shouldLoadMap = false
            isMapVisible = false
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { isPlaying = false }
        }
    }

    private var radarPlayback: some View {
        HStack(spacing: 24) {
            ZStack(alignment: .bottomLeading) {
                RadarMapPreparingView()
                    .opacity(isMapVisible ? 0 : 1)

                if shouldLoadMap {
                    RadarMap(
                        location: snapshot.location,
                        frame: requestedFrame,
                        onMapReady: {
                            RAYNPerformance.radarMapReady()
                            withAnimation(.easeOut(duration: 0.16)) {
                                isMapVisible = true
                            }
                        },
                        onFramePresented: { frameID in
                            guard let index = snapshot.radar.frames.firstIndex(where: { $0.id == frameID }) else { return }
                            RAYNPerformance.radarFramePresented()
                            presentedIndex = index
                            loadFailed = false
                        }
                    )
                    .id(mapReloadGeneration)
                    .opacity(isMapVisible ? 1 : 0)
                }
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 10) {
                        Text(frameDate?.formatted(.time, timezoneIdentifier: snapshot.timezoneIdentifier) ?? "--:--")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        if requestedIndex != presentedIndex {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white.opacity(0.75))
                        }
                    }
                    Text(
                        displayedFrame?.isForecast == true
                            ? String(localized: "Nowcast · Nearby Weather Systems")
                            : String(localized: "Past Two Hours · Nearby Weather Systems")
                    )
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.66))
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 415)
            .background(Color.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 18) {
                Text("Animation Controls").font(.system(size: 26, weight: .bold, design: .rounded))
                if loadFailed {
                    Text("Radar loading failed").font(.system(size: 22, weight: .medium))
                    Button("Retry") {
                        loadFailed = false
                        isMapVisible = false
                        mapReloadGeneration += 1
                    }
                    .buttonStyle(FocusButtonStyle())
                }
                Button {
                    isPlaying.toggle()
                } label: {
                    Label(
                        isPlaying ? String(localized: "Pause Radar") : String(localized: "Play Radar"),
                        systemImage: isPlaying ? "pause.fill" : "play.fill"
                    )
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(FocusButtonStyle())
                .foregroundStyle(.white)
                HStack(spacing: 12) {
                    Button {
                        requestedIndex = max(0, presentedIndex - 1)
                        isPlaying = false
                    } label: {
                        Image(systemName: "backward.fill")
                            .frame(width: 54, height: 44)
                    }
                    .buttonStyle(FocusButtonStyle())
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text("Frame \(snapshot.radar.frames.isEmpty ? 0 : presentedIndex + 1) of \(snapshot.radar.frames.count)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(maxWidth: .infinity)
                    Button {
                        requestedIndex = min(max(snapshot.radar.frames.count - 1, 0), presentedIndex + 1)
                        isPlaying = false
                    } label: {
                        Image(systemName: "forward.fill")
                            .frame(width: 54, height: 44)
                    }
                    .buttonStyle(FocusButtonStyle())
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .foregroundStyle(.white)
                HStack {
                    Text("Earlier").foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Text("Later").foregroundStyle(.white.opacity(0.55))
                }
                .font(.system(size: 19, weight: .medium, design: .rounded))
                RadarLegend(palette: displayedFrame?.tileDescriptor?.palette ?? .universalBlue,
                            legendURLString: displayedFrame?.tileDescriptor?.legendURLString)
                Text(displayedFrame?.source ?? "")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Coverage reflects available radar data")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(16)
            .frame(width: 304)
        }
    }

    private var radarUnavailable: some View {
        GlassCard(cornerRadius: 28, tint: .cyan) {
            HStack(spacing: 22) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 8) {
                    Text("No live radar echoes are available")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(snapshot.radar.message ?? String(localized: "No radar imagery is available for this area."))
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var displayedIndex: Int {
        guard !snapshot.radar.frames.isEmpty else { return 0 }
        return min(max(presentedIndex, 0), snapshot.radar.frames.count - 1)
    }

    private var frameDate: Date? {
        guard snapshot.radar.frames.indices.contains(displayedIndex) else { return nil }
        return snapshot.radar.frames[displayedIndex].date
    }

    private var displayedFrame: RadarFrame? {
        guard snapshot.radar.frames.indices.contains(displayedIndex) else { return nil }
        return snapshot.radar.frames[displayedIndex]
    }

    private var requestedFrame: RadarFrame? {
        guard snapshot.radar.frames.indices.contains(requestedIndex) else { return nil }
        return snapshot.radar.frames[requestedIndex]
    }

    private var hasNowcast: Bool {
        snapshot.radar.frames.contains(where: \.isForecast)
    }

    private var playbackTaskID: String {
        "\(isPlaying)-\(isMapVisible)-\(requestedIndex)-\(presentedIndex)-\(snapshot.radar.frames.count)"
    }
}

private struct RadarMap: View {
    let location: SavedLocation
    let frame: RadarFrame?
    let onMapReady: () -> Void
    let onFramePresented: (Int) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
#if targetEnvironment(simulator)
            #if DEBUG
            if ProcessInfo.processInfo.environment["RAYN_SIMULATOR_RADAR"] == "1",
               let tileURLTemplate = frame?.tileURLTemplate,
               !tileURLTemplate.isEmpty {
                RadarTileMapView(
                    location: location,
                    frameID: frame?.id ?? 0,
                    tileURLTemplate: tileURLTemplate,
                    maximumZoom: frame?.tileDescriptor?.maximumZoom ?? 7,
                    onMapReady: onMapReady,
                    onFramePresented: onFramePresented
                )
            } else {
                simulatorUnavailableView
            }
            #else
            simulatorUnavailableView
            #endif
#else
            if let tileURLTemplate = frame?.tileURLTemplate, !tileURLTemplate.isEmpty {
                RadarTileMapView(
                    location: location,
                    frameID: frame?.id ?? 0,
                    tileURLTemplate: tileURLTemplate,
                    maximumZoom: frame?.tileDescriptor?.maximumZoom ?? 7,
                    onMapReady: onMapReady,
                    onFramePresented: onFramePresented
                )
            } else {
                RadarTileUnavailableView()
            }
#endif
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                Text("Precipitation Playback")
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.42), in: Capsule())
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var simulatorUnavailableView: some View {
        // Live provider tiles can be opted into for maintainer captures, but
        // the default simulator path remains deterministic and never invents
        // precipitation echoes as a visual substitute.
        RadarSimulatorUnavailableView(frame: frame)
            .task(id: frame?.id) {
                onMapReady()
                if let frame {
                    onFramePresented(frame.id)
                }
            }
    }
}

private struct RadarSimulatorUnavailableView: View {
    let frame: RadarFrame?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B1A2B), Color(hex: 0x172D42)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 12) {
                Image(systemName: "tv.and.hifispeaker.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("Live radar maps appear on Apple TV hardware")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(
                    frame == nil
                        ? String(localized: "No radar frame is currently available")
                        : String(localized: "The simulator does not render live map tiles")
                )
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .multilineTextAlignment(.center)
        }
    }
}

private struct RadarMapPreparingView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0B1A2B), Color(hex: 0x172D42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.cyan)
                Text("Preparing Live Radar")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                Text("Weather is ready. The map will load next.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}

private struct RadarTileUnavailableView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B1A2B), Color(hex: 0x172D42)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 10) {
                Image(systemName: "map.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("No map tiles are available for this radar frame")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
            }
            .multilineTextAlignment(.center)
        }
    }
}


private struct RadarLegend: View {
    var palette: RadarPalette
    var legendURLString: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reflectivity (dBZ)").font(.system(size: 22, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.78))
            if palette == .reflectivity {
                AsyncImage(url: legendURLString.flatMap(URL.init(string:))) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Text("Legend unavailable").foregroundStyle(.secondary)
                }
                .frame(maxHeight: 180)
            } else {
                HStack(spacing: 0) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                        VStack(spacing: 8) {
                            Rectangle().fill(color).frame(height: 14)
                            Text(verbatim: "\(15 + index * 10)")
                                .font(.system(size: 19, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var colors: [Color] {
        switch palette {
        case .universalBlue:
            // 15,25,35,45,55,65 dBZ from RainViewer's published Universal Blue CSV.
            return [0x88DDEE, 0x0077AA, 0xFFEE00, 0xFF4400, 0xFFAAFF, 0xFFFFFF].map { Color(hex: $0) }
        case .reflectivity:
            return []
        }
    }
}
