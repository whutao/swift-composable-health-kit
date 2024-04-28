import ComposableHealthPermission
import Dependencies
import Foundation
import HealthKit

extension HealthClient {
    
    public static var liveValue: HealthClient {
        let store = HKHealthStore()
        
        func ensureHealthDataAvailable() throws {
            guard HKHealthStore.isHealthDataAvailable() else {
                throw Failure.healthDataNotAvailable
            }
        }
        
        func mostRecentSampleValue(
            _ identifier: HKQuantityTypeIdentifier,
            unit: HKUnit
        ) -> (() async throws -> Double?) {
            @Dependency(\.date.now) var now
            return {
                try ensureHealthDataAvailable()
                let sample = try await getMostRecentHKQuantitySample(
                    store: store,
                    sampleType: HKQuantityType(identifier),
                    endDate: now
                )
                return sample?.quantity.doubleValue(for: unit)
            }
        }
        
        func samples(
            _ identifier: HKQuantityTypeIdentifier,
            unit: HKUnit
        ) -> ((ClosedRange<Date>, Int?) async throws -> [DoubleSample]) {
            return { dateRange, limit in
                try ensureHealthDataAvailable()
                return try await getHKQuantitySamples(
                    store: store,
                    sampleType: HKQuantityType(identifier),
                    dateRange: dateRange,
                    limit: limit ?? HKObjectQueryNoLimit
                )
                .map { hkSample in
                    return DoubleSample(
                        value: hkSample.quantity.doubleValue(for: unit),
                        start: hkSample.startDate,
                        end: hkSample.endDate
                    )
                }
            }
        }
        
        return HealthClient(
            permissionStatus: { writingType in
                @Dependency(\.healthPermissionClient) var permission
                return permission.status(for: getHKSampleType(from: writingType))
            },
            request: { writingTypes, readingTypes in
                @Dependency(\.healthPermissionClient) var permission
                try await permission.request(
                    writing: Set(writingTypes.map(getHKSampleType(from:))),
                    reading: Set(readingTypes.map(getHKObjectType(from:)))
                )
            },
            biologicalSex: {
                try ensureHealthDataAvailable()
                return try BiologicalSex(hkBiologicalSexObject: store.biologicalSex())
            },
            bloodType: {
                try ensureHealthDataAvailable()
                return try BloodType(hkBloodTypeObject: store.bloodType())
            },
            dateOfBirthComponents: {
                try ensureHealthDataAvailable()
                return try store.dateOfBirthComponents()
            },
            bodyMass: mostRecentSampleValue(.bodyMass, unit: .gram()),
            bodyMassSamples: samples(.bodyMass, unit: .gram()),
            height: mostRecentSampleValue(.height, unit: .meter()),
            heightSamples: samples(.height, unit: .meter())
        )
    }
}

private func getHKObjectType(from readingType: HealthClient.ReadingType) -> HKObjectType {
    return  switch readingType {
    case .biologicalSex: HKCharacteristicType(.biologicalSex)
    case .bloodType: HKCharacteristicType(.bloodType)
    case .dateOfBirth: HKCharacteristicType(.dateOfBirth)
    case .bodyMass: HKQuantityType(.bodyMass)
    case .height: HKQuantityType(.height)
    }
}

private func getHKSampleType(from writingType: HealthClient.WritingType) -> HKSampleType {
    return  switch writingType {
    case .bodyMass: HKQuantityType(.bodyMass)
    case .height: HKQuantityType(.height)
    }
}

private func getMostRecentHKQuantitySample(
    store: HKHealthStore,
    sampleType: HKQuantityType,
    endDate: Date
) async throws -> HKQuantitySample? {
    let samples = try await getHKSamples(
        store: store,
        sampleType: sampleType,
        limit: 1,
        predicate: HKQuery.predicateForSamples(
            withStart: .distantPast,
            end: endDate,
            options: .strictEndDate
        ),
        sortDescriptors: [
            NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )
        ]
    )
    return samples.first as? HKQuantitySample
}

private func getHKQuantitySamples(
    store: HKHealthStore,
    sampleType: HKQuantityType,
    dateRange: ClosedRange<Date>,
    limit: Int
) async throws -> [HKQuantitySample] {
    return try await getHKSamples(
        store: store,
        sampleType: sampleType,
        limit: limit,
        predicate: HKQuery.predicateForSamples(
            withStart: dateRange.lowerBound,
            end: dateRange.upperBound,
            options: [.strictStartDate, .strictEndDate]
        ),
        sortDescriptors: [
            NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )
        ]
    )
    .compactMap { hkSample in
        return hkSample as? HKQuantitySample
    }
}

private func getHKSamples(
    store: HKHealthStore,
    sampleType: HKQuantityType,
    limit: Int,
    predicate: NSPredicate,
    sortDescriptors: [NSSortDescriptor]
) async throws -> [HKSample] {
    return try await withUnsafeThrowingContinuation { continuation in
        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: sortDescriptors
        ) { _, samples, error in
            if let error {
                continuation.resume(throwing: error)
            } else if let samples {
                continuation.resume(returning: samples)
            } else {
                #if DEBUG
                preconditionFailure("Neither result, nor error retrieved")
                #endif
                continuation.resume(returning: [])
            }
        }
        store.execute(query)
    }
}
