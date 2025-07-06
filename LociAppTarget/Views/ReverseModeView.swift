import SwiftUI
import SwiftData

struct ReverseModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [Location]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Reverse Mode")
                    .font(.title)
                Text("Coming soon in Phase 4")
                    .foregroundColor(.secondary)
                
                if !locations.isEmpty {
                    Text("\(locations.count) locations available for reverse practice")
                        .padding()
                }
            }
        }
        .navigationTitle("Reverse")
    }
}

#Preview {
    ReverseModeView()
        .modelContainer(for: [Itinerary.self, Location.self, Review.self])
}