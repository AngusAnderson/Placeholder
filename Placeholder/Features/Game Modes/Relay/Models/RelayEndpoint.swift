import Foundation
import MapKit

nonisolated struct RelayEndpoint: Identifiable, Sendable {
    let id: UUID
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    static func distance(from start: RelayEndpoint, to finish: RelayEndpoint) -> Double {
        let a = start.latitude * .pi / 180
        let b = finish.latitude * .pi / 180
        let latitudeDelta = b - a
        let longitudeDelta = (finish.longitude - start.longitude) * .pi / 180
        let h = pow(sin(latitudeDelta / 2), 2)
            + cos(a) * cos(b) * pow(sin(longitudeDelta / 2), 2)
        return 2 * 6_371_000 * asin(sqrt(min(max(h, 0), 1)))
    }
}
