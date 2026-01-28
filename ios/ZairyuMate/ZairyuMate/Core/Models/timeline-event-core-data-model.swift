//
//  timeline-event-core-data-model.swift
//  ZairyuMate
//
//  Timeline event entity for visa deadlines, reminders, and milestones
//  Integrates with local notifications for proactive deadline management
//

import Foundation
import CoreData

@objc(TimelineEvent)
public class TimelineEvent: NSManagedObject {

    // MARK: - Computed Properties

    /// Event type display name
    var eventTypeDisplayName: String {
        switch eventType ?? "reminder" {
        case "reminder":
            return "Reminder"
        case "milestone":
            return "Milestone"
        case "deadline":
            return "Deadline"
        default:
            return eventType ?? "Event"
        }
    }

    /// Check if event is overdue
    var isOverdue: Bool {
        guard !isCompleted, let eventDate = eventDate else { return false }
        return eventDate < Date()
    }

    /// Check if event is today
    var isToday: Bool {
        guard let eventDate = eventDate else { return false }
        let calendar = Calendar.current
        return calendar.isDateInToday(eventDate)
    }

    /// Check if event is upcoming (within next 7 days)
    var isUpcoming: Bool {
        guard !isCompleted && !isOverdue, let eventDate = eventDate else { return false }
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return eventDate <= sevenDaysFromNow
    }

    /// Days until event
    var daysUntilEvent: Int? {
        guard let eventDate = eventDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: eventDate)
        return components.day
    }

    /// Formatted event date string
    var formattedEventDate: String {
        guard let eventDate = eventDate else { return "No date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: eventDate)
    }

    /// Relative date string (e.g., "Tomorrow", "In 3 days")
    var relativeDateString: String {
        guard let eventDate = eventDate else { return "No date" }
        let calendar = Calendar.current

        if calendar.isDateInToday(eventDate) {
            return "Today"
        }

        if calendar.isDateInTomorrow(eventDate) {
            return "Tomorrow"
        }

        if calendar.isDateInYesterday(eventDate) {
            return "Yesterday"
        }

        if let days = daysUntilEvent {
            if days > 0 {
                return "In \(days) day\(days == 1 ? "" : "s")"
            } else if days < 0 {
                return "\(abs(days)) day\(abs(days) == 1 ? "" : "s") ago"
            }
        }

        return formattedEventDate
    }

    /// Priority level based on type and date
    var priorityLevel: Int {
        if isOverdue { return 3 } // High
        if eventType == "deadline" && isUpcoming { return 2 } // Medium-high
        if isToday { return 2 }
        if isUpcoming { return 1 } // Medium
        return 0 // Low
    }

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "eventDate")
        setPrimitiveValue("reminder", forKey: "eventType")
        setPrimitiveValue(false, forKey: "isCompleted")
    }

    // MARK: - Validation

    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateEvent()
    }

    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateEvent()
    }

    private func validateEvent() throws {
        // Title is required
        if let titleValue = title, titleValue.isEmpty {
            throw ValidationError.missingRequiredField("title")
        }

        // Event type must be valid
        let validTypes = ["reminder", "milestone", "deadline"]
        if let type = eventType, !validTypes.contains(type) {
            throw ValidationError.invalidValue("eventType", type)
        }
    }

    // MARK: - Event Management

    /// Mark event as completed
    func markAsCompleted() {
        isCompleted = true

        // Cancel notification if exists
        if let notifId = notificationId {
            cancelNotification(notifId)
        }
    }

    /// Reopen completed event
    func reopenEvent() {
        isCompleted = false

        // Re-schedule notification if needed
        if let eventDate = eventDate, eventDate > Date() {
            scheduleNotification()
        }
    }

    /// Update event date and reschedule notification
    func updateEventDate(_ newDate: Date) {
        eventDate = newDate

        // Cancel old notification
        if let notifId = notificationId {
            cancelNotification(notifId)
        }

        // Schedule new notification if not completed and date is future
        if !isCompleted && newDate > Date() {
            scheduleNotification()
        }
    }

    // MARK: - Notification Management

    /// Schedule local notification for this event
    private func scheduleNotification() {
        // Notification scheduling will be implemented in Phase 04 (Scheduler)
        // For now, just generate a notification ID
        notificationId = "event.\(id?.uuidString ?? UUID().uuidString)"
    }

    /// Cancel local notification
    private func cancelNotification(_ notificationId: String) {
        // Notification cancellation will be implemented in Phase 04
        // This is a placeholder
    }

    // MARK: - Export

    /// Export event as dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["id"] = id?.uuidString
        dict["title"] = title
        dict["eventDate"] = eventDate?.timeIntervalSince1970
        dict["eventType"] = eventType
        dict["isCompleted"] = isCompleted
        dict["notificationId"] = notificationId
        dict["profileId"] = profile?.id?.uuidString
        return dict
    }
}

// MARK: - Fetch Request

extension TimelineEvent {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimelineEvent> {
        return NSFetchRequest<TimelineEvent>(entityName: "TimelineEvent")
    }

    /// Fetch events for specific profile
    static func fetchRequest(for profile: Profile) -> NSFetchRequest<TimelineEvent> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimelineEvent.eventDate, ascending: true)]
        return request
    }

    /// Fetch upcoming events (not completed, future dates)
    static func upcomingEventsRequest() -> NSFetchRequest<TimelineEvent> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO AND eventDate >= %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimelineEvent.eventDate, ascending: true)]
        return request
    }

    /// Fetch overdue events (not completed, past dates)
    static func overdueEventsRequest() -> NSFetchRequest<TimelineEvent> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO AND eventDate < %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimelineEvent.eventDate, ascending: true)]
        return request
    }

    /// Fetch completed events
    static func completedEventsRequest() -> NSFetchRequest<TimelineEvent> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimelineEvent.eventDate, ascending: false)]
        return request
    }
}
