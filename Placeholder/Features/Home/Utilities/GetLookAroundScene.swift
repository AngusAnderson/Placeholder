import MapKit

extension MapView {
    func GetLookAroundScene(
        from coordinate: CLLocationCoordinate2D
    ) async -> MKLookAroundScene? {
        do {
            let request = MKLookAroundSceneRequest(
                coordinate: coordinate
            )

            return try await request.scene
        } catch {
            print(
                "Cannot retrieve Look Around scene: "
                + error.localizedDescription
            )

            return nil
        }
    }
}
