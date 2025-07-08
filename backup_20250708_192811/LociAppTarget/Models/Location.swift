import Foundation
import SwiftData

@Model
class Location {
    var sequence: Int
    var name: String
    var locationDescription: String
    var imageData: Data
    
    // SuperMemo-2 properties
    var nextReview: Date = Date()
    var easeFactor: Double = 2.5
    var intervalDays: Int = 1
    var repetitionCount: Int = 0
    
    init(sequence: Int, name: String, description: String, imageData: Data) {
        self.sequence = sequence
        self.name = name
        self.locationDescription = description
        self.imageData = imageData
    }
}