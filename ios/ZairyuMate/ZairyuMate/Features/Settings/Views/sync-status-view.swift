//
//  sync-status-view.swift
//  ZairyuMate
//
//  iCloud sync status indicator view
//  Shows current sync state, last sync time, and manual sync trigger
//

import SwiftUI

/// iCloud sync status indicator view
struct SyncStatusView: View {
    /// Cloud sync manager from environment
    @Environment(CloudSyncManager.self) private var syncManager

    /// iCloud status monitor from environment
    @Environment(iCloudStatusMonitor.self) private var icloudMonitor

    /// Is manual sync in progress
    @State private var isManualSyncing = false

    var body: some View {
        VStack(spacing: 16) {
            // Status indicator
            HStack(spacing: 12) {
                statusIcon

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusText)
                        .font(.body)
                        .foregroundColor(.primary)

                    if let lastSync = syncManager.lastSyncDate {
                        Text("Last synced \(formatRelativeTime(lastSync))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Manual sync button (only show if iCloud is available)
            if icloudMonitor.isAvailable {
                Button {
                    Task {
                        isManualSyncing = true
                        await syncManager.triggerSync()
                        isManualSyncing = false
                    }
                } label: {
                    HStack {
                        if isManualSyncing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(isManualSyncing ? "Syncing..." : "Sync Now")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isManualSyncing || syncManager.syncState == .syncing)
            } else {
                // iCloud not available
                iCloudUnavailableView
            }
        }
    }

    // MARK: - Subviews

    /// Status icon based on current state
    @ViewBuilder
    private var statusIcon: some View {
        Group {
            if !icloudMonitor.isAvailable {
                Image(systemName: icloudMonitor.statusIcon)
                    .foregroundColor(icloudMonitor.statusColor)
            } else {
                switch syncManager.syncState {
                case .idle:
                    Image(systemName: "icloud")
                        .foregroundColor(.gray)
                case .syncing:
                    ProgressView()
                        .progressViewStyle(.circular)
                case .success:
                    Image(systemName: "checkmark.icloud.fill")
                        .foregroundColor(.green)
                case .error:
                    Image(systemName: "exclamationmark.icloud.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .font(.title2)
    }

    /// Status text based on current state
    private var statusText: String {
        if !icloudMonitor.isAvailable {
            return icloudMonitor.statusDescription
        }

        return syncManager.statusMessage
    }

    /// iCloud unavailable view
    private var iCloudUnavailableView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("iCloud Not Available", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.orange)

            Text("Sign in to iCloud in Settings to enable sync across your devices.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    /// Format relative time for display
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    SyncStatusView()
        .environment(CloudSyncManager(container: PersistenceController.preview.container))
        .environment(iCloudStatusMonitor())
        .padding()
}
