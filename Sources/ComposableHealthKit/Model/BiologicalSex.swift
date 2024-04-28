import CasePaths
import HealthKit
import Foundation

/// The biological sex of an individual.
@CasePathable
public enum BiologicalSex: UInt8, Sendable {
    
    /// Biological sex is not set, or cannot be retrieved.
    case notSet

    /// Biological sex is categorized as female.
    case female

    /// Biological sex is categorized as male.
    case male

    /// Not categorized as either male or female.
    case other
}

extension BiologicalSex {
    
    init(hkBiologicalSex: HKBiologicalSex) {
        self = switch hkBiologicalSex {
        case .notSet: .notSet
        case .female: .female
        case .male: .male
        case .other: .other
        @unknown default: .notSet
        }
    }
    
    init(hkBiologicalSexObject: HKBiologicalSexObject) {
        self.init(hkBiologicalSex: hkBiologicalSexObject.biologicalSex)
    }
}
