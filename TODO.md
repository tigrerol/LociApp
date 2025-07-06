# LociApp - TODO Tracker

## Pending

### Phase 1: Foundation (Week 1) - PARTIALLY COMPLETE
- [ ] Basic navigation with TabView (SwiftUI app implementation)

### Phase 2: Learning Mode (Week 2)
- [ ] Create simple list of itineraries
- [ ] Create location viewer with next/previous buttons (sequence order)
- [ ] Display images from stored Data using Image(uiImage: UIImage(data:))
- [ ] Handle empty states (show helpful message)

### Phase 3: Review Mode (Week 3)
- [ ] Create review flow: show sequence → show image → show name → rate
- [ ] Add 0-5 rating buttons (SuperMemo-2 scale: 0=complete failure, 5=perfect)
- [ ] Implement SuperMemo-2 algorithm from PAOCards-iOS
- [ ] Show all locations (due ones first, then others)

### Phase 4: Reverse Mode (Week 4)
- [ ] Create reverse flow: show name → sequence input → rate
- [ ] Add number input with validation
- [ ] Use same SuperMemoService (shared review state)
- [ ] Handle wrong answers gracefully

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
- [x] Set up SwiftData container and basic models (sequence, base64 images) - Commit: 1d90741
- [x] Create JSON import with base64 image decoding functionality - Commit: 1d90741
- [x] Write comprehensive tests for models and JSON parsing - Commit: 1d90741
- [x] Initialize git repository and create GitHub repo - Commit: 1d90741
- [x] Create testFiles directory for JSON test files - Commit: 1d90741

## Keep It Simple Rules
1. **Make it work first** - Don't optimize prematurely
2. **One feature at a time** - Complete each phase fully
3. **Commit after each TODO** - Track progress with git
4. **Test on device early** - Don't wait until the end
5. **Ask when stuck** - Don't spend hours debugging alone