//
//  pin-setup-view-creation.swift
//  ZairyuMate
//
//  PIN setup view for creating a new PIN
//  Two-step process: enter PIN, then confirm PIN
//

import SwiftUI

struct PINSetupView: View {
    @Bindable var lockManager: AppLockManager
    @Environment(\.dismiss) private var dismiss

    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var isConfirming = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isShaking = false

    var onComplete: (() -> Void)?

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
                Text(isConfirming ? "Confirm PIN" : "Create PIN")
                    .font(.title2.bold())
                    .foregroundColor(.zmTextPrimary)

                // Subtitle
                Text(isConfirming ? "Enter your PIN again to confirm" : "Create a 6-digit PIN to secure your app")
                    .font(.subheadline)
                    .foregroundColor(.zmTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                // PIN dots
                HStack(spacing: Spacing.md) {
                    ForEach(0..<6) { index in
                        Circle()
                            .fill(index < currentPin.count ? Color.zmPrimary : Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.vertical, Spacing.lg)
                .offset(x: isShaking ? -10 : 0)
                .animation(isShaking ? .spring(response: 0.2, dampingFraction: 0.2) : .default, value: isShaking)

                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                Spacer()

                // Number pad
                NumPadView(pin: Binding(
                    get: { currentPin },
                    set: { newValue in
                        if isConfirming {
                            confirmPin = newValue
                        } else {
                            pin = newValue
                        }
                    }
                ), onComplete: handlePINComplete)

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

                if isConfirming {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Back") {
                            // Go back to PIN entry
                            isConfirming = false
                            confirmPin = ""
                            showError = false
                        }
                        .foregroundColor(.zmPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var currentPin: String {
        isConfirming ? confirmPin : pin
    }

    // MARK: - Actions

    private func handlePINComplete() {
        if isConfirming {
            // Verify PINs match
            if pin == confirmPin {
                // Save PIN
                do {
                    try lockManager.setupPin(pin)

                    // Success feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)

                    // Call completion handler
                    onComplete?()

                    // Dismiss
                    dismiss()
                } catch {
                    showError(message: "Failed to save PIN. Please try again.")
                }
            } else {
                // PINs don't match
                showError(message: "PINs don't match. Please try again.")

                // Shake animation
                triggerShake()

                // Reset to first step
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isConfirming = false
                    pin = ""
                    confirmPin = ""
                    showError = false
                }
            }
        } else {
            // Move to confirmation step
            isConfirming = true
            showError = false
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        // Clear PIN
        confirmPin = ""

        // Auto-hide error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }

    private func triggerShake() {
        isShaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isShaking = false
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Create PIN Step") {
    @Previewable @State var lockManager = AppLockManager()

    PINSetupView(lockManager: lockManager)
}

#Preview("Confirm PIN Step") {
    @Previewable @State var lockManager = AppLockManager()

    PINSetupView(lockManager: lockManager, pin: "123456", isConfirming: true)
}

#Preview("Dark Mode") {
    @Previewable @State var lockManager = AppLockManager()

    PINSetupView(lockManager: lockManager)
        .preferredColorScheme(.dark)
}
#endif
