import Foundation

public enum ImportError: Error {
    case invalidImageData
    case invalidJSONFormat
    case fileNotFound
}

public final class JSONParser {
    public init() {}
    
    public func parseJSONFile(from url: URL) throws -> ItineraryJSON {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ItineraryJSON.self, from: data)
    }
    
    public func parseJSONData(_ data: Data) throws -> ItineraryJSON {
        return try JSONDecoder().decode(ItineraryJSON.self, from: data)
    }
    
    public func decodeBase64Image(from base64String: String) -> Data? {
        let cleanBase64 = base64String
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/gif;base64,", with: "")
        
        return Data(base64Encoded: cleanBase64)
    }
}