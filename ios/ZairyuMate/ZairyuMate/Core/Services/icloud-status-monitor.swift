//
//  icloud-status-monitor.swift
//  ZairyuMate
//
//  Monitors iCloud account status and availability
//  Observes CKAccountChanged notifications for real-time updates
//

import CloudKit
import SwiftUI

/// Monitors iCloud account status and provides availability information
@MainActor
@Observable
class iCloudStatusMonitor {
    /// Current iCloud account status
    var accountStatus: CKAccountStatus = .couldNotDetermine

    /// Whether iCloud is currently available for sync
    var isAvailable: Bool = false

    /// Error message if status check failed
    var errorMessage: String?

    /// Notification observer token
    private var accountChangeObserver: NSObjectProtocol?

    init() {
        checkAccountStatus()
        observeAccountChanges()
    }

    deinit {
        if let observer = accountChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Check current iCloud account status
    func checkAccountStatus() {
        Task {
            do {
                let status = try await CKContainer.default().accountStatus()
                await MainActor.run {
                    self.accountStatus = status
                    self.isAvailable = status == .available
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.accountStatus = .couldNotDetermine
                    self.isAvailable = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Observe account status changes
    private func observeAccountChanges() {
        accountChangeObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAccountStatus()
            }
        }
    }

    /// Human-readable status description
    var statusDescription: String {
        switch accountStatus {
        case .available:
            return "iCloud Connected"
        case .noAccount:
            return "No iCloud Account"
        case .restricted:
            return "iCloud Restricted"
        case .couldNotDetermine:
            return "Checking iCloud..."
        case .temporarilyUnavailable:
            return "iCloud Temporarily Unavailable"
        @unknown default:
            return "Unknown Status"
        }
    }

    /// Status icon name for UI
    var statusIcon: String {
        switch accountStatus {
        case .available:
            return "checkmark.icloud.fill"
        case .noAccount:
            return "exclamationmark.icloud"
        case .restricted:
            return "lock.icloud"
        case .couldNotDetermine:
            return "icloud"
        case .temporarilyUnavailable:
            return "exclamationmark.icloud.fill"
        @unknown default:
            return "questionmark.icloud"
        }
    }

    /// Status color for UI
    var statusColor: Color {
        switch accountStatus {
        case .available:
            return .green
        case .noAccount, .restricted, .temporarilyUnavailable:
            return .orange
        case .couldNotDetermine:
            return .gray
        @unknown default:
            return .gray
        }
    }
}
