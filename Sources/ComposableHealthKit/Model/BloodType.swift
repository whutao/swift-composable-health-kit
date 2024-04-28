import CasePaths
import Foundation
import HealthKit

/// The blood type of an individual.
@CasePathable
public enum BloodType: UInt8, Sendable {
    
    /// Blood type is not set, or cannot be retrieved.
    case notSet

    /// A+ blood type.
    case aPositive
    
    /// A– blood type.
    case aNegative

    /// B+ blood type.
    case bPositive
    
    /// B– blood type.
    case bNegative

    /// AB+ blood type.
    case abPositive
    
    /// AB- blood type.
    case abNegative

    /// O+ blood type.
    case oPositive
    
    /// O- blood type.
    case oNegative
}

extension BloodType {
    
    init(hkBloodType: HKBloodType) {
        self = switch hkBloodType {
        case .notSet: .notSet
        case .aPositive: .aPositive
        case .aNegative: .aNegative
        case .bPositive: .bPositive
        case .bNegative: .bNegative
        case .abPositive: .abPositive
        case .abNegative: .abNegative
        case .oPositive: .oPositive
        case .oNegative: .oNegative
        @unknown default: .notSet
        }
    }
    
    init(hkBloodTypeObject: HKBloodTypeObject) {
        self.init(hkBloodType: hkBloodTypeObject.bloodType)
    }
}
