//
//  pin-auth-service-secure-storage.swift
//  ZairyuMate
//
//  Service for PIN authentication with secure Keychain storage
//  Handles PIN creation, verification, and SHA256 hashing
//

import Foundation
import CryptoKit

/// Errors that can occur during PIN operations
enum PINAuthError: Error {
    case pinNotSet
    case invalidPinLength
    case keychainError(KeychainError)
    case hashingFailed

    var localizedDescription: String {
        switch self {
        case .pinNotSet:
            return "PIN has not been set"
        case .invalidPinLength:
            return "PIN must be 6 digits"
        case .keychainError(let error):
            return "Keychain error: \(error.localizedDescription)"
        case .hashingFailed:
            return "Failed to hash PIN"
        }
    }
}

/// Service for PIN authentication with secure storage
class PINAuthService {

    // MARK: - Properties

    private let keychainKey = "zairyumate_pin_hash"
    private let pinLength = 6

    // MARK: - PIN Management

    /// Set a new PIN
    /// - Parameter pin: 6-digit PIN string
    /// - Throws: PINAuthError if PIN is invalid or Keychain fails
    func setPin(_ pin: String) throws {
        // Validate PIN length
        guard pin.count == pinLength else {
            throw PINAuthError.invalidPinLength
        }

        // Validate PIN contains only digits
        guard pin.allSatisfy({ $0.isNumber }) else {
            throw PINAuthError.invalidPinLength
        }

        // Hash the PIN
        let hash = hashPin(pin)

        // Save to Keychain
        do {
            guard let hashData = hash.data(using: .utf8) else {
                throw PINAuthError.hashingFailed
            }
            try KeychainHelper.save(hashData, for: keychainKey)

            #if DEBUG
            print("✅ PINAuth: PIN set successfully")
            #endif
        } catch let keychainError as KeychainError {
            throw PINAuthError.keychainError(keychainError)
        }
    }

    /// Verify if provided PIN matches stored PIN
    /// - Parameter pin: 6-digit PIN to verify
    /// - Returns: True if PIN matches
    func verifyPin(_ pin: String) -> Bool {
        // Check if PIN is valid length
        guard pin.count == pinLength else {
            return false
        }

        // Load stored hash from Keychain
        guard let storedData = try? KeychainHelper.load(for: keychainKey),
              let storedHash = String(data: storedData, encoding: .utf8) else {
            #if DEBUG
            print("⚠️ PINAuth: No stored PIN found")
            #endif
            return false
        }

        // Compare hashes
        let inputHash = hashPin(pin)
        let isValid = inputHash == storedHash

        #if DEBUG
        print("\(isValid ? "✅" : "❌") PINAuth: PIN verification \(isValid ? "succeeded" : "failed")")
        #endif

        return isValid
    }

    /// Check if PIN is set
    /// - Returns: True if PIN exists in Keychain
    func isPinSet() -> Bool {
        do {
            let data = try KeychainHelper.load(for: keychainKey)
            return data != nil
        } catch {
            return false
        }
    }

    /// Clear stored PIN from Keychain
    /// - Throws: PINAuthError if Keychain operation fails
    func clearPin() throws {
        do {
            try KeychainHelper.delete(for: keychainKey)

            #if DEBUG
            print("✅ PINAuth: PIN cleared successfully")
            #endif
        } catch let keychainError as KeychainError {
            throw PINAuthError.keychainError(keychainError)
        }
    }

    /// Change existing PIN
    /// - Parameters:
    ///   - oldPin: Current PIN for verification
    ///   - newPin: New PIN to set
    /// - Throws: PINAuthError if verification fails or new PIN is invalid
    func changePin(oldPin: String, newPin: String) throws {
        // Verify old PIN
        guard verifyPin(oldPin) else {
            throw PINAuthError.pinNotSet
        }

        // Set new PIN
        try setPin(newPin)

        #if DEBUG
        print("✅ PINAuth: PIN changed successfully")
        #endif
    }

    // MARK: - Hashing

    /// Hash PIN using SHA256
    /// - Parameter pin: PIN to hash
    /// - Returns: Hex string of SHA256 hash
    private func hashPin(_ pin: String) -> String {
        let data = Data(pin.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Validation

    /// Validate if string is a valid 6-digit PIN
    /// - Parameter pin: String to validate
    /// - Returns: True if valid PIN format
    func isValidPinFormat(_ pin: String) -> Bool {
        return pin.count == pinLength && pin.allSatisfy({ $0.isNumber })
    }
}
