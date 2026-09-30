import CryptoKit
import Foundation
import Security

enum AppleSignInHelpers {
    static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)

        let characters = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )

        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randomBytes = [UInt8](repeating: 0, count: 16)

            let status = SecRandomCopyBytes(
                kSecRandomDefault,
                randomBytes.count,
                &randomBytes
            )

            guard status == errSecSuccess else {
                fatalError("Unable to generate secure random bytes")
            }

            for byte in randomBytes where remainingLength > 0 {
                if byte < characters.count {
                    result.append(characters[Int(byte)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))

        return digest
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
