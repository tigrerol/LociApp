import Testing
@testable import LociApp

struct ModelTests {
    
    @Test func testItineraryDataCreation() {
        let imageData = ImageData(format: "base64", data: "test-data")
        let locationData = LocationData(
            name: "Test Location",
            description: "A test location",
            sequence: 1,
            image: imageData
        )
        let itineraryData = ItineraryData(
            name: "Test Itinerary",
            description: "A test itinerary",
            locations: [locationData]
        )
        
        #expect(itineraryData.name == "Test Itinerary")
        #expect(itineraryData.locations.count == 1)
        #expect(itineraryData.locations[0].name == "Test Location")
        #expect(itineraryData.locations[0].sequence == 1)
    }
    
    @Test func testLocationDataSorting() {
        let imageData = ImageData(format: "base64", data: "test-data")
        let location1 = LocationData(name: "First", description: "First location", sequence: 1, image: imageData)
        let location2 = LocationData(name: "Second", description: "Second location", sequence: 2, image: imageData)
        let location3 = LocationData(name: "Third", description: "Third location", sequence: 3, image: imageData)
        
        // Test that locations can be sorted by sequence
        let unsortedLocations = [location3, location1, location2]
        let sortedLocations = unsortedLocations.sorted { $0.sequence < $1.sequence }
        
        #expect(sortedLocations[0].name == "First")
        #expect(sortedLocations[1].name == "Second")
        #expect(sortedLocations[2].name == "Third")
    }
    
    @Test func testImageDataFormats() {
        let jpegImage = ImageData(format: "base64", data: "data:image/jpeg;base64,test")
        let pngImage = ImageData(format: "base64", data: "data:image/png;base64,test")
        
        #expect(jpegImage.format == "base64")
        #expect(pngImage.format == "base64")
        #expect(jpegImage.data.contains("jpeg"))
        #expect(pngImage.data.contains("png"))
    }
}