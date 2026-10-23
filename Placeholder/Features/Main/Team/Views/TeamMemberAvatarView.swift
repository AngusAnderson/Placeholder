import SwiftUI

struct TeamMemberAvatarView: View {
    let path: String?

    @State private var imageURL: URL?

    private let pictureService = ProfilePictureService()

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .empty:
                        ProgressView()

                    case .failure:
                        placeholder

                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 44, height: 44)
        .background(
            Color.secondary.opacity(0.12),
            in: Circle()
        )
        .clipShape(Circle())
        .accessibilityHidden(true)
        .task(id: path) {
            await loadImageURL()
        }
    }

    private var placeholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 19))
            .foregroundStyle(.secondary)
    }

    @MainActor
    private func loadImageURL() async {
        imageURL = nil

        guard let path, !path.isEmpty else {
            return
        }

        do {
            let url = try await pictureService
                .createSignedProfilePictureURL(path: path)

            try Task.checkCancellation()

            imageURL = url
        } catch {
            // Missing or inaccessible avatars keep the placeholder.
        }
    }
}
