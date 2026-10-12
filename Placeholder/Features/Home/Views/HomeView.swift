import SwiftUI

enum tabs {
    case map, profile, activity, challenge, leaderboard
}

struct HomeView: View {
    @State var selectedTab: tabs = .map
    
    @ObservedObject var auth: AuthViewModel

    @StateObject private var home = HomeViewModel()

    var body: some View {
        
        ZStack {
            
            TabView(selection: $selectedTab) {
                Tab("Challenge", systemImage: "target", value: .challenge) {
                    ChallengeView()
                }
                Tab("Activity", systemImage: "waveform.path.ecg", value: .activity) {
                    ActivityView()
                }
                Tab("Map", systemImage: "map", value: .map) {
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
                Tab("Leaderboard", systemImage: "trophy.fill", value: .leaderboard) {
                    LeaderboardView()
                }
                Tab("Profile", systemImage: "person", value: .profile) {
                    ProfileView()
                }
            }
        }
        .task {
            await home.loadProfileImage()
        }
    }
}
