//
//  home-quick-actions-section-view.swift
//  ZairyuMate
//
//  Quick action buttons for common tasks: Renew, Scan, Documents
//  Horizontal scrollable list with icon and label
//

import SwiftUI

struct HomeActionsSectionView: View {

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header
            Text("Quick Actions")
                .font(.zmTitle3)
                .foregroundColor(.zmTextPrimary)
                .padding(.horizontal, Spacing.screenHorizontal)

            // Action Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ActionButton(
                        title: "Renew",
                        icon: "arrow.clockwise.circle.fill",
                        color: .zmPrimary,
                        destination: RenewFormPlaceholderView()
                    )

                    ActionButton(
                        title: "Scan Card",
                        icon: "wave.3.right.circle.fill",
                        color: .green,
                        destination: NFCScanPlaceholderView()
                    )

                    ActionButton(
                        title: "Documents",
                        icon: "folder.fill",
                        color: .orange,
                        destination: DocumentsListPlaceholderView()
                    )

                    ActionButton(
                        title: "Timeline",
                        icon: "calendar.circle.fill",
                        color: .purple,
                        destination: TimelinePlaceholderView()
                    )
                }
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
    }
}

// MARK: - Action Button

struct ActionButton<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: Spacing.sm) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 70, height: 70)

                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(color)
                }

                // Label
                Text(title)
                    .font(.zmCaption)
                    .foregroundColor(.zmTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 90)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .accessibilityHint("Navigate to \(title)")
        }
    }
}

// MARK: - Placeholder Views

struct RenewFormPlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.zmPrimary)

            Text("Renewal Application")
                .zmLargeTitleStyle()

            Text("Coming soon in Phase 05")
                .zmSecondaryBodyStyle()
        }
        .navigationTitle("Renew")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NFCScanPlaceholderView: View {
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        NFCScanEntryView(
            entitlementManager: EntitlementManager(storeManager: storeManager)
        )
    }
}

struct DocumentsListPlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "folder.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Documents")
                .zmLargeTitleStyle()

            Text("Coming soon in Phase 06")
                .zmSecondaryBodyStyle()
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TimelinePlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            Text("Timeline")
                .zmLargeTitleStyle()

            Text("Coming soon in Phase 06")
                .zmSecondaryBodyStyle()
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Quick Actions") {
    NavigationStack {
        ScrollView {
            HomeActionsSectionView()
        }
        .background(Color.zmBackground)
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        ScrollView {
            HomeActionsSectionView()
        }
        .background(Color.zmBackground)
        .preferredColorScheme(.dark)
    }
}
#endif
