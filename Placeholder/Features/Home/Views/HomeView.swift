import SwiftUI

struct HomeView: View {
    @ObservedObject var auth: AuthViewModel

    @StateObject private var home =
        HomeViewModel()

    var body: some View {
        ZStack {
            MapView(
                profileImage: home.profileImage
            )

            if home.isLoadingProfileImage {
                ProgressView()
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )
            }
        }
        .task {
            await home.loadProfileImage()
        }
    }
}
