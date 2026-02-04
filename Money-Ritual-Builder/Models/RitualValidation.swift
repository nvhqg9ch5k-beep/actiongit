import Foundation
import CoreData

struct RitualValidation {
    static func validateRitual(name: String, steps: [String]) -> ValidationResult {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return .failure("Ritual name cannot be empty")
        }
        
        if trimmedName.count > 100 {
            return .failure("Ritual name is too long (max 100 characters)")
        }
        
        // Validate steps
        let validSteps = steps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if validSteps.count < 3 {
            return .failure("Ritual must have at least 3 steps")
        }
        
        if validSteps.count > 7 {
            return .failure("Ritual cannot have more than 7 steps")
        }
        
        for (index, step) in validSteps.enumerated() {
            if step.count > 200 {
                return .failure("Step \(index + 1) is too long (max 200 characters)")
            }
        }
        
        return .success
    }
    
    static func validateCompletion(ritual: MoneyRitual, date: Date) -> ValidationResult {
        guard !ritual.isArchived else {
            return .failure("Cannot complete archived ritual")
        }
        
        guard !ritual.isPaused else {
            return .failure("Cannot complete paused ritual")
        }
        
        // Check if date is in the future
        if date > Date() {
            return .failure("Cannot complete ritual for a future date")
        }
        
        // Check if date is too far in the past (more than 1 year)
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        if date < oneYearAgo {
            return .failure("Cannot complete ritual for a date more than 1 year ago")
        }
        
        return .success
    }
}

enum ValidationResult {
    case success
    case failure(String)
    
    var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }
}
