//
//  zairyu-card-data-model.swift
//  ZairyuMate
//
//  Data model for Zairyu Card IC chip data
//  Extracted from NFC scan

import Foundation

/// Data extracted from Zairyu Card IC chip
struct ZairyuCardData: Equatable {
    /// Full name (Romaji)
    let name: String

    /// Full name in Katakana (if available)
    let nameKatakana: String?

    /// Date of birth
    let dateOfBirth: Date?

    /// Nationality/Region code (ISO 3166-1 alpha-3)
    let nationality: String?

    /// Residence address
    let address: String?

    /// Card number (12 characters)
    let cardNumber: String

    /// Card expiry date
    let cardExpiry: Date?

    /// Status of residence (visa type)
    let visaType: String?

    /// Card type (1: Residence Card, 2: Special PR Certificate)
    let cardType: CardType

    /// Specification version from IC chip
    let specVersion: String?

    enum CardType: Int {
        case residenceCard = 1
        case specialPRCertificate = 2

        var displayName: String {
            switch self {
            case .residenceCard:
                return "Residence Card (在留カード)"
            case .specialPRCertificate:
                return "Special PR Certificate (特別永住者証明書)"
            }
        }
    }
}

extension ZairyuCardData {
    /// Convert to dictionary for ProfileService.update()
    func toProfileUpdates() -> [String: Any] {
        var updates: [String: Any] = [
            "name": name,
            "cardNumber": cardNumber
        ]

        if let katakana = nameKatakana {
            updates["nameKatakana"] = katakana
        }
        if let dob = dateOfBirth {
            updates["dateOfBirth"] = dob
        }
        if let nat = nationality {
            updates["nationality"] = nat
        }
        if let addr = address {
            updates["address"] = addr
        }
        if let expiry = cardExpiry {
            updates["cardExpiry"] = expiry
        }
        if let visa = visaType {
            updates["visaType"] = visa
        }

        return updates
    }
}
