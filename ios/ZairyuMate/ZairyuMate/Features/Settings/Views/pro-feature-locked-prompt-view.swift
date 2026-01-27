//
//  pro-feature-locked-prompt-view.swift
//  ZairyuMate
//
//  Prompt view displayed when user tries to access locked Pro features
//  Shows feature name, description, and upgrade call-to-action
//

import SwiftUI

// MARK: - Pro Feature Locked View

struct ProFeatureLockedView: View {

    // MARK: - Properties

    let feature: String
    let icon: String
    let description: String

    // MARK: - Initialization

    init(
        feature: String,
        icon: String = "lock.fill",
        description: String? = nil
    ) {
        self.feature = feature
        self.icon = icon
        self.description = description ?? "Upgrade to Pro to unlock \(feature)"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Lock icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.zmPrimary.opacity(0.2),
                                Color.zmPrimary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.zmPrimary)
            }

            // Feature name
            Text(feature)
                .font(.zmTitle2)
                .foregroundColor(.zmTextPrimary)
                .multilineTextAlignment(.center)

            // Description
            Text(description)
                .font(.zmBody)
                .foregroundColor(.zmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            // Upgrade button
            NavigationLink(destination: ProUpgradeView()) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "star.fill")
                    Text("Upgrade to Pro")
                }
                .font(.zmHeadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.zmPrimary)
                .cornerRadius(CornerRadius.button)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.md)

            Spacer()
        }
        .padding(.vertical, Spacing.xl)
        .background(Color.zmBackground)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("NFC Locked") {
    NavigationStack {
        ProFeatureLockedView(
            feature: "NFC Card Scan",
            icon: "wave.3.right",
            description: "Scan your Zairyu Card using NFC technology to automatically import your information."
        )
    }
}

#Preview("iCloud Sync Locked") {
    NavigationStack {
        ProFeatureLockedView(
            feature: "iCloud Sync",
            icon: "icloud",
            description: "Sync your profiles and documents across all your devices using iCloud."
        )
    }
}

#Preview("OCR Locked") {
    NavigationStack {
        ProFeatureLockedView(
            feature: "OCR Passport Scan",
            icon: "doc.text.viewfinder",
            description: "Scan your passport with your camera to automatically extract information."
        )
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        ProFeatureLockedView(
            feature: "NFC Card Scan",
            icon: "wave.3.right"
        )
    }
    .preferredColorScheme(.dark)
}
#endif
