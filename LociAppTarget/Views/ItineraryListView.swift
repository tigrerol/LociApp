import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ItineraryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var itineraries: [Itinerary]
    @State private var dataService = DataService()
    @State private var showingImporter = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(itineraries) { itinerary in
                    VStack(alignment: .leading) {
                        Text(itinerary.name)
                            .font(.headline)
                        Text("\(itinerary.locations.count) locations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Imported: \(itinerary.dateImported.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Itineraries")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        showingImporter = true
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert("Import Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                try dataService.importItinerary(from: url, context: modelContext)
            } catch {
                errorMessage = "Failed to import JSON file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ItineraryListView()
        .modelContainer(for: [Itinerary.self, Location.self, Review.self])
}