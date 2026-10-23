import SwiftUI
import MapKit

struct RelayMapContent: MapContent {
    let geometry: RelayRouteGeometry
    let startName: String
    let finishName: String
    
    let creditedMetres: Double
    let targetMetres: Double
    
    private let checkpoints = [25, 50, 75]
    
    private var progress: Double {
        guard targetMetres > 0 else {
            return 0
        }
        
        return min(max(creditedMetres / targetMetres, 0), 1)
    }
    
    private var completedCoordinates: [CLLocationCoordinate2D] {
        geometry.completedCoordinates(at: progress)
    }
    
    var body: some MapContent {
        // This is the line for the entire jouryney, lower opacity to show it has not been completed yet - A.Anderson
        if geometry.coordinates.count >= 2 {
            MapPolyline(coordinates: geometry.coordinates)
                .stroke(Color.cyan.opacity(0.25), lineWidth: 7)
        }
        
        // This is the line for the completed portion of the journey - A.Anderson
        if completedCoordinates.count >= 2 {
            MapPolyline(coordinates: completedCoordinates)
                .stroke(Color.cyan, lineWidth: 7)
        }
        
        if let start = geometry.coordinates.first {
            Marker(startName, coordinate: start)
                .tint(.green)
        }
        
        if let finish = geometry.coordinates.last {
            Marker(finishName, coordinate: finish)
                .tint(.orange)
        }
        
        ForEach(checkpoints, id: \.self) {
            checkpoint in if let coordinate = geometry.position(at: Double(checkpoint) / 100) {
                Annotation("\(checkpoint)% checkpoint", coordinate: coordinate) {
                    Image(
                        systemName: progress >= Double(checkpoint) / 100
                        ? "checkmark.circle.fill"
                        : "flag.cicrle.fill"
                    )
                    .font(.title2)
                    .foregroundStyle(
                        progress >= Double(checkpoint) / 100 ? Color.green : Color.orange
                    )
                    .padding(4)
                    .background(.regularMaterial, in: Circle())
                }
            }
        }
        
        if let coordinate = geometry.position(at: progress) {
            Annotation("Team progress", coordinate: coordinate) {
                VStack(spacing: 5) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.cyan, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 3)
                        }
                        .shadow(radius: 4)

                    Text(
                        String(
                            format: "%.1f / %.1f km",
                            min(creditedMetres, targetMetres) / 1000,
                            targetMetres / 1000
                        )
                    )
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        .regularMaterial,
                        in: Capsule()
                    )
                }
            }
        }
    }
}
