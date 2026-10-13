import Foundation

struct UserSearchResult: Decodable, Identifiable, Sendable {
    let id: UUID
    let firstName: String?
    let surname: String?
    let username: String?
    let profilePicturePath: String?

    var displayName: String {
        let name = [firstName, surname]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? (username ?? "User") : name
    }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case surname
        case username
        case profilePicturePath = "profile_picture_path"
    }
}
