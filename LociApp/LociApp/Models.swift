import Foundation
import SwiftData
import SwiftUI
import SuperMemoKit

// MARK: - SwiftData Models

@Model
class Itinerary {
    var name: String
    var locations: [Location] = []
    var dateImported: Date = Date()
    var colorIndex: Int = 0  // Index into predefined color array with default value
    
    init(name: String) {
        self.name = name
        self.colorIndex = Int.random(in: 0..<ItineraryColors.allColors.count)
    }
}

// MARK: - Itinerary Colors

struct ItineraryColors {
    static let allColors: [ItineraryColor] = [
        ItineraryColor(name: "Blue", color: .blue),
        ItineraryColor(name: "Green", color: .green),
        ItineraryColor(name: "Orange", color: .orange),
        ItineraryColor(name: "Purple", color: .purple),
        ItineraryColor(name: "Red", color: .red),
        ItineraryColor(name: "Teal", color: .teal),
        ItineraryColor(name: "Pink", color: .pink),
        ItineraryColor(name: "Indigo", color: .indigo),
        ItineraryColor(name: "Brown", color: .brown),
        ItineraryColor(name: "Cyan", color: .cyan)
    ]
    
    static func color(for itinerary: Itinerary) -> Color {
        guard !allColors.isEmpty else { return .blue }
        let index = max(0, min(itinerary.colorIndex, allColors.count - 1))
        return allColors[index].color
    }
}

struct ItineraryColor {
    let name: String
    let color: Color
}

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

// MARK: - JSON Import Models

struct ItineraryJSON: Codable {
    let itineraries: [ItineraryData]
}

struct ItineraryData: Codable {
    let name: String
    let description: String
    let image: ImageData?
    let locations: [LocationData]
}

struct LocationData: Codable {
    let name: String
    let description: String
    let sequence: Int
    let image: ImageData?
}

struct ImageData: Codable {
    let format: String
    let data: String
}

// Alternative format for single itinerary files
struct SingleItineraryJSON: Codable {
    let name: String
    let description: String?
    let theme: String?
    let locations: [SingleLocationData]
}

struct SingleLocationData: Codable {
    let name: String
    let description: String
    let sequence: Int
    let image: String?
}

// MARK: - Type Aliases for SuperMemoKit Integration

// Use SuperMemoKit's enhanced algorithm with type aliases for compatibility
public typealias SuperMemoQuality = SuperMemoKit.SuperMemoQuality
public typealias SuperMemoResult = SuperMemoKit.SuperMemoResult

// MARK: - Services

enum ImportError: Error {
    case invalidImageData
    case invalidJSONFormat
}

enum ServiceError: Error {
    case contextNotSet
}

@Observable
class DataService {
    init() {}
    
    func importItinerary(from url: URL, context: ModelContext) throws {
        let data = try Data(contentsOf: url)
        try importItineraryFromData(data, context: context)
    }
    
    func importItineraryFromData(_ data: Data, context: ModelContext) throws {
        // Try to decode as multiple itineraries format first
        if let jsonData = try? JSONDecoder().decode(ItineraryJSON.self, from: data) {
            for itineraryData in jsonData.itineraries {
                let itinerary = Itinerary(name: itineraryData.name)
                
                for locationData in itineraryData.locations {
                    let imageData: Data
                    if let image = locationData.image {
                        guard let decodedImage = decodeBase64Image(from: image.data) else {
                            throw ImportError.invalidImageData
                        }
                        imageData = decodedImage
                    } else {
                        imageData = Data() // Empty data for missing images
                    }
                    
                    let location = Location(
                        sequence: locationData.sequence,
                        name: locationData.name,
                        description: locationData.description,
                        imageData: imageData
                    )
                    
                    itinerary.locations.append(location)
                }
                
                itinerary.locations.sort { $0.sequence < $1.sequence }
                context.insert(itinerary)
            }
        }
        // Try to decode as single itinerary format
        else if let singleData = try? JSONDecoder().decode(SingleItineraryJSON.self, from: data) {
            let itinerary = Itinerary(name: singleData.name)
            
            for locationData in singleData.locations {
                let imageData: Data
                if let imageString = locationData.image {
                    guard let decodedImage = decodeBase64Image(from: imageString) else {
                        throw ImportError.invalidImageData
                    }
                    imageData = decodedImage
                } else {
                    imageData = Data() // Empty data for missing images
                }
                
                let location = Location(
                    sequence: locationData.sequence,
                    name: locationData.name,
                    description: locationData.description,
                    imageData: imageData
                )
                
                itinerary.locations.append(location)
            }
            
            itinerary.locations.sort { $0.sequence < $1.sequence }
            context.insert(itinerary)
        }
        else {
            throw ImportError.invalidJSONFormat
        }
        
        try context.save()
    }
    
    private func decodeBase64Image(from base64String: String) -> Data? {
        guard let commaIndex = base64String.firstIndex(of: ",") else {
            return Data(base64Encoded: base64String)
        }
        let base64Substring = base64String[base64String.index(after: commaIndex)...]
        return Data(base64Encoded: String(base64Substring))
    }
}

@Observable
class SuperMemoService {
    private var modelContext: ModelContext?
    private let superMemoAlgorithm: SuperMemoAlgorithm
    
    init() {
        self.superMemoAlgorithm = SuperMemoAlgorithm()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func getDueLocations(from itinerary: Itinerary? = nil, forceAll: Bool = false) throws -> [Location] {
        guard let modelContext else {
            throw ServiceError.contextNotSet
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        let allLocations: [Location]
        if let itinerary = itinerary {
            // Filter locations from specific itinerary - ensure they're sorted
            allLocations = itinerary.locations.sorted { $0.sequence < $1.sequence }
        } else {
            // Get all locations from all itineraries
            let descriptor = FetchDescriptor<Location>()
            allLocations = try modelContext.fetch(descriptor)
        }
        
        if forceAll {
            // Return all locations sorted by sequence for forced review
            return allLocations.sorted { $0.sequence < $1.sequence }
        } else {
            // Return only due locations
            let dueLocations = allLocations.filter { location in
                let daysUntilDue = calendar.dateComponents([.day], from: now, to: location.nextReview).day ?? 0
                return daysUntilDue <= 0
            }
            
            return dueLocations.sorted { $0.nextReview < $1.nextReview }
        }
    }
    
    func reviewLocation(_ location: Location, quality: SuperMemoQuality) throws {
        guard let modelContext else {
            throw ServiceError.contextNotSet
        }
        
        let result = superMemoAlgorithm.calculateNextReview(
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