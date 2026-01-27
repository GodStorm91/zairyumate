//
//  core-data-preview-helper.swift
//  ZairyuMate
//
//  Helper utilities for SwiftUI previews with Core Data
//  Provides mock data and preview contexts for development
//

import Foundation
import CoreData

/// Helper for creating preview data and contexts
enum CoreDataPreviewHelper {

    /// Create a sample profile for preview
    static func createSampleProfile(in context: NSManagedObjectContext) -> Profile {
        let profile = Profile(context: context)
        profile.id = UUID()
        profile.name = "Nguyen Van A"
        profile.nameKatakana = "グエン・ヴァン・アー"
        profile.dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())
        profile.nationality = "VNM"
        profile.address = "東京都渋谷区渋谷1-2-3 マンション101"
        profile.cardExpiry = Calendar.current.date(byAdding: .month, value: 6, to: Date())
        profile.visaType = "Engineer/Specialist in Humanities/International Services"
        profile.passportExpiry = Calendar.current.date(byAdding: .year, value: 5, to: Date())
        profile.relationship = "self"
        profile.isActive = true
        profile.createdAt = Date()
        profile.updatedAt = Date()

        // Set encrypted fields
        profile.decryptedCardNumber = "AB1234567"
        profile.decryptedPassportNumber = "N12345678"

        return profile
    }

    /// Create sample profiles for preview (multiple)
    static func createSampleProfiles(in context: NSManagedObjectContext, count: Int = 3) -> [Profile] {
        var profiles: [Profile] = []

        // Main profile
        profiles.append(createSampleProfile(in: context))

        // Spouse profile
        if count > 1 {
            let spouse = Profile(context: context)
            spouse.id = UUID()
            spouse.name = "Tran Thi B"
            spouse.nameKatakana = "チャン・ティ・ビー"
            spouse.dateOfBirth = Calendar.current.date(byAdding: .year, value: -28, to: Date())
            spouse.nationality = "VNM"
            spouse.address = "東京都渋谷区渋谷1-2-3 マンション101"
            spouse.cardExpiry = Calendar.current.date(byAdding: .month, value: 8, to: Date())
            spouse.visaType = "Dependent"
            spouse.relationship = "spouse"
            spouse.isActive = false
            spouse.createdAt = Date()
            spouse.updatedAt = Date()
            profiles.append(spouse)
        }

        // Child profile
        if count > 2 {
            let child = Profile(context: context)
            child.id = UUID()
            child.name = "Nguyen Van C"
            child.nameKatakana = "グエン・ヴァン・シー"
            child.dateOfBirth = Calendar.current.date(byAdding: .year, value: -5, to: Date())
            child.nationality = "VNM"
            child.address = "東京都渋谷区渋谷1-2-3 マンション101"
            child.cardExpiry = Calendar.current.date(byAdding: .month, value: 12, to: Date())
            child.visaType = "Dependent"
            child.relationship = "child"
            child.isActive = false
            child.createdAt = Date()
            child.updatedAt = Date()
            profiles.append(child)
        }

        return profiles
    }

    /// Create sample document for profile
    static func createSampleDocument(for profile: Profile, in context: NSManagedObjectContext) -> Document {
        let document = Document(context: context)
        document.id = UUID()
        document.documentType = "extension"
        document.status = "draft"
        document.createdAt = Date()
        document.profile = profile

        return document
    }

    /// Create sample timeline events for profile
    static func createSampleTimelineEvents(for profile: Profile, in context: NSManagedObjectContext) -> [TimelineEvent] {
        var events: [TimelineEvent] = []

        // Event 1: Prepare documents (3 months before expiry)
        if let expiry = profile.cardExpiry,
           let prepareDate = Calendar.current.date(byAdding: .month, value: -3, to: expiry) {
            let event1 = TimelineEvent(context: context)
            event1.id = UUID()
            event1.title = "Start preparing renewal documents"
            event1.eventDate = prepareDate
            event1.eventType = "reminder"
            event1.isCompleted = false
            event1.profile = profile
            events.append(event1)
        }

        // Event 2: Submit application (1 month before expiry)
        if let expiry = profile.cardExpiry,
           let submitDate = Calendar.current.date(byAdding: .month, value: -1, to: expiry) {
            let event2 = TimelineEvent(context: context)
            event2.id = UUID()
            event2.title = "Submit visa renewal application"
            event2.eventDate = submitDate
            event2.eventType = "deadline"
            event2.isCompleted = false
            event2.profile = profile
            events.append(event2)
        }

        // Event 3: Visa expiry
        if let expiry = profile.cardExpiry {
            let event3 = TimelineEvent(context: context)
            event3.id = UUID()
            event3.title = "Visa expiry date"
            event3.eventDate = expiry
            event3.eventType = "milestone"
            event3.isCompleted = false
            event3.profile = profile
            events.append(event3)
        }

        return events
    }

    /// Create sample app settings
    static func createSampleAppSettings(in context: NSManagedObjectContext) -> AppSettings {
        let settings = AppSettings(context: context)
        settings.id = UUID()
        settings.biometricEnabled = true
        settings.selectedLanguage = "vi"
        settings.isPro = false
        settings.lastSyncDate = Date()

        return settings
    }

    /// Initialize preview container with full sample data
    static func previewContainer() -> PersistenceController {
        let controller = PersistenceController.preview
        let context = controller.viewContext

        // Create profiles
        let profiles = createSampleProfiles(in: context, count: 3)

        // Create documents for first profile
        if let mainProfile = profiles.first {
            _ = createSampleDocument(for: mainProfile, in: context)

            // Create timeline events
            _ = createSampleTimelineEvents(for: mainProfile, in: context)
        }

        // Create app settings
        _ = createSampleAppSettings(in: context)

        // Save all
        try? context.save()

        return controller
    }
}

// MARK: - Preview Extensions

extension Profile {
    /// Quick preview instance
    static var preview: Profile {
        let context = PersistenceController.preview.viewContext
        return CoreDataPreviewHelper.createSampleProfile(in: context)
    }
}

extension Document {
    /// Quick preview instance
    static var preview: Document {
        let context = PersistenceController.preview.viewContext
        let profile = Profile.preview
        return CoreDataPreviewHelper.createSampleDocument(for: profile, in: context)
    }
}

extension TimelineEvent {
    /// Quick preview instance
    static var preview: TimelineEvent {
        let context = PersistenceController.preview.viewContext
        let profile = Profile.preview
        let events = CoreDataPreviewHelper.createSampleTimelineEvents(for: profile, in: context)
        return events.first!
    }
}

extension AppSettings {
    /// Quick preview instance
    static var preview: AppSettings {
        let context = PersistenceController.preview.viewContext
        return CoreDataPreviewHelper.createSampleAppSettings(in: context)
    }
}
