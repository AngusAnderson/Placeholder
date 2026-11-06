import CoreImage
import Foundation
@preconcurrency import MapKit
import SwiftUI
import UIKit

@MainActor
private final class MapBackdropSnapshotCache {
    static let shared = MapBackdropSnapshotCache()
    private let cache = NSCache<NSString, MapBackdropImages>()
    private let context = CIContext(options: [.cacheIntermediates: false])

    private init() {
        cache.countLimit = 3
        cache.totalCostLimit = 32 * 1024 * 1024
    }
    func cached(_ key: String) -> MapBackdropImages? {
        cache.object(forKey: key as NSString)
    }
    func load(key: String, region: MKCoordinateRegion, size: CGSize,
              scale: CGFloat, dark: Bool) async throws -> MapBackdropImages {
        if let result = cached(key) { return result }
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.scale = scale
        options.mapType = .standard
        options.pointOfInterestFilter = .excludingAll
        options.traitCollection = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        let snapshot = try await MKMapSnapshotter(options: options).start()
        try Task.checkCancellation()
        let original = snapshot.image
        guard let input = CIImage(image: original) else { throw MapBackdropError.blurFailed }
        let output = input.clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 14 * original.scale])
            .cropped(to: input.extent)
        guard let cgImage = context.createCGImage(output, from: input.extent) else {
            throw MapBackdropError.blurFailed
        }
        let blurred = UIImage(cgImage: cgImage, scale: original.scale, orientation: .up)
        let result = MapBackdropImages(original: original, blurred: blurred)
        let cost = (original.cgImage?.width ?? 0) * (original.cgImage?.height ?? 0) * 8
        cache.setObject(result, forKey: key as NSString, cost: cost)
        return result
    }
}

private final class MapBackdropImages: NSObject {
    let original: UIImage
    let blurred: UIImage
    init(original: UIImage, blurred: UIImage) {
        self.original = original
        self.blurred = blurred
    }
}

private enum MapBackdropError: LocalizedError {
    case blurFailed
    var errorDescription: String? { "Could not prepare the blurred map background." }
}

struct MapBitmapBackdrop: View {
    let region: MKCoordinateRegion
    let size: CGSize
    let attributionHeight: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @State private var images: MapBackdropImages?
    private var scale: CGFloat { min(max(displayScale, 1), 2) }
    private var key: String {
        String(format: "%.6f|%.6f|%.6f|%.6f|%d|%d|%@|%.1f",
               region.center.latitude, region.center.longitude,
               region.span.latitudeDelta, region.span.longitudeDelta,
               Int(size.width.rounded()), Int(size.height.rounded()),
               colorScheme == .dark ? "dark" : "light", Double(scale))
    }
    var body: some View {
        let available = MapBackdropSnapshotCache.shared.cached(key) ?? images
        ZStack {
            Color(uiColor: .systemBackground)
            if let available {
                Image(uiImage: available.original)
                    .resizable()
                    .scaledToFill()
                Image(uiImage: available.blurred)
                    .resizable()
                    .scaledToFill()
                Color.black.opacity(colorScheme == .dark ? 0.18 : 0.025)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: max(size.width, 1), height: max(size.height, 1))
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: key) {
            guard size.width > 50, size.height > 100 else { return }
            do {
                let next = try await MapBackdropSnapshotCache.shared.load(
                    key: key, region: region, size: size, scale: scale,
                    dark: colorScheme == .dark
                )
                try Task.checkCancellation()
                images = next
            } catch {
                guard !Task.isCancelled else { return }
#if DEBUG
                print("[Map Background]", error)
#endif
            }
        }
    }
    
    struct MapAttributionStrip: UIViewRepresentable {
        let region: MKCoordinateRegion
        let fullMapHeight: CGFloat
        
        func makeUIView(context: Context) -> AttributionMapContainer {
            AttributionMapContainer()
        }
        func updateUIView(_ uiView: AttributionMapContainer, context: Context) {
            uiView.configure(region: region, fullHeight: fullMapHeight)
        }
    }
    
    final class AttributionMapContainer: UIView {
        private let map = MKMapView()
        private var desiredRegion: MKCoordinateRegion?
        private var fullHeight: CGFloat = 1
        private var appliedKey: [Double] = []
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            clipsToBounds = true
            map.mapType = .standard
            map.isScrollEnabled = false
            map.isZoomEnabled = false
            map.isRotateEnabled = false
            map.isPitchEnabled = false
            map.showsCompass = false
            map.showsScale = false
            map.showsUserLocation = false
            map.pointOfInterestFilter = .excludingAll
            addSubview(map)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        func configure(region: MKCoordinateRegion, fullHeight: CGFloat) {
            desiredRegion = region
            self.fullHeight = fullHeight
            setNeedsLayout()
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            guard bounds.width > 1, let region = desiredRegion else { return }
            let height = max(fullHeight, bounds.height)
            map.frame = CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
            let key = [region.center.latitude, region.center.longitude,
                       region.span.latitudeDelta, region.span.longitudeDelta,
                       Double(bounds.width), Double(height)]
            if key != appliedKey {
                appliedKey = key
                map.setRegion(region, animated: false)
            }
        }
    }
}
