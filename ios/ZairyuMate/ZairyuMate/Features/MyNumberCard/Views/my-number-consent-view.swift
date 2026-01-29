//
//  my-number-consent-view.swift
//  ZairyuMate
//
//  Consent screen for My Number Card scanning (My Number Act compliance)
//  User must agree to privacy terms before scanning
//

import SwiftUI

struct MyNumberConsentView: View {

    @State private var hasAgreed = false
    let onConsent: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    headerSection

                    privacyNoticesSection

                    Divider()
                        .padding(.vertical, Spacing.sm)

                    agreementSection

                    continueButton
                }
                .padding(Spacing.md)
            }
            .background(Color.zmBackground)
            .navigationTitle("Privacy Notice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.zmPrimary)

            Text("My Number Card Privacy Notice")
                .zmLargeTitleStyle()
                .multilineTextAlignment(.center)

            Text("Please read and accept our privacy policy")
                .zmSecondaryBodyStyle()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Privacy Notices

    private var privacyNoticesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            PrivacyPointView(
                icon: "lock.shield",
                title: "100% On-Device Processing",
                description: "Your My Number is never transmitted to any server. All processing happens exclusively on your iPhone."
            )

            PrivacyPointView(
                icon: "eye.slash.fill",
                title: "Masked Display",
                description: "Only the last 4 digits of your My Number will be displayed in the app (****-****-1234)."
            )

            PrivacyPointView(
                icon: "key.fill",
                title: "Encrypted Storage",
                description: "Your My Number is encrypted using iOS Keychain with biometric protection."
            )

            PrivacyPointView(
                icon: "checkmark.shield.fill",
                title: "My Number Act Compliant",
                description: "This app complies with Japan's My Number Act (Act on the Use of Numbers to Identify a Specific Individual) and APPI regulations."
            )

            PrivacyPointView(
                icon: "hand.raised.fill",
                title: "Full Control",
                description: "You can view, edit, or delete your My Number data at any time from app settings."
            )
        }
    }

    // MARK: - Agreement

    private var agreementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Toggle(isOn: $hasAgreed) {
                Text("I understand and agree to store my My Number Card information on this device in accordance with the privacy policy above")
                    .zmBodyStyle()
            }
            .toggleStyle(SwitchToggleStyle(tint: .zmPrimary))

            Text("By agreeing, you confirm that:")
                .zmCaptionStyle()
                .foregroundColor(.zmSecondary)
                .padding(.top, Spacing.xs)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                bulletPoint("You are the lawful owner of this My Number Card")
                bulletPoint("You consent to on-device storage of your data")
                bulletPoint("You understand your data is encrypted and protected")
            }
            .zmCaptionStyle()
            .foregroundColor(.zmSecondary)
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: {
            onConsent()
        }) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                Text("I Agree - Continue to Scan")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(hasAgreed ? Color.zmPrimary : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.medium)
        }
        .disabled(!hasAgreed)
    }

    // MARK: - Helper Views

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Text("•")
            Text(text)
        }
    }
}

// MARK: - Privacy Point Component

struct PrivacyPointView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.zmPrimary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .zmHeadlineStyle()

                Text(description)
                    .zmSecondaryBodyStyle()
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(Color.zmPrimary.opacity(0.05))
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Consent") {
    MyNumberConsentView(onConsent: {})
}

#Preview("Dark Mode") {
    MyNumberConsentView(onConsent: {})
        .preferredColorScheme(.dark)
}
#endif
