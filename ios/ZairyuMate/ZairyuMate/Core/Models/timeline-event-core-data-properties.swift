//
//  timeline-event-core-data-properties.swift
//  ZairyuMate
//
//  Core Data generated properties for TimelineEvent entity
//

import Foundation
import CoreData

extension TimelineEvent {

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var eventDate: Date
    @NSManaged public var eventType: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var notificationId: String?
    @NSManaged public var profile: Profile?

}

extension TimelineEvent: Identifiable {}
