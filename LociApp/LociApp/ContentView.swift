import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
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
            
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
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
