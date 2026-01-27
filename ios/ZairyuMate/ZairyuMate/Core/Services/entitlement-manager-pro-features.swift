//
//  entitlement-manager-pro-features.swift
//  ZairyuMate
//
//  Manages Pro feature entitlements and feature gating
//  Determines which features are available based on subscription status
//

import Foundation
import Observation

// MARK: - Entitlement Manager

@Observable
@MainActor
class EntitlementManager {

    // MARK: - Properties

    /// Store manager reference
    private let storeManager: StoreManager

    // MARK: - Initialization

    init(storeManager: StoreManager) {
        self.storeManager = storeManager
    }

    // MARK: - Pro Status

    /// Check if user has Pro access
    var isPro: Bool {
        storeManager.isPro
    }

    // MARK: - Feature Gates

    /// Check if NFC scan feature is available
    /// Free: No, Pro: Yes
    func canUseNFC() -> Bool {
        return isPro
    }

    /// Check if iCloud sync feature is available
    /// Free: No, Pro: Yes
    func canUseiCloudSync() -> Bool {
        return isPro
    }

    /// Check if OCR passport scan feature is available
    /// Free: No, Pro: Yes
    func canUseOCR() -> Bool {
        return isPro
    }

    /// Check if PR form is available
    /// Free: No, Pro: Yes
    func canUsePRForm() -> Bool {
        return isPro
    }

    /// Check if PDF export should have watermark
    /// Free: Yes (watermark), Pro: No (clean)
    func shouldAddWatermarkToPDF() -> Bool {
        return !isPro
    }

    /// Check if user can export clean PDF without watermark
    /// Free: No, Pro: Yes
    func canExportCleanPDF() -> Bool {
        return isPro
    }

    /// Maximum number of profiles allowed
    /// Free: 1, Pro: Unlimited
    func maxProfiles() -> Int {
        return isPro ? Int.max : IAPConstants.freeMaxProfiles
    }

    /// Check if user can create more profiles
    /// - Parameter currentCount: Current number of profiles
    /// - Returns: True if user can create more profiles
    func canCreateProfile(currentCount: Int) -> Bool {
        return currentCount < maxProfiles()
    }

    // MARK: - Feature Descriptions

    /// Get list of Pro features for display
    var proFeatures: [ProFeature] {
        return [
            ProFeature(
                name: "NFC Card Scan",
                description: "Scan your Zairyu Card with NFC",
                icon: "wave.3.right"
            ),
            ProFeature(
                name: "iCloud Sync",
                description: "Sync data across devices",
                icon: "icloud"
            ),
            ProFeature(
                name: "OCR Passport Scan",
                description: "Scan passport with camera",
                icon: "doc.text.viewfinder"
            ),
            ProFeature(
                name: "PR Form",
                description: "Access Permanent Residence form",
                icon: "doc.text"
            ),
            ProFeature(
                name: "Watermark-Free PDF",
                description: "Export clean PDFs",
                icon: "doc.badge.gearshape"
            ),
            ProFeature(
                name: "Unlimited Profiles",
                description: "Create unlimited profiles",
                icon: "person.2"
            )
        ]
    }

    /// Get locked feature message for specific feature
    /// - Parameter feature: Feature name
    /// - Returns: User-friendly message
    func getLockedFeatureMessage(for feature: String) -> String {
        return "\(feature) is a Pro feature. Upgrade to unlock."
    }
}

// MARK: - Pro Feature Model

struct ProFeature: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
}
