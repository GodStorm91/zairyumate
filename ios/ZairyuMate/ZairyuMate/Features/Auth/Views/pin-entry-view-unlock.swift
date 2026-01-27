//
//  pin-entry-view-unlock.swift
//  ZairyuMate
//
//  PIN entry view for unlocking the app
//  Shows dots for entered digits and cooldown after failed attempts
//

import SwiftUI

struct PINEntryView: View {
    @Bindable var lockManager: AppLockManager
    @Environment(\.dismiss) private var dismiss

    @State private var pin = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isShaking = false
    @State private var cooldownTimer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Lock icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.zmPrimary)
                    .padding(.bottom, Spacing.sm)

                // Title
                Text("Enter PIN")
                    .font(.title2.bold())
                    .foregroundColor(.zmTextPrimary)

                // Subtitle
                if lockManager.isInCooldown {
                    Text("Too many failed attempts")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.bottom, Spacing.xs)

                    Text("Try again in \(lockManager.cooldownSecondsRemaining)s")
                        .font(.caption)
                        .foregroundColor(.zmTextSecondary)
                        .monospacedDigit()
                } else {
                    Text("Unlock to access your visa information")
                        .font(.subheadline)
                        .foregroundColor(.zmTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                // PIN dots
                HStack(spacing: Spacing.md) {
                    ForEach(0..<6) { index in
                        Circle()
                            .fill(index < pin.count ? Color.zmPrimary : Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.vertical, Spacing.lg)
                .offset(x: isShaking ? -10 : 0)
                .animation(isShaking ? .spring(response: 0.2, dampingFraction: 0.2) : .default, value: isShaking)

                // Error message
                if showError && !lockManager.isInCooldown {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                Spacer()

                // Number pad
                NumPadView(pin: $pin, onComplete: verifyPIN)
                    .disabled(lockManager.isInCooldown)
                    .opacity(lockManager.isInCooldown ? 0.5 : 1.0)

                Spacer()
            }
            .padding()
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.zmPrimary)
                }
            }
            .onAppear {
                if lockManager.isInCooldown {
                    startCooldownTimer()
                }
            }
            .onDisappear {
                cooldownTimer?.invalidate()
            }
        }
    }

    // MARK: - Actions

    private func verifyPIN() {
        // Check cooldown
        guard !lockManager.isInCooldown else {
            return
        }

        // Verify PIN
        if lockManager.authenticateWithPIN(pin) {
            // Success - dismiss
            dismiss()
        } else {
            // Failed - show error
            handleFailedAttempt()
        }
    }

    private func handleFailedAttempt() {
        // Shake animation
        isShaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isShaking = false
        }

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        // Clear PIN
        pin = ""

        // Show error message
        if lockManager.isInCooldown {
            errorMessage = "Too many failed attempts. Please wait."
            startCooldownTimer()
        } else {
            let attemptsRemaining = 3 - lockManager.failedAttempts
            errorMessage = "Incorrect PIN. \(attemptsRemaining) attempt\(attemptsRemaining == 1 ? "" : "s") remaining."
        }

        showError = true

        // Hide error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if !lockManager.isInCooldown {
                showError = false
            }
        }
    }

    private func startCooldownTimer() {
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !lockManager.isInCooldown {
                timer.invalidate()
                showError = false
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Normal State") {
    @Previewable @State var lockManager = AppLockManager()

    PINEntryView(lockManager: lockManager)
}

#Preview("With Error") {
    @Previewable @State var lockManager: AppLockManager = {
        let manager = AppLockManager()
        manager.failedAttempts = 1
        return manager
    }()

    PINEntryView(lockManager: lockManager)
}

#Preview("Dark Mode") {
    @Previewable @State var lockManager = AppLockManager()

    PINEntryView(lockManager: lockManager)
        .preferredColorScheme(.dark)
}
#endif
