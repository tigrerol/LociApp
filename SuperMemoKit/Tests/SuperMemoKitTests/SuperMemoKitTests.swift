import Testing
import Foundation
@testable import SuperMemoKit

@Test func basicSuperMemoCalculation() async throws {
    let algorithm = SuperMemoAlgorithm()
    
    // Test first review - should set interval to 1 day
    let result1 = algorithm.calculateNextReview(
        currentEaseFactor: 2.5,
        currentInterval: 0,
        repetitionCount: 0,
        quality: .perfect
    )
    
    #expect(result1.intervalDays == 1)
    #expect(result1.repetitionCount == 1)
    #expect(result1.easeFactor > 2.5) // Should increase for perfect response
}

@Test func superMemoQualitySuccessCheck() async throws {
    #expect(SuperMemoQuality.blackout.isSuccessful == false)
    #expect(SuperMemoQuality.incorrect.isSuccessful == false)
    #expect(SuperMemoQuality.incorrectEasy.isSuccessful == false)
    #expect(SuperMemoQuality.difficult.isSuccessful == true)
    #expect(SuperMemoQuality.hesitant.isSuccessful == true)
    #expect(SuperMemoQuality.perfect.isSuccessful == true)
}

@Test func superMemoIntervalCap() async throws {
    let config = SuperMemoConfiguration(maxIntervalDays: 90)
    let algorithm = SuperMemoAlgorithm(configuration: config)
    
    // Test with very high ease factor to trigger cap
    let result = algorithm.calculateNextReview(
        currentEaseFactor: 10.0,
        currentInterval: 90,
        repetitionCount: 5,
        quality: .perfect
    )
    
    #expect(result.intervalDays <= 90)
}

@Test func accuracyBiasApplication() async throws {
    let algorithm = SuperMemoAlgorithm()
    
    // Test with poor accuracy (50% correct)
    let resultPoor = algorithm.calculateNextReview(
        currentEaseFactor: 2.5,
        currentInterval: 10,
        repetitionCount: 3,
        quality: .perfect,
        totalReviews: 10,
        correctReviews: 5
    )
    
    // Test with good accuracy (90% correct)
    let resultGood = algorithm.calculateNextReview(
        currentEaseFactor: 2.5,
        currentInterval: 10,
        repetitionCount: 3,
        quality: .perfect,
        totalReviews: 10,
        correctReviews: 9
    )
    
    // Poor accuracy should result in shorter interval
    #expect(resultPoor.intervalDays < resultGood.intervalDays)
}

@Test func failedRecallReset() async throws {
    let algorithm = SuperMemoAlgorithm()
    
    let result = algorithm.calculateNextReview(
        currentEaseFactor: 3.0,
        currentInterval: 30,
        repetitionCount: 5,
        quality: .incorrect
    )
    
    #expect(result.intervalDays == 1)
    #expect(result.repetitionCount == 0)
}

@Test func staticConvenienceMethod() async throws {
    let result = SuperMemoAlgorithm.calculateNextReview(
        currentEaseFactor: 2.5,
        currentInterval: 0,
        repetitionCount: 0,
        quality: .perfect
    )
    
    #expect(result.intervalDays == 1)
    #expect(result.repetitionCount == 1)
}

@Test func noLoadBalancingImplementation() async throws {
    let balancer = NoLoadBalancing()
    let testDate = Date()
    
    let result = try await balancer.balanceReviewDate(testDate)
    #expect(result == testDate)
}
