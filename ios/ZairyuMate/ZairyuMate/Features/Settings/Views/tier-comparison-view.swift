//
//  tier-comparison-view.swift
//  ZairyuMate
//
//  Feature comparison view showing Free vs Pro tiers
//  Displays features in table format with visual indicators
//

import SwiftUI

// MARK: - Tier Comparison View

struct TierComparisonView: View {

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header row
            HStack {
                Text("Feature")
                    .font(.zmHeadline)
                    .foregroundColor(.zmTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Free")
                    .font(.zmHeadline)
                    .foregroundColor(.zmTextSecondary)
                    .frame(width: 70)

                Text("Pro")
                    .font(.zmHeadline)
                    .foregroundColor(.zmPrimary)
                    .frame(width: 70)
            }
            .padding(.bottom, Spacing.xs)

            Divider()

            // Feature rows
            VStack(spacing: Spacing.sm) {
                FeatureRow(
                    feature: "Manual entry",
                    free: .available,
                    pro: .available
                )

                FeatureRow(
                    feature: "Basic timeline",
                    free: .available,
                    pro: .available
                )

                FeatureRow(
                    feature: "Extension form",
                    free: .available,
                    pro: .available
                )

                FeatureRow(
                    feature: "PDF export",
                    free: .text("Watermark"),
                    pro: .text("Clean")
                )

                FeatureRow(
                    feature: "NFC card scan",
                    free: .unavailable,
                    pro: .available
                )

                FeatureRow(
                    feature: "iCloud sync",
                    free: .unavailable,
                    pro: .available
                )

                FeatureRow(
                    feature: "OCR passport",
                    free: .unavailable,
                    pro: .available
                )

                FeatureRow(
                    feature: "PR form",
                    free: .unavailable,
                    pro: .available
                )

                FeatureRow(
                    feature: "Profiles",
                    free: .text("1"),
                    pro: .text("Unlimited")
                )
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.card)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: String
    let free: FeatureValue
    let pro: FeatureValue

    var body: some View {
        HStack {
            Text(feature)
                .font(.zmBody)
                .foregroundColor(.zmTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            featureValueView(free)
                .frame(width: 70)

            featureValueView(pro)
                .frame(width: 70)
        }
        .padding(.vertical, Spacing.xs)
    }

    @ViewBuilder
    private func featureValueView(_ value: FeatureValue) -> some View {
        switch value {
        case .available:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))

        case .unavailable:
            Image(systemName: "xmark.circle")
                .foregroundColor(.zmTextSecondary)
                .font(.system(size: 20))

        case .text(let text):
            Text(text)
                .font(.zmCaption)
                .foregroundColor(.zmTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Feature Value

enum FeatureValue {
    case available
    case unavailable
    case text(String)
}

// MARK: - Preview

#if DEBUG
#Preview("Tier Comparison") {
    VStack {
        TierComparisonView()
    }
    .screenPadding()
    .background(Color.zmBackground)
}

#Preview("Dark Mode") {
    VStack {
        TierComparisonView()
    }
    .screenPadding()
    .background(Color.zmBackground)
    .preferredColorScheme(.dark)
}
#endif
