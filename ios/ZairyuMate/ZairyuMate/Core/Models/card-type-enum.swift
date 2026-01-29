//
//  card-type-enum.swift
//  ZairyuMate
//
//  Card type and read method enumerations for multi-card support
//

import Foundation

/// Supported ID card types in the app
enum CardType: String, Codable, CaseIterable {
    case zairyuCard = "在留カード"
    case myNumberCard = "マイナンバーカード"
    case driverLicense = "運転免許証"

    /// Japanese display name
    var displayName: String { rawValue }

    /// English name for accessibility
    var englishName: String {
        switch self {
        case .zairyuCard: return "Residence Card"
        case .myNumberCard: return "My Number Card"
        case .driverLicense: return "Driver's License"
        }
    }

    /// SF Symbol icon for UI
    var icon: String {
        switch self {
        case .zairyuCard: return "person.badge.shield.checkmark"
        case .myNumberCard: return "creditcard"
        case .driverLicense: return "car"
        }
    }

    /// Supported reading methods for this card type
    var supportedMethods: [ReadMethod] {
        switch self {
        case .zairyuCard: return [.nfc, .ocr]
        case .myNumberCard: return [.nfc, .ocr]
        case .driverLicense: return [.ocr] // IC chip future
        }
    }

    /// UI description for card selection
    var description: String {
        switch self {
        case .zairyuCard:
            return "For foreign residents in Japan"
        case .myNumberCard:
            return "Individual number card for Japanese residents"
        case .driverLicense:
            return "Japanese driver's license"
        }
    }
}

/// Card reading methods
enum ReadMethod: String, Codable {
    case nfc = "NFC"
    case ocr = "Camera OCR"

    /// SF Symbol icon for UI
    var icon: String {
        switch self {
        case .nfc: return "antenna.radiowaves.left.and.right"
        case .ocr: return "camera.fill"
        }
    }

    /// UI description
    var description: String {
        switch self {
        case .nfc: return "Fast & accurate NFC reading"
        case .ocr: return "Camera-based text recognition"
        }
    }

    /// Pro feature flag (NFC requires Pro)
    var requiresPro: Bool {
        switch self {
        case .nfc: return true
        case .ocr: return false
        }
    }
}
