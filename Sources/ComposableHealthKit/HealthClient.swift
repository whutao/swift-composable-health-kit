import CasePaths
import ComposablePermission
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct HealthClient: DependencyKey, Sendable {
    
    /// A sample that represents a quantity, including the value and start/end dates.
    public struct DoubleSample: Sendable {
        
        /// The numeric value of a sample.
        public let value: Double
        
        /// The start date of a sample.
        public let start: Date
        
        /// The end date of a sample.
        public let end: Date
        
        public init(value: Double, start: Date, end: Date) {
            self.value = value
            self.start = start
            self.end = end
        }
    }
    
    @CasePathable
    public enum Failure: Error {
        
        /// Thrown when `HKHealthStore.isHealthDataAvailable()` is false.
        case healthDataNotAvailable
    }
    
    // Permission
    
    /// Types of health data that can be retrieved from the HealthKit store.
    @CasePathable
    public enum ReadingType: Hashable, Sendable {
        case biologicalSex
        case bloodType
        case dateOfBirth
        case bodyMass
        case height
    }
    
    /// Types of health data that can be written to the HealthKit store.
    @CasePathable
    public enum WritingType: Hashable, Sendable {
        case bodyMass
        case height
    }
    
    /// Returns the app’s authorization status for sharing the specified health data type.
    public var permissionStatus: (_ forWriting: WritingType) -> PermissionStatus = { _ in .denied }
    
    /// Requests permission to save and read the specified health data types.
    public var request: (
        _ writing: Set<WritingType>,
        _ reading: Set<ReadingType>
    ) async throws -> Void
    
    // Common
    
    /// Retrieves the user’s biological sex from the HealthKit store.
    public var biologicalSex: () throws -> BiologicalSex
    
    /// Retrieves the user’s blood type from the HealthKit store.
    public var bloodType: () throws -> BloodType
    
    /// Retrieves the user’s date of birth components from the HealthKit store.
    public var dateOfBirthComponents: () throws -> DateComponents
    
    // Body mass
    
    /// Retrieves the user’s body mass (in grams) from the HealthKit store.
    ///
    /// - Throws: `HealthClient.Failure` when
    /// - Throws: `HKError` when sample retrieving fails.
    /// - Returns: A numeric value, or `nil` if no samples found in the store.
    public var bodyMass: () async throws -> Double?
    
    /// Retrieves the user’s body mass (in grams) measurement from the HealthKit store.
    ///
    /// - Throws: `HealthClient.Failure` when
    /// - Throws: `HKError` when sample retrieving fails.
    /// - Returns: A numeric value, or `nil` if no samples found in the store.
    public var bodyMassSamples: (
        _ in: ClosedRange<Date>,
        _ limit: Int?
    ) async throws -> [DoubleSample]
    
    // Height
    
    /// Retrieves the user’s body height (in meters) from the HealthKit store.
    ///
    /// - Throws: `HealthClient.Failure` when
    /// - Throws: `HKError` when sample retrieving fails.
    /// - Returns: A numeric value, or `nil` if no samples found in the store.
    public var height: () async throws -> Double?
    
    /// Retrieves the user’s body height (in meters) measurements from the HealthKit store.
    ///
    /// - Throws: `HealthClient.Failure` when
    /// - Throws: `HKError` when sample retrieving fails.
    /// - Returns: A numeric value, or `nil` if no samples found in the store.
    public var heightSamples: (
        _ in: ClosedRange<Date>,
        _ limit: Int?
    ) async throws -> [DoubleSample]
}

extension DependencyValues {
    
    /// A dependency that provides an API to the HealthKit.
    public var healthClient: HealthClient {
        get { self[HealthClient.self] }
        set { self[HealthClient.self] = newValue }
    }
}
