//
//  timeline-generator-smart-reminders.swift
//  ZairyuMate
//
//  Generates smart timeline events for visa renewal process
//  Creates structured reminder sequence based on expiry date
//

import Foundation
import CoreData

/// Generates timeline events for visa renewal workflow
struct TimelineGenerator {

    /// Generate complete timeline for visa renewal process
    /// - Parameters:
    ///   - profile: Profile with visa expiry date
    ///   - context: Core Data managed object context
    /// - Returns: Array of generated timeline events
    static func generateTimeline(for profile: Profile, in context: NSManagedObjectContext) -> [TimelineEvent] {
        guard let expiryDate = profile.cardExpiry else {
            print("⚠️ No expiry date for profile, cannot generate timeline")
            return []
        }

        var events: [TimelineEvent] = []
        let calendar = Calendar.current

        // 3 months before: Get tax certificate (課税証明書)
        if let date = calendar.date(byAdding: .month, value: -3, to: expiryDate) {
            let event = createTimelineEvent(
                title: "Get tax certificate (課税証明書)",
                description: "Visit city hall to obtain your tax payment certificate. Required for visa renewal application.",
                eventDate: date,
                eventType: "document",
                profile: profile,
                context: context
            )
            events.append(event)
        }

        // 2.5 months before: Get residence certificate (住民票)
        if let date = calendar.date(byAdding: .day, value: -75, to: expiryDate) {
            let event = createTimelineEvent(
                title: "Get residence certificate (住民票)",
                description: "Obtain your residence certificate from city hall. Must be issued within 3 months of application.",
                eventDate: date,
                eventType: "document",
                profile: profile,
                context: context
            )
            events.append(event)
        }

        // 2 months before: Gather employment documents
        if let date = calendar.date(byAdding: .month, value: -2, to: expiryDate) {
            let event = createTimelineEvent(
                title: "Gather employment documents",
                description: "Collect employment certificate, salary slips (last 3 months), and company registration certificate.",
                eventDate: date,
                eventType: "document",
                profile: profile,
                context: context
            )
            events.append(event)
        }

        // 1.5 months before: Prepare photos
        if let date = calendar.date(byAdding: .day, value: -45, to: expiryDate) {
            let event = createTimelineEvent(
                title: "Take passport photos",
                description: "Get passport-sized photos (4cm x 3cm). Need 1-2 recent photos taken within 3 months.",
                eventDate: date,
                eventType: "document",
                profile: profile,
                context: context
            )
            events.append(event)
        }

        // 1 month before: Fill application forms
        if let date = calendar.date(byAdding: .month, value: -1, to: expiryDate) {
            let event = createTimelineEvent(
                title: "Fill visa renewal forms",
                description: "Complete application form for extension of period of stay. Double-check all information.",
                eventDate: date,
                eventType: "form",
                profile: profile,
                context: context
            )
            events.append(event)
        }

        // 3 weeks before: Review and organize documents
        if let date = calendar.date(byAdding: .day, value: -21, to: expiryDate) {
            let event = createTimelineEvent(
                title: "Review all documents",
                description: "Organize all documents, make copies, and verify nothing is missing before submission.",
                eventDate: date,
                eventType: "reminder",
                profile: profile,
                context: context
            )
            events.append(event)
        }

        // 2 weeks before: Submit application (DEADLINE)
        if let date = calendar.date(byAdding: .day, value: -14, to: expiryDate) {
            let event = createTimelineEvent(
                title: "Submit renewal application",
                description: "Visit immigration bureau to submit your application. Bring original documents and copies. Application fee: ¥4,000.",
                eventDate: date,
                eventType: "deadline",
                profile: profile,
                context: context
            )
            events.append(event)
        }

        // 1 week before: Follow up if not submitted
        if let date = calendar.date(byAdding: .day, value: -7, to: expiryDate) {
            let event = createTimelineEvent(
                title: "Follow up on application",
                description: "If you haven't received notification, contact immigration to check application status.",
                eventDate: date,
                eventType: "reminder",
                profile: profile,
                context: context
            )
            events.append(event)
        }

        print("✅ Generated \(events.count) timeline events for \(profile.name)")
        return events
    }

    /// Generate timeline events based on custom visa type
    /// - Parameters:
    ///   - visaType: Type of visa (affects required documents)
    ///   - expiryDate: Visa expiry date
    ///   - profile: Profile object
    ///   - context: Core Data context
    /// - Returns: Array of timeline events customized for visa type
    static func generateTimelineForVisaType(
        _ visaType: String,
        expiryDate: Date,
        profile: Profile,
        in context: NSManagedObjectContext
    ) -> [TimelineEvent] {
        // Start with standard timeline
        var events = generateTimeline(for: profile, in: context)

        // Add visa-type specific events
        let calendar = Calendar.current

        switch visaType.lowercased() {
        case _ where visaType.contains("Spouse"):
            // Spouse visa requires additional documents
            if let date = calendar.date(byAdding: .month, value: -2, to: expiryDate) {
                let event = createTimelineEvent(
                    title: "Get spouse's documents",
                    description: "Collect spouse's residence certificate, income certificate, and employment documents.",
                    eventDate: date,
                    eventType: "document",
                    profile: profile,
                    context: context
                )
                events.append(event)
            }

        case _ where visaType.contains("Student"):
            // Student visa requires school documents
            if let date = calendar.date(byAdding: .month, value: -2, to: expiryDate) {
                let event = createTimelineEvent(
                    title: "Get school documents",
                    description: "Obtain enrollment certificate and attendance record from your school.",
                    eventDate: date,
                    eventType: "document",
                    profile: profile,
                    context: context
                )
                events.append(event)
            }

        case _ where visaType.contains("Business Manager"):
            // Business manager requires company documents
            if let date = calendar.date(byAdding: .month, value: -2, to: expiryDate) {
                let event = createTimelineEvent(
                    title: "Get company financial statements",
                    description: "Prepare company tax returns, financial statements, and business plan documents.",
                    eventDate: date,
                    eventType: "document",
                    profile: profile,
                    context: context
                )
                events.append(event)
            }

        default:
            // Standard work visa - no additional events needed
            break
        }

        return events.sorted { $0.eventDate < $1.eventDate }
    }

    /// Create a timeline event entity
    private static func createTimelineEvent(
        title: String,
        description: String,
        eventDate: Date,
        eventType: String,
        profile: Profile,
        context: NSManagedObjectContext
    ) -> TimelineEvent {
        let event = TimelineEvent(context: context)
        event.id = UUID()
        event.title = title
        event.eventDescription = description
        event.eventDate = eventDate
        event.eventType = eventType
        event.isCompleted = false
        event.createdAt = Date()
        event.profile = profile

        return event
    }

    /// Generate quick reminders for urgent situations (< 30 days to expiry)
    /// - Parameters:
    ///   - daysRemaining: Days until expiry
    ///   - profile: Profile object
    ///   - context: Core Data context
    /// - Returns: Array of urgent timeline events
    static func generateUrgentTimeline(
        daysRemaining: Int,
        profile: Profile,
        in context: NSManagedObjectContext
    ) -> [TimelineEvent] {
        guard let expiryDate = profile.cardExpiry else { return [] }

        var events: [TimelineEvent] = []
        let calendar = Calendar.current

        if daysRemaining <= 30 && daysRemaining > 14 {
            // Urgent: Less than 30 days
            if let date = calendar.date(byAdding: .day, value: -14, to: expiryDate) {
                let event = createTimelineEvent(
                    title: "URGENT: Submit application NOW",
                    description: "You have less than 30 days. Gather all documents immediately and submit application.",
                    eventDate: date,
                    eventType: "deadline",
                    profile: profile,
                    context: context
                )
                events.append(event)
            }
        } else if daysRemaining <= 14 {
            // Critical: Less than 14 days
            if let date = calendar.date(byAdding: .day, value: -7, to: expiryDate) {
                let event = createTimelineEvent(
                    title: "CRITICAL: Contact immigration office",
                    description: "Contact immigration office immediately. You may need to explain late application.",
                    eventDate: date,
                    eventType: "deadline",
                    profile: profile,
                    context: context
                )
                events.append(event)
            }
        }

        return events
    }

    /// Delete all timeline events for a profile
    /// - Parameters:
    ///   - profile: Profile to clear timeline for
    ///   - context: Core Data context
    static func clearTimeline(for profile: Profile, in context: NSManagedObjectContext) {
        if let events = profile.timelineEvents as? Set<TimelineEvent> {
            for event in events {
                context.delete(event)
            }
            print("🗑️ Cleared \(events.count) timeline events for \(profile.name)")
        }
    }

    /// Regenerate timeline (clear and create new)
    /// - Parameters:
    ///   - profile: Profile to regenerate timeline for
    ///   - context: Core Data context
    /// - Returns: New timeline events
    @discardableResult
    static func regenerateTimeline(for profile: Profile, in context: NSManagedObjectContext) -> [TimelineEvent] {
        clearTimeline(for: profile, in: context)
        let events = generateTimeline(for: profile, in: context)

        do {
            try context.save()
            print("✅ Timeline regenerated and saved")
        } catch {
            print("❌ Failed to save regenerated timeline: \(error.localizedDescription)")
        }

        return events
    }
}
