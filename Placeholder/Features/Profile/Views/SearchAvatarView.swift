import SwiftUI

struct SearchAvatarView: View {
    let imageURL: URL?

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

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
        .background(.white.opacity(0.08), in: Circle())
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var placeholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 19))
            .foregroundStyle(.white.opacity(0.7))
    }
}
