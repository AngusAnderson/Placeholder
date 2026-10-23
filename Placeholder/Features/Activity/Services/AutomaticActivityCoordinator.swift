import Foundation
import Observation
@preconcurrency import HealthKit
import UIKit
import Supabase

@MainActor
@Observable
final class AutomaticActivityCoordinator {
    static let shared = AutomaticActivityCoordinator()
    private let reader = HealthActivityReader()
    private let service = AutomaticActivityService()
    private let relayPartialService = RelayPartialActivityService()
    private var observers: [HKObserverQuery] = []
    private var userID: UUID?
    private var generation = UUID()
    private var archive = AutomaticActivityArchive()
    private(set) var isBusy = false
    private(set) var enabled = false
    private(set) var pendingCount = 0
    private(set) var cutoff: Date?
    private(set) var lastSync: Date?
    var errorMessage: String?
    var statusMessage = "Automatic activity is off."
    private init() {}

    // Called synchronously at app launch if this device previously enabled Health sync.
    func installObserversIfPreviouslyEnabled() {
        guard UserDefaults.standard.bool(forKey: "hasConfiguredAutomaticHealthActivity") else { return }
        installObservers()
    }

    private func installObservers() {
        guard observers.isEmpty, HKHealthStore.isHealthDataAvailable() else { return }
        for type in [reader.stepType, reader.distanceType] {
            let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completion, error in
                Task { @MainActor in
                    if error == nil {
                        await AutomaticActivityCoordinator.shared.synchronize()
                    }
                    // Acknowledge even if a read/upload failed; reconciliation retries later.
                    completion()
                }
            }
            observers.append(query)
            reader.store.execute(query)
        }
    }

    func configure(userID: UUID?) {
        guard self.userID != userID else { return }
        self.userID = userID
        generation = UUID()
        archive = AutomaticActivityArchive()
        enabled = false
        pendingCount = 0
        cutoff = nil
        lastSync = nil
        isBusy = false
        errorMessage = nil
        statusMessage = userID == nil ? "Sign in to configure automatic activity." : "Automatic activity is off on this account/device."
    }

    // A foreground user action only. Never prompt for consent in a background callback.
    func enable() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let session = try await supabase.auth.session
            configure(userID: session.user.id)
            isBusy = true
            let token = generation
            try requireUnlocked()
            var saved = try loadArchive(for: session.user.id)
            try await reader.requestReadPermission()
            guard generation == token else { return }
            let preference = try await service.setEnabled(true, userID: session.user.id)
            guard generation == token else { return }
            if saved.preference.cutoffEpoch != preference.cutoffEpoch {
                saved.acknowledged = [:]
                saved.pending = [:]
            }
            saved.preference = preference
            archive = saved
            try persist()
            publishPreference()
            UserDefaults.standard.set(true, forKey: "hasConfiguredAutomaticHealthActivity")
            installObservers()
            try await reader.enableDelivery()
            statusMessage = "Enabled. Eligible activity starts at the next 15-minute boundary. Read access is controlled in Health."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disable() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let session = try await supabase.auth.session
            guard session.user.id == userID else { throw AutomaticActivityError.accountChanged }
            let token = generation
            let preference = try await service.setEnabled(false, userID: session.user.id)
            guard generation == token else { return }
            archive.preference = preference
            archive.pending = [:]
            // Reflect the server's privacy setting immediately, even if local saving fails.
            publishPreference()
            statusMessage = "Automatic sharing is off. Previously credited distance is unchanged."
            try persist()
        } catch { errorMessage = error.localizedDescription }
    }

    // Safe to call from foreground lifecycle, HealthKit observer, or unlock callback.
    func synchronize() async {
        guard !isBusy else { return }
        do { try requireUnlocked() } catch { return }
        isBusy = true
        let initialGeneration = generation
        defer { if generation == initialGeneration { isBusy = false } }
        do {
            let session = try await supabase.auth.session
            if userID != session.user.id {
                configure(userID: session.user.id)
                // A root/foreground pass will retry after configuring the account.
                return
            }
            let token = generation
            archive = try loadArchive(for: session.user.id)
            publishPreference()
            guard archive.preference.enabled else { return }
            let remote = try await service.preference()
            guard generation == token else { return }
            guard remote.enabled else {
                archive.preference = remote
                archive.pending = [:]
                try persist()
                publishPreference()
                return
            }
            if remote.cutoffEpoch != archive.preference.cutoffEpoch {
                archive.acknowledged = [:]
                archive.pending = [:]
            }
            archive.preference = remote
            publishPreference()
            errorMessage = nil

            let snapshots = try await reader.snapshots(cutoffEpoch: remote.cutoffEpoch)
            guard generation == token else { return }
            for bucket in snapshots {
                let old = archive.acknowledged[bucket.key]
                let queued = archive.pending[bucket.key]
                let oldMetres = max(old?.metres ?? 0, queued?.metres ?? 0)
                let oldSteps = max(old?.steps ?? 0, queued?.steps ?? 0)
                if bucket.metres > oldMetres || bucket.steps > oldSteps {
                    archive.pending[bucket.key] = HealthActivityBucket(
                        startEpoch: bucket.startEpoch, endEpoch: bucket.endEpoch,
                        measuredUntilEpoch: max(bucket.measuredUntilEpoch, queued?.measuredUntilEpoch ?? 0),
                        metres: max(bucket.metres, oldMetres), steps: max(bucket.steps, oldSteps))
                }
            }
            // Keep unacknowledged work, prune old ACK metadata only.
            let oldest = Date().timeIntervalSince1970 - 8 * 86400
            archive.acknowledged = archive.acknowledged.filter { $0.value.endEpoch >= oldest }
            try persist()
            pendingCount = archive.pending.count
            // Bounded network work per callback. Remaining work stays durably queued.
            for _ in 0..<2 {
                let batch = Array(archive.pending.values.sorted { $0.startEpoch < $1.startEpoch }.prefix(32))
                if batch.isEmpty { break }
                try await service.upload(batch, userID: session.user.id)
                guard generation == token else { return }
                for bucket in batch {
                    archive.acknowledged[bucket.key] = bucket
                    archive.pending.removeValue(forKey: bucket.key)
                }
                try persist()
                pendingCount = archive.pending.count
            }
            try await relayPartialService.synchronize(
                reader: reader,
                userID: session.user.id
            )

            guard generation == token else {
                return
            }

            NotificationCenter.default.post(
                name: .relayActivityDidSync,
                object: nil
            )
            lastSync = Date()
            statusMessage = snapshots.isEmpty
                ? "No readable eligible activity yet. This can mean no data or restricted Health access."
                : "Activity reconciled. Team totals update after eligible uploads."
        } catch {
            if generation == initialGeneration { errorMessage = error.localizedDescription }
        }
    }

    // Called when returning to foreground. Loads status without requesting permissions.
    func restoreLocalStatus() {
        guard let userID, UIApplication.shared.isProtectedDataAvailable else { return }
        do { archive = try loadArchive(for: userID); publishPreference() }
        catch { errorMessage = error.localizedDescription }
    }

    private func publishPreference() {
        enabled = archive.preference.enabled
        cutoff = archive.preference.cutoffEpoch > 0 ? Date(timeIntervalSince1970: archive.preference.cutoffEpoch) : nil
        pendingCount = archive.pending.count
    }
    private func requireUnlocked() throws {
        guard UIApplication.shared.isProtectedDataAvailable else { throw AutomaticActivityError.protectedData }
    }
    private func archiveURL(for userID: UUID) throws -> URL {
        var directory = try FileManager.default.url(for: .applicationSupportDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("AutomaticHealthActivity", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        return directory.appendingPathComponent(userID.uuidString + ".json")
    }
    private func loadArchive(for userID: UUID) throws -> AutomaticActivityArchive {
        try requireUnlocked()
        let url = try archiveURL(for: userID)
        guard FileManager.default.fileExists(atPath: url.path) else { return AutomaticActivityArchive() }
        return try JSONDecoder().decode(AutomaticActivityArchive.self, from: Data(contentsOf: url))
    }
    private func persist() throws {
        try requireUnlocked()
        guard let userID else { throw AutomaticActivityError.signedOut }
        let data = try JSONEncoder().encode(archive)
        try data.write(to: archiveURL(for: userID), options: [.atomic, .completeFileProtection])
    }
}
