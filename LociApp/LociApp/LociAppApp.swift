import SwiftUI
import SwiftData
import Foundation

@main
struct LociAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleFileImport(url: url)
                }
        }
        .modelContainer(for: [
            Itinerary.self,
            Location.self,
            Review.self
        ])
    }
    
    private func handleFileImport(url: URL) {
        // Handle JSON file opening from Files app
        guard url.pathExtension.lowercased() == "json" else { return }
        
        // Ensure we have access to the file
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Create a temporary copy of the file to ensure we can read it
        do {
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".json")
            try FileManager.default.copyItem(at: url, to: tempURL)
            
            // Post notification to handle import with the temporary URL
            NotificationCenter.default.post(
                name: NSNotification.Name("ImportJSONFile"),
                object: tempURL
            )
        } catch {
            print("Failed to copy shared file: \(error)")
            // Still try with original URL
            NotificationCenter.default.post(
                name: NSNotification.Name("ImportJSONFile"),
                object: url
            )
        }
    }
}
