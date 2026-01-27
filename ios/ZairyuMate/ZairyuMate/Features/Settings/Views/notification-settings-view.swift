//
//  notification-settings-view.swift
//  ZairyuMate
//
//  Notification settings UI for managing reminder preferences
//  Allows users to enable/disable notifications and customize reminder schedule
//

import SwiftUI

struct NotificationSettingsView: View {

    // MARK: - State

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderDays") private var reminderDaysData = Data()

    @State private var reminderDays: Set<Int> = [90, 60, 30, 14, 7, 3, 1]
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false
    @State private var pendingNotificationCount = 0

    // MARK: - Available reminder options

    private let availableReminderDays = [90, 60, 30, 14, 7, 3, 1]

    // MARK: - Body

    var body: some View {
        Form {
            // Permission status section
            permissionSection

            // Toggle notifications
            toggleSection

            // Reminder schedule section
            if notificationsEnabled {
                reminderScheduleSection
            }

            // Info section
            infoSection
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadReminderDays()
            checkPermissionStatus()
            loadPendingNotificationCount()
        }
        .alert("Notification Permission Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in Settings to receive visa expiry reminders.")
        }
    }

    // MARK: - Sections

    private var permissionSection: some View {
        Section {
            HStack {
                Image(systemName: permissionIcon)
                    .foregroundStyle(permissionColor)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Permission Status")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(permissionStatusText)
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                Spacer()

                if permissionStatus == .denied {
                    Button("Settings") {
                        openAppSettings()
                    }
                    .font(.subheadline)
                }
            }
            .padding(.vertical, 4)

            if permissionStatus == .notDetermined {
                Button("Request Permission") {
                    requestPermission()
                }
                .frame(maxWidth: .infinity)
            }
        } header: {
            Text("System Permission")
        }
    }

    private var toggleSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { oldValue, newValue in
                    handleNotificationToggle(enabled: newValue)
                }
        } footer: {
            Text("Receive reminders before your visa expires to ensure timely renewal.")
        }
    }

    private var reminderScheduleSection: some View {
        Section {
            ForEach(availableReminderDays, id: \.self) { days in
                Toggle(isOn: binding(for: days)) {
                    HStack {
                        Text("\(days) days before")
                            .font(.body)

                        Spacer()

                        Text(reminderDescription(for: days))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!notificationsEnabled)
            }
        } header: {
            Text("Reminder Schedule")
        } footer: {
            if pendingNotificationCount > 0 {
                Text("You have \(pendingNotificationCount) reminder(s) scheduled.")
            } else {
                Text("Customize when you want to receive reminders. At least one reminder is recommended.")
            }
        }
    }

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "wifi.slash",
                    title: "Works Offline",
                    description: "Reminders are scheduled locally on your device"
                )

                Divider()

                InfoRow(
                    icon: "bell.badge",
                    title: "Smart Reminders",
                    description: "Notifications include actionable steps for visa renewal"
                )

                Divider()

                InfoRow(
                    icon: "moon.zzz",
                    title: "Do Not Disturb",
                    description: "Respects system Do Not Disturb settings"
                )
            }
            .padding(.vertical, 4)
        } header: {
            Text("About Notifications")
        }
    }

    // MARK: - Helper Views

    private var permissionIcon: String {
        switch permissionStatus {
        case .authorized: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        default: return "bell.slash.fill"
        }
    }

    private var permissionColor: Color {
        switch permissionStatus {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        default: return .gray
        }
    }

    private var permissionStatusText: String {
        switch permissionStatus {
        case .authorized: return "Allowed"
        case .denied: return "Denied"
        case .notDetermined: return "Not Requested"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Helper Methods

    private func binding(for days: Int) -> Binding<Bool> {
        Binding(
            get: { reminderDays.contains(days) },
            set: { enabled in
                if enabled {
                    reminderDays.insert(days)
                } else {
                    reminderDays.remove(days)
                }
                saveReminderDays()
            }
        )
    }

    private func reminderDescription(for days: Int) -> String {
        switch days {
        case 90: return "3 months"
        case 60: return "2 months"
        case 30: return "1 month"
        case 14: return "2 weeks"
        case 7: return "1 week"
        case 3: return "3 days"
        case 1: return "1 day"
        default: return "\(days) days"
        }
    }

    private func saveReminderDays() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(Array(reminderDays)) {
            reminderDaysData = encoded
            print("✅ Reminder days saved: \(reminderDays.sorted())")
        }
    }

    private func loadReminderDays() {
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([Int].self, from: reminderDaysData) {
            reminderDays = Set(decoded)
            print("✅ Reminder days loaded: \(reminderDays.sorted())")
        } else {
            // Default values
            reminderDays = [90, 60, 30, 14, 7, 3, 1]
        }
    }

    private func handleNotificationToggle(enabled: Bool) {
        if enabled {
            if permissionStatus == .denied {
                showPermissionAlert = true
            } else if permissionStatus == .notDetermined {
                requestPermission()
            }
        } else {
            // Cancel all notifications when disabled
            NotificationScheduler.shared.cancelAllNotifications()
            pendingNotificationCount = 0
        }
    }

    private func requestPermission() {
        Task {
            let granted = await NotificationScheduler.shared.requestPermission()
            await MainActor.run {
                permissionStatus = granted ? .authorized : .denied
                notificationsEnabled = granted
            }
        }
    }

    private func checkPermissionStatus() {
        Task {
            let status = await NotificationScheduler.shared.checkPermissionStatus()
            await MainActor.run {
                permissionStatus = status
                if status == .denied {
                    notificationsEnabled = false
                }
            }
        }
    }

    private func loadPendingNotificationCount() {
        Task {
            let count = await NotificationScheduler.shared.getPendingNotificationCount()
            await MainActor.run {
                pendingNotificationCount = count
            }
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
