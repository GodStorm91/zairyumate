//
//  profile-list-view-model.swift
//  ZairyuMate
//
//  ViewModel for profile list management
//  Handles loading, deleting, and activating profiles
//

import Foundation
import Observation

@MainActor
@Observable
class ProfileListViewModel {

    // MARK: - State

    var profiles: [Profile] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var showingError: Bool = false

    // Undo delete state
    var deletedProfile: Profile?
    var undoTimer: Timer?
    var showingUndoAlert: Bool = false

    // MARK: - Dependencies

    private let profileService: ProfileService

    // MARK: - Initialization

    nonisolated init(profileService: ProfileService) {
        self.profileService = profileService
    }

    /// Convenience initializer with default service
    convenience init() {
        self.init(profileService: ProfileService())
    }

    // MARK: - Load Profiles

    func loadProfiles() async {
        isLoading = true
        defer { isLoading = false }

        do {
            profiles = try await profileService.fetchAll()

            #if DEBUG
            print("✅ Loaded \(profiles.count) profiles")
            #endif
        } catch {
            errorMessage = "Failed to load profiles: \(error.localizedDescription)"
            showingError = true

            #if DEBUG
            print("❌ Failed to load profiles: \(error)")
            #endif
        }
    }

    // MARK: - Delete Profiles

    /// Delete profiles at given offsets with undo support
    func deleteProfiles(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let profile = profiles[index]

        // Store for undo
        deletedProfile = profile
        showingUndoAlert = true

        // Remove from list immediately
        profiles.remove(atOffsets: offsets)

        // Start timer for permanent deletion
        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.confirmDelete()
            }
        }
    }

    /// Undo delete operation
    func undoDelete() {
        undoTimer?.invalidate()
        undoTimer = nil

        if let profile = deletedProfile {
            // Re-insert profile
            profiles.insert(profile, at: 0)
            profiles.sort { $0.isActive && !$1.isActive || $0.createdAt ?? Date() > $1.createdAt ?? Date() }
        }

        deletedProfile = nil
        showingUndoAlert = false

        #if DEBUG
        print("✅ Undo delete profile")
        #endif
    }

    /// Permanently delete profile after timeout
    private func confirmDelete() async {
        guard let profile = deletedProfile else { return }

        do {
            try await profileService.delete(profile)
            deletedProfile = nil
            showingUndoAlert = false

            #if DEBUG
            print("✅ Permanently deleted profile: \(profile.name)")
            #endif
        } catch {
            errorMessage = "Failed to delete profile: \(error.localizedDescription)"
            showingError = true

            // Re-add profile on error
            await loadProfiles()

            #if DEBUG
            print("❌ Failed to delete profile: \(error)")
            #endif
        }
    }

    /// Delete profile immediately (no undo)
    func deleteProfileImmediately(_ profile: Profile) async {
        do {
            try await profileService.delete(profile)
            await loadProfiles()

            #if DEBUG
            print("✅ Deleted profile: \(profile.name)")
            #endif
        } catch {
            errorMessage = "Failed to delete profile: \(error.localizedDescription)"
            showingError = true

            #if DEBUG
            print("❌ Failed to delete profile: \(error)")
            #endif
        }
    }

    // MARK: - Activate Profile

    func setActiveProfile(_ profile: Profile) async {
        do {
            try await profileService.setActive(profile)
            await loadProfiles()

            #if DEBUG
            print("✅ Set active profile: \(profile.name)")
            #endif
        } catch {
            errorMessage = "Failed to set active profile: \(error.localizedDescription)"
            showingError = true

            #if DEBUG
            print("❌ Failed to set active profile: \(error)")
            #endif
        }
    }

    // MARK: - Statistics

    var totalProfiles: Int {
        profiles.count
    }

    var activeProfile: Profile? {
        profiles.first { $0.isActive }
    }

    var hasProfiles: Bool {
        !profiles.isEmpty
    }
}
