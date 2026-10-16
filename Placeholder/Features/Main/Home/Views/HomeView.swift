import SwiftUI

enum tabs {
    case map, profile, activity, challenge, leaderboard
}

struct HomeView: View {
    @State private var selectedTab: tabs = .map

    @Environment(UserProfileStore.self) private var userProfileStore

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Challenge", systemImage: "target", value: .challenge) {
                ChallengeView()
            }

            Tab("Activity", systemImage: "waveform.path.ecg", value: .activity) {
                ActivityView()
            }

            Tab("Map", systemImage: "map", value: .map) {
                ZStack {
                    MapView(
                        profileImage: userProfileStore.profileImage
                    )

                    if userProfileStore.isLoadingProfileImage {
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
            }

            Tab("Leaderboard", systemImage: "trophy.fill", value: .leaderboard) {
                LeaderboardView()
            }

            Tab("Profile", systemImage: "person", value: .profile) {
                NavigationStack {
                    ProfileView()    
                }
            }
        }
    }
}
