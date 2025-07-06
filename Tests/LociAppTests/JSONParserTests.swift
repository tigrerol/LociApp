import Testing
@testable import LociApp

struct JSONParserTests {
    
    @Test func testBase64ImageDecoding() {
        let parser = JSONParser()
        let base64String = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD//2Q="
        
        let result = parser.decodeBase64Image(from: base64String)
        #expect(result != nil)
        #expect(result!.count > 0)
    }
    
    @Test func testJSONParsing() throws {
        let parser = JSONParser()
        
        let jsonString = """
        {
          "itineraries": [
            {
              "name": "Test Itinerary",
              "description": "A test itinerary",
              "locations": [
                {
                  "name": "Location 1",
                  "description": "First location",
                  "sequence": 1,
                  "image": {
                    "format": "base64",
                    "data": "data:image/jpeg;base64,/9j/4AAQSkZJRg=="
                  }
                }
              ]
            }
          ]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let result = try parser.parseJSONData(data)
        
        #expect(result.itineraries.count == 1)
        #expect(result.itineraries[0].name == "Test Itinerary")
        #expect(result.itineraries[0].locations.count == 1)
        #expect(result.itineraries[0].locations[0].sequence == 1)
    }
}