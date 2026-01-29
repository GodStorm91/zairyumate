//
//  app-logger.swift
//  ZairyuMate
//
//  Centralized logging utility using OSLog
//  Provides better filtering and performance than print()
//

import Foundation
import OSLog

/// Centralized logger for the app
enum AppLogger {
    
    // MARK: - Log Categories
    
    /// NFC reading operations
    static let nfc = Logger(subsystem: AppConstants.bundleIdentifier, category: "NFC")
    
    /// Data parsing operations
    static let parser = Logger(subsystem: AppConstants.bundleIdentifier, category: "Parser")
    
    /// View models and UI logic
    static let viewModel = Logger(subsystem: AppConstants.bundleIdentifier, category: "ViewModel")
    
    /// Persistence and Core Data
    static let persistence = Logger(subsystem: AppConstants.bundleIdentifier, category: "Persistence")
    
    /// In-app purchases and entitlements
    static let store = Logger(subsystem: AppConstants.bundleIdentifier, category: "Store")
    
    /// Cloud sync operations
    static let cloudSync = Logger(subsystem: AppConstants.bundleIdentifier, category: "CloudSync")
    
    /// Notifications
    static let notifications = Logger(subsystem: AppConstants.bundleIdentifier, category: "Notifications")
    
    /// General app lifecycle
    static let app = Logger(subsystem: AppConstants.bundleIdentifier, category: "App")
}

// MARK: - Convenience Extensions

#if DEBUG
extension Logger {
    /// Log a step with emoji prefix
    func step(_ step: Int, _ message: String) {
        self.info("🔵 Step \(step): \(message)")
    }
    
    /// Log success with emoji
    func success(_ message: String) {
        self.info("✅ \(message)")
    }
    
    /// Log error with emoji
    func failure(_ message: String) {
        self.error("❌ \(message)")
    }
    
    /// Log warning with emoji
    func warning(_ message: String) {
        self.warning("⚠️ \(message)")
    }
    
    /// Log data with emoji
    func data(_ message: String) {
        self.debug("📊 \(message)")
    }
}
#endif

/*
 USAGE EXAMPLES:
 
 // In NFC Reader:
 AppLogger.nfc.step(1, "Selecting application...")
 AppLogger.nfc.success("Card read complete - \(data.count) bytes")
 AppLogger.nfc.failure("Invalid response from card")
 
 // In Parser:
 AppLogger.parser.info("Starting parse - total data: \(data.count) bytes")
 AppLogger.parser.data("Name: \(name)")
 AppLogger.parser.success("Parsing complete")
 
 // In ViewModel:
 AppLogger.viewModel.info("Starting scan with card number: \(cardNumber)")
 AppLogger.viewModel.warning("Card number invalid")
 
 FILTERING IN CONSOLE.APP:
 - subsystem:com.khanhnguyenhoangviet.zairyumate
 - category:NFC
 - category:Parser
 - category:ViewModel
 
 FILTERING IN XCODE CONSOLE:
 - Search for category names: NFC, Parser, ViewModel
 - Or search for emojis: ✅, ❌, 🔵
 */
