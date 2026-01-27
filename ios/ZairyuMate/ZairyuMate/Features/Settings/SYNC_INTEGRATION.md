# iCloud Sync Integration Guide

## Overview
Phase 09 implements automatic iCloud sync using CloudKit and NSPersistentCloudKitContainer.

## Architecture

```
┌─────────────────────────────────────┐
│      ZairyuMateApp.swift            │
│  ┌─────────────────────────────┐   │
│  │ syncManager (Environment)   │   │
│  │ icloudMonitor (Environment) │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Core/Storage/                     │
│   persistence-controller.swift      │
│  ┌─────────────────────────────┐   │
│  │ NSPersistentCloudKit        │   │
│  │ Container with CloudKit     │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   iCloud Private Database           │
│   - Profile records                 │
│   - Document records                │
│   - TimelineEvent records           │
└─────────────────────────────────────┘
```

## Components Created

### 1. CloudSyncManager
**File:** `Core/Services/cloud-sync-manager.swift`

Observable class that manages sync state and provides manual sync triggers.

```swift
@Environment(CloudSyncManager.self) private var syncManager

// Check sync state
switch syncManager.syncState {
case .idle: // Ready
case .syncing: // In progress
case .success: // Completed
case .error(let msg): // Failed
}

// Manual sync
Task {
    await syncManager.triggerSync()
}
```

### 2. iCloudStatusMonitor
**File:** `Core/Services/icloud-status-monitor.swift`

Observable class that monitors iCloud account availability.

```swift
@Environment(iCloudStatusMonitor.self) private var icloudMonitor

// Check availability
if icloudMonitor.isAvailable {
    // iCloud ready
} else {
    // Show setup guide
}
```

### 3. SyncStatusView
**File:** `Features/Settings/Views/sync-status-view.swift`

Pre-built UI component for displaying sync status.

```swift
import SwiftUI

Section("iCloud Sync") {
    SyncStatusView()
}
```

## Usage in Settings

To add sync status to your Settings view:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(CloudSyncManager.self) private var syncManager
    @Environment(iCloudStatusMonitor.self) private var icloudMonitor

    var body: some View {
        Form {
            Section("iCloud Sync") {
                SyncStatusView()
            }

            // Other settings...
        }
        .navigationTitle("Settings")
    }
}
```

## How It Works

### Automatic Sync
- Core Data automatically syncs changes to CloudKit
- No manual intervention required
- Changes propagate within 30 seconds
- Background sync enabled

### Manual Sync
```swift
Task {
    await syncManager.triggerSync()
}
```

### Sync Events
CloudSyncManager observes:
- `NSPersistentStoreRemoteChange` - Remote data changes
- `NSPersistentCloudKitContainer.eventChangedNotification` - Import/export events

### Conflict Resolution
- Policy: Last-write-wins
- Implementation: `NSMergeByPropertyObjectTrumpMergePolicy`
- Automatic - no user intervention needed

## iCloud Account States

| State | Description | UI Action |
|-------|-------------|-----------|
| `.available` | iCloud ready | Show sync status |
| `.noAccount` | Not signed in | Prompt to sign in |
| `.restricted` | Parental controls | Show restriction message |
| `.temporarilyUnavailable` | Network issue | Show retry option |
| `.couldNotDetermine` | Checking... | Show loading state |

## Testing

### Prerequisites
- Physical iOS device (simulator has limited iCloud support)
- Signed in to iCloud
- iCloud Drive enabled
- Two devices for multi-device testing

### Test Checklist
1. Create profile on Device A
2. Wait 30 seconds
3. Check Device B for synced profile
4. Modify on Device B
5. Verify changes on Device A
6. Test offline mode (airplane)
7. Test account sign out/in

### Debugging
Enable debug logging in Xcode:
```
-com.apple.CoreData.CloudKitDebug 1
```

Monitor CloudKit events:
```swift
#if DEBUG
print("☁️ CloudKit event: \(event.type)")
#endif
```

## Security

- **Private Database:** User data only (zero developer access)
- **Encryption:** Apple manages encryption at rest/transit
- **File Protection:** `FileProtectionType.complete`
- **Card Numbers:** Already encrypted before Core Data (Phase 02)

## Configuration

### Entitlements
Already configured in `Supporting/ZairyuMate.entitlements`:
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.zairyumate.app</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

### Container ID
```swift
"iCloud.com.zairyumate.app"
```

### Xcode Setup
1. Select target "ZairyuMate"
2. Go to "Signing & Capabilities"
3. Ensure "iCloud" capability is enabled
4. Verify container ID matches

## Troubleshooting

### Sync Not Working
1. Check iCloud account status
2. Verify container ID in Xcode
3. Check CloudKit dashboard
4. Enable debug logging

### Slow Sync
- Initial sync may take longer
- Large attachments sync separately
- Network speed dependent

### Data Not Appearing
- Wait 30 seconds minimum
- Check both devices have network
- Verify same iCloud account
- Force manual sync

## API Reference

### CloudSyncManager
```swift
// Properties
var syncState: CloudSyncState
var lastSyncDate: Date?
var isCloudSyncEnabled: Bool
var statusMessage: String

// Methods
func triggerSync() async
```

### iCloudStatusMonitor
```swift
// Properties
var accountStatus: CKAccountStatus
var isAvailable: Bool
var errorMessage: String?
var statusDescription: String
var statusIcon: String
var statusColor: Color

// Methods
func checkAccountStatus()
```

### CloudSyncState
```swift
enum CloudSyncState: Equatable {
    case idle
    case syncing
    case success
    case error(String)
}
```

## Next Steps

1. Integrate SyncStatusView into Settings screen
2. Test on physical devices
3. Monitor CloudKit usage/quotas
4. Add to Phase 11 (Pro feature gating if needed)
