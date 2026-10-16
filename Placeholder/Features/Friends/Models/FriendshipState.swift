import Foundation

enum FriendshipState: String, Decodable, Sendable {
    case ownProfile = "own_profile"
    case none
    case outgoing
    case incoming
    case friends
}

enum FriendshipAction: String, Sendable {
    case send
    case accept
    case cancel
    case decline
    case remove
}
