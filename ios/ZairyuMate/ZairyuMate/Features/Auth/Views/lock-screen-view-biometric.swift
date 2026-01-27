//
//  lock-screen-view-biometric.swift
//  ZairyuMate
//
//  Lock screen overlay for biometric authentication
//  Shows biometric prompt on appear with PIN fallback option
//

import SwiftUI

struct LockScreenView: View {
    @Bindable var lockManager: AppLockManager
    @State private var showPINEntry = false
    @State private var showPINSetup = false
    @State private var isAuthenticating = false

    var body: some View {
        ZStack {
            // Background blur effect
            Color.white
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Lock icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.zmCardGradientStart.opacity(0.2), Color.zmCardGradientEnd.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.zmPrimary)
                }
                .padding(.bottom, Spacing.sm)

                // App name
                Text("Zairyu Mate")
                    .font(.title.bold())
                    .foregroundColor(.zmTextPrimary)

                // Description
                Text("Unlock to access your visa information")
                    .font(.subheadline)
                    .foregroundColor(.zmTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                Spacer()

                // Biometric button
                if lockManager.isBiometricAvailable {
                    PrimaryButton(
                        title: "Unlock with \(lockManager.biometryName)",
                        action: {
                            Task {
                                isAuthenticating = true
                                await lockManager.authenticateWithBiometrics()
                                isAuthenticating = false
                            }
                        },
                        isLoading: isAuthenticating
                    )
                    .padding(.horizontal, Spacing.xl)
                }

                // PIN button
                if lockManager.isPinSet {
                    Button(action: {
                        showPINEntry = true
                    }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "number.square.fill")
                                .font(.body)

                            Text("Use PIN")
                                .font(.zmHeadline)
                        }
                        .foregroundColor(.zmPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.zmBackground)
                        .cornerRadius(CornerRadius.button)
                    }
                    .padding(.horizontal, Spacing.xl)
                } else {
                    // Setup PIN option
                    Button(action: {
                        showPINSetup = true
                    }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(.body)

                            Text("Set Up PIN")
                                .font(.zmHeadline)
                        }
                        .foregroundColor(.zmPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.zmBackground)
                        .cornerRadius(CornerRadius.button)
                    }
                    .padding(.horizontal, Spacing.xl)
                }

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showPINEntry) {
            PINEntryView(lockManager: lockManager)
        }
        .sheet(isPresented: $showPINSetup) {
            PINSetupView(lockManager: lockManager)
        }
        .onAppear {
            // Automatically trigger biometric authentication if available
            if lockManager.isBiometricAvailable && !isAuthenticating {
                Task {
                    isAuthenticating = true
                    // Small delay for better UX
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    await lockManager.authenticateWithBiometrics()
                    isAuthenticating = false
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Biometrics") {
    @Previewable @State var lockManager: AppLockManager = {
        let manager = AppLockManager()
        manager.isLocked = true
        return manager
    }()

    LockScreenView(lockManager: lockManager)
}

#Preview("Without PIN") {
    @Previewable @State var lockManager: AppLockManager = {
        let manager = AppLockManager()
        manager.isLocked = true
        return manager
    }()

    LockScreenView(lockManager: lockManager)
}

#Preview("Dark Mode") {
    @Previewable @State var lockManager: AppLockManager = {
        let manager = AppLockManager()
        manager.isLocked = true
        return manager
    }()

    LockScreenView(lockManager: lockManager)
        .preferredColorScheme(.dark)
}
#endif
