import SwiftUI

struct ProfileView: View {
    
    let profileImage: UIImage?
    
    @Environment(UserProfileStore.self) private var userProfileStore
    
    var body: some View {
        if let profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .frame(
                    width: 50,
                    height: 50
                )
                .background(.gray)
                .clipShape(Circle())
        }
        
        Text(userProfileStore.displayName)
    }
}
