import Foundation
@preconcurrency import HealthKit

extension HealthActivityReader {
    func relayPartialMetres(start: Date, end: Date) async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw AutomaticActivityError.unsupported
        }
        guard end > start else { return 0 }

        // Conservative boundary policy: only complete samples inside the window.
        // Do not estimate what fraction of a straddling sample occurred afterward.
        let datePredicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: [.strictStartDate, .strictEndDate]
        )
        // Exclude zero-duration samples at the right boundary: the next regular
        // bucket owns them. This keeps partial and regular accounting disjoint.
        let beforeEnd = NSPredicate(format: "startDate < %@", end as NSDate)
        var filters: [NSPredicate] = [datePredicate, beforeEnd]
        #if !DEBUG
        let manual = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeyWasUserEntered,
            allowedValues: [true]
        )
        filters.append(NSCompoundPredicate(notPredicateWithSubpredicate: manual))
        #endif
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: filters)

        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning:
                        statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                    )
                }
            }
            store.execute(query)
        }
    }
}
