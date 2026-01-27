//
//  home-card-section-with-countdown-view.swift
//  ZairyuMate
//
//  Displays Zairyu card with countdown ring showing days until expiry
//  Includes status message and expiry warning indicators
//

import SwiftUI

struct HomeCardSectionView: View {

    // MARK: - Properties

    let profile: Profile
    let daysRemaining: Int
    let totalDays: Int
    let statusMessage: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Zairyu Card
            if let cardNumber = profile.cardNumber,
               let visaType = profile.visaType,
               let expiryDate = profile.cardExpiry {
                ZairyuCardView(
                    name: profile.name,
                    cardNumber: cardNumber,
                    visaType: visaType,
                    expiryDate: expiryDate
                )
                .padding(.horizontal, Spacing.screenHorizontal)
            } else {
                incompleteCardPlaceholder
            }

            // Countdown Ring + Status
            countdownSection
        }
    }

    // MARK: - Countdown Section

    @ViewBuilder
    private var countdownSection: some View {
        HStack(spacing: Spacing.lg) {
            // Countdown Ring
            CountdownRingView(
                daysRemaining: daysRemaining,
                totalDays: totalDays
            )

            // Status Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Days until expiry")
                    .font(.zmCallout)
                    .foregroundColor(.zmTextSecondary)

                Text(statusMessage)
                    .font(.zmTitle3)
                    .foregroundColor(statusColor)

                if let expiryDate = profile.cardExpiry {
                    Text("Expires: \(expiryDate.displayFormatted)")
                        .font(.zmCaption)
                        .foregroundColor(.zmTextSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Incomplete Card Placeholder

    @ViewBuilder
    private var incompleteCardPlaceholder: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Incomplete Profile")
                .font(.zmHeadline)
                .foregroundColor(.zmTextPrimary)

            Text("Add your Zairyu card details to see your virtual card")
                .font(.zmBody)
                .foregroundColor(.zmTextSecondary)
                .multilineTextAlignment(.center)

            NavigationLink(destination: ProfileEditPlaceholderView()) {
                Text("Edit Profile")
                    .font(.zmHeadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.zmPrimary)
                    .cornerRadius(CornerRadius.button)
            }
        }
        .padding(Spacing.xl)
        .background(Color.white.opacity(0.05))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        if daysRemaining < 0 {
            return .red
        } else if daysRemaining < 30 {
            return .red
        } else if daysRemaining < 90 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Placeholder View

struct ProfileEditPlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.zmPrimary)

            Text("Edit Profile")
                .zmLargeTitleStyle()

            Text("Coming soon in Phase 05")
                .zmSecondaryBodyStyle()
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Complete Profile") {
    let context = PersistenceController.preview.viewContext
    let profile = Profile(context: context)
    profile.name = "山田太郎"
    profile.cardNumber = "1234567890123456"
    profile.visaType = "就労"
    profile.cardExpiry = Calendar.current.date(byAdding: .day, value: 180, to: Date())

    return ScrollView {
        HomeCardSectionView(
            profile: profile,
            daysRemaining: 180,
            totalDays: 365,
            statusMessage: "Valid"
        )
    }
    .background(Color.zmBackground)
}

#Preview("Warning Status") {
    let context = PersistenceController.preview.viewContext
    let profile = Profile(context: context)
    profile.name = "田中花子"
    profile.cardNumber = "9876543210987654"
    profile.visaType = "留学"
    profile.cardExpiry = Calendar.current.date(byAdding: .day, value: 60, to: Date())

    return ScrollView {
        HomeCardSectionView(
            profile: profile,
            daysRemaining: 60,
            totalDays: 365,
            statusMessage: "Renew soon"
        )
    }
    .background(Color.zmBackground)
}

#Preview("Urgent Status") {
    let context = PersistenceController.preview.viewContext
    let profile = Profile(context: context)
    profile.name = "佐藤次郎"
    profile.cardNumber = "1111222233334444"
    profile.visaType = "永住"
    profile.cardExpiry = Calendar.current.date(byAdding: .day, value: 15, to: Date())

    return ScrollView {
        HomeCardSectionView(
            profile: profile,
            daysRemaining: 15,
            totalDays: 365,
            statusMessage: "Renew immediately!"
        )
    }
    .background(Color.zmBackground)
}

#Preview("Incomplete Profile") {
    let context = PersistenceController.preview.viewContext
    let profile = Profile(context: context)
    profile.name = "田中二郎"
    // No card details

    return ScrollView {
        HomeCardSectionView(
            profile: profile,
            daysRemaining: 0,
            totalDays: 365,
            statusMessage: "No data"
        )
    }
    .background(Color.zmBackground)
}
#endif
