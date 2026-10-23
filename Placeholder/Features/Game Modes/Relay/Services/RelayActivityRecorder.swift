import Foundation
import Observation
import CoreMotion

nonisolated enum RelayRecordingError: LocalizedError {
    case unavailable, noDistance, accountChanged, storage
    var errorDescription: String? {
        switch self {
        case .unavailable: return "Walking-distance estimation is unavailable on this device. Test on a supported physical iPhone."
        case .noDistance: return "No estimated distance was returned. Check Motion & Fitness permission and try again."
        case .accountChanged: return "Sign back into the account that owns this recording."
        case .storage: return "The recording could not be saved locally. No activity was uploaded."
        }
    }
}

@MainActor
@Observable
final class RelayActivityRecorder {
    static let shared = RelayActivityRecorder()
    private let pedometer = CMPedometer()
    private let service = RelayService()
    private var userID: UUID?
    private var generation = UUID()
    private(set) var draft: RelayRecordingDraft?
    private(set) var pending: RelayPendingActivity?
    private(set) var isBusy = false
    var errorMessage: String?
    var message: String?

    private init() {}

    // Call from the authenticated root whenever its user ID changes.
    func configure(userID: UUID?) {
        guard self.userID != userID else { return }
        self.userID = userID
        generation = UUID()
        draft = nil
        pending = nil
        isBusy = false
        errorMessage = nil
        message = nil
        guard let userID else { return }
        do {
            let url = try archiveURL(userID: userID)
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let archive = try JSONDecoder().decode(RelayRecordingArchive.self, from: Data(contentsOf: url))
            guard archive.draft?.userID == userID || archive.draft == nil,
                  archive.pending?.userID == userID || archive.pending == nil else {
                throw RelayRecordingError.storage
            }
            draft = archive.draft
            pending = archive.pending
        } catch {
            errorMessage = "The saved recording could not be restored: \(error.localizedDescription)"
        }
    }

    func start(game: RelayGame) async {
        guard !isBusy, draft == nil, pending == nil, game.status == .active else { return }
        guard let userID else { errorMessage = "Sign in before recording."; return }
        guard CMPedometer.isDistanceAvailable() else {
            errorMessage = RelayRecordingError.unavailable.localizedDescription
            return
        }
        let token = generation
        isBusy = true
        errorMessage = nil
        message = nil
        defer { if generation == token { isBusy = false } }
        do {
            // Requests motion access before choosing the recording start time.
            _ = try await measurement(from: Date().addingTimeInterval(-60), to: Date())
            guard generation == token else { return }
            let now = Date()
            draft = RelayRecordingDraft(userID: userID, gameID: game.id, teamID: game.teamID,
                                        startedAt: now, cursor: now, stopAt: nil)
            do { try persist() }
            catch { draft = nil; throw error }
        } catch {
            if generation == token { errorMessage = error.localizedDescription }
        }
    }

    // Historical, non-overlapping chunks. Each pending payload survives retries unchanged.
    func sync(finish: Bool = false) async {
        guard !isBusy, let initialDraft = draft, let userID, initialDraft.userID == userID else { return }
        let token = generation
        isBusy = true
        errorMessage = nil
        defer { if generation == token { isBusy = false } }
        do {
            if finish || Date().timeIntervalSince(initialDraft.startedAt) >= 86400 {
                if draft?.stopAt == nil {
                    draft?.stopAt = min(Date(), initialDraft.startedAt.addingTimeInterval(86400))
                    try persist()
                }
            }
            if let previous = pending {
                let receipt = try await service.submit(previous)
                guard generation == token else { return }
                try acknowledge(previous, receipt: receipt)
            }
            guard let current = draft else { return }
            let end = current.stopAt ?? Date()
            // Millisecond timestamps match the format sent to Postgres.
            let start = Date(timeIntervalSince1970: ceil(current.cursor.timeIntervalSince1970 * 1000) / 1000)
            let stop = Date(timeIntervalSince1970: floor(end.timeIntervalSince1970 * 1000) / 1000)
            if stop <= start {
                if current.stopAt != nil { draft = nil; try persist() }
                return
            }
            let (metres, steps) = try await measurement(from: start, to: stop)
            guard generation == token else { return }
            let activity = RelayPendingActivity(id: UUID(), userID: userID, gameID: current.gameID,
                startedAt: start, endedAt: stop, metres: metres, steps: steps)
            pending = activity
            // Persist BEFORE submitting: a response lost after commit can be retried safely.
            try persist()
            let receipt = try await service.submit(activity)
            guard generation == token else { return }
            try acknowledge(activity, receipt: receipt)
        } catch {
            if generation == token { errorMessage = error.localizedDescription }
        }
    }

    func discard() {
        guard !isBusy else { return }
        let previousDraft = draft
        let previousPending = pending
        draft = nil
        pending = nil
        do {
            try persist()
            errorMessage = nil
            message = "Unsubmitted recording discarded. Already credited activity is unchanged."
        } catch {
            draft = previousDraft
            pending = previousPending
            errorMessage = error.localizedDescription
        }
    }

    private func acknowledge(_ activity: RelayPendingActivity, receipt: RelayReceipt) throws {
        pending = nil
        draft?.cursor = activity.endedAt
        if receipt.gameStatus != .active {
            draft = nil
            message = "Relay completed. Recording stopped."
        } else if let stop = draft?.stopAt, activity.endedAt >= Date(timeIntervalSince1970: floor(stop.timeIntervalSince1970 * 1000) / 1000) {
            draft = nil
            message = "Recording finished and synced."
        }
        try persist()
    }

    private func measurement(from start: Date, to end: Date) async throws -> (Double, Int) {
        guard CMPedometer.isDistanceAvailable() else { throw RelayRecordingError.unavailable }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Double, Int), Error>) in
            pedometer.queryPedometerData(from: start, to: end) { data, error in
                if let error { continuation.resume(throwing: error); return }
                guard let data, let distance = data.distance else {
                    continuation.resume(throwing: RelayRecordingError.noDistance); return
                }
                let metres = distance.doubleValue
                guard metres.isFinite, metres >= 0 else {
                    continuation.resume(throwing: RelayRecordingError.noDistance); return
                }
                continuation.resume(returning: (metres, data.numberOfSteps.intValue))
            }
        }
    }

    private func archiveURL(userID: UUID) throws -> URL {
        let directory = try FileManager.default.url(for: .applicationSupportDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("RelayRecordings", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(userID.uuidString + ".json")
    }

    private func persist() throws {
        guard let userID else { throw RelayRecordingError.accountChanged }
        do {
            let data = try JSONEncoder().encode(RelayRecordingArchive(draft: draft, pending: pending))
            try data.write(to: archiveURL(userID: userID), options: .atomic)
        } catch { throw RelayRecordingError.storage }
    }
}
