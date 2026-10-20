import SwiftUI

enum tabs {
    case map, profile, team, challenge, leaderboard
}

struct HomeView: View {
    @State private var selectedTab: tabs = .map
    
    @ObservedObject var auth: AuthViewModel

    @Environment(UserProfileStore.self) private var userProfileStore

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Challenge", systemImage: "target", value: .challenge) {
                ChallengeView()
            }

            Tab("Teams", systemImage: "person.3.fill", value: .team) {
                TeamView()
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
                    ProfileView(auth: auth)
                }
            }
        }
    }
}
