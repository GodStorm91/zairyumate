//
//  document-core-data-model.swift
//  ZairyuMate
//
//  Document entity for storing visa application forms and PDFs
//  Tracks document status through lifecycle: draft -> completed -> submitted
//

import Foundation
import CoreData

@objc(Document)
public class Document: NSManagedObject {

    // MARK: - Computed Properties

    /// Display name for document type
    var documentTypeDisplayName: String {
        switch documentType ?? "" {
        case "extension":
            return "Extension of Period of Stay"
        case "change":
            return "Change of Status of Residence"
        case "permanent":
            return "Permanent Residence Application"
        case "reentry":
            return "Re-entry Permit"
        default:
            return documentType ?? "Unknown"
        }
    }

    /// Status display name with localization support
    var statusDisplayName: String {
        switch status ?? "draft" {
        case "draft":
            return "Draft"
        case "completed":
            return "Completed"
        case "submitted":
            return "Submitted"
        default:
            return status ?? "Unknown"
        }
    }

    /// Check if document has PDF data
    var hasPdfData: Bool {
        return pdfData != nil && (pdfData?.count ?? 0) > 0
    }

    /// File size in human-readable format
    var pdfFileSizeFormatted: String? {
        guard let data = pdfData else { return nil }
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(data.count))
    }

    /// Days since creation
    var daysSinceCreation: Int? {
        guard let created = createdAt else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: created, to: Date())
        return components.day
    }

    /// Check if document is in draft state
    var isDraft: Bool {
        return status == "draft"
    }

    /// Check if document is completed
    var isCompleted: Bool {
        return status == "completed"
    }

    /// Check if document is submitted
    var isSubmitted: Bool {
        return status == "submitted"
    }

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdAt")
        setPrimitiveValue("draft", forKey: "status")
        setPrimitiveValue("extension", forKey: "documentType")
    }

    // MARK: - Validation

    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateDocument()
    }

    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateDocument()
    }

    private func validateDocument() throws {
        // Document type is required
        let validTypes = ["extension", "change", "permanent", "reentry"]
        if let type = documentType, !validTypes.contains(type) {
            throw ValidationError.invalidValue("documentType", type)
        }

        // Status is required
        let validStatuses = ["draft", "completed", "submitted"]
        if let statusValue = status, !validStatuses.contains(statusValue) {
            throw ValidationError.invalidValue("status", statusValue)
        }

        // Submitted date requires completed/submitted status
        if submittedAt != nil && status == "draft" {
            throw ValidationError.invalidValue("submittedAt", "Cannot have submission date in draft status")
        }
    }

    // MARK: - Status Management

    /// Mark document as completed
    func markAsCompleted() {
        status = "completed"
    }

    /// Mark document as submitted
    /// - Parameter date: Submission date (defaults to now)
    func markAsSubmitted(date: Date = Date()) {
        status = "submitted"
        submittedAt = date
    }

    /// Revert to draft status
    func revertToDraft() {
        status = "draft"
        submittedAt = nil
    }

    // MARK: - Export

    /// Export document metadata as dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["id"] = id?.uuidString
        dict["documentType"] = documentType
        dict["status"] = status
        dict["createdAt"] = createdAt?.timeIntervalSince1970
        dict["submittedAt"] = submittedAt?.timeIntervalSince1970
        dict["profileId"] = profile?.id?.uuidString
        dict["hasPdfData"] = hasPdfData
        dict["pdfSize"] = pdfData?.count
        return dict
    }
}

// MARK: - Fetch Request

extension Document {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Document> {
        return NSFetchRequest<Document>(entityName: "Document")
    }

    /// Fetch documents for specific profile
    static func fetchRequest(for profile: Profile) -> NSFetchRequest<Document> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.createdAt, ascending: false)]
        return request
    }

    /// Fetch documents by status
    static func fetchRequest(status: String) -> NSFetchRequest<Document> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", status)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.createdAt, ascending: false)]
        return request
    }
}
