//
//  document-service-crud.swift
//  ZairyuMate
//
//  Document service for CRUD operations with async/await
//  Manages visa application documents and PDF generation workflow
//

import Foundation
import CoreData

/// Service for managing Document entities
@MainActor
class DocumentService {

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

    /// Create a new document
    /// - Parameters:
    ///   - profile: Associated profile
    ///   - documentType: Type of document (extension, change, permanent, reentry)
    ///   - status: Initial status (defaults to draft)
    ///   - pdfData: Optional PDF data
    /// - Returns: Created document
    /// - Throws: Core Data save errors
    func create(
        for profile: Profile,
        documentType: String,
        status: String = "draft",
        pdfData: Data? = nil
    ) async throws -> Document {
        let document = Document(context: viewContext)

        document.profile = profile
        document.documentType = documentType
        document.status = status
        document.pdfData = pdfData

        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Created document: \(documentType) for \(profile.name)")
        #endif

        return document
    }

    // MARK: - Read

    /// Fetch all documents
    /// - Returns: Array of all documents sorted by creation date
    /// - Throws: Core Data fetch errors
    func fetchAll() async throws -> [Document] {
        let request = Document.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.createdAt, ascending: false)]

        return try viewContext.fetch(request)
    }

    /// Fetch documents for specific profile
    /// - Parameter profile: Profile to fetch documents for
    /// - Returns: Array of documents for profile
    /// - Throws: Core Data fetch errors
    func fetch(for profile: Profile) async throws -> [Document] {
        let request = Document.fetchRequest(for: profile)
        return try viewContext.fetch(request)
    }

    /// Fetch document by ID
    /// - Parameter id: Document UUID
    /// - Returns: Document if found
    /// - Throws: Core Data fetch errors
    func fetch(id: UUID) async throws -> Document? {
        let request = Document.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try viewContext.fetch(request).first
    }

    /// Fetch documents by status
    /// - Parameter status: Document status (draft, completed, submitted)
    /// - Returns: Array of matching documents
    /// - Throws: Core Data fetch errors
    func fetchByStatus(_ status: String) async throws -> [Document] {
        let request = Document.fetchRequest(status: status)
        return try viewContext.fetch(request)
    }

    /// Fetch documents by type
    /// - Parameter type: Document type
    /// - Returns: Array of matching documents
    /// - Throws: Core Data fetch errors
    func fetchByType(_ type: String) async throws -> [Document] {
        let request = Document.fetchRequest()
        request.predicate = NSPredicate(format: "documentType == %@", type)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.createdAt, ascending: false)]

        return try viewContext.fetch(request)
    }

    /// Fetch recent documents (last 10)
    /// - Returns: Array of recent documents
    /// - Throws: Core Data fetch errors
    func fetchRecent(limit: Int = 10) async throws -> [Document] {
        let request = Document.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Document.createdAt, ascending: false)]
        request.fetchLimit = limit

        return try viewContext.fetch(request)
    }

    // MARK: - Update

    /// Update document
    /// - Parameter document: Document to update
    /// - Throws: Core Data save errors
    func update(_ document: Document) async throws {
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Updated document: \(document.documentTypeDisplayName)")
        #endif
    }

    /// Update document PDF data
    /// - Parameters:
    ///   - document: Document to update
    ///   - pdfData: New PDF data
    /// - Throws: Core Data save errors
    func updatePdfData(_ document: Document, pdfData: Data) async throws {
        document.pdfData = pdfData
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Updated PDF data for document: \(document.documentTypeDisplayName)")
        #endif
    }

    /// Update document status
    /// - Parameters:
    ///   - document: Document to update
    ///   - status: New status
    /// - Throws: Core Data save errors
    func updateStatus(_ document: Document, status: String) async throws {
        document.status = status

        // Update submitted date if marking as submitted
        if status == "submitted" && document.submittedAt == nil {
            document.submittedAt = Date()
        }

        // Clear submitted date if reverting to draft
        if status == "draft" {
            document.submittedAt = nil
        }

        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Updated document status to: \(status)")
        #endif
    }

    // MARK: - Delete

    /// Delete document
    /// - Parameter document: Document to delete
    /// - Throws: Core Data save errors
    func delete(_ document: Document) async throws {
        viewContext.delete(document)
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Deleted document: \(document.documentTypeDisplayName)")
        #endif
    }

    /// Delete multiple documents
    /// - Parameter documents: Array of documents to delete
    /// - Throws: Core Data save errors
    func delete(_ documents: [Document]) async throws {
        for document in documents {
            viewContext.delete(document)
        }
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Deleted \(documents.count) documents")
        #endif
    }

    /// Delete all documents for a profile
    /// - Parameter profile: Profile whose documents should be deleted
    /// - Throws: Core Data save errors
    func deleteAll(for profile: Profile) async throws {
        let documents = try await fetch(for: profile)
        try await delete(documents)
    }

    // MARK: - Status Management

    /// Mark document as completed
    /// - Parameter document: Document to mark as completed
    /// - Throws: Core Data save errors
    func markAsCompleted(_ document: Document) async throws {
        document.markAsCompleted()
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Marked document as completed")
        #endif
    }

    /// Mark document as submitted
    /// - Parameters:
    ///   - document: Document to mark as submitted
    ///   - date: Submission date (defaults to now)
    /// - Throws: Core Data save errors
    func markAsSubmitted(_ document: Document, date: Date = Date()) async throws {
        document.markAsSubmitted(date: date)
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Marked document as submitted")
        #endif
    }

    /// Revert document to draft
    /// - Parameter document: Document to revert
    /// - Throws: Core Data save errors
    func revertToDraft(_ document: Document) async throws {
        document.revertToDraft()
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Reverted document to draft")
        #endif
    }

    // MARK: - Statistics

    /// Get document count
    /// - Returns: Total number of documents
    /// - Throws: Core Data fetch errors
    func count() async throws -> Int {
        let request = Document.fetchRequest()
        return try viewContext.count(for: request)
    }

    /// Get document count by status
    /// - Parameter status: Document status
    /// - Returns: Count of documents with status
    /// - Throws: Core Data fetch errors
    func count(status: String) async throws -> Int {
        let request = Document.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", status)
        return try viewContext.count(for: request)
    }

    /// Get document count for profile
    /// - Parameter profile: Profile to count documents for
    /// - Returns: Count of documents
    /// - Throws: Core Data fetch errors
    func count(for profile: Profile) async throws -> Int {
        let request = Document.fetchRequest()
        request.predicate = NSPredicate(format: "profile == %@", profile)
        return try viewContext.count(for: request)
    }

    /// Check if profile has any documents
    /// - Parameter profile: Profile to check
    /// - Returns: True if profile has documents
    /// - Throws: Core Data fetch errors
    func hasDocuments(for profile: Profile) async throws -> Bool {
        return try await count(for: profile) > 0
    }
}
