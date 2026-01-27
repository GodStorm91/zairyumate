//
//  biometric-auth-service.swift
//  ZairyuMate
//
//  Service for managing biometric authentication (FaceID/TouchID)
//  Wraps LocalAuthentication framework with async/await support
//

import Foundation
import LocalAuthentication

/// Errors that can occur during biometric authentication
enum BiometricAuthError: Error {
    case notAvailable
    case notEnrolled
    case lockout
    case userCancel
    case userFallback
    case systemCancel
    case passcodeNotSet
    case biometryNotAvailable
    case biometryNotEnrolled
    case invalidContext
    case unknown(Error)

    var localizedDescription: String {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric data is enrolled"
        case .lockout:
            return "Biometric authentication is locked. Please use passcode"
        case .userCancel:
            return "User canceled authentication"
        case .userFallback:
            return "User chose to use passcode"
        case .systemCancel:
            return "System canceled authentication"
        case .passcodeNotSet:
            return "Device passcode is not set"
        case .biometryNotAvailable:
            return "Biometry is not available"
        case .biometryNotEnrolled:
            return "No biometric data enrolled"
        case .invalidContext:
            return "Invalid authentication context"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

/// Service for biometric authentication using LocalAuthentication
class BiometricAuthService {

    // MARK: - Properties

    private var context: LAContext {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use PIN"
        return context
    }

    // MARK: - Biometry Type

    /// Get the type of biometry available on the device
    var biometryType: LABiometryType {
        let context = self.context
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    /// Human-readable name for the biometry type
    var biometryName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometrics"
        @unknown default:
            return "Biometrics"
        }
    }

    // MARK: - Availability

    /// Check if biometric authentication is available on the device
    var isBiometricAvailable: Bool {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        #if DEBUG
        if let error = error {
            print("⚠️ BiometricAuth: Not available - \(error.localizedDescription)")
        }
        #endif

        return canEvaluate
    }

    /// Check if device has passcode set
    var isPasscodeSet: Bool {
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    // MARK: - Authentication

    /// Authenticate user with biometrics
    /// - Parameter reason: Localized reason to show to user
    /// - Returns: True if authentication succeeded
    /// - Throws: BiometricAuthError if authentication fails
    func authenticate(reason: String) async throws -> Bool {
        let context = self.context

        // Check if biometrics are available
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                throw mapError(error)
            }
            throw BiometricAuthError.notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            #if DEBUG
            print("✅ BiometricAuth: Authentication \(success ? "succeeded" : "failed")")
            #endif

            return success
        } catch let laError as LAError {
            #if DEBUG
            print("⚠️ BiometricAuth: \(laError.localizedDescription)")
            #endif
            throw mapError(laError)
        } catch {
            #if DEBUG
            print("⚠️ BiometricAuth: Unknown error - \(error.localizedDescription)")
            #endif
            throw BiometricAuthError.unknown(error)
        }
    }

    /// Authenticate with device passcode as fallback
    /// - Parameter reason: Localized reason to show to user
    /// - Returns: True if authentication succeeded
    func authenticateWithPasscode(reason: String) async throws -> Bool {
        let context = self.context

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            #if DEBUG
            print("✅ BiometricAuth: Passcode authentication \(success ? "succeeded" : "failed")")
            #endif

            return success
        } catch let laError as LAError {
            throw mapError(laError)
        } catch {
            throw BiometricAuthError.unknown(error)
        }
    }

    // MARK: - Error Mapping

    /// Map LAError to BiometricAuthError
    private func mapError(_ error: Error) -> BiometricAuthError {
        guard let laError = error as? LAError else {
            return .unknown(error)
        }

        switch laError.code {
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .lockout
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .invalidContext:
            return .invalidContext
        default:
            return .unknown(error)
        }
    }
}
