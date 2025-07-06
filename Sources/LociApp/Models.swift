import Foundation

public struct ItineraryData: Codable {
    public let name: String
    public let description: String
    public let image: ImageData?
    public let locations: [LocationData]
    
    public init(name: String, description: String, image: ImageData? = nil, locations: [LocationData]) {
        self.name = name
        self.description = description
        self.image = image
        self.locations = locations
    }
}

public struct LocationData: Codable {
    public let name: String
    public let description: String
    public let sequence: Int
    public let image: ImageData
    
    public init(name: String, description: String, sequence: Int, image: ImageData) {
        self.name = name
        self.description = description
        self.sequence = sequence
        self.image = image
    }
}

public struct ImageData: Codable {
    public let format: String
    public let data: String
    
    public init(format: String, data: String) {
        self.format = format
        self.data = data
    }
}

public struct ItineraryJSON: Codable {
    public let itineraries: [ItineraryData]
    
    public init(itineraries: [ItineraryData]) {
        self.itineraries = itineraries
    }
}