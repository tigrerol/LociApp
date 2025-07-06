import Foundation
import SwiftData

@Model
class Itinerary {
    var name: String
    var locations: [Location] = []
    var dateImported: Date = Date()
    
    init(name: String) {
        self.name = name
    }
}