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
        .onOpenURL { url in
            handleFileImport(url: url)
        }
    }
    
    private func handleFileImport(url: URL) {
        // Handle JSON file opening from Files app
        guard url.pathExtension.lowercased() == "json" else { return }
        
        // Post notification to handle import
        NotificationCenter.default.post(
            name: NSNotification.Name("ImportJSONFile"),
            object: url
        )
    }
}