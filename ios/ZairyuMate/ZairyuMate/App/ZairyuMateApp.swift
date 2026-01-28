//
//  ZairyuMateApp.swift
//  ZairyuMate
//
//  Created on 2026-01-27
//  iOS app for managing Japanese visa applications and Zairyu card data
//

import SwiftUI

@main
struct ZairyuMateApp: App {
    // Initialize Core Data persistence controller
    let persistenceController = PersistenceController.shared

    // Initialize app lock manager
    @State private var lockManager = AppLockManager()

    // Initialize cloud sync manager
    @State private var syncManager: CloudSyncManager

    // Initialize iCloud status monitor
    @State private var icloudMonitor = iCloudStatusMonitor()

    init() {
        let controller = PersistenceController.shared
        _syncManager = State(initialValue: CloudSyncManager(container: controller.container))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeScreenView()
                    .environment(\.managedObjectContext, persistenceController.viewContext)
                    .environment(syncManager)
                    .environment(icloudMonitor)

                // Lock screen overlay
                if lockManager.isLocked {
                    LockScreenView(lockManager: lockManager)
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                lockManager.appDidEnterBackground()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Get biometric enabled setting from Core Data
                let context = persistenceController.viewContext
                let settings = AppSettings.shared(in: context)
                lockManager.appWillEnterForeground(biometricEnabled: settings.biometricEnabled)
            }
            .onAppear {
                // Check lock state on app launch
                let context = persistenceController.viewContext
                let settings = AppSettings.shared(in: context)
                lockManager.checkLockState(biometricEnabled: settings.biometricEnabled)

                // Sync widget data on app launch
                Task {
                    let profileService = ProfileService(persistenceController: persistenceController)
                    await profileService.syncWidgetOnLaunch()
                }
            }
        }
    }
}
