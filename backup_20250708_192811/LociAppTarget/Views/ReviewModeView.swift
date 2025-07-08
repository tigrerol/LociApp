import SwiftUI
import SwiftData
import LociApp

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
            
            // Move to next location or refresh list
            if currentLocationIndex < dueLocations.count - 1 {
                currentLocationIndex += 1
                withAnimation {
                    reviewStep = .sequence
                }
            } else {
                // Refresh due locations list
                loadDueLocations()
            }
        } catch {
            print("Error reviewing location: \(error)")
        }
    }
}

#Preview {
    ReviewModeView()
        .modelContainer(for: [Itinerary.self, Location.self, Review.self])
}