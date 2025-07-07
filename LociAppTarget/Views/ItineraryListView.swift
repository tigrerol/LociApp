import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct JSONInputView: View {
    let onSubmit: (String) -> Void
    @State private var jsonText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Paste JSON Content")
                    .font(.headline)
                    .padding()
                
                TextEditor(text: $jsonText)
                    .border(Color.gray, width: 1)
                    .padding()
                
                Text("Paste your JSON itinerary content here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                Spacer()
            }
            .navigationTitle("Import JSON")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        onSubmit(jsonText)
                    }
                    .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentSelected: (URL) -> Void
    let onError: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // iOS 18 fix: Use asCopy parameter to avoid view service termination
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
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
    @State private var showingJSONInput = false
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ImportJSONFile"))) { notification in
                if let url = notification.object as? URL {
                    handleFileSelection(url: url)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Paste JSON") {
                        showingJSONInput = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Import") {
                        Button("Import File") {
                            showingImporter = true
                        }
                        Button("Paste JSON") {
                            showingJSONInput = true
                        }
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
            .sheet(isPresented: $showingJSONInput) {
                JSONInputView { jsonText in
                    showingJSONInput = false
                    handleJSONInput(jsonText)
                }
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
    
    private func handleJSONInput(_ jsonText: String) {
        do {
            guard let data = jsonText.data(using: .utf8) else {
                errorMessage = "Invalid text encoding"
                return
            }
            try dataService.importItineraryFromData(data, context: modelContext)
        } catch {
            errorMessage = "Failed to import JSON: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ItineraryListView()
        .modelContainer(for: [Itinerary.self, Location.self, Review.self])
}