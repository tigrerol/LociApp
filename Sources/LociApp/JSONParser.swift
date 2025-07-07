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
        // More robust implementation that handles any data URI format
        guard let commaIndex = base64String.firstIndex(of: ",") else {
            // Handle cases where the string is just the base64 data
            return Data(base64Encoded: base64String)
        }
        let base64Substring = base64String[base64String.index(after: commaIndex)...]
        return Data(base64Encoded: String(base64Substring))
    }
}