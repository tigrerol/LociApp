import Foundation
import SwiftData

@Model
class Review {
    var location: Location
    var quality: Int
    var reviewDate: Date = Date()
    var isReverse: Bool = false
    
    init(location: Location, quality: Int, isReverse: Bool = false) {
        self.location = location
        self.quality = quality
        self.isReverse = isReverse
    }
}