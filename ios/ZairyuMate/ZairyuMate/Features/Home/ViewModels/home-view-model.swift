//
//  home-view-model.swift
//  ZairyuMate
//
//  Home screen view model using @Observable for iOS 17+
//  Manages active profile, profile list, and upcoming events
//

import SwiftUI

@MainActor
@Observable
class HomeViewModel {

    // MARK: - Properties

    var activeProfile: Profile?
    var profiles: [Profile] = []
    var upcomingEvents: [TimelineEvent] = []
    var isLoading = false
    var errorMessage: String?

    private let profileService: ProfileService
    private let timelineService: TimelineEventService

    // MARK: - Computed Properties

    /// Calculate days until card expiry
    var daysUntilExpiry: Int {
        guard let expiry = activeProfile?.cardExpiry else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
    }

    /// Total days for progress calculation (1 year)
    var totalDaysForProgress: Int {
        return 365
    }

    /// Status message based on days remaining
    var expiryStatusMessage: String {
        let days = daysUntilExpiry
        if days < 0 {
            return "Expired"
        } else if days < 30 {
            return "Renew immediately!"
        } else if days < 90 {
            return "Renew soon"
        } else {
            return "Valid"
        }
    }

    /// Whether to show urgent warning
    var isUrgent: Bool {
        return daysUntilExpiry < 90 && daysUntilExpiry >= 0
    }

    // MARK: - Initialization

    nonisolated init(
        profileService: ProfileService,
        timelineService: TimelineEventService
    ) {
        self.profileService = profileService
        self.timelineService = timelineService
    }

    /// Convenience initializer with default services
    convenience init() {
        self.init(
            profileService: ProfileService(),
            timelineService: TimelineEventService()
        )
    }

    // MARK: - Data Loading

    /// Load all dashboard data
    func loadData() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Fetch all profiles
            profiles = try await profileService.fetchAll()

            // Fetch active profile
            activeProfile = try await profileService.fetchActive()

            #if DEBUG
            // Seed test profile if empty (for testing) - AFTER fetching to avoid timing issues
            if profiles.isEmpty && activeProfile == nil {
                print("🌱 Seeding test profile for DEBUG testing...")
                do {
                    let testProfile = try await profileService.create(
                        name: "Test User",
                        nameKatakana: "テスト ユーザー",
                        dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
                        nationality: "US",
                        address: "Tokyo, Japan",
                        cardNumber: "AB12 3456 78CD",
                        cardExpiry: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
                        visaType: "Engineer"
                    )
                    // Set as active
                    try await profileService.setActive(testProfile)
                    profiles = try await profileService.fetchAll()
                    activeProfile = testProfile
                    print("✅ Test profile created and activated")
                } catch {
                    print("⚠️ Failed to seed test profile: \(error)")
                }
            }
            #endif

            // Fetch upcoming events for active profile
            if let profile = activeProfile {
                let allEvents = try await timelineService.fetch(for: profile)
                upcomingEvents = allEvents
                    .filter { !$0.isCompleted && ($0.eventDate ?? Date.distantPast) >= Date() }
                    .sorted { ($0.eventDate ?? Date.distantPast) < ($1.eventDate ?? Date.distantPast) }
                    .prefix(5) // Show max 5 upcoming events
                    .map { $0 }
            } else {
                upcomingEvents = []
            }

            #if DEBUG
            print("✅ Loaded dashboard data: \(profiles.count) profiles, \(upcomingEvents.count) events")
            #endif

        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            #if DEBUG
            print("❌ Error loading dashboard data: \(error)")
            #endif
        }
    }

    /// Refresh data (for pull-to-refresh)
    func refreshData() async {
        await loadData()
    }

    // MARK: - Profile Management

    /// Select and activate a different profile
    /// - Parameter profile: Profile to activate
    func selectProfile(_ profile: Profile) async {
        guard profile.id != activeProfile?.id else { return }

        do {
            try await profileService.setActive(profile)
            activeProfile = profile

            // Reload events for new profile
            let allEvents = try await timelineService.fetch(for: profile)
            upcomingEvents = allEvents
                .filter { !$0.isCompleted && ($0.eventDate ?? Date.distantPast) >= Date() }
                .sorted { ($0.eventDate ?? Date.distantPast) < ($1.eventDate ?? Date.distantPast) }
                .prefix(5)
                .map { $0 }

            #if DEBUG
            print("✅ Switched to profile: \(profile.name)")
            #endif

        } catch {
            errorMessage = "Failed to switch profile: \(error.localizedDescription)"
            #if DEBUG
            print("❌ Error switching profile: \(error)")
            #endif
        }
    }

    // MARK: - Helper Methods

    /// Check if user has any profiles
    var hasProfiles: Bool {
        return !profiles.isEmpty
    }

    /// Check if user has multiple profiles
    var hasMultipleProfiles: Bool {
        return profiles.count > 1
    }
}
