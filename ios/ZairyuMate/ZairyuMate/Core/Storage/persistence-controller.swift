//
//  persistence-controller.swift
//  ZairyuMate
//
//  Core Data stack with NSPersistentCloudKitContainer for iCloud sync
//  Manages database lifecycle and provides preview/test containers
//

import CoreData
import Foundation

/// Core Data persistence controller with CloudKit integration
class PersistenceController: ObservableObject {
    /// Shared singleton instance for production use
    static let shared = PersistenceController()

    /// Flag indicating if store loaded successfully
    @Published private(set) var isStoreLoaded = false

    /// Preview instance with in-memory store and mock data for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample profile for preview
        let profile = Profile(context: viewContext)
        profile.id = UUID()
        profile.name = "Nguyen Van A"
        profile.nameKatakana = "グエン・ヴァン・アー"
        profile.dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())
        profile.nationality = "VNM"
        profile.address = "東京都渋谷区1-2-3"
        profile.cardNumber = "AB1234567"
        profile.cardExpiry = Calendar.current.date(byAdding: .year, value: 2, to: Date())
        profile.visaType = "Engineer/Specialist in Humanities/International Services"
        profile.passportNumber = "N12345678"
        profile.passportExpiry = Calendar.current.date(byAdding: .year, value: 5, to: Date())
        profile.relationship = "self"
        profile.isActive = true
        profile.createdAt = Date()
        profile.updatedAt = Date()

        // Create sample document
        let document = Document(context: viewContext)
        document.id = UUID()
        document.documentType = "extension"
        document.status = "draft"
        document.createdAt = Date()
        document.profile = profile

        // Create sample timeline event
        let event = TimelineEvent(context: viewContext)
        event.id = UUID()
        event.title = "Visa expiring soon - prepare documents"
        event.eventDate = Calendar.current.date(byAdding: .month, value: -1, to: profile.cardExpiry ?? Date()) ?? Date()
        event.eventType = "reminder"
        event.isCompleted = false
        event.profile = profile

        // Create app settings
        let settings = AppSettings(context: viewContext)
        settings.id = UUID()
        settings.biometricEnabled = true
        settings.selectedLanguage = "vi"
        settings.isPro = false

        do {
            try viewContext.save()
        } catch {
            fatalError("Preview data creation failed: \(error.localizedDescription)")
        }

        return controller
    }()

    /// The persistent container with CloudKit support
    let container: NSPersistentCloudKitContainer

    /// Main view context for UI operations
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Initialize persistence controller
    /// - Parameter inMemory: If true, uses in-memory store for testing/previews
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ZairyuMateDataModel")

        if inMemory {
            // Use in-memory store for previews and tests
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure persistent store for production
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve persistent store description")
            }

            // Disable CloudKit for simulator - only enable for device with iCloud
            #if !targetEnvironment(simulator)
            // Enable CloudKit sync with private database (device only)
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.khanhnguyenhoangviet.zairyumate"
            )
            #endif

            // Enable persistent history tracking for CloudKit sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            // Enable file protection for security (device only, not supported on simulator)
            #if !targetEnvironment(simulator)
            description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
            #endif
        }

        // Load persistent stores asynchronously (non-blocking)
        container.loadPersistentStores { [weak self] storeDescription, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    #if DEBUG
                    print("❌ Core Data store failed to load: \(error), \(error.userInfo)")
                    print("⚠️ Continuing with local-only storage (no CloudKit sync)")
                    #endif

                    // In DEBUG: Allow app to continue without CloudKit
                    // In RELEASE: Crash
                    #if DEBUG
                    self?.isStoreLoaded = true
                    #else
                    fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
                    #endif
                } else {
                    self?.isStoreLoaded = true
                    #if DEBUG
                    print("✅ Core Data store loaded: \(storeDescription.url?.lastPathComponent ?? "unknown")")
                    #endif
                }
            }
        }

        // Automatically merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Merge policy: prefer newer data in conflicts
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Create a background context for async operations
    /// - Returns: A new background managed object context
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Save context with error handling
    /// - Parameter context: The context to save
    /// - Throws: Core Data save error
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
            #if DEBUG
            print("✅ Context saved successfully")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to save context: \(error.localizedDescription)")
            #endif
            throw error
        }
    }

    /// Check if CloudKit sync is enabled
    var isCloudSyncEnabled: Bool {
        guard let description = container.persistentStoreDescriptions.first else {
            return false
        }
        return description.cloudKitContainerOptions != nil
    }
}
