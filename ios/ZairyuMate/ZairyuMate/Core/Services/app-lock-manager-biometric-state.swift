//
//  app-lock-manager-biometric-state.swift
//  ZairyuMate
//
//  Manages app lock state with biometric and PIN authentication
//  Handles background/foreground transitions and cooldown logic
//

import SwiftUI
import Observation

/// Manager for app lock state using @Observable macro (iOS 17+)
@Observable
class AppLockManager {

    // MARK: - Lock State

    /// Whether app is currently locked
    var isLocked = true

    /// Number of failed authentication attempts
    var failedAttempts = 0

    /// Timestamp when cooldown period ends
    var cooldownEndTime: Date?

    // MARK: - Services

    let biometricService = BiometricAuthService()
    let pinService = PINAuthService()

    // MARK: - Configuration

    /// Lock timeout in seconds (0 = immediate)
    var lockTimeout: TimeInterval = 0

    // MARK: - Private Properties

    /// Timestamp when app entered background
    private var backgroundTime: Date?

    /// Maximum failed attempts before cooldown
    private let maxFailedAttempts = 3

    /// Cooldown duration in seconds
    private let cooldownDuration: TimeInterval = 30

    // MARK: - Computed Properties

    /// Check if currently in cooldown period
    var isInCooldown: Bool {
        guard let cooldownEnd = cooldownEndTime else { return false }
        return Date() < cooldownEnd
    }

    /// Seconds remaining in cooldown
    var cooldownSecondsRemaining: Int {
        guard let cooldownEnd = cooldownEndTime else { return 0 }
        let remaining = cooldownEnd.timeIntervalSince(Date())
        return max(0, Int(ceil(remaining)))
    }

    /// Get biometry type name for display
    var biometryName: String {
        biometricService.biometryName
    }

    /// Check if biometrics are available
    var isBiometricAvailable: Bool {
        biometricService.isBiometricAvailable
    }

    /// Check if PIN is set
    var isPinSet: Bool {
        pinService.isPinSet()
    }

    // MARK: - Lock State Management

    /// Check if app should be locked based on background time
    /// - Parameter biometricEnabled: Whether biometric lock is enabled in settings
    func checkLockState(biometricEnabled: Bool) {
        // If biometric lock is disabled, unlock
        guard biometricEnabled else {
            isLocked = false
            return
        }

        // If no background time recorded, lock
        guard let backgroundTime = backgroundTime else {
            isLocked = true
            return
        }

        // Check if enough time passed to trigger lock
        let timeInBackground = Date().timeIntervalSince(backgroundTime)
        if timeInBackground >= lockTimeout {
            isLocked = true
        } else {
            isLocked = false
        }

        #if DEBUG
        print("🔐 AppLock: Check state - locked=\(isLocked), backgroundTime=\(timeInBackground)s")
        #endif
    }

    /// Force lock the app
    func lock() {
        isLocked = true
        #if DEBUG
        print("🔐 AppLock: Locked")
        #endif
    }

    /// Unlock the app
    func unlock() {
        isLocked = false
        failedAttempts = 0
        cooldownEndTime = nil
        #if DEBUG
        print("🔓 AppLock: Unlocked")
        #endif
    }

    // MARK: - Biometric Authentication

    /// Authenticate user with biometrics
    /// - Returns: True if authentication succeeded
    func authenticateWithBiometrics() async -> Bool {
        // Don't allow authentication during cooldown
        guard !isInCooldown else {
            #if DEBUG
            print("⏱️ AppLock: Authentication blocked - in cooldown")
            #endif
            return false
        }

        do {
            let success = try await biometricService.authenticate(
                reason: "Unlock Zairyu Mate to access your visa information"
            )

            if success {
                unlock()
            }

            return success
        } catch {
            #if DEBUG
            print("⚠️ AppLock: Biometric auth failed - \(error.localizedDescription)")
            #endif
            return false
        }
    }

    // MARK: - PIN Authentication

    /// Authenticate user with PIN
    /// - Parameter pin: 6-digit PIN
    /// - Returns: True if authentication succeeded
    func authenticateWithPIN(_ pin: String) -> Bool {
        // Don't allow authentication during cooldown
        guard !isInCooldown else {
            #if DEBUG
            print("⏱️ AppLock: PIN authentication blocked - in cooldown")
            #endif
            return false
        }

        // Verify PIN
        if pinService.verifyPin(pin) {
            unlock()
            return true
        } else {
            // Increment failed attempts
            failedAttempts += 1

            #if DEBUG
            print("❌ AppLock: PIN failed - attempt \(failedAttempts)/\(maxFailedAttempts)")
            #endif

            // Trigger cooldown after max attempts
            if failedAttempts >= maxFailedAttempts {
                startCooldown()
            }

            return false
        }
    }

    // MARK: - Cooldown Management

    /// Start cooldown period after too many failed attempts
    private func startCooldown() {
        cooldownEndTime = Date().addingTimeInterval(cooldownDuration)

        #if DEBUG
        print("⏱️ AppLock: Cooldown started - \(Int(cooldownDuration))s")
        #endif
    }

    /// Reset cooldown and failed attempts
    func resetCooldown() {
        cooldownEndTime = nil
        failedAttempts = 0

        #if DEBUG
        print("✅ AppLock: Cooldown reset")
        #endif
    }

    // MARK: - App Lifecycle

    /// Called when app enters background
    func appDidEnterBackground() {
        backgroundTime = Date()

        #if DEBUG
        print("📱 AppLock: App entered background")
        #endif
    }

    /// Called when app enters foreground
    /// - Parameter biometricEnabled: Whether biometric lock is enabled
    func appWillEnterForeground(biometricEnabled: Bool) {
        checkLockState(biometricEnabled: biometricEnabled)

        #if DEBUG
        print("📱 AppLock: App entered foreground")
        #endif
    }

    // MARK: - PIN Management

    /// Set up new PIN
    /// - Parameter pin: 6-digit PIN
    /// - Throws: PINAuthError if PIN is invalid
    func setupPin(_ pin: String) throws {
        try pinService.setPin(pin)

        #if DEBUG
        print("✅ AppLock: PIN setup complete")
        #endif
    }

    /// Change existing PIN
    /// - Parameters:
    ///   - oldPin: Current PIN
    ///   - newPin: New PIN
    /// - Throws: PINAuthError if verification fails
    func changePin(oldPin: String, newPin: String) throws {
        try pinService.changePin(oldPin: oldPin, newPin: newPin)

        #if DEBUG
        print("✅ AppLock: PIN changed")
        #endif
    }

    /// Clear stored PIN
    func clearPin() throws {
        try pinService.clearPin()

        #if DEBUG
        print("✅ AppLock: PIN cleared")
        #endif
    }
}
