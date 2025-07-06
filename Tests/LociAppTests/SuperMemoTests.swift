import Testing
@testable import LociApp

struct SuperMemoTests {
    
    @Test func testSuperMemoAlgorithmFirstReview() {
        let result = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: 2.5,
            currentInterval: 1,
            repetitionCount: 0,
            quality: .perfect
        )
        
        #expect(result.intervalDays == 1)
        #expect(result.repetitionCount == 1)
        #expect(result.easeFactor > 2.5)
    }
    
    @Test func testSuperMemoAlgorithmSecondReview() {
        let result = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: 2.6,
            currentInterval: 1,
            repetitionCount: 1,
            quality: .perfect
        )
        
        #expect(result.intervalDays == 6)
        #expect(result.repetitionCount == 2)
    }
    
    @Test func testSuperMemoAlgorithmFailedReview() {
        let result = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: 2.5,
            currentInterval: 10,
            repetitionCount: 3,
            quality: .incorrect
        )
        
        #expect(result.intervalDays == 1)
        #expect(result.repetitionCount == 0)
    }
    
    @Test func testSuperMemoQualityDescriptions() {
        #expect(SuperMemoQuality.perfect.description == "Perfect recall")
        #expect(SuperMemoQuality.blackout.description == "Complete blackout")
        #expect(SuperMemoQuality.difficult.description == "Correct but difficult")
    }
}