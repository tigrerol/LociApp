# LociApp - Memory Palace iOS App Implementation Plan

## Project Overview
A **simple** iOS app for memorizing "itineraries" using the loci technique (memory palace method). The app will import JSON files containing location sequences and provide three core modes: Learning, Review, and Reverse.

**PRINCIPLE**: Keep it simple - implement only what's needed, avoid over-engineering.

## Core Requirements
- **Target**: iPhone 15 Pro with iOS 18+
- **Optional**: Apple Watch 10 extension (Phase 7 - can be skipped initially)
- **Data Source**: JSON file import only (no in-app creation)
- **SuperMemo Integration**: Simplified spaced repetition algorithm

## Application Modes

### 1. Learning Mode
- Sequential display of locations in order
- User scrolls through to memorize the sequence
- Display: Location number, image, name, description
- No performance tracking

### 2. Review Mode
- Show location number → User recalls → Reveal image hint → Reveal name/description
- User rates performance (0-5 scale)
- SuperMemo algorithm calculates next review date
- Track review statistics

### 3. Reverse Mode
- Show location name → User inputs location number
- User rates performance (0-5 scale)
- Separate SuperMemo tracking from Review mode
- Simple number input interface

## Technical Architecture

### Technology Stack
- **UI**: SwiftUI (iOS 18+)
- **Data**: SwiftData (simple, modern persistence)
- **Architecture**: Simple MVVM (no complex modules initially)
- **Testing**: XCTest with basic coverage

### Data Models (SwiftData) - SIMPLIFIED
```swift
@Model
class Itinerary {
    var name: String
    var locations: [Location] = []
    var dateImported: Date = Date()
    
    init(name: String) {
        self.name = name
    }
}

@Model
class Location {
    var sequence: Int
    var name: String
    var description: String
    var imageData: Data // Base64 decoded image data
    
    // SuperMemo-2 properties
    var nextReview: Date = Date()
    var easeFactor: Double = 2.5
    var intervalDays: Int = 1
    var repetitionCount: Int = 0
    
    init(sequence: Int, name: String, description: String, imageData: Data) {
        self.sequence = sequence
        self.name = name
        self.description = description
        self.imageData = imageData
    }
}

// Single review tracking - keep it simple
@Model
class Review {
    var location: Location
    var quality: Int // 0-5 (SuperMemo-2 scale: 0=complete failure, 5=perfect)
    var reviewDate: Date = Date()
    var isReverse: Bool = false
    
    init(location: Location, quality: Int, isReverse: Bool = false) {
        self.location = location
        self.quality = quality
        self.isReverse = isReverse
    }
}
```

### JSON Import Format
```json
{
  "itineraries": [
    {
      "name": "Ancient Rome Walk",
      "description": "A journey through the landmarks of ancient Rome",
      "image": {
        "format": "base64",
        "data": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
      },
      "locations": [
        {
          "name": "The Colosseum",
          "description": "The grand amphitheater where gladiators fought",
          "sequence": 1,
          "image": {
            "format": "base64",
            "data": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
          }
        },
        {
          "name": "Roman Forum",
          "description": "The center of political and social life",
          "sequence": 2,
          "image": {
            "format": "base64",
            "data": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
          }
        }
      ]
    }
  ]
}
```

**Import Specifications**:
- One itinerary imported at a time
- All images are base64 encoded
- Locations are read-only after import
- No limits on number of locations or itineraries

## Implementation Plan - SIMPLIFIED

### Phase 1: Foundation (Week 1)
**Goal**: Get basic app working with data

**Tasks**:
- [ ] Create Xcode project with iOS 18 minimum target
- [ ] Set up SwiftData container and basic models
- [ ] Create JSON import via iOS Share Sheet and document picker
- [ ] Implement base64 image decoding and storage as Data
- [ ] Basic navigation with TabView
- [ ] Write basic tests for models and JSON parsing

**Deliverables**:
- Working Xcode project that builds
- SwiftData models that work
- JSON import with base64 image decoding that doesn't crash
- Basic app that shows imported itineraries

**Critical Implementation Details**:
- Use UIDocumentPickerViewController for JSON file selection
- Register app to handle .json files in Info.plist
- Decode base64 image data and store as Data in SwiftData
- Import one itinerary at a time from JSON array

### Phase 2: Learning Mode (Week 2)
**Goal**: First working feature

**Tasks**:
- [ ] Create simple list of itineraries
- [ ] Create location viewer with next/previous buttons (sequence order)
- [ ] Display images from stored Data using Image(uiImage: UIImage(data:))
- [ ] Handle empty states (show helpful message)

**Deliverables**:
- Working Learning Mode that user can navigate through in sequence order

### Phase 3: Review Mode (Week 3)
**Goal**: Add review functionality

**Tasks**:
- [ ] Create review flow: show sequence → show image → show name → rate
- [ ] Add 0-5 rating buttons (SuperMemo-2 scale: 0=complete failure, 5=perfect)
- [ ] Create SuperMemoService with updateLocation(location, quality) method
- [ ] Implement SuperMemo-2 algorithm from PAOCards-iOS
- [ ] Show all locations (due ones first, then others)

**Deliverables**:
- Working Review Mode with SuperMemo-2 spaced repetition
- SuperMemoService handles all algorithm logic
- Reviews shared between forward and reverse modes

### Phase 4: Reverse Mode (Week 4)
**Goal**: Add reverse review

**Tasks**:
- [ ] Create reverse flow: show name → sequence input → rate
- [ ] Add number input with validation
- [ ] Use same SuperMemoService (shared review state)
- [ ] Handle wrong answers gracefully

**Deliverables**:
- Working Reverse Mode with shared SuperMemo-2 tracking

### Phase 5: Polish (Week 5)
**Goal**: Make it production ready

**Tasks**:
- [ ] Add error handling that doesn't crash
- [ ] No onboarding needed (user decision)
- [ ] Comprehensive automated testing
- [ ] Add app icon and basic styling
- [ ] Final device testing once automated tests pass

**Deliverables**:
- App ready for App Store submission with comprehensive test coverage

### Phase 6: Watch Extension (Optional - Week 6)
**Goal**: Basic watch functionality

**Tasks**:
- [ ] Create simple watch app
- [ ] Show due reviews only
- [ ] Basic review flow
- [ ] Sync with phone

**Deliverables**:
- Working watch app (if needed)

## File Structure - SIMPLIFIED
```
LociApp/
├── LociApp.xcodeproj
├── LociApp/
│   ├── LociAppApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── Itinerary.swift
│   │   ├── Location.swift
│   │   └── Review.swift
│   ├── Views/
│   │   ├── ItineraryListView.swift
│   │   ├── LearningModeView.swift
│   │   ├── ReviewModeView.swift
│   │   └── ReverseModeView.swift
│   ├── Services/
│   │   ├── DataService.swift
│   │   └── SuperMemoService.swift
│   └── Assets.xcassets/
├── LociAppTests/
├── LociAppWatch/ (Optional)
├── PLAN.md
├── TODO.md
├── BUGS.md
├── BUILD.md
└── CLAUDE.md
```

## Success Criteria - SIMPLIFIED
- [ ] All three modes working (don't crash)
- [ ] Basic SuperMemo algorithm working
- [ ] JSON import works
- [ ] App can be submitted to App Store
- [ ] Watch app working (optional)

## Keep It Simple Rules
1. **No premature optimization** - Make it work first
2. **No complex architecture** - Use simple MVVM
3. **No fancy UI** - Basic SwiftUI components
4. **No edge cases initially** - Handle happy path first
5. **Comprehensive automated testing** - Full test coverage before device testing
6. **SuperMemo-2 algorithm** - Use PAOCards-iOS implementation
7. **Base64 image handling** - Decode to Data, store in SwiftData
8. **Read-only data** - No editing after import

## Technical Decisions
- **SwiftData**: Simple, modern persistence
- **Single-file views**: Keep views simple and focused
- **No complex modules**: Everything in main app target initially
- **Bundle images**: Avoid complex image management
- **Basic SuperMemo**: Use simplified algorithm from PAOCards

## Requirements Clarified ✅

1. **JSON Import**: ✅ No sample itineraries - users provide their own JSON files
2. **Image Sources**: ✅ Base64 encoded images in JSON, stored as Data in SwiftData  
3. **SuperMemo Complexity**: ✅ Full SuperMemo-2 algorithm from PAOCards-iOS
4. **Review Modes**: ✅ Forward/reverse reviews share the same SuperMemo state
5. **Watch Priority**: ✅ Nice-to-have, implement later
6. **Onboarding**: ✅ No onboarding needed
7. **Error Handling**: ✅ Basic "Something went wrong" messages acceptable for V1
8. **Testing Strategy**: ✅ Comprehensive automated testing, device testing only after tests pass

## Additional Specifications Clarified ✅

- **Import**: One itinerary at a time from JSON array
- **Data Model**: Use "sequence" instead of "number" 
- **Rating Scale**: 0-5 (SuperMemo-2 standard: 0=complete failure, 5=perfect)
- **Review Display**: Show all locations (due ones first, then others)
- **Data Persistence**: Read-only after import (no editing/deleting)
- **Limits**: No limits on locations per itinerary or total itineraries