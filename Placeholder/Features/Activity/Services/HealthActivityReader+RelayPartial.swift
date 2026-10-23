import Foundation
@preconcurrency import HealthKit

extension HealthActivityReader {
    func relayPartialMetres(
        start: Date,
        end: Date
    ) async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw AutomaticActivityError.unsupported
        }

        guard end > start else {
            return 0
        }

        #if DEBUG
        print(
            "[Relay Partial] Query window:",
            start,
            "to",
            end
        )
        #endif

        // Only accept samples fully inside the eligible window.
        let datePredicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: [
                .strictStartDate,
                .strictEndDate
            ]
        )

        // A sample starting exactly at the right boundary belongs
        // to the next interval, not this partial interval.
        let beforeEnd = NSPredicate(
            format: "startDate < %@",
            end as NSDate
        )

        var filters: [NSPredicate] = [
            datePredicate,
            beforeEnd
        ]

        #if !DEBUG
        let manuallyEntered = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeyWasUserEntered,
            allowedValues: [true]
        )

        filters.append(
            NSCompoundPredicate(
                notPredicateWithSubpredicate: manuallyEntered
            )
        )
        #endif

        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: filters
        )

        return try await withCheckedThrowingContinuation {
            (
                continuation:
                    CheckedContinuation<Double, Error>
            ) in

            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    let healthError = error as NSError

                    if healthError.domain == HKErrorDomain,
                       healthError.code ==
                        HKError.Code.errorNoData.rawValue {
                        #if DEBUG
                        print(
                            "[Relay Partial] No readable matching samples.",
                            "Returning 0 metres."
                        )
                        #endif

                        continuation.resume(returning: 0)
                        return
                    }

                    // Do not hide unrelated failures, such as
                    // unavailable protected Health data.
                    continuation.resume(throwing: error)
                    return
                }

                let metres = statistics?
                    .sumQuantity()?
                    .doubleValue(for: .meter()) ?? 0

                #if DEBUG
                print(
                    "[Relay Partial] Matching distance:",
                    metres,
                    "metres"
                )
                #endif

                continuation.resume(returning: metres)
            }

            store.execute(query)
        }
    }
}
