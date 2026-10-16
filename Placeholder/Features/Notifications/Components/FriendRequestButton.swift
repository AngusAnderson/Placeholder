import SwiftUI

struct FriendRequestButton: View {
    
    @State private var showFriendRequests = false
    
    var body: some View {
        VStack {
            Button {
                showFriendRequests = true
            } label: {
                Image(systemName: "person.fill.badge.plus")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.cyan)
            .background(
                .regularMaterial,
                in: Circle()
            )
            .overlay {
                Circle()
                    .stroke(
                        .white.opacity(0.15),
                        lineWidth: 1
                    )
            }
            .accessibilityLabel("Open friend requests")
        }
        .sheet(isPresented: $showFriendRequests) {
            RequestView()
        }
    }
}
