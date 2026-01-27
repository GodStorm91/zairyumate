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

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.viewContext)

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
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // App icon placeholder
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.zmPrimary)

                // Welcome text
                Text("Zairyu Mate")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.zmTextPrimary)

                Text("Japanese Visa Application Assistant")
                    .font(.system(size: 17))
                    .foregroundColor(.zmTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Sample card with gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.zmCardGradientStart, Color.zmCardGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                    .overlay(
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Zairyu Card")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("NFC Ready")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            HStack {
                                Image(systemName: "wave.3.right")
                                    .font(.title)
                                Text("Tap to scan")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                        }
                        .padding(20)
                    )
                    .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 60)
            .background(Color.zmBackground)
        }
    }
}

#Preview {
    ContentView()
}
