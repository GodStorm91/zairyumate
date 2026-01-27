//
//  profile-core-data-properties.swift
//  ZairyuMate
//
//  Core Data generated properties for Profile entity
//  Managed by Core Data - defines attributes and relationships
//

import Foundation
import CoreData

extension Profile {

    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var nameKatakana: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var nationality: String?
    @NSManaged public var address: String?
    @NSManaged public var cardNumber: String?
    @NSManaged public var cardExpiry: Date?
    @NSManaged public var visaType: String?
    @NSManaged public var passportNumber: String?
    @NSManaged public var passportExpiry: Date?
    @NSManaged public var photoData: Data?
    @NSManaged public var relationship: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var documents: NSSet?
    @NSManaged public var timelineEvents: NSSet?

}

// MARK: - Relationship Accessors

extension Profile {

    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: Document)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: Document)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)

    @objc(addTimelineEventsObject:)
    @NSManaged public func addToTimelineEvents(_ value: TimelineEvent)

    @objc(removeTimelineEventsObject:)
    @NSManaged public func removeFromTimelineEvents(_ value: TimelineEvent)

    @objc(addTimelineEvents:)
    @NSManaged public func addToTimelineEvents(_ values: NSSet)

    @objc(removeTimelineEvents:)
    @NSManaged public func removeFromTimelineEvents(_ values: NSSet)

}

// MARK: - Type-safe Accessors

extension Profile {

    /// Type-safe documents array
    var documentsArray: [Document] {
        let set = documents as? Set<Document> ?? []
        return set.sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
    }

    /// Type-safe timeline events array
    var timelineEventsArray: [TimelineEvent] {
        let set = timelineEvents as? Set<TimelineEvent> ?? []
        return set.sorted { $0.eventDate < $1.eventDate }
    }

    /// Active (incomplete) timeline events
    var activeTimelineEvents: [TimelineEvent] {
        return timelineEventsArray.filter { !$0.isCompleted }
    }

    /// Completed timeline events
    var completedTimelineEvents: [TimelineEvent] {
        return timelineEventsArray.filter { $0.isCompleted }
    }
}

extension Profile: Identifiable {}
