//
//  notification-scheduler-local-push.swift
//  ZairyuMate
//
//  Service for scheduling local push notifications for visa expiry reminders
//  Works offline without server connection - uses UNUserNotificationCenter
//

import Foundation
import UserNotifications

/// Manages local notification scheduling for visa expiry reminders
class NotificationScheduler {

    /// Shared singleton instance
    static let shared = NotificationScheduler()

    private init() {}

    // MARK: - Permission Management

    /// Request notification permission from user
    /// - Returns: Bool indicating if permission was granted
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print(granted ? "✅ Notification permission granted" : "❌ Notification permission denied")
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }

    /// Check current notification permission status
    /// - Returns: UNAuthorizationStatus
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Visa Expiry Reminders

    /// Schedule a single visa expiry reminder notification
    /// - Parameters:
    ///   - expiryDate: The visa expiry date
    ///   - daysBeforeExpiry: Number of days before expiry to fire notification
    ///   - profileName: Name of the profile for personalized message
    func scheduleVisaReminder(expiryDate: Date, daysBeforeExpiry: Int, profileName: String = "Your visa") {
        let calendar = Calendar.current

        // Calculate reminder date
        guard let reminderDate = calendar.date(byAdding: .day, value: -daysBeforeExpiry, to: expiryDate) else {
            print("❌ Failed to calculate reminder date")
            return
        }

        // Don't schedule past notifications
        if reminderDate < Date() {
            print("⚠️ Skipping past reminder for \(daysBeforeExpiry) days (date: \(reminderDate))")
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Visa Expiry Reminder"
        content.body = getReminderMessage(daysRemaining: daysBeforeExpiry, profileName: profileName)
        content.sound = .default
        content.badge = 1

        // Add category for actions (optional)
        content.categoryIdentifier = "VISA_REMINDER"

        // Create trigger for specific date at 9 AM
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // Create request with unique identifier
        let identifier = "visa-reminder-\(daysBeforeExpiry)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Schedule notification
        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled reminder: \(daysBeforeExpiry) days before expiry")
            }
        }
    }

    /// Get appropriate reminder message based on days remaining
    private func getReminderMessage(daysRemaining: Int, profileName: String) -> String {
        switch daysRemaining {
        case 90:
            return "Your visa expires in 3 months. Start preparing renewal documents."
        case 60:
            return "Your visa expires in 2 months. Gather tax certificates and required documents."
        case 30:
            return "Your visa expires in 1 month. Time to fill out renewal forms."
        case 14:
            return "Your visa expires in 2 weeks. Submit your renewal application soon."
        case 7:
            return "Your visa expires in 1 week! Ensure your renewal application is submitted."
        case 3:
            return "Urgent: Your visa expires in 3 days! Check application status."
        case 1:
            return "Critical: Your visa expires tomorrow! Contact immigration office if needed."
        default:
            return "Your visa expires in \(daysRemaining) days. Time to prepare for renewal."
        }
    }

    /// Schedule all standard visa expiry reminders for a profile
    /// - Parameters:
    ///   - expiryDate: The visa expiry date
    ///   - profileName: Name of the profile for personalized messages
    ///   - customDays: Optional array of custom reminder days (defaults to standard schedule)
    func scheduleAllReminders(expiryDate: Date, profileName: String, customDays: [Int]? = nil) {
        // Default reminder schedule: 90, 60, 30, 14, 7, 3, 1 days before
        let reminderDays = customDays ?? [90, 60, 30, 14, 7, 3, 1]

        print("📅 Scheduling \(reminderDays.count) reminders for \(profileName)")

        for days in reminderDays {
            scheduleVisaReminder(
                expiryDate: expiryDate,
                daysBeforeExpiry: days,
                profileName: profileName
            )
        }

        print("✅ All reminders scheduled for expiry: \(expiryDate)")
    }

    // MARK: - Notification Management

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        center.setBadgeCount(0)
        print("🗑️ All notifications cancelled")
    }

    /// Cancel specific visa reminder notification
    /// - Parameter daysBeforeExpiry: The reminder day to cancel
    func cancelVisaReminder(daysBeforeExpiry: Int) {
        let identifier = "visa-reminder-\(daysBeforeExpiry)"
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled reminder: \(daysBeforeExpiry) days")
    }

    /// Get list of all pending notification identifiers
    /// - Returns: Array of pending notification identifiers
    func getPendingNotifications() async -> [String] {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        return requests.map { $0.identifier }
    }

    /// Get count of pending notifications
    /// - Returns: Number of scheduled notifications
    func getPendingNotificationCount() async -> Int {
        let pending = await getPendingNotifications()
        return pending.count
    }

    // MARK: - Timeline Event Reminders

    /// Schedule notification for a timeline event
    /// - Parameters:
    ///   - eventTitle: Title of the timeline event
    ///   - eventDate: Date of the event
    ///   - eventId: Unique identifier for the event
    func scheduleTimelineEventReminder(eventTitle: String, eventDate: Date, eventId: String) {
        // Don't schedule past events
        guard eventDate > Date() else {
            print("⚠️ Skipping past timeline event: \(eventTitle)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Timeline Reminder"
        content.body = eventTitle
        content.sound = .default
        content.categoryIdentifier = "TIMELINE_EVENT"

        // Schedule for event date at 9 AM
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let identifier = "timeline-\(eventId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule timeline reminder: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled timeline reminder: \(eventTitle)")
            }
        }
    }

    /// Cancel timeline event notification
    /// - Parameter eventId: Unique identifier of the event
    func cancelTimelineEventReminder(eventId: String) {
        let identifier = "timeline-\(eventId)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled timeline reminder: \(eventId)")
    }
}
