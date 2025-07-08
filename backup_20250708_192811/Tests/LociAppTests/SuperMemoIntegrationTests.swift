import Testing
@testable import LociApp

struct SuperMemoIntegrationTests {
    
    @Test func testMultipleReviewsProgression() {
        let easeFactor = 2.5
        let intervalDays: Int32 = 1
        let repetitionCount: Int16 = 0
        
        // First review - perfect
        let firstResult = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: easeFactor,
            currentInterval: intervalDays,
            repetitionCount: repetitionCount,
            quality: .perfect
        )
        
        #expect(firstResult.intervalDays == 1) // First interval is always 1
        #expect(firstResult.repetitionCount == 1)
        #expect(firstResult.easeFactor > 2.5) // Should increase
        
        // Second review - perfect
        let secondResult = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: firstResult.easeFactor,
            currentInterval: firstResult.intervalDays,
            repetitionCount: firstResult.repetitionCount,
            quality: .perfect
        )
        
        #expect(secondResult.intervalDays == 6) // Second interval is always 6
        #expect(secondResult.repetitionCount == 2)
        
        // Third review - perfect (should start using ease factor)
        let thirdResult = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: secondResult.easeFactor,
            currentInterval: secondResult.intervalDays,
            repetitionCount: secondResult.repetitionCount,
            quality: .perfect
        )
        
        #expect(thirdResult.intervalDays > 6) // Should be interval * easeFactor
        #expect(thirdResult.repetitionCount == 3)
    }
    
    @Test func testReviewFailureResetsProgress() {
        // Start with some progress
        let result1 = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: 2.8,
            currentInterval: 15,
            repetitionCount: 5,
            quality: .incorrect
        )
        
        #expect(result1.intervalDays == 1) // Reset to 1 day
        #expect(result1.repetitionCount == 0) // Reset repetitions
    }
    
    @Test func testQualityScaleImpactOnEaseFactor() {
        let baseEaseFactor = 2.5
        let baseInterval: Int32 = 10
        let baseRepetition: Int16 = 3
        
        // Test different quality levels
        let perfectResult = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: baseEaseFactor,
            currentInterval: baseInterval,
            repetitionCount: baseRepetition,
            quality: .perfect
        )
        
        let hesitantResult = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: baseEaseFactor,
            currentInterval: baseInterval,
            repetitionCount: baseRepetition,
            quality: .hesitant
        )
        
        let difficultResult = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: baseEaseFactor,
            currentInterval: baseInterval,
            repetitionCount: baseRepetition,
            quality: .difficult
        )
        
        // Perfect should increase ease factor the most
        #expect(perfectResult.easeFactor > hesitantResult.easeFactor)
        #expect(hesitantResult.easeFactor > difficultResult.easeFactor)
        
        // All successful reviews should increase repetition count
        #expect(perfectResult.repetitionCount == 4)
        #expect(hesitantResult.repetitionCount == 4)
        #expect(difficultResult.repetitionCount == 4)
    }
    
    @Test func testEaseFactorMinimumBound() {
        // Test that ease factor never goes below 1.3
        let result = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: 1.3, // At minimum
            currentInterval: 1,
            repetitionCount: 1,
            quality: .difficult // Should decrease ease factor
        )
        
        #expect(result.easeFactor >= 1.3) // Should not go below minimum
    }
}