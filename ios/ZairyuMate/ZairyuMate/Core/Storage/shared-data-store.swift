//
//  shared-data-store.swift
//  ZairyuMate
//
//  Shared data container for App Groups communication between main app and widget
//  Enables widget to access profile data for countdown display
//

import Foundation

/// Data model for widget display
struct WidgetData: Codable {
    let profileName: String
    let visaType: String
    let expiryDate: Date
    let daysRemaining: Int
    let lastUpdated: Date

    init(profileName: String, visaType: String, expiryDate: Date, daysRemaining: Int) {
        self.profileName = profileName
        self.visaType = visaType
        self.expiryDate = expiryDate
        self.daysRemaining = daysRemaining
        self.lastUpdated = Date()
    }
}

/// Shared data store using App Groups for main app and widget communication
class SharedDataStore {
    // IMPORTANT: This must match the App Group identifier in entitlements
    static let appGroup = "group.com.zairyumate.app"

    private static let widgetDataKey = "widgetData"

    /// Shared UserDefaults container for App Groups
    static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroup)
    }

    /// Save widget data to shared container
    static func saveWidgetData(_ data: WidgetData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let encoded = try encoder.encode(data)
            sharedDefaults?.set(encoded, forKey: widgetDataKey)
            sharedDefaults?.synchronize()
            print("✅ Widget data saved: \(data.profileName) - \(data.daysRemaining) days")
        } catch {
            print("❌ Failed to encode widget data: \(error.localizedDescription)")
        }
    }

    /// Load widget data from shared container
    static func loadWidgetData() -> WidgetData? {
        guard let data = sharedDefaults?.data(forKey: widgetDataKey) else {
            print("⚠️ No widget data found in shared container")
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let decoded = try decoder.decode(WidgetData.self, from: data)
            print("✅ Widget data loaded: \(decoded.profileName) - \(decoded.daysRemaining) days")
            return decoded
        } catch {
            print("❌ Failed to decode widget data: \(error.localizedDescription)")
            return nil
        }
    }

    /// Clear widget data from shared container
    static func clearWidgetData() {
        sharedDefaults?.removeObject(forKey: widgetDataKey)
        sharedDefaults?.synchronize()
        print("🗑️ Widget data cleared")
    }

    /// Check if widget data exists
    static func hasWidgetData() -> Bool {
        return sharedDefaults?.data(forKey: widgetDataKey) != nil
    }
}
