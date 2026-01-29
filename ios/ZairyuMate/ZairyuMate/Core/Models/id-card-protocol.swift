//
//  id-card-protocol.swift
//  ZairyuMate
//
//  Protocol for card abstraction across Zairyu, My Number, and Driver's License
//

import Foundation
import UIKit

/// Common protocol for all ID card types
protocol IDCard {
    // MARK: - Type Information

    var cardType: CardType { get }

    // MARK: - Common Fields

    var name: String { get }
    var dateOfBirth: Date? { get }
    var cardNumber: String { get }
    var expiryDate: Date? { get }

    // MARK: - Optional Fields

    var facePhoto: UIImage? { get }

    // MARK: - Metadata

    var supportedReadMethods: [ReadMethod] { get }

    // MARK: - Display Helpers

    var displayName: String { get }
    var formattedExpiry: String { get }
    var daysUntilExpiry: Int? { get }
    var isExpired: Bool { get }
    var isExpiringSoon: Bool { get } // Within 90 days
}

// MARK: - Default Implementations

extension IDCard {
    /// Days until card expiry
    var daysUntilExpiry: Int? {
        guard let expiry = expiryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiry).day
    }

    /// Formatted expiry date (yyyy.MM.dd)
    var formattedExpiry: String {
        guard let expiry = expiryDate else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: expiry)
    }

    /// Check if card is expired
    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return Date() > expiry
    }

    /// Check if expiring within 90 days
    var isExpiringSoon: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days <= 90 && days > 0
    }

    /// Default display name (uses name field)
    var displayName: String { name }
}
