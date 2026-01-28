//
//  nfc-reader-errors.swift
//  ZairyuMate
//
//  NFC Reader error types with localized messages
//

import Foundation

/// Errors that can occur during NFC card reading
enum NFCReaderError: LocalizedError {
    case notAvailable
    case sessionTimeout
    case connectionFailed
    case invalidCardNumber
    case readFailed(underlying: Error?)
    case invalidResponse
    case multipleTags
    case userCancelled
    case securityViolation

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "NFC is not available on this device"
        case .sessionTimeout:
            return "NFC session timed out. Please try again."
        case .connectionFailed:
            return "Failed to connect to card. Please try again."
        case .invalidCardNumber:
            return "Invalid card number. Please check and try again."
        case .readFailed(let error):
            return "Failed to read card: \(error?.localizedDescription ?? "Unknown error")"
        case .invalidResponse:
            return "Invalid response from card"
        case .multipleTags:
            return "Multiple cards detected. Please use only one card."
        case .userCancelled:
            return "Scan cancelled"
        case .securityViolation:
            return "Security error. Check NFC entitlements."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAvailable:
            return "NFC requires iPhone 7 or later with iOS 17+"
        case .invalidCardNumber:
            return "Enter the 12-character code from top-right of your card"
        case .connectionFailed, .readFailed:
            return "Position the card flat against the back of your iPhone"
        default:
            return nil
        }
    }
}
