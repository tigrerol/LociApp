import Foundation

/// SuperMemoKit - Enhanced SuperMemo algorithm implementation
/// 
/// This package provides an enhanced version of the SuperMemo-2 spaced repetition algorithm
/// with improvements for practical memory training applications.
///
/// Key enhancements over basic SuperMemo-2:
/// - 90-day interval cap to prevent exponential growth
/// - Accuracy bias multiplier based on historical performance
/// - Load balancing support for review scheduling
/// - Separation of practice sessions vs due reviews

// MARK: - Version Information

/// SuperMemoKit version and build information
public struct SuperMemoKitInfo {
    public static let version = "1.0.0"
    public static let buildDate = "2025-07-10"
    public static let features = [
        "90-day interval cap",
        "Accuracy bias multiplier",
        "Load balancing support",
        "Enhanced spaced repetition"
    ]
    
    public static var versionString: String {
        return "SuperMemoKit v\(version) (\(buildDate))"
    }
    
    public static var fullDescription: String {
        return "\(versionString) - Enhanced SuperMemo with: \(features.joined(separator: ", "))"
    }
}

// MARK: - SuperMemo Quality Ratings

/// Quality ratings for SuperMemo reviews
public enum SuperMemoQuality: Int, CaseIterable, Sendable {
    case blackout = 0      // Complete blackout
    case incorrect = 1     // Incorrect response
    case incorrectEasy = 2 // Incorrect but felt easy
    case difficult = 3     // Correct after significant difficulty
    case hesitant = 4      // Correct with some hesitation
    case perfect = 5       // Perfect, immediate recall
    
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
    
    /// Whether this quality represents a successful recall (≥ 3)
    public var isSuccessful: Bool {
        return rawValue >= 3
    }
}

// MARK: - SuperMemo Result

/// Result of a SuperMemo calculation
public struct SuperMemoResult: Sendable {
    public let easeFactor: Double
    public let intervalDays: Int32
    public let repetitionCount: Int16
    public let nextReviewDate: Date
    
    public init(
        easeFactor: Double,
        intervalDays: Int32,
        repetitionCount: Int16,
        nextReviewDate: Date
    ) {
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetitionCount = repetitionCount
        self.nextReviewDate = nextReviewDate
    }
}

// MARK: - SuperMemo Configuration

/// Configuration options for SuperMemo algorithm
public struct SuperMemoConfiguration: Sendable {
    /// Maximum interval in days (default: 90)
    public let maxIntervalDays: Int32
    
    /// Minimum ease factor (default: 1.3)
    public let minEaseFactor: Double
    
    /// Whether to apply accuracy bias (default: true)
    public let useAccuracyBias: Bool
    
    /// Accuracy bias range (default: 0.5 to 1.0)
    public let accuracyBiasRange: ClosedRange<Double>
    
    public init(
        maxIntervalDays: Int32 = 90,
        minEaseFactor: Double = 1.3,
        useAccuracyBias: Bool = true,
        accuracyBiasRange: ClosedRange<Double> = 0.5...1.0
    ) {
        self.maxIntervalDays = maxIntervalDays
        self.minEaseFactor = minEaseFactor
        self.useAccuracyBias = useAccuracyBias
        self.accuracyBiasRange = accuracyBiasRange
    }
    
    /// Default configuration with proven settings
    public static let `default` = SuperMemoConfiguration()
}

// MARK: - Enhanced SuperMemo Algorithm

/// Enhanced SuperMemo-2 algorithm implementation
public final class SuperMemoAlgorithm: Sendable {
    
    private let configuration: SuperMemoConfiguration
    
    public init(configuration: SuperMemoConfiguration = .default) {
        self.configuration = configuration
    }
    
    /// Calculate next review parameters based on current state and quality response
    ///
    /// - Parameters:
    ///   - currentEaseFactor: Current ease factor (typically starts at 2.5)
    ///   - currentInterval: Current interval in days
    ///   - repetitionCount: Number of successful repetitions
    ///   - quality: Quality of the response (0-5)
    ///   - totalReviews: Total number of reviews (for accuracy bias)
    ///   - correctReviews: Number of correct reviews (for accuracy bias)
    /// - Returns: SuperMemoResult with updated parameters
    public func calculateNextReview(
        currentEaseFactor: Double,
        currentInterval: Int32,
        repetitionCount: Int16,
        quality: SuperMemoQuality,
        totalReviews: Int32 = 0,
        correctReviews: Int32 = 0
    ) -> SuperMemoResult {
        
        var newEaseFactor = currentEaseFactor
        var newInterval = currentInterval
        var newRepetition = repetitionCount
        
        if quality.isSuccessful {
            // Successful recall - update ease factor and advance
            newEaseFactor = currentEaseFactor + (0.1 - Double(5 - quality.rawValue) * (0.08 + Double(5 - quality.rawValue) * 0.02))
            newEaseFactor = max(configuration.minEaseFactor, newEaseFactor)
            newRepetition = repetitionCount + 1
            
            // Calculate new interval based on repetition count
            switch newRepetition {
            case 1:
                newInterval = 1
            case 2:
                newInterval = 6
            default:
                newInterval = Int32(round(Double(currentInterval) * newEaseFactor))
            }
            
            // Apply accuracy bias for cards with history
            if configuration.useAccuracyBias && newRepetition >= 3 && totalReviews > 0 {
                let accuracy = Double(correctReviews) / Double(totalReviews)
                // Accuracy multiplier ranges from accuracyBiasRange
                // Cards with 100% accuracy get no penalty
                // Cards with 0% accuracy get maximum reduction
                let range = configuration.accuracyBiasRange
                let accuracyMultiplier = max(
                    range.lowerBound,
                    min(range.upperBound, range.lowerBound + accuracy * (range.upperBound - range.lowerBound))
                )
                newInterval = Int32(Double(newInterval) * accuracyMultiplier)
            }
            
            // Cap at maximum interval
            newInterval = min(newInterval, configuration.maxIntervalDays)
        } else {
            // Failed recall - reset
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

// MARK: - Convenience Extensions

extension SuperMemoAlgorithm {
    /// Convenience method that uses default configuration
    public static func calculateNextReview(
        currentEaseFactor: Double,
        currentInterval: Int32,
        repetitionCount: Int16,
        quality: SuperMemoQuality,
        totalReviews: Int32 = 0,
        correctReviews: Int32 = 0
    ) -> SuperMemoResult {
        let algorithm = SuperMemoAlgorithm()
        return algorithm.calculateNextReview(
            currentEaseFactor: currentEaseFactor,
            currentInterval: currentInterval,
            repetitionCount: repetitionCount,
            quality: quality,
            totalReviews: totalReviews,
            correctReviews: correctReviews
        )
    }
}

// MARK: - Load Balancing Support

/// Protocol for load balancing review dates
public protocol ReviewDateBalancer: Sendable {
    /// Balance a proposed review date to distribute load
    /// - Parameter proposedDate: The date suggested by SuperMemo algorithm
    /// - Returns: Balanced date that considers review load distribution
    func balanceReviewDate(_ proposedDate: Date) async throws -> Date
}

/// Default implementation that doesn't perform load balancing
public struct NoLoadBalancing: ReviewDateBalancer {
    public init() {}
    
    public func balanceReviewDate(_ proposedDate: Date) async throws -> Date {
        return proposedDate
    }
}

// MARK: - Statistics Support

/// Statistics for review performance
public struct ReviewStats: Sendable {
    public let totalReviews: Int
    public let correctReviews: Int
    public let accuracy: Double
    public let averageResponseTimeMs: Int32
    public let periodDays: Int
    
    public init(
        totalReviews: Int,
        correctReviews: Int,
        accuracy: Double,
        averageResponseTimeMs: Int32,
        periodDays: Int
    ) {
        self.totalReviews = totalReviews
        self.correctReviews = correctReviews
        self.accuracy = accuracy
        self.averageResponseTimeMs = averageResponseTimeMs
        self.periodDays = periodDays
    }
}

/// Daily review statistics
public struct DailyReviewStat: Sendable {
    public let date: Date
    public let totalReviews: Int
    public let correctReviews: Int
    public let accuracy: Double
    
    public init(
        date: Date,
        totalReviews: Int,
        correctReviews: Int,
        accuracy: Double
    ) {
        self.date = date
        self.totalReviews = totalReviews
        self.correctReviews = correctReviews
        self.accuracy = accuracy
    }
}
