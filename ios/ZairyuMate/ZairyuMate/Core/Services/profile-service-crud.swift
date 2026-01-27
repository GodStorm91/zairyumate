//
//  profile-service-crud.swift
//  ZairyuMate
//
//  Profile service for CRUD operations with async/await
//  Manages profile lifecycle including secure data storage via Keychain
//

import Foundation
import CoreData

/// Service for managing Profile entities
@MainActor
class ProfileService {

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

    /// Create a new profile
    /// - Parameters:
    ///   - name: Full name (required)
    ///   - nameKatakana: Name in Katakana
    ///   - dateOfBirth: Date of birth
    ///   - nationality: Country code
    ///   - address: Japanese address
    ///   - cardNumber: Zairyu card number (encrypted)
    ///   - cardExpiry: Card expiry date
    ///   - visaType: Status of residence
    ///   - passportNumber: Passport number (encrypted)
    ///   - passportExpiry: Passport expiry date
    ///   - relationship: Relationship type
    ///   - photoData: Profile photo
    /// - Returns: Created profile
    /// - Throws: Core Data or Keychain errors
    func create(
        name: String,
        nameKatakana: String? = nil,
        dateOfBirth: Date? = nil,
        nationality: String? = nil,
        address: String? = nil,
        cardNumber: String? = nil,
        cardExpiry: Date? = nil,
        visaType: String? = nil,
        passportNumber: String? = nil,
        passportExpiry: Date? = nil,
        relationship: String = "self",
        photoData: Data? = nil
    ) async throws -> Profile {
        let profile = Profile(context: viewContext)

        // Set basic attributes
        profile.name = name
        profile.nameKatakana = nameKatakana
        profile.dateOfBirth = dateOfBirth
        profile.nationality = nationality
        profile.address = address
        profile.cardExpiry = cardExpiry
        profile.visaType = visaType
        profile.passportExpiry = passportExpiry
        profile.relationship = relationship
        profile.photoData = photoData

        // Save encrypted fields to Keychain
        if let cardNum = cardNumber, !cardNum.isEmpty {
            profile.decryptedCardNumber = cardNum
        }

        if let passportNum = passportNumber, !passportNum.isEmpty {
            profile.decryptedPassportNumber = passportNum
        }

        // Save context
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Created profile: \(profile.name)")
        #endif

        return profile
    }

    // MARK: - Read

    /// Fetch all profiles
    /// - Returns: Array of all profiles sorted by creation date
    /// - Throws: Core Data fetch errors
    func fetchAll() async throws -> [Profile] {
        let request = Profile.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Profile.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Profile.createdAt, ascending: false)
        ]

        return try viewContext.fetch(request)
    }

    /// Fetch active profile
    /// - Returns: Currently active profile, or nil if none
    /// - Throws: Core Data fetch errors
    func fetchActive() async throws -> Profile? {
        let request = Profile.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1

        return try viewContext.fetch(request).first
    }

    /// Fetch profile by ID
    /// - Parameter id: Profile UUID
    /// - Returns: Profile if found
    /// - Throws: Core Data fetch errors
    func fetch(id: UUID) async throws -> Profile? {
        let request = Profile.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try viewContext.fetch(request).first
    }

    /// Fetch profiles by relationship
    /// - Parameter relationship: Relationship type (self, spouse, child, dependent)
    /// - Returns: Array of matching profiles
    /// - Throws: Core Data fetch errors
    func fetchByRelationship(_ relationship: String) async throws -> [Profile] {
        let request = Profile.fetchRequest()
        request.predicate = NSPredicate(format: "relationship == %@", relationship)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Profile.createdAt, ascending: false)]

        return try viewContext.fetch(request)
    }

    /// Fetch profiles expiring soon (within 3 months)
    /// - Returns: Array of profiles with expiring cards
    /// - Throws: Core Data fetch errors
    func fetchExpiringSoon() async throws -> [Profile] {
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

        let request = Profile.fetchRequest()
        request.predicate = NSPredicate(format: "cardExpiry != nil AND cardExpiry <= %@", threeMonthsFromNow as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Profile.cardExpiry, ascending: true)]

        return try viewContext.fetch(request)
    }

    // MARK: - Update

    /// Update profile
    /// - Parameter profile: Profile to update
    /// - Throws: Core Data save errors
    func update(_ profile: Profile) async throws {
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Updated profile: \(profile.name)")
        #endif
    }

    /// Update profile fields
    /// - Parameters:
    ///   - profile: Profile to update
    ///   - updates: Dictionary of field updates
    /// - Throws: Core Data save errors
    func update(_ profile: Profile, with updates: [String: Any]) async throws {
        for (key, value) in updates {
            switch key {
            case "name":
                if let name = value as? String {
                    profile.name = name
                }
            case "nameKatakana":
                profile.nameKatakana = value as? String
            case "dateOfBirth":
                profile.dateOfBirth = value as? Date
            case "nationality":
                profile.nationality = value as? String
            case "address":
                profile.address = value as? String
            case "cardNumber":
                if let cardNum = value as? String, !cardNum.isEmpty {
                    profile.decryptedCardNumber = cardNum
                }
            case "cardExpiry":
                profile.cardExpiry = value as? Date
            case "visaType":
                profile.visaType = value as? String
            case "passportNumber":
                if let passportNum = value as? String, !passportNum.isEmpty {
                    profile.decryptedPassportNumber = passportNum
                }
            case "passportExpiry":
                profile.passportExpiry = value as? Date
            case "relationship":
                profile.relationship = value as? String
            case "photoData":
                profile.photoData = value as? Data
            default:
                break
            }
        }

        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Updated profile fields: \(updates.keys.joined(separator: ", "))")
        #endif
    }

    // MARK: - Delete

    /// Delete profile and associated data
    /// - Parameter profile: Profile to delete
    /// - Throws: Core Data save errors
    func delete(_ profile: Profile) async throws {
        // Keychain cleanup is handled by Profile.prepareForDeletion()
        viewContext.delete(profile)
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Deleted profile: \(profile.name)")
        #endif
    }

    /// Delete multiple profiles
    /// - Parameter profiles: Array of profiles to delete
    /// - Throws: Core Data save errors
    func delete(_ profiles: [Profile]) async throws {
        for profile in profiles {
            viewContext.delete(profile)
        }
        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Deleted \(profiles.count) profiles")
        #endif
    }

    // MARK: - Active Profile Management

    /// Set profile as active (only one can be active)
    /// - Parameter profile: Profile to activate
    /// - Throws: Core Data save errors
    func setActive(_ profile: Profile) async throws {
        // Deactivate all profiles first
        let allProfiles = try await fetchAll()
        for p in allProfiles {
            p.isActive = false
        }

        // Activate selected profile
        profile.isActive = true

        try persistenceController.save(context: viewContext)

        #if DEBUG
        print("✅ Set active profile: \(profile.name)")
        #endif
    }

    // MARK: - Statistics

    /// Get profile count
    /// - Returns: Total number of profiles
    /// - Throws: Core Data fetch errors
    func count() async throws -> Int {
        let request = Profile.fetchRequest()
        return try viewContext.count(for: request)
    }

    /// Check if any profiles exist
    /// - Returns: True if at least one profile exists
    /// - Throws: Core Data fetch errors
    func hasProfiles() async throws -> Bool {
        return try await count() > 0
    }
}
