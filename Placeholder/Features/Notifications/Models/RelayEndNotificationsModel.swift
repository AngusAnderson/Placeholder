import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class RelayEndNotificationsModel {
    var notifications: [RelayEndNotification] = []
    var presented: RelayEndNotification?
    var isLoading = false
    var errorMessage: String?
    private var acknowledgementTarget: RelayEndNotification?
    private let client: SupabaseClient

    init(client: SupabaseClient) { self.client = client }

    func load(autoPresent: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let session = try await client.auth.session
            let rows: [RelayEndNotification] = try await client
                .from("relay_end_notifications")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .order("created_at", ascending: false)
                .limit(100)
                .execute().value
            guard !Task.isCancelled else { return }
            notifications = rows
            // Retry acknowledgements saved locally if an earlier request failed.
            for row in rows where row.isCompleted && row.celebrationSeenAt == nil
                && UserDefaults.standard.bool(forKey: row.localAcknowledgementKey) {
                do { try await saveAcknowledgement(row.id) }
                catch { errorMessage = "Could not save an acknowledgement. It will retry next refresh." }
            }
            if autoPresent && presented == nil && acknowledgementTarget == nil,
               let next = rows.first(where: {
                   $0.isCompleted && $0.celebrationSeenAt == nil
                   && !UserDefaults.standard.bool(forKey: $0.localAcknowledgementKey)
               }) {
                open(next)
            }
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func open(_ notification: RelayEndNotification) {
        acknowledgementTarget = notification
        presented = notification
    }

    func presentationDismissed() async {
        guard let row = acknowledgementTarget else { return }
        acknowledgementTarget = nil
        if row.isCompleted {
            UserDefaults.standard.set(true, forKey: row.localAcknowledgementKey)
        }
        if let index = notifications.firstIndex(where: { $0.id == row.id }) {
            notifications[index].readAt = Date()
            if row.isCompleted { notifications[index].celebrationSeenAt = Date() }
        }
        do { try await saveAcknowledgement(row.id) }
        catch { errorMessage = "Could not save the acknowledgement. Please refresh when online." }
    }

    private func saveAcknowledgement(_ id: UUID) async throws {
        _ = try await client.rpc("ack_relay_end_notification", params: [
            "p_notification_id": id.uuidString
        ]).execute()
    }
}
