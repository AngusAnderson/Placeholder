import CoreLocation
import MapKit

extension MapView {

    func GetUserLocation() async -> CLLocationCoordinate2D? {
        do {
            for try await update in CLLocationUpdate.liveUpdates() {

                if update.authorizationDenied {
                    print("Location permission was denied.")
                    return nil
                }

                if let location = update.location {
                    return location.coordinate
                }
            }
        } catch {
            print(
                "Cannot get the user location: "
                + error.localizedDescription
            )
        }

        return nil
    }
}
