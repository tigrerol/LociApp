import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation
import Combine
import SuperMemoKit

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

struct ColoredItineraryName: View {
    let itinerary: Itinerary
    let font: Font
    
    init(_ itinerary: Itinerary, font: Font = .body) {
        self.itinerary = itinerary
        self.font = font
    }
    
    var body: some View {
        Text(itinerary.name)
            .font(font)
            .foregroundColor(ItineraryColors.color(for: itinerary))
    }
}

// MARK: - Itinerary List View

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
            
            // Request access to security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Failed to access selected file"
                return
            }
            
            // Ensure we stop accessing the resource when done
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
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

// MARK: - Learning Mode View

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
    @State private var audioMode = false
    @State private var speechService = SpeechService()
    
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
                            Text("Import")
                        }
                    }
                }
            } else if let selectedItinerary {
                learningView(for: selectedItinerary)
            } else {
                itinerarySelector
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
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
        List {
            ForEach(itineraries) { itinerary in
                Button(action: {
                    selectedItinerary = itinerary
                    currentLocationIndex = 0
                }) {
                    VStack(alignment: .leading) {
                        ColoredItineraryName(itinerary, font: .headline)
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
            .onDelete(perform: deleteItinerary)
        }
        .navigationTitle("Choose Itinerary")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Import") {
                    showingImporter = true
                }
            }
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Request access to security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Failed to access selected file"
                return
            }
            
            // Ensure we stop accessing the resource when done
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                try dataService.importItinerary(from: url, context: modelContext)
            } catch {
                errorMessage = "Failed to import JSON file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
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
    
    private func speakCurrentLocationIfNeeded() {
        guard audioMode, let selectedItinerary else { return }
        
        let sortedLocations = selectedItinerary.locations.sorted { $0.sequence < $1.sequence }
        guard currentLocationIndex < sortedLocations.count else { return }
        
        let location = sortedLocations[currentLocationIndex]
        let textToSpeak = "Step \(location.sequence + 1). \(location.name). \(location.locationDescription)"
        
        speechService.speak(text: textToSpeak)
    }
    
    private func advanceToNextLocation() {
        guard audioMode, let selectedItinerary else { return }
        
        let sortedLocations = selectedItinerary.locations.sorted { $0.sequence < $1.sequence }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.currentLocationIndex < sortedLocations.count - 1 {
                self.currentLocationIndex += 1
            } else {
                // End of itinerary - turn off audio mode
                self.audioMode = false
            }
        }
    }
    
    private func colorForQuality(_ quality: SpeechService.VoiceQuality) -> Color {
        switch quality {
        case .standard:
            return .secondary
        case .enhanced:
            return .orange
        case .premium:
            return .green
        }
    }
    
    private func qualityIndicator(for quality: SpeechService.VoiceQuality) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < quality.rawValue + 1 ? colorForQuality(quality) : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    private func deleteItinerary(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let itinerary = itineraries[index]
                
                // Delete all locations associated with this itinerary
                for location in itinerary.locations {
                    // Delete any reviews associated with this location
                    let locationId = location.id
                    let reviewDescriptor = FetchDescriptor<Review>(
                        predicate: #Predicate<Review> { review in
                            review.location.id == locationId
                        }
                    )
                    if let reviews = try? modelContext.fetch(reviewDescriptor) {
                        for review in reviews {
                            modelContext.delete(review)
                        }
                    }
                    
                    // Delete the location
                    modelContext.delete(location)
                }
                
                // Delete the itinerary
                modelContext.delete(itinerary)
            }
            
            // Save the changes
            try? modelContext.save()
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
                    
                    HStack {
                        Text(location.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        if speechService.isSpeaking {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .symbolEffect(.pulse)
                        }
                    }
                    
                    Text(location.locationDescription)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    HStack {
                        Button("Previous") {
                            speechService.stop()
                            if currentLocationIndex > 0 {
                                currentLocationIndex -= 1
                            }
                        }
                        .disabled(currentLocationIndex == 0 || (audioMode && speechService.isSpeaking))
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
                            speechService.stop()
                            if currentLocationIndex < sortedLocations.count - 1 {
                                currentLocationIndex += 1
                            }
                        }
                        .disabled(currentLocationIndex == sortedLocations.count - 1 || (audioMode && speechService.isSpeaking))
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                }
                .padding()
                .onAppear {
                    speakCurrentLocationIfNeeded()
                }
                .onChange(of: currentLocationIndex) { oldValue, newValue in
                    speakCurrentLocationIfNeeded()
                }
                .onChange(of: audioMode) { oldValue, newValue in
                    if newValue {
                        speakCurrentLocationIfNeeded()
                    } else {
                        speechService.stop()
                    }
                }
                .onReceive(speechService.speechCompleted) { _ in
                    if audioMode {
                        advanceToNextLocation()
                    }
                }
                .onDisappear {
                    speechService.stop()
                }
            }
        }
        .navigationTitle(itinerary.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    speechService.stop()
                    selectedItinerary = nil
                    audioMode = false
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Menu {
                        ForEach(speechService.availableVoices, id: \.identifier) { voice in
                            Button(action: {
                                speechService.setVoice(voice)
                            }) {
                                HStack {
                                    Text("\(speechService.getVoiceName(voice)) (\(speechService.getVoiceQuality(voice).description))")
                                    
                                    Spacer()
                                    
                                    if voice.identifier == speechService.selectedVoice?.identifier {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "person.wave.2")
                    }
                    .disabled(!audioMode)
                    
                    Toggle("Audio", isOn: $audioMode)
                        .toggleStyle(SwitchToggleStyle())
                }
            }
        }
    }
}

// MARK: - Review Mode View

struct ReviewModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [Location]
    @Query private var itineraries: [Itinerary]
    @State private var superMemoService = SuperMemoService()
    @State private var dueLocations: [Location] = []
    @State private var currentLocationIndex = 0
    @State private var reviewStep: ReviewStep = .sequence
    @State private var isLoading = false
    @State private var selectedItinerary: Itinerary?
    @State private var reviewType: ReviewType = .multiple
    @State private var hasSelectedReviewType = false
    
    enum ReviewType {
        case single
        case multiple
    }
    
    enum ReviewStep {
        case sequence
        case image
        case nameAndDescription
    }
    
    var body: some View {
        NavigationView {
            if itineraries.isEmpty {
                ContentUnavailableView(
                    "No Itineraries",
                    systemImage: "list.bullet",
                    description: Text("Import JSON files to start reviewing")
                )
                .navigationTitle("Review")
            } else if !hasSelectedReviewType {
                reviewTypeSelector
            } else if reviewType == .single && selectedItinerary == nil {
                itinerarySelector
            } else if dueLocations.isEmpty && !isLoading {
                if selectedItinerary != nil {
                    // Single itinerary mode - offer to review all locations
                    noReviewsDueSingleItinerary
                } else {
                    // Multiple itinerary mode - standard message
                    ContentUnavailableView(
                        "No Reviews Due",
                        systemImage: "checkmark.circle",
                        description: Text("All locations are up to date! Come back later or import more itineraries.")
                    )
                    .navigationTitle("Review")
                }
            } else if isLoading {
                ProgressView("Loading reviews...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Review")
            } else {
                reviewView
                    .navigationTitle(currentItineraryName)
            }
        }
        .onAppear {
            superMemoService.setModelContext(modelContext)
            loadDueLocations()
        }
    }
    
    private var reviewTypeSelector: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Image(systemName: "repeat.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Choose Review Type")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 20) {
                Button(action: {
                    reviewType = .multiple
                    selectedItinerary = nil
                    hasSelectedReviewType = true
                    loadDueLocations()
                }) {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("All Itineraries")
                                .font(.headline)
                            Text("Review locations from all imported itineraries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    reviewType = .single
                    selectedItinerary = nil
                    hasSelectedReviewType = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Single Itinerary")
                                .font(.headline)
                            Text("Review locations from one specific itinerary")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Review")
    }
    
    private var itinerarySelector: some View {
        VStack {
            List(itineraries) { itinerary in
                Button(action: {
                    selectedItinerary = itinerary
                    loadDueLocations()
                }) {
                    VStack(alignment: .leading) {
                        ColoredItineraryName(itinerary, font: .headline)
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
        }
        .navigationTitle("Choose Itinerary")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    reviewType = .multiple
                    selectedItinerary = nil
                    hasSelectedReviewType = false
                }
            }
        }
    }
    
    private var noReviewsDueSingleItinerary: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("All Caught Up!")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let selectedItinerary {
                    Text("No reviews are due for \"\(selectedItinerary.name)\" right now.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 15) {
                Button(action: {
                    loadAllLocations()
                }) {
                    HStack {
                        Image(systemName: "repeat.circle.fill")
                            .font(.title2)
                        Text("Review All Locations Anyway")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    selectedItinerary = nil
                    reviewType = .multiple
                    hasSelectedReviewType = false
                }) {
                    Text("Back to Type Selection")
                        .font(.body)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Review")
    }
    
    private var currentItineraryName: String {
        guard !dueLocations.isEmpty else { return "Review" }
        let location = dueLocations[currentLocationIndex]
        return itineraries.first { $0.locations.contains(where: { $0.id == location.id }) }?.name ?? "Review"
    }
    
    private var reviewView: some View {
        let location = dueLocations[currentLocationIndex]
        
        return VStack(spacing: 20) {
            Text("Review \(currentLocationIndex + 1) of \(dueLocations.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(currentLocationIndex + 1), total: Double(dueLocations.count))
                .padding(.horizontal)
            
            Spacer()
            
            switch reviewStep {
            case .sequence:
                sequenceStep(for: location)
            case .image:
                imageStep(for: location)
            case .nameAndDescription:
                nameAndDescriptionStep(for: location)
            }
            
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    // Reset to type selection or itinerary selection based on reviewType
                    if reviewType == .single {
                        selectedItinerary = nil
                    } else {
                        hasSelectedReviewType = false
                    }
                    dueLocations = []
                    currentLocationIndex = 0
                    reviewStep = .sequence
                }
            }
        }
    }
    
    private func sequenceStep(for location: Location) -> some View {
        VStack(spacing: 30) {
            Text("What is at step \(location.sequence + 1)?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Think about what you remember...")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                Button("Show Image Hint") {
                    withAnimation {
                        reviewStep = .image
                    }
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                
                Button("Show Answer") {
                    withAnimation {
                        reviewStep = .nameAndDescription
                    }
                }
                .buttonStyle(.bordered)
                .font(.headline)
            }
        }
    }
    
    private func imageStep(for location: Location) -> some View {
        VStack(spacing: 30) {
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
            
            Text("Step \(location.sequence + 1)")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button("Show Answer") {
                withAnimation {
                    reviewStep = .nameAndDescription
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
        }
    }
    
    private func nameAndDescriptionStep(for location: Location) -> some View {
        VStack(spacing: 20) {
            if let uiImage = UIImage(data: location.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
            
            VStack(spacing: 10) {
                Text("Step \(location.sequence + 1)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(location.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(location.locationDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Rating buttons at bottom
            VStack(spacing: 15) {
                Text("How well did you remember this?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(SuperMemoQuality.allCases, id: \.rawValue) { quality in
                        Button(action: {
                            rateLocation(quality: quality)
                        }) {
                            VStack(spacing: 4) {
                                Text("\(quality.rawValue)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(quality.description)
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorForQuality(quality))
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.bottom)
        }
    }
    
    
    private func colorForQuality(_ quality: SuperMemoQuality) -> Color {
        switch quality {
        case .blackout, .incorrect:
            return .red
        case .incorrectEasy, .difficult:
            return .orange
        case .hesitant:
            return .yellow
        case .perfect:
            return .green
        }
    }
    
    private func loadDueLocations() {
        isLoading = true
        do {
            dueLocations = try superMemoService.getDueLocations(from: selectedItinerary)
            currentLocationIndex = 0
            reviewStep = .sequence
        } catch {
            print("Error loading due locations: \(error)")
            dueLocations = []
        }
        isLoading = false
    }
    
    private func loadAllLocations() {
        isLoading = true
        do {
            dueLocations = try superMemoService.getDueLocations(from: selectedItinerary, forceAll: true)
            currentLocationIndex = 0
            reviewStep = .sequence
        } catch {
            print("Error loading all locations: \(error)")
            dueLocations = []
        }
        isLoading = false
    }
    
    private func rateLocation(quality: SuperMemoQuality) {
        let location = dueLocations[currentLocationIndex]
        
        do {
            try superMemoService.reviewLocation(location, quality: quality)
            
            if currentLocationIndex < dueLocations.count - 1 {
                // Reset to sequence step first to avoid showing the answer
                withAnimation {
                    reviewStep = .sequence
                }
                // Then move to next location after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentLocationIndex += 1
                }
            } else {
                loadDueLocations()
            }
        } catch {
            print("Error reviewing location: \(error)")
        }
    }
}

// MARK: - Reverse Mode View

struct ReverseModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [Location]
    @Query private var itineraries: [Itinerary]
    @State private var superMemoService = SuperMemoService()
    @State private var dueLocations: [Location] = []
    @State private var currentLocationIndex = 0
    @State private var userInput = ""
    @State private var reverseStep: ReverseStep = .nameInput
    @State private var isCorrect = false
    @State private var isLoading = false
    @State private var selectedItinerary: Itinerary?
    @State private var reviewType: ReviewType = .multiple
    @State private var hasSelectedReviewType = false
    @FocusState private var isInputFocused: Bool
    
    enum ReviewType {
        case single
        case multiple
    }
    
    enum ReverseStep {
        case nameInput
        case result
    }
    
    var body: some View {
        NavigationView {
            if itineraries.isEmpty {
                ContentUnavailableView(
                    "No Itineraries",
                    systemImage: "list.bullet",
                    description: Text("Import JSON files to start reverse reviewing")
                )
                .navigationTitle("Reverse")
            } else if !hasSelectedReviewType {
                reverseTypeSelector
            } else if reviewType == .single && selectedItinerary == nil {
                reverseItinerarySelector
            } else if dueLocations.isEmpty && !isLoading {
                if selectedItinerary != nil {
                    // Single itinerary mode - offer to review all locations
                    noReverseReviewsDueSingleItinerary
                } else {
                    // Multiple itinerary mode - standard message
                    ContentUnavailableView(
                        "No Reviews Due",
                        systemImage: "checkmark.circle",
                        description: Text("All locations are up to date! Come back later or import more itineraries.")
                    )
                    .navigationTitle("Reverse")
                }
            } else if isLoading {
                ProgressView("Loading reviews...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Reverse")
            } else {
                reverseView
                    .navigationTitle(currentItineraryNameReverse)
            }
        }
        .onAppear {
            superMemoService.setModelContext(modelContext)
            loadDueLocations()
        }
    }
    
    private var reverseTypeSelector: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Choose Reverse Type")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 20) {
                Button(action: {
                    reviewType = .multiple
                    selectedItinerary = nil
                    hasSelectedReviewType = true
                    loadDueLocations()
                }) {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("All Itineraries")
                                .font(.headline)
                            Text("Reverse review locations from all imported itineraries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    reviewType = .single
                    selectedItinerary = nil
                    hasSelectedReviewType = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Single Itinerary")
                                .font(.headline)
                            Text("Reverse review locations from one specific itinerary")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Reverse")
    }
    
    private var reverseItinerarySelector: some View {
        VStack {
            List(itineraries) { itinerary in
                Button(action: {
                    selectedItinerary = itinerary
                    loadDueLocations()
                }) {
                    VStack(alignment: .leading) {
                        ColoredItineraryName(itinerary, font: .headline)
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
        }
        .navigationTitle("Choose Itinerary")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    reviewType = .multiple
                    selectedItinerary = nil
                    hasSelectedReviewType = false
                }
            }
        }
    }
    
    private var noReverseReviewsDueSingleItinerary: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("All Caught Up!")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let selectedItinerary {
                    Text("No reverse reviews are due for \"\(selectedItinerary.name)\" right now.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 15) {
                Button(action: {
                    loadAllReverseLocations()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title2)
                        Text("Reverse Review All Locations Anyway")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    selectedItinerary = nil
                    reviewType = .multiple
                    hasSelectedReviewType = false
                }) {
                    Text("Back to Type Selection")
                        .font(.body)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Reverse")
    }
    
    private var currentItineraryNameReverse: String {
        guard !dueLocations.isEmpty else { return "Reverse" }
        let location = dueLocations[currentLocationIndex]
        return itineraries.first { $0.locations.contains(where: { $0.id == location.id }) }?.name ?? "Reverse"
    }
    
    private var reverseView: some View {
        let location = dueLocations[currentLocationIndex]
        
        return VStack(spacing: 20) {
            Text("Reverse \(currentLocationIndex + 1) of \(dueLocations.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(currentLocationIndex + 1), total: Double(dueLocations.count))
                .padding(.horizontal)
            
            Spacer()
            
            switch reverseStep {
            case .nameInput:
                nameInputStep(for: location)
            case .result:
                resultStep(for: location)
            }
            
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    // Reset to type selection or itinerary selection based on reviewType
                    if reviewType == .single {
                        selectedItinerary = nil
                    } else {
                        hasSelectedReviewType = false
                    }
                    dueLocations = []
                    currentLocationIndex = 0
                    reverseStep = .nameInput
                    userInput = ""
                    isCorrect = false
                }
            }
        }
    }
    
    private func nameInputStep(for location: Location) -> some View {
        VStack(spacing: 30) {
            Text("What step number is this location?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                Text(location.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(location.locationDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 15) {
                TextField("Enter step number", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .focused($isInputFocused)
                    .onSubmit {
                        checkAnswer()
                    }
                
                Button("Submit") {
                    checkAnswer()
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                .disabled(userInput.isEmpty)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func resultStep(for location: Location) -> some View {
        VStack(spacing: 20) {
            if let uiImage = UIImage(data: location.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
            
            VStack(spacing: 15) {
                Text(location.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(location.locationDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 10) {
                HStack {
                    Text("Correct answer:")
                        .font(.headline)
                    Text("\(location.sequence + 1)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Your answer:")
                        .font(.headline)
                    Text(userInput)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isCorrect ? .green : .red)
                }
                
                Text(isCorrect ? "✅ Correct!" : "❌ Incorrect")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isCorrect ? .green : .red)
                    .padding(.top, 10)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            
            Spacer()
            
            // Rating buttons at bottom
            VStack(spacing: 15) {
                Text("How well did you remember this?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                if !isCorrect {
                    Text("Consider rating lower since your answer was incorrect")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(SuperMemoQuality.allCases, id: \.rawValue) { quality in
                        Button(action: {
                            rateLocation(quality: quality)
                        }) {
                            VStack(spacing: 4) {
                                Text("\(quality.rawValue)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(quality.description)
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorForQuality(quality))
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.bottom)
        }
    }
    
    
    private func colorForQuality(_ quality: SuperMemoQuality) -> Color {
        switch quality {
        case .blackout, .incorrect:
            return .red
        case .incorrectEasy, .difficult:
            return .orange
        case .hesitant:
            return .yellow
        case .perfect:
            return .green
        }
    }
    
    private func loadDueLocations() {
        isLoading = true
        do {
            dueLocations = try superMemoService.getDueLocations(from: selectedItinerary)
            // Shuffle locations for random order in reverse mode
            dueLocations.shuffle()
            currentLocationIndex = 0
            reverseStep = .nameInput
        } catch {
            print("Error loading due locations: \(error)")
            dueLocations = []
        }
        isLoading = false
    }
    
    private func loadAllReverseLocations() {
        isLoading = true
        do {
            dueLocations = try superMemoService.getDueLocations(from: selectedItinerary, forceAll: true)
            // Shuffle locations for random order in reverse mode
            dueLocations.shuffle()
            currentLocationIndex = 0
            reverseStep = .nameInput
        } catch {
            print("Error loading all locations: \(error)")
            dueLocations = []
        }
        isLoading = false
    }
    
    private func checkAnswer() {
        let location = dueLocations[currentLocationIndex]
        isCorrect = Int(userInput) == (location.sequence + 1)
        withAnimation {
            reverseStep = .result
        }
    }
    
    private func rateLocation(quality: SuperMemoQuality) {
        let location = dueLocations[currentLocationIndex]
        
        do {
            try superMemoService.reviewLocation(location, quality: quality)
            
            if currentLocationIndex < dueLocations.count - 1 {
                currentLocationIndex += 1
                resetView()
            } else {
                loadDueLocations()
            }
        } catch {
            print("Error reviewing location: \(error)")
        }
    }
    
    private func resetView() {
        userInput = ""
        isCorrect = false
        withAnimation {
            reverseStep = .nameInput
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isInputFocused = true
        }
    }
}

// MARK: - Schedule View

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [Location]
    @Query private var itineraries: [Itinerary]
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            if locations.isEmpty {
                ContentUnavailableView(
                    "No Locations",
                    systemImage: "calendar",
                    description: Text("Import JSON files to see your review schedule")
                )
                .navigationTitle("Schedule")
            } else {
                List {
                    ForEach(groupedLocations, id: \.key) { group in
                        Section(header: Text(group.key)) {
                            ForEach(group.value, id: \.id) { location in
                                ScheduleRowView(location: location, itineraryName: getItineraryName(for: location))
                            }
                        }
                    }
                    
                    Section("SuperMemo Algorithm") {
                        HStack {
                            Image(systemName: "brain.filled.head.profile")
                                .foregroundStyle(.purple)
                                .frame(width: 20)
                            
                            Text("Version")
                            
                            Spacer()
                            
                            Text(SuperMemoKitInfo.versionString)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .frame(width: 20)
                                
                                Text("Enhanced Features")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                            }
                            
                            ForEach(SuperMemoKitInfo.features, id: \.self) { feature in
                                HStack {
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    
                                    Text(feature)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Schedule")
                .refreshable {
                    // Refresh is automatic with @Query
                }
            }
        }
    }
    
    private var groupedLocations: [(key: String, value: [Location])] {
        let calendar = Calendar.current
        let now = Date()
        
        let grouped = Dictionary(grouping: locations.sorted { $0.nextReview < $1.nextReview }) { location in
            let daysUntilDue = calendar.dateComponents([.day], from: now, to: location.nextReview).day ?? 0
            
            if daysUntilDue < 0 {
                return "Overdue"
            } else if daysUntilDue == 0 {
                return "Today"
            } else if daysUntilDue == 1 {
                return "Tomorrow"
            } else if daysUntilDue <= 7 {
                return "This Week"
            } else if daysUntilDue <= 14 {
                return "Next Week"
            } else if daysUntilDue <= 30 {
                return "This Month"
            } else {
                return "Later"
            }
        }
        
        // Sort sections in logical order
        let sectionOrder = ["Overdue", "Today", "Tomorrow", "This Week", "Next Week", "This Month", "Later"]
        return sectionOrder.compactMap { section in
            if let locations = grouped[section], !locations.isEmpty {
                return (key: section, value: locations)
            }
            return nil
        }
    }
    
    private func getItineraryName(for location: Location) -> String {
        return itineraries.first { $0.locations.contains(where: { $0.id == location.id }) }?.name ?? "Unknown"
    }
}

struct ScheduleRowView: View {
    let location: Location
    let itineraryName: String
    @Query private var itineraries: [Itinerary]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(location.sequence + 1): \(location.name)")
                    .font(.headline)
                    .foregroundColor(isOverdue ? .red : .primary)
                
                Spacer()
                
                Text(formatDate(location.nextReview))
                    .font(.caption)
                    .foregroundColor(isOverdue ? .red : .secondary)
            }
            
            HStack {
                if let itinerary = itineraries.first(where: { $0.locations.contains(where: { $0.id == location.id }) }) {
                    ColoredItineraryName(itinerary, font: .caption)
                } else {
                    Text(itineraryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Ease Factor (difficulty)
                    HStack(spacing: 2) {
                        Image(systemName: "brain")
                            .font(.caption2)
                        Text(String(format: "%.1f", location.easeFactor))
                            .font(.caption2)
                    }
                    .foregroundColor(colorForEaseFactor(location.easeFactor))
                    
                    // Repetition count
                    HStack(spacing: 2) {
                        Image(systemName: "repeat")
                            .font(.caption2)
                        Text("\(location.repetitionCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    
                    // Interval days
                    HStack(spacing: 2) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("\(location.intervalDays)d")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var isOverdue: Bool {
        return location.nextReview < Date()
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
                formatter.dateFormat = "MMM d"
            } else {
                formatter.dateFormat = "MMM d, yyyy"
            }
            return formatter.string(from: date)
        }
    }
    
    private func colorForEaseFactor(_ easeFactor: Double) -> Color {
        if easeFactor < 1.5 {
            return .red       // Very difficult
        } else if easeFactor < 2.0 {
            return .orange    // Difficult
        } else if easeFactor < 2.5 {
            return .yellow    // Moderate
        } else {
            return .green     // Easy
        }
    }
}