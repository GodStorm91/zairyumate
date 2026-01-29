//
//  Constants.swift
//  ZairyuMate
//
//  App-wide constants and configuration values
//

import Foundation

// MARK: - App Constants

enum AppConstants {
    /// App name
    static let appName = "Zairyu Mate"

    /// Bundle identifier
    static let bundleIdentifier = "com.khanhnguyenhoangviet.zairyumate"

    /// App version
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    /// Build number
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    /// Minimum iOS version supported
    static let minimumIOSVersion = "17.0"
}

// MARK: - API Constants

enum APIConstants {
    /// Base URL for any future API endpoints (currently unused - offline first)
    static let baseURL = "https://api.zairyumate.com"

    /// API timeout interval
    static let timeoutInterval: TimeInterval = 30
}

// MARK: - NFC Constants

enum NFCConstants {
    /// NFC session timeout (seconds)
    static let sessionTimeout: TimeInterval = 60

    /// Zairyu card Application Identifier (AID)
    /// Reference: MOJ Residence Card Specification
    static let zairyuCardAID = "A0000002471001"

    /// NFC Alert Messages
    enum AlertMessage {
        static let ready = "Hold the TOP of your iPhone against the back of the Zairyu Card"
        static let readyJP = "iPhoneの上部を在留カードの裏面に当ててください"
        static let success = "Card read successfully!"
        static let successJP = "カードの読み取りに成功しました"
        static let multipleCards = "Multiple cards detected. Please use only one card."
        static let multipleCardsJP = "複数のカードが検出されました。1枚だけお使いください。"
        static let connecting = "Connecting to card..."
        static let reading = "Reading card data..."
    }
}

// MARK: - Storage Constants

enum StorageConstants {
    /// User defaults suite name
    static let userDefaultsSuite = "com.khanhnguyenhoangviet.zairyumate"

    /// Keychain service identifier
    static let keychainService = "com.khanhnguyenhoangviet.zairyumate.keychain"

    /// iCloud container identifier
    static let iCloudContainerID = "iCloud.com.khanhnguyenhoangviet.zairyumate"

    // MARK: - User Defaults Keys

    enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredLanguage = "preferredLanguage"
        static let biometricAuthEnabled = "biometricAuthEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let lastSyncDate = "lastSyncDate"
    }
}

// MARK: - Notification Constants

enum NotificationConstants {
    /// Visa expiration reminder notification ID
    static let visaExpirationReminderID = "visa.expiration.reminder"

    /// Document preparation reminder notification ID
    static let documentPreparationReminderID = "document.preparation.reminder"

    /// Timeline task notification ID prefix
    static let timelineTaskNotificationPrefix = "timeline.task."

    // MARK: - Reminder Intervals (days before expiration)

    /// 3 months before expiration
    static let firstReminderDays = 90

    /// 1 month before expiration
    static let secondReminderDays = 30

    /// 2 weeks before expiration
    static let thirdReminderDays = 14

    /// 1 week before expiration
    static let finalReminderDays = 7
}

// MARK: - Form Constants

enum FormConstants {
    /// Maximum file size for PDF export (in bytes) - 10MB
    static let maxPDFFileSize: Int = 10 * 1024 * 1024

    /// Supported form types
    enum FormType: String, CaseIterable {
        case `extension` = "extension"
        case changeOfStatus = "change_of_status"
        case permanentResidence = "permanent_residence"

        var displayName: String {
            switch self {
            case .extension:
                return "Extension of Period of Stay"
            case .changeOfStatus:
                return "Change of Status of Residence"
            case .permanentResidence:
                return "Permanent Residence (Eijuu)"
            }
        }
    }
}

// MARK: - Privacy Constants

enum PrivacyConstants {
    /// NFC reader usage description key
    static let nfcUsageDescription = "NFCReaderUsageDescription"

    /// Face ID usage description key
    static let faceIDUsageDescription = "NSFaceIDUsageDescription"

    /// Camera usage description key
    static let cameraUsageDescription = "NSCameraUsageDescription"
}

// MARK: - In-App Purchase Constants

enum IAPConstants {
    /// Pro upgrade product ID (non-consumable)
    static let proProductID = "com.khanhnguyenhoangviet.zairyumate.pro"

    /// All product IDs
    static let productIDs: [String] = [proProductID]

    // MARK: - User Defaults Keys

    enum Keys {
        /// Cached Pro status for offline access
        static let isPro = "isPro"

        /// Last purchase verification date
        static let lastVerificationDate = "lastVerificationDate"
    }

    // MARK: - Feature Flags

    /// Free tier watermark text
    static let watermarkText = "Created with Zairyu Mate Free"

    /// Max profiles for free tier
    static let freeMaxProfiles = 1
}

// MARK: - Debug Constants

#if DEBUG
enum DebugConstants {
    /// Enable verbose logging
    static let verboseLogging = true

    /// Enable NFC simulation (for testing without real card)
    static let enableNFCSimulation = false

    /// Simulated scan delay (seconds)
    static let simulatedScanDelay: TimeInterval = 2
}
#endif
