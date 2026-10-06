import SwiftUI
import MapKit

struct MapView: View {

    let cameraPosition: MapCameraPosition = .region(
        .init(
            center: .init(
                latitude: 37.3346,
                longitude: -122.0090
            ),
            latitudinalMeters: 1300,
            longitudinalMeters: 1300
        )
    )
    
    let locationManager = CLLocationManager()
    
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isShowingLookAround = false
    
    @State var route: MKRoute?
    
    var body: some View {
        Map(initialPosition: cameraPosition) {
            
            Annotation(
                "Apple Visitor Centre",
                coordinate: .appleVisitorCentre,
                anchor: .center
            ) {
                Image(systemName: "apple.logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .padding(7)
                    .background(
                        .pink.gradient,
                        in: .circle
                    )
                    .contextMenu {
                        
                        Button(
                            "Open Look Around",
                            systemImage: "binoculars"
                        ) {
                            Task {
                                lookAroundScene =
                                    await GetLookAroundScene(
                                        from: .appleVisitorCentre
                                    )
                                
                                guard lookAroundScene != nil else {
                                    return
                                }
                                
                                isShowingLookAround = true
                            }
                        }
                        
                        Button(
                            "Get Directions",
                            systemImage: "arrow.turn.down.right"
                        ) {
                            GetDirections(
                                to: .appleVisitorCentre
                            )
                        }
                    }
            }
            
            Annotation(
                "Panama Park",
                coordinate: .panamaPark,
                anchor: .center
            ) {
                Image(systemName: "tree.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .padding(7)
                    .background(
                        .green.gradient,
                        in: .circle
                    )
                    .contextMenu {
                        
                        Button(
                            "Open Look Around",
                            systemImage: "binoculars"
                        ) {
                            Task {
                                lookAroundScene =
                                    await GetLookAroundScene(
                                        from: .panamaPark
                                    )
                                
                                guard lookAroundScene != nil else {
                                    return
                                }
                                
                                isShowingLookAround = true
                            }
                        }
                        
                        Button(
                            "Get Directions",
                            systemImage: "arrow.turn.down.right"
                        ) {
                            GetDirections(
                                to: .panamaPark
                            )
                        }
                    }
            }
            
            Annotation(
                "Smithstone",
                coordinate: .smithstone,
                anchor: .center
            ) {
                Image(systemName: "house.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .padding(7)
                    .background(
                        .red.gradient,
                        in: .circle
                    )
                    .contextMenu {
                        
                        Button(
                            "Open Look Around",
                            systemImage: "binoculars"
                        ) {
                            Task {
                                lookAroundScene =
                                    await GetLookAroundScene(
                                        from: .smithstone
                                    )
                                
                                guard lookAroundScene != nil else {
                                    return
                                }
                                
                                isShowingLookAround = true
                            }
                        }
                        
                        Button(
                            "Get Directions",
                            systemImage: "arrow.turn.down.right"
                        ) {
                            GetDirections(
                                to: .smithstone
                            )
                        }
                    }
            }
            
            UserAnnotation()
            
            if let route {
                MapPolyline(route)
                    .stroke(
                        Color.pink,
                        lineWidth: 4
                    )
            }
        }
        
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
        }
        
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapPitchToggle()
            MapScaleView()
        }
        
        .mapStyle(.standard)
        
        .lookAroundViewer(
            isPresented: $isShowingLookAround,
            initialScene: lookAroundScene
        )
    }
}
