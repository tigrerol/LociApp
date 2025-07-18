# LociApp - TODO Tracker

## Pending

### Phase 1: Foundation (Week 1) ✅ COMPLETE

### Phase 2: Learning Mode (Week 2) ✅ COMPLETE

### Phase 3: Review Mode (Week 3) ✅ COMPLETE

### Phase 4: Reverse Mode (Week 4) ✅ COMPLETE

### Phase 5: Polish (Week 5)
- [ ] Add error handling that doesn't crash
- [ ] No onboarding needed (user decision)
- [ ] Comprehensive automated testing
- [ ] Add app icon and basic styling
- [ ] Final device testing once automated tests pass

### Phase 6: Watch Extension (Optional - Week 6)
- [ ] Create simple watch app
- [ ] Show due reviews only
- [ ] Basic review flow
- [ ] Sync with phone

## Completed

### Phase 1: Foundation ✅
- [x] Create Xcode project with iOS 18 minimum target - Commit: 1d90741
- [x] Set up SwiftData container and basic models (sequence, base64 images) - Commit: a66bba8
- [x] Create JSON import with base64 image decoding functionality - Commit: a66bba8
- [x] Write comprehensive tests for models and JSON parsing - Commit: 1d90741
- [x] Initialize git repository and create GitHub repo - Commit: 1d90741
- [x] Create testFiles directory for JSON test files - Commit: 1d90741
- [x] Create SwiftData @Model classes (Itinerary, Location, Review) - Commit: a66bba8
- [x] Create DataService to bridge JSONParser and SwiftData - Commit: a66bba8
- [x] Create SwiftUI app structure with ModelContainer - Commit: a66bba8
- [x] Implement ItineraryListView with TabView navigation - Commit: a66bba8

### Phase 2: Learning Mode ✅
- [x] Implement itinerary selection in Learning Mode - Commit: a4ffda3
- [x] Create location viewer with next/previous navigation - Commit: a4ffda3
- [x] Implement proper image display from stored Data - Commit: a4ffda3
- [x] Handle empty states with helpful messages - Commit: a4ffda3
- [x] Add tests for Learning Mode functionality - Commit: a4ffda3
- [x] Enhance base64 decoding with robust implementation - Commit: a4ffda3

### Phase 3: Review Mode ✅
- [x] Create review flow: show sequence → show image → show name → rate - Commit: 88cb86c
- [x] Add 0-5 rating buttons (SuperMemo-2 scale) - Commit: 88cb86c
- [x] Integrate SuperMemoService with location reviews - Commit: 88cb86c
- [x] Show all locations (due ones first, then others) - Commit: 88cb86c
- [x] Add tests for Review Mode functionality - Commit: 88cb86c

### Phase 4: Reverse Mode ✅
- [x] Create reverse flow: show name → sequence input → rate - Commit: bd0a847
- [x] Add number input with validation - Commit: bd0a847
- [x] Use same SuperMemoService (shared review state) - Commit: bd0a847
- [x] Handle wrong answers gracefully - Commit: bd0a847
- [x] Add tests for Reverse Mode functionality - Commit: bd0a847

## Keep It Simple Rules
1. **Make it work first** - Don't optimize prematurely
2. **One feature at a time** - Complete each phase fully
3. **Commit after each TODO** - Track progress with git
4. **Test on device early** - Don't wait until the end
5. **Ask when stuck** - Don't spend hours debugging alone