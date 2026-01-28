//
//  home-empty-state-onboarding-view.swift
//  ZairyuMate
//
//  Empty state view for new users with no profiles
//  Prompts user to add their first profile with onboarding message
//

import SwiftUI

struct HomeEmptyStateView: View {

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.zmPrimary.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "person.crop.rectangle.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.zmPrimary)
            }

            // Welcome Message
            VStack(spacing: Spacing.sm) {
                Text("Welcome to Zairyu Mate")
                    .font(.zmTitle)
                    .foregroundColor(.zmTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Your personal assistant for managing your residence status in Japan")
                    .font(.zmBody)
                    .foregroundColor(.zmTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            // Features List
            VStack(alignment: .leading, spacing: Spacing.md) {
                OnboardingFeatureRow(
                    icon: "creditcard.fill",
                    title: "Virtual Zairyu Card",
                    description: "Keep your residence card info secure and accessible"
                )

                OnboardingFeatureRow(
                    icon: "bell.fill",
                    title: "Renewal Reminders",
                    description: "Never miss important visa deadlines"
                )

                OnboardingFeatureRow(
                    icon: "doc.text.fill",
                    title: "Document Management",
                    description: "Store and organize important documents"
                )
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)

            Spacer()

            // Call to Action Button
            NavigationLink(destination: ProfileFormPlaceholderView()) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))

                    Text("Add Your Profile")
                        .font(.zmHeadline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.zmPrimary)
                .cornerRadius(CornerRadius.button)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.zmBackground)
    }
}

// MARK: - Feature Row

private struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.zmPrimary)
                .frame(width: 32)

            // Text
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.zmHeadline)
                    .foregroundColor(.zmTextPrimary)

                Text(description)
                    .font(.zmCallout)
                    .foregroundColor(.zmTextSecondary)
            }
        }
    }
}

// MARK: - Placeholder View

struct ProfileFormPlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.zmPrimary)

            Text("Add Profile")
                .zmLargeTitleStyle()

            Text("Coming soon in Phase 05")
                .zmSecondaryBodyStyle()
        }
        .navigationTitle("New Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Empty State") {
    NavigationStack {
        HomeEmptyStateView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        HomeEmptyStateView()
            .preferredColorScheme(.dark)
    }
}

#Preview("With Navigation") {
    NavigationStack {
        HomeEmptyStateView()
            .navigationTitle("Zairyu Mate")
    }
}
#endif
