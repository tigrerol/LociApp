import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation
import Combine

// MARK: - Helper Views

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

struct LearningModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var itineraries: [Itinerary]
    @State private var selectedItinerary: Itinerary?
    @State private var currentLocationIndex = 0
    @State private var dataService = DataService()
    @State private var showingImporter = false
    @State private var showingJSONInput = false
    @State private var errorMessage: String?
    @State private var urlToImport: URL?
    
    var body: some View {
        NavigationView {
            if itineraries.isEmpty {
                ContentUnavailableView(
                    "No Itineraries",
                    systemImage: "list.bullet",
                    description: Text("Import JSON files to start learning")
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Import File", systemImage: "doc.badge.plus") {
                                showingImporter = true
                            }
                            Button("Paste JSON", systemImage: "doc.plaintext") {
                                showingJSONInput = true
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            } else if let selectedItinerary {
                learningView(for: selectedItinerary)
            } else {
                itinerarySelector
            }
        }
        .sheet(isPresented: $showingJSONInput) {
            JSONInputView { jsonText in
                showingJSONInput = false
                handleJSONInput(jsonText)
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ImportJSONFile"))) { notification in
            if let url = notification.object as? URL {
                urlToImport = url
            }
        }
        .onChange(of: urlToImport) { oldValue, newValue in
            if let url = newValue {
                do {
                    try dataService.importItinerary(from: url, context: modelContext)
                    urlToImport = nil
                    
                    // Clean up temporary file if it exists
                    if url.path.contains(FileManager.default.temporaryDirectory.path) {
                        try? FileManager.default.removeItem(at: url)
                    }
                } catch {
                    errorMessage = "Failed to import shared file: \(error.localizedDescription)"
                    urlToImport = nil
                    
                    // Clean up temporary file if it exists
                    if url.path.contains(FileManager.default.temporaryDirectory.path) {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
            }
        }
    }
    
    private var itinerarySelector: some View {
        List(itineraries) { itinerary in
            Button(action: {
                selectedItinerary = itinerary
                currentLocationIndex = 0
            }) {
                VStack(alignment: .leading) {
                    Text(itinerary.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(itinerary.locations.count) locations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Imported: \(itinerary.dateImported.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .navigationTitle("Choose Itinerary")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Import File", systemImage: "doc.badge.plus") {
                        showingImporter = true
                    }
                    Button("Paste JSON", systemImage: "doc.plaintext") {
                        showingJSONInput = true
                    }
                } label: {
                    Text("Import")
                }
            }
        }
    }
    
    private func learningView(for itinerary: Itinerary) -> some View {
        VStack {
            if itinerary.locations.isEmpty {
                ContentUnavailableView(
                    "No Locations",
                    systemImage: "location.slash",
                    description: Text("This itinerary has no locations")
                )
            } else {
                let sortedLocations = itinerary.locations.sorted { $0.sequence < $1.sequence }
                let location = sortedLocations[currentLocationIndex]
                
                VStack(spacing: 20) {
                    Text("Step \(currentLocationIndex + 1)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let uiImage = UIImage(data: location.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .cornerRadius(10)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("Image not available")
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    
                    Text(location.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(location.locationDescription)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    HStack {
                        Button("Previous") {
                            if currentLocationIndex > 0 {
                                currentLocationIndex -= 1
                            }
                        }
                        .disabled(currentLocationIndex == 0)
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        VStack {
                            Text("\(currentLocationIndex + 1) of \(sortedLocations.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: Double(currentLocationIndex + 1), total: Double(sortedLocations.count))
                                .frame(width: 100)
                        }
                        
                        Spacer()
                        
                        Button("Next") {
                            if currentLocationIndex < sortedLocations.count - 1 {
                                currentLocationIndex += 1
                            }
                        }
                        .disabled(currentLocationIndex == sortedLocations.count - 1)
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                }
                .padding()
            }
        }
        .navigationTitle(itinerary.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    selectedItinerary = nil
                }
            }
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
    LearningModeView()
        .modelContainer(for: [Itinerary.self, Location.self, Review.self])
}