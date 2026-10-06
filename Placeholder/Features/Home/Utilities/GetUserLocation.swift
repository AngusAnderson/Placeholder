import CoreLocation
import MapKit

extension MapView {
    func GetUserLocation() async -> CLLocationCoordinate2D? {
        let updates = CLLocationUpdate.liveUpdates()

        do {
            let update = try await updates.first {
                $0.location?.coordinate != nil
            }

            return update?.location?.coordinate
        } catch {
            print("Cannot get the user location")
            return nil
        }
    }
}
