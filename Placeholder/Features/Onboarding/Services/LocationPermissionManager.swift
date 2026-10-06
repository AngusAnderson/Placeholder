import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationPermissionManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isAlwaysAuthorized = false

    private let locationManager: CLLocationManager

    override init() {
        let manager = CLLocationManager()

        self.locationManager = manager
        self.authorizationStatus = manager.authorizationStatus

        super.init()

        manager.delegate = self
        updateAuthorizationState()
    }

    func refreshAuthorizationStatus() {
        updateAuthorizationState()
    }

    func requestInitialPermission() {
        guard locationManager.authorizationStatus == .notDetermined else {
            return
        }

        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysUpgrade() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse else {
            return
        }

        locationManager.requestAlwaysAuthorization()
    }

    private func updateAuthorizationState() {
        let status = locationManager.authorizationStatus

        authorizationStatus = status
        isAlwaysAuthorized = status == .authorizedAlways
    }
}

extension LocationPermissionManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        let status = manager.authorizationStatus

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            authorizationStatus = status
            isAlwaysAuthorized = status == .authorizedAlways
        }
    }
}
