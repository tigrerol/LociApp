import SwiftUI
import SwiftData
import LociApp

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
            
            // Move to next location or refresh list
            if currentLocationIndex < dueLocations.count - 1 {
                currentLocationIndex += 1
                resetView()
            } else {
                // Refresh due locations list
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
        // Delay focusing to avoid animation conflicts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isInputFocused = true
        }
    }
}

#Preview {
    ReverseModeView()
        .modelContainer(for: [Itinerary.self, Location.self, Review.self])
}