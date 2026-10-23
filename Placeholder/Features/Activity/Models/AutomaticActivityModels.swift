import Foundation

nonisolated struct HealthSharingPreference: Codable, Sendable {
    let enabled: Bool
    let cutoffEpoch: Double
}

nonisolated struct HealthActivityBucket: Codable, Sendable {
    let startEpoch: Double
    let endEpoch: Double
    let measuredUntilEpoch: Double
    let metres: Double
    let steps: Int
    var key: String { String(Int64(startEpoch)) }
}

nonisolated struct AutomaticActivityArchive: Codable, Sendable {
    var preference = HealthSharingPreference(enabled: false, cutoffEpoch: 0)
    var acknowledged: [String: HealthActivityBucket] = [:]
    var pending: [String: HealthActivityBucket] = [:]
}

nonisolated enum AutomaticActivityError: LocalizedError {
    case unsupported, signedOut, protectedData, accountChanged
    var errorDescription: String? {
        switch self {
        case .unsupported: return "Health data is unavailable on this device."
        case .signedOut: return "Sign in before enabling automatic activity."
        case .protectedData: return "Unlock your iPhone to read activity data. It will be retried later."
        case .accountChanged: return "The signed-in account changed."
        }
    }
}
