import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [Location]
    @State private var notificationService = NotificationService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LearningModeView()
                .tabItem {
                    Label("Learning", systemImage: "brain.head.profile")
                }
                .tag(0)
            
            ReviewModeView()
                .tabItem {
                    Label("Review", systemImage: "repeat.circle")
                }
                .tag(1)
            
            ReverseModeView()
                .tabItem {
                    Label("Reverse", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(2)
            
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(3)
        }
        .onAppear {
            scheduleNotifications()
        }
        .onChange(of: locations) { _, _ in
            scheduleNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenReviewMode"))) { _ in
            // Switch to Review tab when notification is tapped
            selectedTab = 1
            updateBadgeCount()
        }
    }
    
    private func scheduleNotifications() {
        Task {
            await notificationService.scheduleReviewNotifications(for: locations)
            updateBadgeCount()
        }
    }
    
    private func updateBadgeCount() {
        let now = Date()
        let dueCount = locations.filter { $0.nextReview <= now }.count
        notificationService.updateBadgeCount(to: dueCount)
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
