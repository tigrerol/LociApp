import SwiftUI
import SwiftData

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
}

#Preview {
    LearningModeView()
        .modelContainer(for: [Itinerary.self, Location.self, Review.self])
}