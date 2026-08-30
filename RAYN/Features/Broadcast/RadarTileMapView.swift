import MapKit
import SwiftUI

struct RadarTileMapView: UIViewRepresentable {
    let location: SavedLocation
    let frameID: Int
    let tileURLTemplate: String
    let maximumZoom: Int
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
            tileURLTemplate: tileURLTemplate,
            maximumZoom: maximumZoom
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
            tileURLTemplate: tileURLTemplate,
            maximumZoom: maximumZoom
        )
    }

    static func dismantleUIView(_ mapView: MKMapView, coordinator: Coordinator) {
        coordinator.prepareForRemoval(from: mapView)
        mapView.delegate = nil
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private var currentLocation: SavedLocation?
        private var desiredFrameID: Int?
        private var desiredTileURLTemplate: String?
        private var desiredMaximumZoom: Int?
        private var radarOverlay: RadarTileOverlay?
        private var pendingOverlay: RadarTileOverlay?
        private var locationAnnotation: MKPointAnnotation?
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
            tileURLTemplate: String,
            maximumZoom: Int
        ) {
            updateLocation(location, on: mapView)
            currentLocation = location
            desiredFrameID = frameID
            desiredTileURLTemplate = tileURLTemplate
            desiredMaximumZoom = maximumZoom
            commitRadarFrame(
                frameID: frameID,
                tileURLTemplate: tileURLTemplate,
                maximumZoom: maximumZoom,
                on: mapView
            )
        }

        func update(
            mapView: MKMapView,
            location: SavedLocation,
            frameID: Int,
            tileURLTemplate: String,
            maximumZoom: Int
        ) {
            if currentLocation != location {
                updateLocation(location, on: mapView)
                currentLocation = location
            }

            guard desiredFrameID != frameID || desiredTileURLTemplate != tileURLTemplate
                    || desiredMaximumZoom != maximumZoom else { return }
            desiredFrameID = frameID
            desiredTileURLTemplate = tileURLTemplate
            desiredMaximumZoom = maximumZoom
            commitRadarFrame(
                frameID: frameID,
                tileURLTemplate: tileURLTemplate,
                maximumZoom: maximumZoom,
                on: mapView
            )
        }

        func prepareForRemoval(from mapView: MKMapView) {
            let radarOverlays = mapView.overlays.compactMap { $0 as? RadarTileOverlay }
            radarOverlays.forEach { $0.cancelPendingRequests() }
            if !radarOverlays.isEmpty {
                mapView.removeOverlays(radarOverlays)
            }
            if let locationAnnotation {
                mapView.removeAnnotation(locationAnnotation)
            }
            radarOverlay = nil
            pendingOverlay = nil
            locationAnnotation = nil
            currentLocation = nil
            desiredFrameID = nil
            desiredTileURLTemplate = nil
            desiredMaximumZoom = nil
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

        private func commitRadarFrame(
            frameID: Int,
            tileURLTemplate: String,
            maximumZoom: Int,
            on mapView: MKMapView
        ) {
            let nextOverlay = RadarTileOverlay(urlTemplate: tileURLTemplate, maximumZoom: maximumZoom)
            // Keep the last drawn frame, not an unrendered intermediate frame.
            // Rapid input discards only the superseded pending layer.
            if let pendingOverlay {
                pendingOverlay.cancelPendingRequests()
                mapView.removeOverlay(pendingOverlay)
            }
            pendingOverlay = nextOverlay
            nextOverlay.onFirstTileLoaded = { [weak self, weak nextOverlay] in
                guard let self, let nextOverlay, nextOverlay === self.pendingOverlay else { return }
                if !self.didReportMapReady {
                    self.didReportMapReady = true
                    self.onMapReady()
                }
            }
            nextOverlay.onFirstDraw = { [weak self, weak nextOverlay, weak mapView] in
                guard let self, let nextOverlay, let mapView,
                      nextOverlay === self.pendingOverlay,
                      self.desiredFrameID == frameID,
                      self.desiredTileURLTemplate == tileURLTemplate else { return }
                if let old = self.radarOverlay {
                    old.cancelPendingRequests()
                    mapView.removeOverlay(old)
                }
                self.radarOverlay = nextOverlay
                self.pendingOverlay = nil
                self.onFramePresented(frameID)
            }
            mapView.addOverlay(nextOverlay, level: .aboveLabels)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? RadarTileOverlay {
                return RadarTileRenderer(tileOverlay: tileOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
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

/// Drawing callbacks also occur on tile-only updates, unlike base-map completion.
private final class RadarTileRenderer: MKTileOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        super.draw(mapRect, zoomScale: zoomScale, in: context)
        (overlay as? RadarTileOverlay)?.reportFirstDraw()
    }
}

private final class RadarTileOverlay: MKTileOverlay {
    private let resolvedTileURLTemplate: String
    private let taskLock = NSLock()
    private var pendingTasks: [UUID: Task<Void, Never>] = [:]
    private var cancelled = false
    private var didReportFirstTile = false
    private var didReportDraw = false
    var onFirstTileLoaded: (() -> Void)?
    var onFirstDraw: (() -> Void)?

    init(urlTemplate: String, maximumZoom: Int) {
        resolvedTileURLTemplate = urlTemplate
        super.init(urlTemplate: urlTemplate)
        tileSize = CGSize(width: 256, height: 256)
        minimumZ = 1
        maximumZ = min(max(maximumZoom, 1), 20)
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

        let taskID = UUID()
        // Register under the same lock as removal: a cache hit may complete
        // immediately on another executor.
        taskLock.lock()
        guard !cancelled else {
            taskLock.unlock()
            result(nil, CancellationError())
            return
        }
        let task = Task { [weak self] in
            defer { self?.removePendingTask(taskID) }
            do {
                let data = try await RadarTileStore.shared.data(for: url)
                try Task.checkCancellation()
                self?.reportFirstTileLoaded()
                result(data, nil)
            } catch {
                result(nil, error)
            }
        }
        pendingTasks[taskID] = task
        taskLock.unlock()
    }


    func cancelPendingRequests() {
        taskLock.lock()
        cancelled = true
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
        guard !cancelled, !didReportFirstTile else {
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

    func reportFirstDraw() {
        taskLock.lock()
        guard !cancelled, didReportFirstTile, !didReportDraw else {
            taskLock.unlock()
            return
        }
        didReportDraw = true
        let callback = onFirstDraw
        taskLock.unlock()
        if let callback { DispatchQueue.main.async(execute: callback) }
    }


    private static func tileURL(
        from template: String,
        z: Int,
        x: Int,
        y: Int,
        scale: Int
    ) -> URL? {
        RadarTileURL.resolve(template, z: z, x: x, y: y, scale: scale)
    }

    deinit {
        cancelPendingRequests()
    }
}
