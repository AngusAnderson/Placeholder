import SwiftUI

struct NotificationsView: View {
    
    var body: some View {
        HStack {
            Text("Notifications")
                .font(.system(size: 20))
        }
        
        FriendRequestButton()
            
        
    }
}
