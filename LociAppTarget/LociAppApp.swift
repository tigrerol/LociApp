import SwiftUI
import SwiftData

@main
struct LociAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Itinerary.self,
            Location.self,
            Review.self
        ])
    }
}