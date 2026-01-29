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
    // Using @ObservedObject (not @StateObject) because shared singleton is pre-initialized
    // This ensures SwiftUI properly observes isStoreLoaded changes during async loading
    @ObservedObject private var persistenceController = PersistenceController.shared

    // Initialize app lock manager
    @State private var lockManager = AppLockManager()

    // Initialize cloud sync manager
    @State private var syncManager: CloudSyncManager

    // Initialize iCloud status monitor
    @State private var icloudMonitor = iCloudStatusMonitor()

    // Initialize StoreKit manager for in-app purchases
    @State private var storeManager = StoreManager()

    init() {
        let controller = PersistenceController.shared
        _syncManager = State(initialValue: CloudSyncManager(container: controller.container))
    }

    var body: some Scene {
        WindowGroup {
            // Show loading screen until Core Data store is ready
            if persistenceController.isStoreLoaded {
                ZStack {
                    HomeScreenView()
                        .environment(\.managedObjectContext, persistenceController.viewContext)
                        .environment(syncManager)
                        .environment(icloudMonitor)
                        .environment(storeManager)

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
                    Task {
                        // Small delay to ensure Core Data is ready after background
                        try? await Task.sleep(for: .milliseconds(50))
                        
                        // Only access Core Data if store is loaded
                        guard persistenceController.isStoreLoaded else { return }

                        let context = persistenceController.viewContext
                        let settings = AppSettings.shared(in: context)
                        lockManager.appWillEnterForeground(biometricEnabled: settings.biometricEnabled)
                    }
                }
                .onAppear {
                    // Small delay to ensure Core Data is fully ready
                    Task {
                        // Wait a tiny bit for store coordinator to stabilize
                        try? await Task.sleep(for: .milliseconds(100))
                        
                        // Only access Core Data if store is loaded
                        guard persistenceController.isStoreLoaded else { return }

                        let context = persistenceController.viewContext
                        let settings = AppSettings.shared(in: context)
                        lockManager.checkLockState(biometricEnabled: settings.biometricEnabled)

                        // Sync widget data on app launch
                        let profileService = ProfileService(persistenceController: persistenceController)
                        await profileService.syncWidgetOnLaunch()
                    }
                }
            } else {
                // Loading screen while Core Data initializes (especially CloudKit on device)
                ZStack {
                    Color(uiColor: UIColor.systemBackground)
                        .ignoresSafeArea()

                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
