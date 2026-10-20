import Foundation

nonisolated struct Profile: Decodable, Sendable, Equatable {
    let id: UUID
    let username: String?
    let firstName: String?
    let surname: String?
    let profilePicturePath: String?
    let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case firstName = "first_name"
        case surname
        case profilePicturePath = "profile_picture_path"
        case onboardingCompleted = "onboarding_completed"
    }
}

nonisolated struct NameUpdate: Encodable, Sendable {
    let firstName: String
    let surname: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case surname
    }
}

nonisolated struct UsernameUpdate: Encodable, Sendable {
    let username: String

    enum CodingKeys: String, CodingKey {
        case username
    }
}

nonisolated struct OnboardingCompletionUpdate: Encodable, Sendable {
    let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case onboardingCompleted = "onboarding_completed"
    }
}

nonisolated struct ProfileDetailsUpdate: Encodable, Sendable {
    let firstName: String
    let surname: String
    let username: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case surname
        case username
    }
}
