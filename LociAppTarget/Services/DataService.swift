import Foundation
import SwiftData
import LociApp

@Observable
class DataService {
    private let jsonParser = JSONParser()
    
    init() {}
    
    func importItinerary(from url: URL, context: ModelContext) throws {
        let itineraryJSON = try jsonParser.parseJSONFile(from: url)
        
        for itineraryData in itineraryJSON.itineraries {
            let itinerary = Itinerary(name: itineraryData.name)
            
            for locationData in itineraryData.locations {
                guard let imageData = jsonParser.decodeBase64Image(from: locationData.image.data) else {
                    throw ImportError.invalidImageData
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
        
        try context.save()
    }
}

enum ImportError: Error {
    case invalidImageData
    case invalidJSONFormat
}