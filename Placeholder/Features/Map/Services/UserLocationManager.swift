import Combine
import CoreLocation
import Foundation

@MainActor
final class UserLocationManager: NSObject, ObservableObject {
    @Published private(set) var coordinate:
        CLLocationCoordinate2D?

    private let locationManager: CLLocationManager

    override init() {
        let manager = CLLocationManager()

        self.locationManager = manager

        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
    }

    func startUpdatingLocation() {
        guard locationManager.authorizationStatus ==
                .authorizedAlways
        else {
            return
        }

        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension UserLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latestLocation = locations.last else {
            return
        }

        let newCoordinate = latestLocation.coordinate

        Task { @MainActor [weak self] in
            self?.coordinate = newCoordinate
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        Task { @MainActor [weak self] in
            self?.startUpdatingLocation()
        }
    }
}
