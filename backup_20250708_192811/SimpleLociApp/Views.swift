import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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
    
    var body: some View {
        NavigationView {
            if itineraries.isEmpty {
                ContentUnavailableView(
                    "No Itineraries",
                    systemImage: "list.bullet",
                    description: Text("Import JSON files to start learning")
                )
            } else if let selectedItinerary {
                learningView(for: selectedItinerary)
            } else {
                itinerarySelector
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
                let location = itinerary.locations[currentLocationIndex]
                
                VStack(spacing: 20) {
                    Text("Location \(location.sequence)")
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
                            Text("\(currentLocationIndex + 1) of \(itinerary.locations.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: Double(currentLocationIndex + 1), total: Double(itinerary.locations.count))
                                .frame(width: 100)
                        }
                        
                        Spacer()
                        
                        Button("Next") {
                            if currentLocationIndex < itinerary.locations.count - 1 {
                                currentLocationIndex += 1
                            }
                        }
                        .disabled(currentLocationIndex == itinerary.locations.count - 1)
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
}

// MARK: - Review Mode View

struct ReviewModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [Location]
    @State private var superMemoService = SuperMemoService()
    @State private var dueLocations: [Location] = []
    @State private var currentLocationIndex = 0
    @State private var reviewStep: ReviewStep = .sequence
    @State private var isLoading = false
    
    enum ReviewStep {
        case sequence
        case image
        case nameAndDescription
        case rating
    }
    
    var body: some View {
        NavigationView {
            if dueLocations.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No Reviews Due",
                    systemImage: "checkmark.circle",
                    description: Text("All locations are up to date! Come back later or import more itineraries.")
                )
            } else if isLoading {
                ProgressView("Loading reviews...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                reviewView
            }
        }
        .navigationTitle("Review")
        .onAppear {
            superMemoService.setModelContext(modelContext)
            loadDueLocations()
        }
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
            case .rating:
                ratingStep(for: location)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func sequenceStep(for location: Location) -> some View {
        VStack(spacing: 30) {
            Text("What is at location \(location.sequence)?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Think about what you remember...")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Show Image Hint") {
                withAnimation {
                    reviewStep = .image
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
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
            
            Text("Location \(location.sequence)")
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
        VStack(spacing: 30) {
            if let uiImage = UIImage(data: location.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
            
            VStack(spacing: 10) {
                Text("Location \(location.sequence)")
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
            
            Button("Rate Your Performance") {
                withAnimation {
                    reviewStep = .rating
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
        }
    }
    
    private func ratingStep(for location: Location) -> some View {
        VStack(spacing: 30) {
            Text("How well did you remember this?")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                ForEach(SuperMemoQuality.allCases, id: \.rawValue) { quality in
                    Button(action: {
                        rateLocation(quality: quality)
                    }) {
                        VStack(spacing: 8) {
                            Text("\(quality.rawValue)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text(quality.description)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorForQuality(quality))
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
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
            dueLocations = try superMemoService.getDueLocations()
            currentLocationIndex = 0
            reviewStep = .sequence
        } catch {
            print("Error loading due locations: \(error)")
            dueLocations = []
        }
        isLoading = false
    }
    
    private func rateLocation(quality: SuperMemoQuality) {
        let location = dueLocations[currentLocationIndex]
        
        do {
            try superMemoService.reviewLocation(location, quality: quality)
            
            if currentLocationIndex < dueLocations.count - 1 {
                currentLocationIndex += 1
                withAnimation {
                    reviewStep = .sequence
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
    @State private var superMemoService = SuperMemoService()
    @State private var dueLocations: [Location] = []
    @State private var currentLocationIndex = 0
    @State private var userInput = ""
    @State private var reverseStep: ReverseStep = .nameInput
    @State private var isCorrect = false
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool
    
    enum ReverseStep {
        case nameInput
        case result
        case rating
    }
    
    var body: some View {
        NavigationView {
            if dueLocations.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No Reviews Due",
                    systemImage: "checkmark.circle",
                    description: Text("All locations are up to date! Come back later or import more itineraries.")
                )
            } else if isLoading {
                ProgressView("Loading reviews...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                reverseView
            }
        }
        .navigationTitle("Reverse")
        .onAppear {
            superMemoService.setModelContext(modelContext)
            loadDueLocations()
        }
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
            case .rating:
                ratingStep(for: location)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func nameInputStep(for location: Location) -> some View {
        VStack(spacing: 30) {
            Text("What sequence number is this location?")
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
                TextField("Enter sequence number", text: $userInput)
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
        VStack(spacing: 30) {
            if let uiImage = UIImage(data: location.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
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
                    Text("\(location.sequence)")
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
            
            Button("Rate Your Performance") {
                withAnimation {
                    reverseStep = .rating
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
        }
    }
    
    private func ratingStep(for location: Location) -> some View {
        VStack(spacing: 30) {
            Text("How well did you remember this?")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if !isCorrect {
                Text("Consider rating lower since your answer was incorrect")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                ForEach(SuperMemoQuality.allCases, id: \.rawValue) { quality in
                    Button(action: {
                        rateLocation(quality: quality)
                    }) {
                        VStack(spacing: 8) {
                            Text("\(quality.rawValue)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text(quality.description)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorForQuality(quality))
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
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
            dueLocations = try superMemoService.getDueLocations()
            currentLocationIndex = 0
            reverseStep = .nameInput
        } catch {
            print("Error loading due locations: \(error)")
            dueLocations = []
        }
        isLoading = false
    }
    
    private func checkAnswer() {
        let location = dueLocations[currentLocationIndex]
        isCorrect = Int(userInput) == location.sequence
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