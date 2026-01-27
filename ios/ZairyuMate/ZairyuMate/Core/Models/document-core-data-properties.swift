//
//  document-core-data-properties.swift
//  ZairyuMate
//
//  Core Data generated properties for Document entity
//

import Foundation
import CoreData

extension Document {

    @NSManaged public var id: UUID?
    @NSManaged public var documentType: String?
    @NSManaged public var status: String?
    @NSManaged public var pdfData: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var submittedAt: Date?
    @NSManaged public var profile: Profile?

}

extension Document: Identifiable {}
