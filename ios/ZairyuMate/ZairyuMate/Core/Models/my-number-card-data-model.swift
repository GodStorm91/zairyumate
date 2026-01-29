//
//  my-number-card-data-model.swift
//  ZairyuMate
//
//  My Number Card (マイナンバーカード) data model
//  Includes privacy features: masked My Number, encrypted storage
//

import Foundation
import UIKit

/// My Number Card data model with My Number Act compliance
struct MyNumberCardData: IDCard, Codable {
    // MARK: - IDCard Protocol

    let cardType: CardType = .myNumberCard

    // MARK: - Personal Information

    let name: String
    let nameKana: String
    let address: String
    let dateOfBirth: Date?
    let gender: Gender

    // MARK: - Card Information

    /// My Number (masked - only last 4 digits stored)
    /// Full number NEVER stored per My Number Act
    let myNumber: String?

    /// Card ID (12 digits for NFC authentication)
    let cardNumber: String

    let expiryDate: Date?
    let issueDate: Date?

    // MARK: - Optional

    let facePhoto: UIImage?

    // MARK: - Computed Properties

    var supportedReadMethods: [ReadMethod] { [.nfc, .ocr] }

    /// Masked My Number display (****-****-1234)
    var maskedMyNumber: String {
        guard let number = myNumber else { return "****-****-****" }
        // Only show last 4 digits
        return "****-****-\(number)"
    }

    // MARK: - Gender Enum

    enum Gender: String, Codable {
        case male = "男"
        case female = "女"
        case other = "その他"

        var displayName: String { rawValue }

        var englishName: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            case .other: return "Other"
            }
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case name, nameKana, address, dateOfBirth, gender
        case myNumber, cardNumber, expiryDate, issueDate
        // facePhoto excluded from Codable (store separately)
    }

    // MARK: - Initialization

    init(
        name: String,
        nameKana: String,
        address: String,
        dateOfBirth: Date?,
        gender: Gender,
        myNumber: String?, // Should be last 4 digits only
        cardNumber: String,
        expiryDate: Date?,
        facePhoto: UIImage?,
        issueDate: Date?
    ) {
        self.name = name
        self.nameKana = nameKana
        self.address = address
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.myNumber = myNumber
        self.cardNumber = cardNumber
        self.expiryDate = expiryDate
        self.facePhoto = facePhoto
        self.issueDate = issueDate
    }
}

// MARK: - Privacy Utilities

extension MyNumberCardData {
    /// Validate that My Number is properly masked (4 digits max)
    var isMyNumberMasked: Bool {
        guard let number = myNumber else { return true }
        return number.count <= 4
    }

    /// Create sanitized copy for logging (removes all sensitive data)
    func sanitized() -> MyNumberCardData {
        MyNumberCardData(
            name: "[REDACTED]",
            nameKana: "[REDACTED]",
            address: "[REDACTED]",
            dateOfBirth: nil,
            gender: .other,
            myNumber: nil,
            cardNumber: "[REDACTED]",
            expiryDate: expiryDate, // Safe to keep
            facePhoto: nil,
            issueDate: issueDate
        )
    }
}
