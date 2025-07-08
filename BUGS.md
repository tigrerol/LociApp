# LociApp - Bug Tracker

## Known Bugs

## Bug #001: iOS 18.5 File Picker Permission Error
**Status**: Open
**Priority**: High
**Platform**: iOS 18.5 physical devices (works on simulator)

**Steps to reproduce**:
1. Open LociApp on iOS 18.5 physical device
2. Tap Import button in Learning tab
3. Select "Import File" 
4. Choose a JSON file from Files app
5. File picker shows but import fails

**Expected behavior**:
JSON file should be imported successfully into the app

**Actual behavior**:
- Error: "The file could not be opened because you don't have permission to view it"
- Debug error: "The view service did terminate with error: Error Domain=_UIViewServiceErrorDomain Code=1"
- File picker shows files but fails on selection

**Root cause**:
iOS 18.5 has stricter security-scoped resource enforcement. The app receives security-scoped URLs from .fileImporter but doesn't request access before reading the file.

**Three Potential Fixes**:

### Fix #1: Add Security-Scoped Resource Access (Recommended)
**Location**: Views.swift lines 232-246 (handleImport method)
**Current problematic code**:
```swift
do {
    try dataService.importItinerary(from: url, context: modelContext)
} catch {
    errorMessage = "Failed to import JSON file: \(error.localizedDescription)"
}
```

**Fixed code**:
```swift
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
```

### Fix #2: Enhanced Entitlements Configuration
**Location**: LociApp.entitlements (needs to be created in Xcode project settings)
**Add these entitlements**:
```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
<key>com.apple.security.files.bookmarks.app-scope</key>
<true/>
<key>com.apple.security.files.bookmarks.document-scope</key>
<true/>
```

**Also add to Info.plist**:
```xml
<key>NSDocumentsFolderUsageDescription</key>
<string>This app needs access to import itinerary JSON files</string>
<key>LSSupportsOpeningDocumentsInPlace</key>
<false/>
```

### Fix #3: Legacy UIDocumentPickerViewController Implementation
**Location**: Create new DocumentPickerView.swift
**Implementation**: Replace SwiftUI .fileImporter with UIKit UIDocumentPickerViewController that properly handles security-scoped resources in iOS 18.5

**Code**:
```swift
import UIKit

class DocumentPickerViewController: UIDocumentPickerViewController {
    var onDocumentPicked: ((URL) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        allowsMultipleSelection = false
    }
}

extension DocumentPickerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        onDocumentPicked?(url)
    }
}
```

**Current Workarounds Available**:
- ✅ JSON paste functionality (working)
- ✅ Share sheet integration (working) 
- ❌ Direct file picker (.fileImporter needs fix)

**Recommended Action**: 
Implement Fix #1 first as it's the simplest and most direct solution for the current codebase.

## Fixed Bugs

*No bugs fixed yet*

## Bug Report Template

When reporting bugs, use this format:

```markdown
## Bug #XXX: Brief description
**Status**: Open/Fixed
**Priority**: High/Medium/Low
**Commit**: [commit hash when fixed]

**Steps to reproduce**:
1. Step one
2. Step two
3. Step three

**Expected behavior**:
What should happen

**Actual behavior**:
What actually happens

**Root cause**:
What caused the bug (when known)

**Fix**:
How it was fixed (when fixed)
```