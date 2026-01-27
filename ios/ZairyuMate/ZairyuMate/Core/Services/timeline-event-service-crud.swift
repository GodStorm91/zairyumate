//
//  timeline-event-service-crud.swift
//  ZairyuMate
//
//  Timeline event service for CRUD operations with async/await
//  Manages visa deadlines, reminders, and milestone tracking
//

import Foundation
import CoreData

/// Service for managing TimelineEvent entities
@MainActor
class TimelineEventService {

    // MARK: - Properties

    private let persistenceController: PersistenceController
    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Create

    /// Create a new timeline event
    /// - Parameters:
    ///   - profile: Associated profile
    ///   - title: Event title/description
    ///   - eventDate: When the event occurs
    ///   - eventType: Type (reminder, milestone, deadline)
    ///   - isCompleted: Completion status (defaults to false)
    /// - Returns: Created timeline event
    /// - Throws: Core Data save errors
    func create(
        for profile: Profile,
        title: String,
        eventDate: Date,
        eventType: String = "reminder",
        isCompleted: Bool = false
    ) async throws -> TimelineEvent {
        let event = TimelineEvent(context: viewContext)

        event.profile = profile
        event.title = title
        event.eventDate = eventDate
        event.eventType = eventType
        event.isCompleted = isCompleted

        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Created timeline event: \(title)")
        #endif

        return event
    }

    // MARK: - Read

    /// Fetch all timeline events
    /// - Returns: Array of all events sorted by event date
    /// - Throws: Core Data fetch errors
    func fetchAll() async throws -> [TimelineEvent] {
        let request = TimelineEvent.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimelineEvent.eventDate, ascending: true)]

        return try viewContext.fetch(request)
    }

    /// Fetch events for specific profile
    /// - Parameter profile: Profile to fetch events for
    /// - Returns: Array of events for profile
    /// - Throws: Core Data fetch errors
    func fetch(for profile: Profile) async throws -> [TimelineEvent] {
        let request = TimelineEvent.fetchRequest(for: profile)
        return try viewContext.fetch(request)
    }

    /// Fetch event by ID
    /// - Parameter id: Event UUID
    /// - Returns: Event if found
    /// - Throws: Core Data fetch errors
    func fetch(id: UUID) async throws -> TimelineEvent? {
        let request = TimelineEvent.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try viewContext.fetch(request).first
    }

    /// Fetch upcoming events (not completed, future dates)
    /// - Returns: Array of upcoming events
    /// - Throws: Core Data fetch errors
    func fetchUpcoming() async throws -> [TimelineEvent] {
        let request = TimelineEvent.upcomingEventsRequest()
        return try viewContext.fetch(request)
    }

    /// Fetch overdue events (not completed, past dates)
    /// - Returns: Array of overdue events
    /// - Throws: Core Data fetch errors
    func fetchOverdue() async throws -> [TimelineEvent] {
        let request = TimelineEvent.overdueEventsRequest()
        return try viewContext.fetch(request)
    }

    /// Fetch completed events
    /// - Returns: Array of completed events
    /// - Throws: Core Data fetch errors
    func fetchCompleted() async throws -> [TimelineEvent] {
        let request = TimelineEvent.completedEventsRequest()
        return try viewContext.fetch(request)
    }

    /// Fetch events by type
    /// - Parameter type: Event type (reminder, milestone, deadline)
    /// - Returns: Array of matching events
    /// - Throws: Core Data fetch errors
    func fetchByType(_ type: String) async throws -> [TimelineEvent] {
        let request = TimelineEvent.fetchRequest()
        request.predicate = NSPredicate(format: "eventType == %@", type)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimelineEvent.eventDate, ascending: true)]

        return try viewContext.fetch(request)
    }

    /// Fetch events in date range
    /// - Parameters:
    ///   - startDate: Range start date
    ///   - endDate: Range end date
    /// - Returns: Array of events in range
    /// - Throws: Core Data fetch errors
    func fetch(from startDate: Date, to endDate: Date) async throws -> [TimelineEvent] {
        let request = TimelineEvent.fetchRequest()
        request.predicate = NSPredicate(format: "eventDate >= %@ AND eventDate <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimelineEvent.eventDate, ascending: true)]

        return try viewContext.fetch(request)
    }

    /// Fetch events for today
    /// - Returns: Array of today's events
    /// - Throws: Core Data fetch errors
    func fetchToday() async throws -> [TimelineEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        return try await fetch(from: startOfDay, to: endOfDay)
    }

    // MARK: - Update

    /// Update event
    /// - Parameter event: Event to update
    /// - Throws: Core Data save errors
    func update(_ event: TimelineEvent) async throws {
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Updated timeline event: \(event.title ?? "")")
        #endif
    }

    /// Update event date
    /// - Parameters:
    ///   - event: Event to update
    ///   - newDate: New event date
    /// - Throws: Core Data save errors
    func updateEventDate(_ event: TimelineEvent, newDate: Date) async throws {
        event.updateEventDate(newDate)
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Updated event date")
        #endif
    }

    // MARK: - Delete

    /// Delete event
    /// - Parameter event: Event to delete
    /// - Throws: Core Data save errors
    func delete(_ event: TimelineEvent) async throws {
        viewContext.delete(event)
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Deleted timeline event: \(event.title ?? "")")
        #endif
    }

    /// Delete multiple events
    /// - Parameter events: Array of events to delete
    /// - Throws: Core Data save errors
    func delete(_ events: [TimelineEvent]) async throws {
        for event in events {
            viewContext.delete(event)
        }
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Deleted \(events.count) timeline events")
        #endif
    }

    /// Delete all events for a profile
    /// - Parameter profile: Profile whose events should be deleted
    /// - Throws: Core Data save errors
    func deleteAll(for profile: Profile) async throws {
        let events = try await fetch(for: profile)
        try await delete(events)
    }

    /// Delete completed events
    /// - Throws: Core Data save errors
    func deleteCompleted() async throws {
        let events = try await fetchCompleted()
        try await delete(events)

        #if DEBUG
        print("✅ Deleted completed events")
        #endif
    }

    // MARK: - Completion Management

    /// Mark event as completed
    /// - Parameter event: Event to mark as completed
    /// - Throws: Core Data save errors
    func markAsCompleted(_ event: TimelineEvent) async throws {
        event.markAsCompleted()
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Marked event as completed")
        #endif
    }

    /// Reopen completed event
    /// - Parameter event: Event to reopen
    /// - Throws: Core Data save errors
    func reopenEvent(_ event: TimelineEvent) async throws {
        event.reopenEvent()
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Reopened event")
        #endif
    }

    /// Mark multiple events as completed
    /// - Parameter events: Events to mark as completed
    /// - Throws: Core Data save errors
    func markAsCompleted(_ events: [TimelineEvent]) async throws {
        for event in events {
            event.markAsCompleted()
        }
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Marked \(events.count) events as completed")
        #endif
    }

    // MARK: - Statistics

    /// Get event count
    /// - Returns: Total number of events
    /// - Throws: Core Data fetch errors
    func count() async throws -> Int {
        let request = TimelineEvent.fetchRequest()
        return try viewContext.count(for: request)
    }

    /// Get count of upcoming events
    /// - Returns: Count of upcoming events
    /// - Throws: Core Data fetch errors
    func countUpcoming() async throws -> Int {
        let request = TimelineEvent.upcomingEventsRequest()
        return try viewContext.count(for: request)
    }

    /// Get count of overdue events
    /// - Returns: Count of overdue events
    /// - Throws: Core Data fetch errors
    func countOverdue() async throws -> Int {
        let request = TimelineEvent.overdueEventsRequest()
        return try viewContext.count(for: request)
    }

    /// Get count of completed events
    /// - Returns: Count of completed events
    /// - Throws: Core Data fetch errors
    func countCompleted() async throws -> Int {
        let request = TimelineEvent.completedEventsRequest()
        return try viewContext.count(for: request)
    }

    /// Get event count for profile
    /// - Parameter profile: Profile to count events for
    /// - Returns: Count of events
    /// - Throws: Core Data fetch errors
    func count(for profile: Profile) async throws -> Int {
        let request = TimelineEvent.fetchRequest()
        request.predicate = NSPredicate(format: "profile == %@", profile)
        return try viewContext.count(for: request)
    }

    // MARK: - Auto-generation Helpers

    /// Generate automatic timeline events for profile based on visa expiry
    /// - Parameter profile: Profile to generate events for
    /// - Throws: Core Data save errors
    func generateAutoEvents(for profile: Profile) async throws {
        guard let cardExpiry = profile.cardExpiry else { return }

        // Delete existing auto-generated events for this profile
        let existingEvents = try await fetch(for: profile)
        let autoEvents = existingEvents.filter { $0.eventType == "reminder" }
        try await delete(autoEvents)

        // 3 months before expiry: Start gathering documents
        if let threeMonthsBefore = Calendar.current.date(byAdding: .month, value: -3, to: cardExpiry) {
            _ = try await create(
                for: profile,
                title: "Start preparing renewal documents",
                eventDate: threeMonthsBefore,
                eventType: "reminder"
            )
        }

        // 1 month before expiry: Submit application
        if let oneMonthBefore = Calendar.current.date(byAdding: .month, value: -1, to: cardExpiry) {
            _ = try await create(
                for: profile,
                title: "Submit visa renewal application",
                eventDate: oneMonthBefore,
                eventType: "deadline"
            )
        }

        // Expiry date: Milestone
        _ = try await create(
            for: profile,
            title: "Visa expiry date",
            eventDate: cardExpiry,
            eventType: "milestone"
        )

        #if DEBUG
        print("✅ Generated auto events for profile: \(profile.name)")
        #endif
    }
}
