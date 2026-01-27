# Zairyu Mate iOS App

Japanese Visa Application Assistant - Native iOS Application

## Project Overview

Zairyu Mate is an iOS app that helps users manage Japanese visa applications and Zairyu (Residence) Card data. The app leverages iPhone hardware features (NFC, FaceID, Camera) to automate data entry and provides a secure, offline-first experience.

## Requirements

- **iOS:** 17.0+
- **Xcode:** 15.0+
- **Swift:** 5.9+
- **Devices:** iPhone only (iPad not supported in MVP)

## Project Structure

```
ZairyuMate/
├── ZairyuMate.xcodeproj/       # Xcode project file
├── ZairyuMate/
│   ├── App/                     # App entry point
│   │   └── ZairyuMateApp.swift
│   ├── Features/                # Feature modules (MVVM-ish)
│   │   ├── Home/
│   │   ├── Profile/
│   │   ├── Documents/
│   │   ├── Timeline/
│   │   └── Settings/
│   ├── Core/                    # Core business logic
│   │   ├── Models/
│   │   ├── Services/
│   │   ├── Storage/
│   │   └── Utilities/
│   │       ├── Constants.swift
│   │       └── Extensions.swift
│   ├── UI/                      # Reusable UI components
│   │   ├── Components/
│   │   ├── Styles/
│   │   └── Theme/
│   │       ├── ColorTheme.swift
│   │       ├── Typography.swift
│   │       └── Spacing.swift
│   ├── Resources/               # Assets and localizations
│   │   └── Assets.xcassets/
│   └── Supporting/              # Configuration files
│       ├── Info.plist
│       └── ZairyuMate.entitlements
└── .swiftlint.yml              # Code quality rules
```

## Key Features (Planned)

### Phase 1 (MVP)
- Manual data entry
- Visa expiration tracker
- PDF form generation
- Local storage

### Phase 2
- NFC Zairyu Card scanning
- OCR passport scanning
- iCloud sync
- Biometric authentication

### Phase 3
- Timeline scheduler
- Local notifications
- Multiple profiles
- In-app purchases

## Design System

### Colors
- **Primary:** iOS Blue (#007AFF light, #0A84FF dark)
- **Background:** (#F2F2F7 light, #1C1C1E dark)
- **Card Gradient:** Green to Teal
- **Text Primary:** Black/White (adaptive)
- **Text Secondary:** Gray (#8E8E93)

### Typography
- Uses SF Pro (system font)
- Predefined sizes: `.zmLargeTitle`, `.zmTitle`, `.zmBody`, etc.
- Style modifiers: `.zmHeadlineStyle()`, `.zmBodyStyle()`

### Spacing
- 8pt grid system
- Constants: `Spacing.xs` (4), `Spacing.sm` (8), `Spacing.md` (16), etc.
- Corner radius: `CornerRadius.button`, `CornerRadius.card`

## State Management

- **iOS 17+:** Uses `@Observable` macro (modern SwiftUI)
- **NO ObservableObject:** Following iOS 17 best practices

## Privacy & Security

- **Zero-PII Server:** No personal data sent to external servers
- **Offline-First:** All features work without internet
- **iCloud Sync:** Data synced via user's personal iCloud
- **Biometric Lock:** FaceID/TouchID for app access
- **Keychain:** Sensitive data stored securely

## Capabilities

The app requires the following capabilities:
- NFC Tag Reading (for Zairyu Card scanning)
- iCloud (CloudKit for data sync)
- Push Notifications (time-sensitive reminders)
- Keychain Sharing
- App Groups

## Privacy Usage Descriptions

Required permission prompts:
- **NFC:** Scan Zairyu Card for automatic data entry
- **Face ID:** Secure app access to protect personal information
- **Camera:** Scan passport and documents with OCR

## Build & Run

1. Open `ZairyuMate.xcodeproj` in Xcode
2. Select a target device or simulator (iOS 17+)
3. Update signing team in project settings
4. Build and run (⌘R)

## Code Quality

### SwiftLint
Project uses SwiftLint for code quality enforcement:
```bash
# Install SwiftLint
brew install swiftlint

# Run linter
swiftlint lint

# Auto-fix issues
swiftlint --fix
```

### Custom Rules
- Use `@Observable` instead of `ObservableObject`
- Use `Color.zm*` theme colors (not hardcoded)
- Use `Spacing.*` constants (not magic numbers)

## Development Guidelines

1. **File Naming:** Use PascalCase for Swift files
2. **Architecture:** MVVM-ish (View + ViewModel + Model)
3. **No UIKit:** Pure SwiftUI (except bridging when necessary)
4. **Offline First:** All features must work offline
5. **Dark Mode:** Support light/dark mode from day one
6. **Localization:** Prepare for Japanese, Vietnamese, English

## Testing

```bash
# Run unit tests
xcodebuild test -scheme ZairyuMate -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests (when available)
xcodebuild test -scheme ZairyuMateUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Git Workflow

1. Create feature branch: `git checkout -b feature/name`
2. Make changes and commit: `git commit -m "feat: description"`
3. Push to remote: `git push origin feature/name`
4. Create pull request

## Deployment

### TestFlight (Beta)
1. Archive build in Xcode
2. Upload to App Store Connect
3. Submit for beta testing

### App Store (Production)
1. Complete App Store metadata
2. Submit for review
3. Release when approved

## License

Proprietary - All rights reserved

## Contact

For development questions, see project documentation in `/docs`.
