import Foundation
@preconcurrency import HealthKit

@MainActor
final class HealthActivityReader {
    let store = HKHealthStore()
    let stepType = HKQuantityType(.stepCount)
    let distanceType = HKQuantityType(.distanceWalkingRunning)

    func requestReadPermission() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { throw AutomaticActivityError.unsupported }
        let readTypes: Set<HKObjectType> = [stepType, distanceType]
        try await store.requestAuthorization(toShare: [], read: readTypes)
        // Successful completion does NOT establish that read access was granted.
    }

    func enableDelivery() async throws {
        try await store.enableBackgroundDelivery(for: stepType, frequency: .hourly)
        try await store.enableBackgroundDelivery(for: distanceType, frequency: .hourly)
    }

    func snapshots(cutoffEpoch: Double) async throws -> [HealthActivityBucket] {
        guard HKHealthStore.isHealthDataAvailable() else { throw AutomaticActivityError.unsupported }
        let now = Date()
        let lookback = floor((now.timeIntervalSince1970 - 7 * 86400) / 900) * 900
        let from = max(cutoffEpoch, lookback)
        guard from < now.timeIntervalSince1970 else { return [] }
        let start = Date(timeIntervalSince1970: from)
        let metres = try await statistics(type: distanceType, start: start, end: now, isSteps: false)
        let steps = try await statistics(type: stepType, start: start, end: now, isSteps: true)
        return Set(metres.keys).union(steps.keys).sorted().compactMap { key in
            let epoch = Double(key)
            guard epoch >= cutoffEpoch, epoch < now.timeIntervalSince1970 else { return nil }
            let distance = metres[key] ?? 0
            let count = Int((steps[key] ?? 0).rounded(.down))
            guard distance.isFinite, distance >= 0, count >= 0, distance > 0 || count > 0 else { return nil }
            return HealthActivityBucket(startEpoch: epoch, endEpoch: epoch + 900,
                measuredUntilEpoch: min(epoch + 900, now.timeIntervalSince1970), metres: distance, steps: count)
        }
    }

    private func statistics(type: HKQuantityType, start: Date, end: Date, isSteps: Bool) async throws -> [Int64: Double] {
        let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let manual = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyWasUserEntered, allowedValues: [true])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            datePredicate, NSCompoundPredicate(notPredicateWithSubpredicate: manual)
        ])
        let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate,
            options: .cumulativeSum, anchorDate: Date(timeIntervalSince1970: 0),
            intervalComponents: DateComponents(minute: 15))
        return try await withCheckedThrowingContinuation { continuation in
            query.initialResultsHandler = { _, collection, error in
                if let error { continuation.resume(throwing: error); return }
                guard let collection else { continuation.resume(returning: [:]); return }
                var values: [Int64: Double] = [:]
                collection.enumerateStatistics(from: start, to: end) { statistic, _ in
                    guard let quantity = statistic.sumQuantity() else { return }
                    let value = quantity.doubleValue(for: isSteps ? HKUnit.count() : HKUnit.meter())
                    let key = Int64(statistic.startDate.timeIntervalSince1970.rounded())
                    values[key] = value
                }
                continuation.resume(returning: values)
            }
            store.execute(query)
        }
    }
}
