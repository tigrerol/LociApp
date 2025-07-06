import SwiftUI
import SwiftData

struct ReviewModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [Location]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Review Mode")
                    .font(.title)
                Text("Coming soon in Phase 3")
                    .foregroundColor(.secondary)
                
                if !locations.isEmpty {
                    Text("\(locations.count) locations available for review")
                        .padding()
                }
            }
        }
        .navigationTitle("Review")
    }
}

#Preview {
    ReviewModeView()
        .modelContainer(for: [Itinerary.self, Location.self, Review.self])
}