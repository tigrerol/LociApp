import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ItineraryListView()
                .tabItem {
                    Label("Itineraries", systemImage: "list.bullet")
                }
            
            LearningModeView()
                .tabItem {
                    Label("Learning", systemImage: "brain.head.profile")
                }
            
            ReviewModeView()
                .tabItem {
                    Label("Review", systemImage: "repeat.circle")
                }
            
            ReverseModeView()
                .tabItem {
                    Label("Reverse", systemImage: "arrow.triangle.2.circlepath")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Itinerary.self,
            Location.self,
            Review.self
        ])
}