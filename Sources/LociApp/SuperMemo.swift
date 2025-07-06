import Foundation

public enum SuperMemoQuality: Int, CaseIterable {
    case blackout = 0
    case incorrect = 1
    case incorrectEasy = 2
    case difficult = 3
    case hesitant = 4
    case perfect = 5
    
    public var description: String {
        switch self {
        case .blackout: return "Complete blackout"
        case .incorrect: return "Incorrect"
        case .incorrectEasy: return "Incorrect but easy"
        case .difficult: return "Correct but difficult"
        case .hesitant: return "Correct with hesitation"
        case .perfect: return "Perfect recall"
        }
    }
}

public struct SuperMemoResult {
    public let easeFactor: Double
    public let intervalDays: Int32
    public let repetitionCount: Int16
    public let nextReviewDate: Date
    
    public init(easeFactor: Double, intervalDays: Int32, repetitionCount: Int16, nextReviewDate: Date) {
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetitionCount = repetitionCount
        self.nextReviewDate = nextReviewDate
    }
}

public final class SuperMemoAlgorithm {
    public static func calculateNextReview(
        currentEaseFactor: Double,
        currentInterval: Int32,
        repetitionCount: Int16,
        quality: SuperMemoQuality
    ) -> SuperMemoResult {
        
        var newEaseFactor = currentEaseFactor
        var newInterval = currentInterval
        var newRepetition = repetitionCount
        
        if quality.rawValue >= 3 {
            newEaseFactor = currentEaseFactor + (0.1 - Double(5 - quality.rawValue) * (0.08 + Double(5 - quality.rawValue) * 0.02))
            newEaseFactor = max(1.3, newEaseFactor)
            newRepetition = repetitionCount + 1
            
            switch newRepetition {
            case 1:
                newInterval = 1
            case 2:
                newInterval = 6
            default:
                newInterval = Int32(round(Double(currentInterval) * newEaseFactor))
            }
        } else {
            newInterval = 1
            newRepetition = 0
        }
        
        let nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: Int(newInterval),
            to: Date()
        ) ?? Date()
        
        return SuperMemoResult(
            easeFactor: newEaseFactor,
            intervalDays: newInterval,
            repetitionCount: newRepetition,
            nextReviewDate: nextReviewDate
        )
    }
}