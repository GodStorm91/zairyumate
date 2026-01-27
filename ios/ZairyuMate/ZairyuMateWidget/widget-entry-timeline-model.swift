//
//  widget-entry-timeline-model.swift
//  ZairyuMateWidget
//
//  Timeline entry model for countdown widget display
//  Contains profile data snapshot for widget rendering
//

import WidgetKit

/// Timeline entry containing visa countdown data for widget display
struct CountdownEntry: TimelineEntry {
    /// Time this entry becomes relevant
    let date: Date

    /// Profile display name
    let profileName: String

    /// Visa type (e.g., "Engineer/Specialist", "Permanent Resident")
    let visaType: String

    /// Card expiry date
    let expiryDate: Date

    /// Days remaining until expiry
    let daysRemaining: Int

    /// Color indicator based on days remaining
    var urgencyColor: String {
        if daysRemaining <= 7 {
            return "red"
        } else if daysRemaining <= 30 {
            return "orange"
        } else if daysRemaining <= 60 {
            return "yellow"
        } else {
            return "green"
        }
    }

    /// Formatted expiry date string (yyyy/MM/dd)
    var formattedExpiryDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: expiryDate)
    }

    /// Placeholder entry for widget preview
    static var placeholder: CountdownEntry {
        CountdownEntry(
            date: Date(),
            profileName: "John Doe",
            visaType: "Engineer/Specialist",
            expiryDate: Calendar.current.date(byAdding: .day, value: 89, to: Date())!,
            daysRemaining: 89
        )
    }

    /// Empty state entry when no profile exists
    static var empty: CountdownEntry {
        CountdownEntry(
            date: Date(),
            profileName: "No Profile",
            visaType: "Add profile in app",
            expiryDate: Date(),
            daysRemaining: 0
        )
    }
}
