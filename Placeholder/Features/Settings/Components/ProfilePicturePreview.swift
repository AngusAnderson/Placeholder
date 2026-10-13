import SwiftUI

struct ProfilePicturePreview: View {
    let currentImage: UIImage?
    let newImage: UIImage?

    var body: some View {
        Group {
            if let newImage {
                Image(uiImage: newImage)
                    .resizable()
            } else if let currentImage {
                Image(uiImage: currentImage)
                    .resizable()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .scaledToFill()
        .frame(width: 72, height: 72)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        }
    }
}
