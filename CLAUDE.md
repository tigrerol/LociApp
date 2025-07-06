# LociApp - Claude AI Assistant Guidelines

## Project Overview

This is a simple iOS app for memorizing "itineraries" using the loci technique (memory palace method). The app imports JSON files containing location sequences and provides three core modes: Learning, Review, and Reverse.

**CORE PRINCIPLE**: Keep it simple - implement only what's needed, avoid over-engineering.

## Development Philosophy

### YAGNI (You Aren't Gonna Need It)
- Implement only the functionality that is currently necessary
- Avoid speculative or premature features
- If unsure, ask first

### SOLID Principles
- Single Responsibility: Each class/view has one clear purpose
- Open/Closed: Extend behavior without modifying existing code
- Keep interfaces simple and focused

## Architecture Guidelines

### Technology Stack
- **UI**: SwiftUI (iOS 18+)
- **Data**: SwiftData (simple, modern persistence)
- **Architecture**: Simple MVVM (no complex modules initially)
- **Testing**: XCTest with basic coverage

### File Organization
```
LociApp/
├── Models/          # SwiftData models
├── Views/           # SwiftUI views
├── Services/        # Business logic
└── Assets.xcassets/ # Images and resources
```

## Code Standards

### Naming Conventions
- **Classes**: PascalCase (e.g., `ItineraryListView`)
- **Variables**: camelCase (e.g., `currentLocation`)
- **Files**: Match class names (e.g., `ItineraryListView.swift`)

### SwiftUI Guidelines
- Keep views simple and focused
- Use `@State` for local state, `@StateObject` for data services
- Prefer composition over inheritance
- Use basic SwiftUI components initially

### Error Handling
- Always handle errors gracefully
- Don't crash the app
- Show user-friendly error messages
- Log errors for debugging

## Testing Strategy

### Unit Tests
- Test models and business logic
- Test SuperMemo algorithm
- Test JSON import functionality
- Basic coverage, not comprehensive

### Manual Testing
- Test on device early and often
- Test all three modes (Learning, Review, Reverse)
- Test with different JSON files
- Test edge cases (empty data, invalid JSON)

## Git Workflow

### Commit Guidelines
- Commit after each completed TODO item
- Use descriptive commit messages
- Follow format: `feat(scope): description`
- Push to GitHub regularly

### Branch Strategy
- Use `main` branch for development
- Create feature branches for major features
- Merge back to main when complete

## Development Process

### Phase-by-Phase Development
1. **Foundation**: Get basic app structure working
2. **Learning Mode**: First working feature
3. **Review Mode**: Add spaced repetition
4. **Reverse Mode**: Add reverse review
5. **Polish**: Make it production ready
6. **Watch Extension**: Optional additional platform

### Definition of Done
For each phase, the feature should:
- Work without crashing
- Handle basic error cases
- Be manually tested
- Have basic unit tests
- Be committed to git

## Common Patterns

### Data Models
```swift
@Model
class ModelName {
    var property: Type
    
    init(property: Type) {
        self.property = property
    }
}
```

### SwiftUI Views
```swift
struct ViewName: View {
    @State private var localState: Type
    
    var body: some View {
        // View content
    }
}
```

### Services
```swift
class ServiceName: ObservableObject {
    @Published var data: Type
    
    func performAction() {
        // Business logic
    }
}
```

## When to Ask for Help

- If stuck for more than 30 minutes
- If unsure about architecture decisions
- If encountering complex SwiftData issues
- If SuperMemo algorithm is confusing
- If app crashes and can't debug

## Quality Gates

### Before Each Commit
- [ ] Code builds without warnings
- [ ] Basic functionality tested
- [ ] No debug prints or temporary code
- [ ] Follows naming conventions

### Before Each Phase
- [ ] All TODOs for phase completed
- [ ] Feature works on device
- [ ] Basic error handling added
- [ ] Ready for next phase

## Resources

- **SuperMemo Reference**: Use PAOCards-iOS implementation as guide
- **SwiftData**: Use Apple's documentation and examples
- **SwiftUI**: Prefer simple, built-in components
- **Testing**: Focus on critical business logic