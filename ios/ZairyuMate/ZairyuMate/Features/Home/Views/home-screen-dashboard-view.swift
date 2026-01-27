//
//  home-screen-dashboard-view.swift
//  ZairyuMate
//
//  Main home dashboard with Zairyu card, countdown, and quick actions
//  Includes profile switcher and pull-to-refresh functionality
//

import SwiftUI

struct HomeScreenView: View {

    // MARK: - Properties

    @State private var viewModel = HomeViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zmBackground
                    .ignoresSafeArea()

                if viewModel.hasProfiles {
                    dashboardContent
                } else {
                    HomeEmptyStateView()
                }
            }
            .navigationTitle("Zairyu Mate")
            .toolbar {
                toolbarContent
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: Spacing.section) {
                if let profile = viewModel.activeProfile {
                    // Zairyu Card + Countdown Section
                    HomeCardSectionView(
                        profile: profile,
                        daysRemaining: viewModel.daysUntilExpiry,
                        totalDays: viewModel.totalDaysForProgress,
                        statusMessage: viewModel.expiryStatusMessage
                    )

                    // Quick Actions Section
                    HomeActionsSectionView()

                    // Upcoming Events Section
                    if !viewModel.upcomingEvents.isEmpty {
                        UpcomingEventsSectionView(events: viewModel.upcomingEvents)
                    }
                } else if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding(.top, 100)
                } else {
                    HomeEmptyStateView()
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Profile Selector (Left)
        ToolbarItem(placement: .topBarLeading) {
            if viewModel.hasMultipleProfiles {
                ProfileSelectorView(
                    profiles: viewModel.profiles,
                    selectedProfile: Binding(
                        get: { viewModel.activeProfile },
                        set: { newProfile in
                            if let profile = newProfile {
                                Task {
                                    await viewModel.selectProfile(profile)
                                }
                            }
                        }
                    ),
                    displayName: { $0.name }
                )
            }
        }

        // Settings Button (Right)
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink(destination: SettingsPlaceholderView()) {
                Image(systemName: "gearshape")
                    .foregroundColor(.zmPrimary)
                    .accessibilityLabel("Settings")
            }
        }
    }
}

// MARK: - Placeholder Views

struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(.zmPrimary)

            Text("Settings")
                .zmLargeTitleStyle()

            Text("Coming soon in Phase 06")
                .zmSecondaryBodyStyle()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Active Profile") {
    HomeScreenView()
}

#Preview("Dark Mode") {
    HomeScreenView()
        .preferredColorScheme(.dark)
}
#endif
