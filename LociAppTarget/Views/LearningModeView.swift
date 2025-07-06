import SwiftUI
import SwiftData

struct LearningModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var itineraries: [Itinerary]
    
    var body: some View {
        NavigationView {
            if itineraries.isEmpty {
                ContentUnavailableView(
                    "No Itineraries",
                    systemImage: "list.bullet",
                    description: Text("Import JSON files to start learning")
                )
            } else {
                VStack {
                    Text("Learning Mode")
                        .font(.title)
                    Text("Coming soon in Phase 2")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Learning")
    }
}

#Preview {
    LearningModeView()
        .modelContainer(for: [Itinerary.self, Location.self, Review.self])
}