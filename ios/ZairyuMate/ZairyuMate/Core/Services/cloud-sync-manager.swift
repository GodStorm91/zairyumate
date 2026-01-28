//
//  cloud-sync-manager.swift
//  ZairyuMate
//
//  Orchestrates CloudKit sync with Core Data
//  Monitors sync state and provides manual sync triggers
//

import CoreData
import CloudKit
import SwiftUI

/// Sync state enumeration
enum CloudSyncState: Equatable {
    case idle
    case syncing
    case success
    case error(String)
}

/// Manages CloudKit synchronization with Core Data
@MainActor
@Observable
class CloudSyncManager {
    /// Current sync state
    var syncState: CloudSyncState = .idle

    /// Last successful sync timestamp
    var lastSyncDate: Date?

    /// Persistence container reference
    private let container: NSPersistentCloudKitContainer

    /// Remote change notification observer
    private nonisolated(unsafe) var remoteChangeObserver: NSObjectProtocol?

    /// Import notification observer
    private nonisolated(unsafe) var importObserver: NSObjectProtocol?

    /// Export notification observer
    private nonisolated(unsafe) var exportObserver: NSObjectProtocol?

    init(container: NSPersistentCloudKitContainer) {
        self.container = container
        setupSyncObservers()
    }

    deinit {
        if let observer = remoteChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = importObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = exportObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Setup observers for sync events
    private func setupSyncObservers() {
        // Observe remote changes
        remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleRemoteChange()
            }
        }

        // Observe import events
        importObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleCloudKitEvent(notification)
            }
        }
    }

    /// Handle remote change notification
    private func handleRemoteChange() {
        syncState = .syncing

        // Core Data automatically merges changes
        // Wait briefly then mark as success
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await MainActor.run {
                self.syncState = .success
                self.lastSyncDate = Date()

                // Auto-reset to idle after 3 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        if case .success = self.syncState {
                            self.syncState = .idle
                        }
                    }
                }
            }
        }
    }

    /// Handle CloudKit event notification
    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        switch event.type {
        case .setup:
            #if DEBUG
            print("☁️ CloudKit setup completed")
            #endif

        case .import:
            syncState = .syncing
            if let error = event.error {
                syncState = .error(error.localizedDescription)
                #if DEBUG
                print("❌ CloudKit import error: \(error.localizedDescription)")
                #endif
            } else {
                syncState = .success
                lastSyncDate = Date()
                #if DEBUG
                print("✅ CloudKit import successful")
                #endif
            }

        case .export:
            syncState = .syncing
            if let error = event.error {
                syncState = .error(error.localizedDescription)
                #if DEBUG
                print("❌ CloudKit export error: \(error.localizedDescription)")
                #endif
            } else {
                syncState = .success
                lastSyncDate = Date()
                #if DEBUG
                print("✅ CloudKit export successful")
                #endif
            }

        @unknown default:
            break
        }
    }

    /// Manually trigger sync by saving context
    func triggerSync() async {
        syncState = .syncing

        do {
            // Save context to trigger CloudKit sync
            if container.viewContext.hasChanges {
                try container.viewContext.save()
            }

            // Wait for sync to propagate
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            await MainActor.run {
                self.syncState = .success
                self.lastSyncDate = Date()
            }
        } catch {
            await MainActor.run {
                self.syncState = .error(error.localizedDescription)
            }
            #if DEBUG
            print("❌ Manual sync failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// Check if CloudKit is enabled
    var isCloudSyncEnabled: Bool {
        guard let description = container.persistentStoreDescriptions.first else {
            return false
        }
        return description.cloudKitContainerOptions != nil
    }

    /// Status message for UI
    var statusMessage: String {
        switch syncState {
        case .idle:
            if let lastSync = lastSyncDate {
                return "Last synced \(formatRelativeTime(lastSync))"
            }
            return "Ready to sync"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Up to date"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    /// Format relative time for display
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
