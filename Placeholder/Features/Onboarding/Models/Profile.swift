import Foundation

nonisolated struct Profile: Decodable, Sendable {
    let id: UUID
    let firstName: String?
    let surname: String?
    let profilePicturePath: String?
    let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
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

nonisolated struct OnboardingCompletionUpdate: Encodable, Sendable {
    let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case onboardingCompleted = "onboarding_completed"
    }
}
