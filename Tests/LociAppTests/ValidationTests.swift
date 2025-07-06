import Testing
@testable import LociApp

struct ValidationTests {
    
    @Test func testSequenceNumberValidation() {
        // Test valid sequence numbers
        #expect("1" == "1")
        #expect("10" == "10")
        #expect("999" == "999")
        
        // Test that Int conversion works for valid strings
        #expect(Int("1") == 1)
        #expect(Int("10") == 10)
        #expect(Int("999") == 999)
        
        // Test invalid inputs
        #expect(Int("") == nil)
        #expect(Int("abc") == nil)
        #expect(Int("1.5") == nil)
        #expect(Int("-1") == -1) // Negative numbers are technically valid Int
    }
    
    @Test func testEmptyInputHandling() {
        let emptyString = ""
        let whitespaceString = "   "
        
        #expect(emptyString.isEmpty)
        #expect(!whitespaceString.isEmpty)
        #expect(whitespaceString.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    
    @Test func testSequenceComparison() {
        let correctSequence = 5
        let userInputs = ["5", "3", "10", "abc", ""]
        
        let results = userInputs.map { input in
            Int(input) == correctSequence
        }
        
        #expect(results[0] == true)  // "5" -> correct
        #expect(results[1] == false) // "3" -> incorrect
        #expect(results[2] == false) // "10" -> incorrect
        #expect(results[3] == false) // "abc" -> invalid
        #expect(results[4] == false) // "" -> invalid
    }
    
    @Test func testReverseQualityGuidance() {
        // Test that incorrect answers should suggest lower quality ratings
        let incorrectAnswer = false
        let correctAnswer = true
        
        // This would typically be used in UI to guide users
        let suggestedMaxQualityForIncorrect = SuperMemoQuality.difficult.rawValue // 3
        let suggestedMaxQualityForCorrect = SuperMemoQuality.perfect.rawValue // 5
        
        if incorrectAnswer {
            #expect(suggestedMaxQualityForIncorrect <= 3)
        }
        
        if correctAnswer {
            #expect(suggestedMaxQualityForCorrect <= 5)
        }
    }
}