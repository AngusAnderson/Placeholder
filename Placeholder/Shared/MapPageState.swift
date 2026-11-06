import MapKit
import Observation

@MainActor
@Observable
final class MapPageState {
    static let shared = MapPageState()

    var region = MKCoordinateRegion(
        center: .appleHQ,
        latitudinalMeters: 1300,
        longitudinalMeters: 1300
    )

    var regionComponents: [Double] {
        [region.center.latitude, region.center.longitude,
         region.span.latitudeDelta, region.span.longitudeDelta]
    }

    func reset() {
        region = MKCoordinateRegion(
            center: .appleHQ,
            latitudinalMeters: 1300,
            longitudinalMeters: 1300
        )
    }
}
