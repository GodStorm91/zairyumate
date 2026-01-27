//
//  app-settings-core-data-model.swift
//  ZairyuMate
//
//  App settings entity (singleton pattern) for user preferences
//  Manages biometric auth, language, pro status, and sync state
//

import Foundation
import CoreData

@objc(AppSettings)
public class AppSettings: NSManagedObject {

    // MARK: - Singleton Access

    /// Fetch or create the singleton settings instance
    /// - Parameter context: Managed object context
    /// - Returns: The app settings instance
    static func shared(in context: NSManagedObjectContext) -> AppSettings {
        let request = fetchRequest()
        request.fetchLimit = 1

        do {
            if let settings = try context.fetch(request).first {
                return settings
            }
        } catch {
            print("⚠️ Failed to fetch AppSettings: \(error)")
        }

        // Create new settings if none exists
        let settings = AppSettings(context: context)
        settings.id = UUID()
        settings.biometricEnabled = false
        settings.selectedLanguage = "vi"
        settings.isPro = false
        settings.lastSyncDate = nil

        do {
            try context.save()
        } catch {
            print("⚠️ Failed to save new AppSettings: \(error)")
        }

        return settings
    }

    // MARK: - Computed Properties

    /// Check if biometric authentication is available on device
    var isBiometricAvailable: Bool {
        // Will implement with LocalAuthentication in Phase 03
        return false
    }

    /// Language display name
    var languageDisplayName: String {
        switch selectedLanguage ?? "vi" {
        case "vi":
            return "Tiếng Việt"
        case "ja":
            return "日本語"
        case "en":
            return "English"
        default:
            return selectedLanguage ?? "Unknown"
        }
    }

    /// Check if synced recently (within 24 hours)
    var isSyncedRecently: Bool {
        guard let lastSync = lastSyncDate else { return false }
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return lastSync > dayAgo
    }

    /// Time since last sync in human-readable format
    var timeSinceLastSync: String? {
        guard let lastSync = lastSyncDate else { return nil }

        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: lastSync, to: Date())

        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }

        if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }

        if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        }

        return "Just now"
    }

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(false, forKey: "biometricEnabled")
        setPrimitiveValue("vi", forKey: "selectedLanguage")
        setPrimitiveValue(false, forKey: "isPro")
    }

    // MARK: - Settings Management

    /// Update language preference
    /// - Parameter language: Language code (vi, ja, en)
    func updateLanguage(_ language: String) {
        let validLanguages = ["vi", "ja", "en"]
        if validLanguages.contains(language) {
            selectedLanguage = language
        }
    }

    /// Enable biometric authentication
    func enableBiometric() {
        biometricEnabled = true
    }

    /// Disable biometric authentication
    func disableBiometric() {
        biometricEnabled = false
    }

    /// Mark as Pro user (after IAP)
    func unlockPro() {
        isPro = true
    }

    /// Update last sync timestamp
    func updateLastSync() {
        lastSyncDate = Date()
    }

    /// Reset to default settings
    func resetToDefaults() {
        biometricEnabled = false
        selectedLanguage = "vi"
        isPro = false
        lastSyncDate = nil
    }

    // MARK: - Validation

    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateSettings()
    }

    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateSettings()
    }

    private func validateSettings() throws {
        // Language must be valid
        let validLanguages = ["vi", "ja", "en"]
        if let lang = selectedLanguage, !validLanguages.contains(lang) {
            throw ValidationError.invalidValue("selectedLanguage", lang)
        }
    }

    // MARK: - Export

    /// Export settings as dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["id"] = id?.uuidString
        dict["biometricEnabled"] = biometricEnabled
        dict["selectedLanguage"] = selectedLanguage
        dict["isPro"] = isPro
        dict["lastSyncDate"] = lastSyncDate?.timeIntervalSince1970
        return dict
    }
}

// MARK: - Fetch Request

extension AppSettings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppSettings> {
        return NSFetchRequest<AppSettings>(entityName: "AppSettings")
    }
}
