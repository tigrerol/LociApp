import Foundation
import SwiftData
import LociApp

@Observable
class SuperMemoService {
    private var modelContext: ModelContext?
    
    init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func getDueLocations() throws -> [Location] {
        guard let modelContext else {
            throw ServiceError.contextNotSet
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        let descriptor = FetchDescriptor<Location>()
        let allLocations = try modelContext.fetch(descriptor)
        
        let dueLocations = allLocations.filter { location in
            let daysUntilDue = calendar.dateComponents([.day], from: now, to: location.nextReview).day ?? 0
            return daysUntilDue <= 0
        }
        
        return dueLocations.sorted { $0.nextReview < $1.nextReview }
    }
    
    func reviewLocation(_ location: Location, quality: SuperMemoQuality) throws {
        guard let modelContext else {
            throw ServiceError.contextNotSet
        }
        
        let result = SuperMemoAlgorithm.calculateNextReview(
            currentEaseFactor: location.easeFactor,
            currentInterval: Int32(location.intervalDays),
            repetitionCount: Int16(location.repetitionCount),
            quality: quality
        )
        
        location.easeFactor = result.easeFactor
        location.intervalDays = Int(result.intervalDays)
        location.repetitionCount = Int(result.repetitionCount)
        location.nextReview = result.nextReviewDate
        
        let review = Review(
            location: location,
            quality: quality.rawValue
        )
        
        modelContext.insert(review)
        try modelContext.save()
    }
}

enum ServiceError: Error {
    case contextNotSet
}