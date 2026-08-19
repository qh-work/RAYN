import MapKit
import SwiftUI

enum RadarPerformancePolicy {
    static let mapActivationDelayNanoseconds: UInt64 = 280_000_000
    static let initialPlaybackDelayNanoseconds: UInt64 = 900_000_000
    static let playbackIntervalNanoseconds: UInt64 = 1_100_000_000
    static let staleOverlayRemovalDelayNanoseconds: UInt64 = 80_000_000
    static let mapReadyFallbackDelayNanoseconds: UInt64 = 1_200_000_000
    static let tileMemoryLimit = 32 * 1_024 * 1_024
    static let tilePrefetchLimit = 34
}

struct RadarScene: View {
    let snapshot: WeatherSnapshot
    @State private var isPlaying = true
    @State private var requestedIndex = 0
    @State private var presentedIndex = 0
    @State private var shouldLoadMap = false
    @State private var isMapVisible = false

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
        .task {
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
                  isMapVisible,
                  requestedIndex == presentedIndex,
                  snapshot.radar.frames.count > 1 else { return }
            try? await Task.sleep(nanoseconds: RadarPerformancePolicy.initialPlaybackDelayNanoseconds)
            guard !Task.isCancelled,
                  isPlaying,
                  requestedIndex == presentedIndex else { return }
            requestedIndex = (presentedIndex + 1) % snapshot.radar.frames.count
        }
        .onDisappear {
            shouldLoadMap = false
            isMapVisible = false
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
                        }
                    )
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
            .shadow(color: .black.opacity(0.14), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 18) {
                Text("Animation Controls").font(.system(size: 26, weight: .bold, design: .rounded))
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
                RadarLegend()
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
                    Text(snapshot.radar.message ?? String(localized: "Radar coverage is temporarily unavailable for this location. Demo imagery will not be substituted."))
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
                Text("The real timestamp is preserved without substitute echoes")
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .multilineTextAlignment(.center)
        }
    }
}

private struct RadarTileMapView: UIViewRepresentable {
    let location: SavedLocation
    let frameID: Int
    let tileURLTemplate: String
    let onMapReady: () -> Void
    let onFramePresented: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onMapReady: onMapReady, onFramePresented: onFramePresented)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.pointOfInterestFilter = MKPointOfInterestFilter(including: [])
        mapView.showsBuildings = false
        mapView.showsScale = false
        mapView.showsTraffic = false
        context.coordinator.install(
            mapView: mapView,
            location: location,
            frameID: frameID,
            tileURLTemplate: tileURLTemplate
        )
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.updateCallbacks(
            onMapReady: onMapReady,
            onFramePresented: onFramePresented
        )
        context.coordinator.update(
            mapView: mapView,
            location: location,
            frameID: frameID,
            tileURLTemplate: tileURLTemplate
        )
    }

    static func dismantleUIView(_ mapView: MKMapView, coordinator: Coordinator) {
        coordinator.prepareForRemoval(from: mapView)
        mapView.delegate = nil
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private var currentLocation: SavedLocation?
        private var currentFrameID: Int?
        private var desiredFrameID: Int?
        private var currentTileURLTemplate: String?
        private var radarOverlay: RadarTileOverlay?
        private var locationAnnotation: MKPointAnnotation?
        private var frameLoadTask: Task<Void, Never>?
        private var mapReadyFallbackTask: Task<Void, Never>?
        private var baseMapRendered = false
        private var initialRadarTileRendered = false
        private var didReportMapReady = false
        private var onMapReady: () -> Void
        private var onFramePresented: (Int) -> Void

        init(onMapReady: @escaping () -> Void, onFramePresented: @escaping (Int) -> Void) {
            self.onMapReady = onMapReady
            self.onFramePresented = onFramePresented
        }

        func updateCallbacks(
            onMapReady: @escaping () -> Void,
            onFramePresented: @escaping (Int) -> Void
        ) {
            self.onMapReady = onMapReady
            self.onFramePresented = onFramePresented
        }

        func install(
            mapView: MKMapView,
            location: SavedLocation,
            frameID: Int,
            tileURLTemplate: String
        ) {
            updateLocation(location, on: mapView)
            currentLocation = location
            desiredFrameID = frameID
            installInitialRadarFrame(
                frameID: frameID,
                tileURLTemplate: tileURLTemplate,
                on: mapView
            )
        }

        func update(
            mapView: MKMapView,
            location: SavedLocation,
            frameID: Int,
            tileURLTemplate: String
        ) {
            if currentLocation != location {
                updateLocation(location, on: mapView)
                currentLocation = location
            }

            guard desiredFrameID != frameID || currentTileURLTemplate != tileURLTemplate else { return }
            desiredFrameID = frameID
            prepareRadarFrame(
                frameID: frameID,
                tileURLTemplate: tileURLTemplate,
                location: location,
                on: mapView
            )
        }

        func prepareForRemoval(from mapView: MKMapView) {
            frameLoadTask?.cancel()
            mapReadyFallbackTask?.cancel()
            let radarOverlays = mapView.overlays.compactMap { $0 as? RadarTileOverlay }
            radarOverlays.forEach { $0.cancelPendingRequests() }
            if !radarOverlays.isEmpty {
                mapView.removeOverlays(radarOverlays)
            }
            if let locationAnnotation {
                mapView.removeAnnotation(locationAnnotation)
            }
            radarOverlay = nil
            locationAnnotation = nil
            currentLocation = nil
            currentFrameID = nil
            desiredFrameID = nil
            currentTileURLTemplate = nil
        }

        private func updateLocation(_ location: SavedLocation, on mapView: MKMapView) {
            let coordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 8.0)
            )
            mapView.setRegion(region, animated: false)

            if let locationAnnotation {
                locationAnnotation.coordinate = coordinate
                locationAnnotation.title = location.name
            } else {
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = location.name
                locationAnnotation = annotation
                mapView.addAnnotation(annotation)
            }
        }

        private func installInitialRadarFrame(
            frameID: Int,
            tileURLTemplate: String,
            on mapView: MKMapView
        ) {
            let overlay = RadarTileOverlay(urlTemplate: tileURLTemplate)
            overlay.onFirstTileLoaded = { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    initialRadarTileRendered = true
                    onFramePresented(frameID)
                    reportMapReadyIfPossible()
                }
            }
            radarOverlay = overlay
            currentFrameID = frameID
            currentTileURLTemplate = tileURLTemplate
            mapView.addOverlay(overlay, level: .aboveLabels)

            mapReadyFallbackTask?.cancel()
            mapReadyFallbackTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: RadarPerformancePolicy.mapReadyFallbackDelayNanoseconds)
                guard let self, !Task.isCancelled, !didReportMapReady else { return }
                didReportMapReady = true
                onMapReady()
            }
        }

        private func prepareRadarFrame(
            frameID: Int,
            tileURLTemplate: String,
            location: SavedLocation,
            on mapView: MKMapView
        ) {
            frameLoadTask?.cancel()
            frameLoadTask = Task { @MainActor [weak self, weak mapView] in
                let loadedTileCount = await RadarTileOverlay.prefetch(
                    urlTemplate: tileURLTemplate,
                    around: location
                )
                guard let self,
                      let mapView,
                      !Task.isCancelled,
                      desiredFrameID == frameID,
                      loadedTileCount > 0 else { return }
                commitRadarFrame(
                    frameID: frameID,
                    tileURLTemplate: tileURLTemplate,
                    on: mapView
                )
            }
        }

        private func commitRadarFrame(
            frameID: Int,
            tileURLTemplate: String,
            on mapView: MKMapView
        ) {
            let staleOverlay = radarOverlay
            let nextOverlay = RadarTileOverlay(urlTemplate: tileURLTemplate)
            radarOverlay = nextOverlay
            currentFrameID = frameID
            currentTileURLTemplate = tileURLTemplate
            mapView.addOverlay(nextOverlay, level: .aboveLabels)

            // Core visible tiles are already in the bounded memory cache. Keep
            // the old overlay underneath for a few display frames so MapKit can
            // draw the new renderer without ever exposing an empty frame.
            Task { @MainActor [weak self, weak mapView] in
                try? await Task.sleep(nanoseconds: RadarPerformancePolicy.staleOverlayRemovalDelayNanoseconds)
                guard let self, let mapView, let staleOverlay, staleOverlay !== radarOverlay else { return }
                staleOverlay.cancelPendingRequests()
                mapView.removeOverlay(staleOverlay)
            }
            onFramePresented(frameID)
        }

        private func reportMapReadyIfPossible() {
            guard !didReportMapReady, baseMapRendered, initialRadarTileRendered else { return }
            didReportMapReady = true
            mapReadyFallbackTask?.cancel()
            onMapReady()
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? RadarTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tileOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
            guard fullyRendered else { return }
            baseMapRendered = true
            reportMapReadyIfPossible()
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "RAYNLocationPin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.displayPriority = .required
            return view
        }
    }
}

private final class RadarTileOverlay: MKTileOverlay {
    private static let tileCache: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 160
        cache.totalCostLimit = RadarPerformancePolicy.tileMemoryLimit
        return cache
    }()

    private static let tileSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpMaximumConnectionsPerHost = 4
        configuration.timeoutIntervalForRequest = 8
        return URLSession(configuration: configuration)
    }()

    private let resolvedTileURLTemplate: String
    private let taskLock = NSLock()
    private var pendingTasks: [UUID: URLSessionDataTask] = [:]
    private var didReportFirstTile = false
    var onFirstTileLoaded: (() -> Void)?

    init(urlTemplate: String) {
        resolvedTileURLTemplate = urlTemplate
        super.init(urlTemplate: urlTemplate)
        tileSize = CGSize(width: 256, height: 256)
        minimumZ = 1
        maximumZ = 7
        canReplaceMapContent = false
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        guard let url = Self.tileURL(
            from: resolvedTileURLTemplate,
            z: path.z,
            x: path.x,
            y: path.y,
            scale: path.contentScaleFactor > 1 ? 2 : 1
        ) else {
            result(nil, WeatherProviderError.invalidURL)
            return
        }

        // Every provider frame has its timestamp in the URL. A small in-memory
        // cache therefore reuses only identical tiles during playback loops and
        // can never surface a previous-launch or different-frame image.
        let cacheKey = url.absoluteString as NSString
        if let cachedData = Self.tileCache.object(forKey: cacheKey) {
            reportFirstTileLoaded()
            result(cachedData as Data, nil)
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let taskID = UUID()
        let task = Self.tileSession.dataTask(with: request) { [weak self] data, response, error in
            self?.removePendingTask(taskID)
            if let error {
                result(nil, error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode), let data else {
                result(nil, WeatherProviderError.invalidResponse)
                return
            }
            Self.tileCache.setObject(data as NSData, forKey: cacheKey, cost: data.count)
            self?.reportFirstTileLoaded()
            result(data, nil)
        }
        taskLock.lock()
        pendingTasks[taskID] = task
        taskLock.unlock()
        task.resume()
    }

    static func prefetch(urlTemplate: String, around location: SavedLocation) async -> Int {
        let urls = prefetchURLs(urlTemplate: urlTemplate, around: location)
        return await withTaskGroup(of: Bool.self, returning: Int.self) { group in
            for url in urls {
                group.addTask {
                    await fetchAndCache(url)
                }
            }

            var loadedCount = 0
            for await didLoad in group where didLoad {
                loadedCount += 1
            }
            return loadedCount
        }
    }

    func cancelPendingRequests() {
        taskLock.lock()
        let tasks = Array(pendingTasks.values)
        pendingTasks.removeAll(keepingCapacity: false)
        taskLock.unlock()
        tasks.forEach { $0.cancel() }
    }

    private func removePendingTask(_ taskID: UUID) {
        taskLock.lock()
        pendingTasks[taskID] = nil
        taskLock.unlock()
    }

    private func reportFirstTileLoaded() {
        taskLock.lock()
        guard !didReportFirstTile else {
            taskLock.unlock()
            return
        }
        didReportFirstTile = true
        let callback = onFirstTileLoaded
        taskLock.unlock()
        if let callback {
            DispatchQueue.main.async(execute: callback)
        }
    }

    private static func fetchAndCache(_ url: URL) async -> Bool {
        guard !Task.isCancelled else { return false }
        let cacheKey = url.absoluteString as NSString
        if tileCache.object(forKey: cacheKey) != nil {
            return true
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, response) = try await tileSession.data(for: request)
            guard !Task.isCancelled,
                  let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else { return false }
            tileCache.setObject(data as NSData, forKey: cacheKey, cost: data.count)
            return true
        } catch {
            return false
        }
    }

    private static func prefetchURLs(urlTemplate: String, around location: SavedLocation) -> [URL] {
        var urls: [URL] = []
        var seen = Set<URL>()

        for (zoom, radius) in [(6, 1), (7, 2)] {
            let center = tileCoordinate(
                latitude: location.latitude,
                longitude: location.longitude,
                zoom: zoom
            )
            let tileCount = 1 << zoom
            let offsets = (-radius...radius).flatMap { x in
                (-radius...radius).map { y in (x: x, y: y) }
            }
            .sorted {
                (abs($0.x) + abs($0.y)) < (abs($1.x) + abs($1.y))
            }

            for offset in offsets {
                let x = ((center.x + offset.x) % tileCount + tileCount) % tileCount
                let y = min(max(center.y + offset.y, 0), tileCount - 1)
                guard let url = tileURL(from: urlTemplate, z: zoom, x: x, y: y, scale: 1),
                      seen.insert(url).inserted else { continue }
                urls.append(url)
            }
        }

        return Array(urls.prefix(RadarPerformancePolicy.tilePrefetchLimit))
    }

    private static func tileCoordinate(latitude: Double, longitude: Double, zoom: Int) -> (x: Int, y: Int) {
        let clampedLatitude = min(max(latitude, -85.051_128_78), 85.051_128_78)
        let latitudeRadians = clampedLatitude * .pi / 180
        let scale = pow(2, Double(zoom))
        let x = Int(floor((longitude + 180) / 360 * scale))
        let y = Int(floor((1 - log(tan(latitudeRadians) + 1 / cos(latitudeRadians)) / .pi) / 2 * scale))
        return (x, y)
    }

    private static func tileURL(
        from template: String,
        z: Int,
        x: Int,
        y: Int,
        scale: Int
    ) -> URL? {
        let urlString = template
            .replacingOccurrences(of: "{z}", with: String(z))
            .replacingOccurrences(of: "{x}", with: String(x))
            .replacingOccurrences(of: "{y}", with: String(y))
            .replacingOccurrences(of: "{scale}", with: String(scale))
        return URL(string: urlString)
    }

    deinit {
        cancelPendingRequests()
    }
}

private struct RadarLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Precipitation Intensity").font(.system(size: 20, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.68))
            HStack(spacing: 0) {
                ForEach([Color.blue, Color.cyan, Color.green, Color.yellow, Color.orange, Color.red], id: \.self) { color in
                    Rectangle().fill(color).frame(maxWidth: .infinity).frame(height: 10)
                }
            }
            HStack {
                Text("Light").foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text("Heavy").foregroundStyle(.white.opacity(0.55))
            }
            .font(.system(size: 17, weight: .medium, design: .rounded))
        }
    }
}
