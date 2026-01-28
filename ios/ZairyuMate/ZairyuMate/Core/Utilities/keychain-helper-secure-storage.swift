//
//  keychain-helper-secure-storage.swift
//  ZairyuMate
//
//  Secure storage utility for sensitive data using iOS Keychain
//  Encrypts card numbers, passport numbers, and other PII
//

import Foundation
import Security

/// Errors that can occur during Keychain operations
enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedStatus(OSStatus)
    case unableToConvertToData
    case unableToConvertToString
}

/// Helper for secure Keychain operations
enum KeychainHelper {

    /// Service identifier for Keychain items
    private static let service = "com.khanhnguyenhoangviet.zairyumate.secure"

    // MARK: - Save Operations

    /// Save data to Keychain
    /// - Parameters:
    ///   - data: Data to store securely
    ///   - key: Unique identifier for the data
    /// - Throws: KeychainError if operation fails
    static func save(_ data: Data, for key: String) throws {
        // First, try to delete any existing item with this key
        try? delete(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateItem
            }
            throw KeychainError.unexpectedStatus(status)
        }

        #if DEBUG
        print("✅ Keychain: Saved item for key '\(key)'")
        #endif
    }

    /// Save string to Keychain
    /// - Parameters:
    ///   - string: String to store securely
    ///   - key: Unique identifier
    /// - Throws: KeychainError if operation fails
    static func save(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unableToConvertToData
        }
        try save(data, for: key)
    }

    // MARK: - Load Operations

    /// Load data from Keychain
    /// - Parameter key: Unique identifier for the data
    /// - Returns: Stored data, or nil if not found
    /// - Throws: KeychainError if operation fails
    static func load(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        #if DEBUG
        print("✅ Keychain: Loaded item for key '\(key)'")
        #endif

        return data
    }

    /// Load string from Keychain
    /// - Parameter key: Unique identifier
    /// - Returns: Stored string, or nil if not found
    /// - Throws: KeychainError if operation fails
    static func loadString(for key: String) throws -> String? {
        guard let data = try load(for: key) else {
            return nil
        }

        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unableToConvertToString
        }

        return string
    }

    // MARK: - Delete Operations

    /// Delete data from Keychain
    /// - Parameter key: Unique identifier for the data
    /// - Throws: KeychainError if operation fails
    static func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Success if deleted or item didn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }

        #if DEBUG
        print("✅ Keychain: Deleted item for key '\(key)'")
        #endif
    }

    /// Delete all Keychain items for this app
    /// - Throws: KeychainError if operation fails
    static func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }

        #if DEBUG
        print("✅ Keychain: Deleted all items")
        #endif
    }

    // MARK: - Helper Methods

    /// Check if a key exists in Keychain
    /// - Parameter key: Unique identifier
    /// - Returns: True if key exists
    static func exists(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Convenience Methods for Profile Data

    /// Generate Keychain key for profile-specific data
    /// - Parameters:
    ///   - profileId: Profile UUID
    ///   - field: Field name (e.g., "cardNumber", "passportNumber")
    /// - Returns: Unique Keychain key
    static func profileKey(profileId: UUID, field: String) -> String {
        return "profile.\(profileId.uuidString).\(field)"
    }

    /// Save encrypted card number for profile
    static func saveCardNumber(_ cardNumber: String, for profileId: UUID) throws {
        let key = profileKey(profileId: profileId, field: "cardNumber")
        try save(cardNumber, for: key)
    }

    /// Load encrypted card number for profile
    static func loadCardNumber(for profileId: UUID) throws -> String? {
        let key = profileKey(profileId: profileId, field: "cardNumber")
        return try loadString(for: key)
    }

    /// Save encrypted passport number for profile
    static func savePassportNumber(_ passportNumber: String, for profileId: UUID) throws {
        let key = profileKey(profileId: profileId, field: "passportNumber")
        try save(passportNumber, for: key)
    }

    /// Load encrypted passport number for profile
    static func loadPassportNumber(for profileId: UUID) throws -> String? {
        let key = profileKey(profileId: profileId, field: "passportNumber")
        return try loadString(for: key)
    }

    /// Delete all sensitive data for a profile
    static func deleteProfileData(for profileId: UUID) throws {
        try? delete(for: profileKey(profileId: profileId, field: "cardNumber"))
        try? delete(for: profileKey(profileId: profileId, field: "passportNumber"))
    }
}
