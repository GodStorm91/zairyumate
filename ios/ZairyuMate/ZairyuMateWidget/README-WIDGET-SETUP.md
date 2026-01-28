# ZairyuMate Widget Setup Guide

## Overview
This widget extension displays visa expiry countdown on the home screen and lock screen. It uses App Groups to share data between the main app and widget.

## Architecture

### Files
- `widget-bundle-entry-point.swift` - Main entry point for widget extension
- `widget-entry-timeline-model.swift` - TimelineEntry model containing countdown data
- `widget-timeline-provider-data-loader.swift` - Timeline provider that loads data from shared storage
- `countdown-widget-views-ui.swift` - Widget UI for all sizes (small, medium, lock screen)
- `ZairyuMateWidget.entitlements` - App Groups entitlement
- `Info.plist` - Widget extension configuration

### Supported Sizes
1. **Small Widget (2x2)** - Large number countdown with "days" label
2. **Medium Widget (4x2)** - Circular progress ring with profile details
3. **Lock Screen Widget** - Compact "89d | Visa" format (iOS 16+)

## App Groups Configuration

### Identifier
`group.com.khanhnguyenhoangviet.zairyumate`

### Setup in Xcode
1. Select ZairyuMateWidget target
2. Signing & Capabilities
3. Add "App Groups" capability
4. Enable `group.com.khanhnguyenhoangviet.zairyumate`

### Shared Data
The main app writes profile data to App Groups using `SharedDataStore`:
```swift
SharedDataStore.saveWidgetData(widgetData)
WidgetCenter.shared.reloadAllTimelines()
```

Widget reads data on timeline update:
```swift
SharedDataStore.loadWidgetData()
```

## Widget Update Schedule

### Automatic Updates
- **Midnight refresh**: Widget updates daily at midnight to recalculate days remaining
- **Manual refresh**: When app calls `WidgetCenter.shared.reloadAllTimelines()`
- **App launch sync**: Widget data synced when main app opens

### Timeline Policy
```swift
let timeline = Timeline(entries: [entry], policy: .after(midnight))
```

## Color Coding by Urgency

| Days Remaining | Color | Meaning |
|---------------|-------|---------|
| 0-7 days | Red | Critical |
| 8-30 days | Orange | Urgent |
| 31-60 days | Yellow | Warning |
| 61+ days | Green | Safe |

## Integration Points

### ProfileService
When profile is created/updated/activated:
```swift
syncWidgetData(for: profile)
WidgetCenter.shared.reloadAllTimelines()
```

### App Launch
```swift
Task {
    let profileService = ProfileService(persistenceController: persistenceController)
    await profileService.syncWidgetOnLaunch()
}
```

## Testing

### Preview in Xcode
1. Select ZairyuMateWidget scheme
2. Run on simulator
3. Long press home screen > Add Widget > Zairyu Mate

### Debug Widget Data
```swift
if let data = SharedDataStore.loadWidgetData() {
    print("Widget data: \(data.profileName) - \(data.daysRemaining) days")
}
```

### Manual Timeline Reload
```swift
WidgetCenter.shared.reloadAllTimelines()
```

## Troubleshooting

### Widget shows "No Profile"
- Check App Groups entitlement is enabled in both targets
- Verify `group.com.khanhnguyenhoangviet.zairyumate` identifier matches
- Ensure active profile exists and has expiry date
- Check widget data in shared container: `SharedDataStore.loadWidgetData()`

### Widget not updating
- Verify timeline policy is set correctly
- Check system widget refresh limits (iOS limits background updates)
- Force reload: `WidgetCenter.shared.reloadAllTimelines()`

### App Groups data not syncing
- Confirm both app and widget have same App Group ID
- Check provisioning profiles include App Groups
- Verify UserDefaults(suiteName:) is using correct identifier

## Next Steps

### Phase 10 Implementation
- [x] Create widget extension files
- [x] Configure App Groups
- [x] Implement timeline provider
- [x] Create widget views (small, medium, lock)
- [x] Add widget sync to ProfileService
- [x] Update app launch to sync widget
- [ ] Test on device (requires proper provisioning)
- [ ] Test all widget sizes
- [ ] Verify midnight refresh

### Future Enhancements (Optional)
- Interactive widgets (iOS 17+) for quick actions
- Live Activities for renewal process tracking
- Multiple profiles support (switch active profile)
- Custom widget configuration (choose which profile to display)
