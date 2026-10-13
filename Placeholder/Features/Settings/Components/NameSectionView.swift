import SwiftUI

struct NameSectionView: View {
    
    @Environment(UserProfileStore.self) private var userProfileStore
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            if userProfileStore.displayName.isEmpty {
                Text("No name has been set.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.65))
            } else {
                Text("Display name: \(userProfileStore.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            Button {
                
            } label: {
                Label(
                    "Change name",
                    systemImage: "pencil"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#1C99FF"))
            Text("""
                Made by Angus the Anderson
                Nothing is stored on Servers, only your phone
                """)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.66))

            Link(
                "Weather data by Open-Meteo.com",
                destination: URL(
                    string: "https://open-meteo.com/"
                )!
            )
            .font(.system(size: 12))
            .foregroundStyle(Color.white.opacity(0.66))
        }
    }
}
