//
//  widget-timeline-provider-data-loader.swift
//  ZairyuMateWidget
//
//  Timeline provider for countdown widget - loads data from shared storage
//  Schedules widget updates at midnight for accurate day countdown
//

import WidgetKit
import SwiftUI

/// Timeline provider that supplies countdown data to widget
struct CountdownProvider: TimelineProvider {

    /// Provides placeholder entry for widget gallery and initial load
    func placeholder(in context: Context) -> CountdownEntry {
        return .placeholder
    }

    /// Provides snapshot entry for quick display (e.g., widget gallery)
    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }

    /// Provides timeline of entries for widget updates
    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let currentEntry = loadCurrentEntry()

        // Schedule next update at midnight to refresh day count
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)

        // Create timeline with single entry, updating at midnight
        let timeline = Timeline(entries: [currentEntry], policy: .after(midnight))

        completion(timeline)
    }

    /// Load current countdown entry from shared data store
    private func loadCurrentEntry() -> CountdownEntry {
        // Attempt to load widget data from App Groups
        guard let widgetData = SharedDataStore.loadWidgetData() else {
            print("⚠️ Widget: No data available, showing empty state")
            return .empty
        }

        // Calculate days remaining
        let daysRemaining = calculateDaysRemaining(until: widgetData.expiryDate)

        // Create entry with loaded data
        let entry = CountdownEntry(
            date: Date(),
            profileName: widgetData.profileName,
            visaType: widgetData.visaType,
            expiryDate: widgetData.expiryDate,
            daysRemaining: daysRemaining
        )

        return entry
    }

    /// Calculate days remaining until expiry date
    private func calculateDaysRemaining(until expiryDate: Date) -> Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let expiry = calendar.startOfDay(for: expiryDate)

        let components = calendar.dateComponents([.day], from: now, to: expiry)
        return max(0, components.day ?? 0)
    }
}
