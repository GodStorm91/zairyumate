# Core Data Usage Guide

## Quick Start

### 1. Access Persistence Controller

```swift
// In your SwiftUI view
@Environment(\.managedObjectContext) private var viewContext

// Or use shared instance
let context = PersistenceController.shared.viewContext
```

### 2. Using Services (Recommended)

```swift
// Initialize services
let profileService = ProfileService()
let documentService = DocumentService()
let timelineService = TimelineEventService()

// Create a profile
let profile = try await profileService.create(
    name: "Nguyen Van A",
    nameKatakana: "グエン・ヴァン・アー",
    dateOfBirth: someDate,
    nationality: "VNM",
    cardNumber: "AB1234567",  // Auto-encrypted in Keychain
    cardExpiry: expiryDate,
    visaType: "Engineer/Specialist in Humanities"
)

// Fetch active profile
let activeProfile = try await profileService.fetchActive()

// Create document
let document = try await documentService.create(
    for: profile,
    documentType: "extension"
)

// Generate timeline events automatically
try await timelineService.generateAutoEvents(for: profile)
```

### 3. Using @FetchRequest in SwiftUI

```swift
struct ProfileListView: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Profile.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Profile.createdAt, ascending: false)
        ],
        animation: .default
    )
    private var profiles: FetchedResults<Profile>

    var body: some View {
        List(profiles) { profile in
            Text(profile.displayName)
        }
    }
}
```

### 4. SwiftUI Previews

```swift
#Preview {
    ProfileCardView(profile: Profile.preview)
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

// Or use helper for complex previews
#Preview {
    let controller = CoreDataPreviewHelper.previewContainer()
    return ContentView()
        .environment(\.managedObjectContext, controller.viewContext)
}
```

## Data Models

### Profile
- **Encrypted fields**: `decryptedCardNumber`, `decryptedPassportNumber` (via Keychain)
- **Computed properties**: `isExpiringSoon`, `daysUntilExpiry`, `age`, `displayName`
- **Relationships**: `documents`, `timelineEvents`

### Document
- **Status workflow**: `draft` → `completed` → `submitted`
- **Methods**: `markAsCompleted()`, `markAsSubmitted()`, `revertToDraft()`
- **Computed**: `documentTypeDisplayName`, `hasPdfData`, `pdfFileSizeFormatted`

### TimelineEvent
- **Types**: `reminder`, `milestone`, `deadline`
- **Computed**: `isOverdue`, `isToday`, `isUpcoming`, `priorityLevel`
- **Methods**: `markAsCompleted()`, `reopenEvent()`, `updateEventDate()`

### AppSettings (Singleton)
- **Access**: `AppSettings.shared(in: context)`
- **Properties**: `biometricEnabled`, `selectedLanguage`, `isPro`, `lastSyncDate`
- **Methods**: `updateLanguage()`, `enableBiometric()`, `unlockPro()`

## Security Best Practices

```swift
// ✅ DO: Use decrypted properties for display
let cardNumber = profile.decryptedCardNumber

// ✅ DO: Set via computed property (auto-encrypts)
profile.decryptedCardNumber = "AB1234567"

// ❌ DON'T: Access cardNumber directly (it's a reference key, not the value)
let wrong = profile.cardNumber  // This is NOT the actual card number!

// ✅ DO: Check for expiring visas
let expiring = try await profileService.fetchExpiringSoon()

// ✅ DO: Clean up on deletion (automatic via prepareForDeletion)
try await profileService.delete(profile)  // Keychain cleanup automatic
```

## Common Patterns

### Creating Profile with Family
```swift
// Main profile
let mainProfile = try await profileService.create(
    name: "Nguyen Van A",
    relationship: "self"
)
try await profileService.setActive(mainProfile)

// Spouse
let spouse = try await profileService.create(
    name: "Tran Thi B",
    relationship: "spouse"
)

// Child
let child = try await profileService.create(
    name: "Nguyen Van C",
    relationship: "child"
)
```

### Document Workflow
```swift
// 1. Create draft
let doc = try await documentService.create(
    for: profile,
    documentType: "extension",
    status: "draft"
)

// 2. Add PDF data
try await documentService.updatePdfData(doc, pdfData: generatedPdf)

// 3. Mark as completed
try await documentService.markAsCompleted(doc)

// 4. Submit
try await documentService.markAsSubmitted(doc)
```

### Timeline Management
```swift
// Auto-generate from profile
try await timelineService.generateAutoEvents(for: profile)

// Fetch upcoming tasks
let upcoming = try await timelineService.fetchUpcoming()

// Mark as done
try await timelineService.markAsCompleted(event)

// Custom event
let customEvent = try await timelineService.create(
    for: profile,
    title: "Visit immigration office",
    eventDate: appointmentDate,
    eventType: "reminder"
)
```

## Testing

### Unit Tests (Phase 08)
```swift
// Test with in-memory store
let controller = PersistenceController(inMemory: true)
let service = ProfileService(persistenceController: controller)

// Test CRUD operations
let profile = try await service.create(name: "Test User")
XCTAssertNotNil(profile.id)

let fetched = try await service.fetch(id: profile.id!)
XCTAssertEqual(fetched?.name, "Test User")
```

### Preview Testing
```swift
// Quick preview instance
let profile = Profile.preview
print(profile.displayName)  // "Nguyen Van A"

// Full preview context
let controller = CoreDataPreviewHelper.previewContainer()
// Now has sample profiles, documents, events, settings
```

## Performance Tips

1. **Use batch operations** for multiple updates
2. **Fetch only needed properties** with `propertiesToFetch`
3. **Use predicates** to filter at database level
4. **Background context** for heavy operations:

```swift
let service = ProfileService()
// Services already use @MainActor for thread safety

// For custom background work:
let bgContext = PersistenceController.shared.newBackgroundContext()
bgContext.perform {
    // Heavy work here
}
```

## Troubleshooting

### "Entity not found"
- Check that .xcdatamodeld is added to Xcode project
- Clean build folder (Cmd+Shift+K)

### "Keychain error"
- Keychain only works on device/simulator, not unit tests
- Use in-memory store for tests

### "CloudKit not syncing"
- Phase 09 implementation pending
- Currently local-only storage

## File Locations

```
Core/
├── Storage/
│   ├── ZairyuMateDataModel.xcdatamodeld    # Core Data schema
│   ├── persistence-controller.swift         # Persistence stack
│   └── core-data-preview-helper.swift      # Preview utilities
├── Models/
│   ├── profile-core-data-*.swift           # Profile entity
│   ├── document-core-data-*.swift          # Document entity
│   ├── timeline-event-core-data-*.swift    # TimelineEvent entity
│   └── app-settings-core-data-*.swift      # AppSettings entity
├── Services/
│   ├── profile-service-crud.swift          # Profile CRUD
│   ├── document-service-crud.swift         # Document CRUD
│   └── timeline-event-service-crud.swift   # Timeline CRUD
└── Utilities/
    └── keychain-helper-secure-storage.swift # Encryption
```

## Further Reading

- [Phase 02 Implementation Report](../../../plans/reports/fullstack-developer-260127-1626-phase-02-core-data-implementation.md)
- [Phase Plan](../../../plans/260127-1502-zairyumate-ios-app/phase-02-core-data-models-and-storage.md)
- Apple Docs: [Core Data](https://developer.apple.com/documentation/coredata)
- Apple Docs: [CloudKit](https://developer.apple.com/documentation/cloudkit)
