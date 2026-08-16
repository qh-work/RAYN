#if os(tvOS)
@preconcurrency import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentLocation() async throws -> CLLocation {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            throw LocationServiceError.authorizationDenied
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation?.resume(throwing: LocationServiceError.requestReplaced)
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor [weak self] in
            self?.finish(with: .success(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor [weak self] in
            self?.finish(with: .failure(LocationServiceError.providerFailure(message)))
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.handleAuthorizationChange(status)
        }
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            finish(with: .failure(LocationServiceError.authorizationDenied))
        }
    }

    private func finish(with result: Result<CLLocation, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        switch result {
        case .success(let location):
            continuation.resume(returning: location)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

enum LocationServiceError: LocalizedError {
    case authorizationDenied
    case requestReplaced
    case providerFailure(String)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied: return String(localized: "Location access was not granted.")
        case .requestReplaced: return String(localized: "A newer location request replaced the current request.")
        case .providerFailure(let message): return String(localized: "Unable to get the current location: \(message)")
        }
    }
}
#else
import Foundation

@MainActor
final class LocationService {
    func requestCurrentLocation() async throws -> Never {
        throw LocationServiceError.authorizationDenied
    }
}

enum LocationServiceError: LocalizedError {
    case authorizationDenied
    case requestReplaced
    var errorDescription: String? { String(localized: "Current location is available only on tvOS.") }
}
#endif
