import Foundation
import Supabase

enum ProfilePictureServiceError: LocalizedError {
    case noAuthenticatedUser
    case imageConversionFailed
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "No authenticated user found."

        case .imageConversionFailed:
            return "The selected image could not be prepared."

        case .invalidImage:
            return "Please select a valid profile picture."
        }
    }
}

nonisolated struct ProfilePictureUpdate: Encodable, Sendable {
    let profilePicturePath: String

    enum CodingKeys: String, CodingKey {
        case profilePicturePath = "profile_picture_path"
    }
}

struct ProfilePictureService {
    private let bucketName = "avatars"

    func uploadProfilePicture(
        imageData: Data,
        fileExtension: String = "jpg"
    ) async throws -> String {
        guard !imageData.isEmpty else {
            throw ProfilePictureServiceError.invalidImage
        }

        let session = try await supabase.auth.session
        let user = session.user

        let userID = user.id.uuidString.lowercased()
        let path = "\(userID)/profile.\(fileExtension)"

        print("Authenticated user ID: \(userID)")
        print("Avatar upload path: \(path)")

        try await supabase.storage
            .from(bucketName)
            .upload(
                path,
                data: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: contentType(
                        for: fileExtension
                    ),
                    upsert: true
                )
            )

        let update = ProfilePictureUpdate(
            profilePicturePath: path
        )

        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: user.id)
            .execute()

        return path
    }

    func deleteProfilePicture(
        path: String
    ) async throws {
        let session = try await supabase.auth.session
        let user = session.user

        try await supabase.storage
            .from(bucketName)
            .remove(paths: [path])

        let update = ProfilePictureUpdate(
            profilePicturePath: ""
        )

        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: user.id)
            .execute()
    }

    private func contentType(
        for fileExtension: String
    ) -> String {
        switch fileExtension.lowercased() {
        case "png":
            return "image/png"

        case "heic":
            return "image/heic"

        default:
            return "image/jpeg"
        }
    }
}
