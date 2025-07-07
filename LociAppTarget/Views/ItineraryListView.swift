import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentSelected: (URL) -> Void
    let onError: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Use import mode with deprecated initializer - most reliable
        let picker = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentSelected(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled, no action needed
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
            parent.onDocumentSelected(url)
        }
    }
}

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
            .sheet(isPresented: $showingImporter) {
                DocumentPicker(
                    onDocumentSelected: { url in
                        showingImporter = false
                        handleFileSelection(url: url)
                    },
                    onError: { error in
                        showingImporter = false
                        errorMessage = error
                    }
                )
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
    
    private func handleFileSelection(url: URL) {
        // Simplest possible file reading - import mode should give us direct access
        do {
            let data = try Data(contentsOf: url)
            try dataService.importItineraryFromData(data, context: modelContext)
        } catch {
            errorMessage = "Failed to import JSON file: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ItineraryListView()
        .modelContainer(for: [Itinerary.self, Location.self, Review.self])
}