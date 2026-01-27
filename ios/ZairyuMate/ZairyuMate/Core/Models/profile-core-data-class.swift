//
//  profile-core-data-class.swift
//  ZairyuMate
//
//  Profile entity extension with business logic and computed properties
//  Handles secure storage of sensitive fields via Keychain
//

import Foundation
import CoreData

@objc(Profile)
public class Profile: NSManagedObject {

    // MARK: - Computed Properties for Encrypted Fields

    /// Decrypted card number from Keychain
    var decryptedCardNumber: String? {
        get {
            guard let id = id else { return nil }
            return try? KeychainHelper.loadCardNumber(for: id)
        }
        set {
            guard let id = id else { return }
            if let value = newValue {
                try? KeychainHelper.saveCardNumber(value, for: id)
            } else {
                try? KeychainHelper.delete(for: KeychainHelper.profileKey(profileId: id, field: "cardNumber"))
            }
        }
    }

    /// Decrypted passport number from Keychain
    var decryptedPassportNumber: String? {
        get {
            guard let id = id else { return nil }
            return try? KeychainHelper.loadPassportNumber(for: id)
        }
        set {
            guard let id = id else { return }
            if let value = newValue {
                try? KeychainHelper.savePassportNumber(value, for: id)
            } else {
                try? KeychainHelper.delete(for: KeychainHelper.profileKey(profileId: id, field: "passportNumber"))
            }
        }
    }

    // MARK: - Computed Properties

    /// Check if visa/card is expiring soon (within 3 months)
    var isExpiringSoon: Bool {
        guard let expiry = cardExpiry else { return false }
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        return expiry <= threeMonthsFromNow
    }

    /// Days until card expiry
    var daysUntilExpiry: Int? {
        guard let expiry = cardExpiry else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiry)
        return components.day
    }

    /// Check if profile has complete basic information
    var isComplete: Bool {
        return name.isEmpty == false &&
               dateOfBirth != nil &&
               nationality != nil &&
               cardExpiry != nil
    }

    /// Display name with fallback
    var displayName: String {
        return name.isEmpty ? "Unnamed Profile" : name
    }

    /// Age calculated from date of birth
    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dob, to: Date())
        return components.year
    }

    /// Full display name with katakana
    var fullDisplayName: String {
        if let katakana = nameKatakana, !katakana.isEmpty {
            return "\(name) (\(katakana))"
        }
        return name
    }

    // MARK: - Lifecycle

    /// Called before insertion into context
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdAt")
        setPrimitiveValue(Date(), forKey: "updatedAt")
        setPrimitiveValue(false, forKey: "isActive")
        setPrimitiveValue("self", forKey: "relationship")
    }

    /// Called before update
    public override func willSave() {
        super.willSave()
        if !isInserted {
            setPrimitiveValue(Date(), forKey: "updatedAt")
        }
    }

    /// Called before deletion
    public override func prepareForDeletion() {
        super.prepareForDeletion()

        // Clean up Keychain data
        if let id = id {
            try? KeychainHelper.deleteProfileData(for: id)
        }
    }

    // MARK: - Validation

    /// Validate profile data before saving
    /// - Throws: ValidationError if data is invalid
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateProfile()
    }

    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateProfile()
    }

    private func validateProfile() throws {
        // Name is required
        if name.isEmpty {
            throw ValidationError.missingRequiredField("name")
        }

        // Relationship must be valid
        let validRelationships = ["self", "spouse", "child", "dependent"]
        if !validRelationships.contains(relationship ?? "") {
            throw ValidationError.invalidValue("relationship", relationship ?? "")
        }
    }

    // MARK: - Convenience Methods

    /// Create a copy of profile for export/backup
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["id"] = id?.uuidString
        dict["name"] = name
        dict["nameKatakana"] = nameKatakana
        dict["dateOfBirth"] = dateOfBirth?.timeIntervalSince1970
        dict["nationality"] = nationality
        dict["address"] = address
        dict["cardExpiry"] = cardExpiry?.timeIntervalSince1970
        dict["visaType"] = visaType
        dict["passportExpiry"] = passportExpiry?.timeIntervalSince1970
        dict["relationship"] = relationship
        dict["isActive"] = isActive
        dict["createdAt"] = createdAt?.timeIntervalSince1970
        dict["updatedAt"] = updatedAt?.timeIntervalSince1970
        // Note: Do NOT export encrypted fields
        return dict
    }
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case missingRequiredField(String)
    case invalidValue(String, String)

    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Required field is missing: \(field)"
        case .invalidValue(let field, let value):
            return "Invalid value '\(value)' for field: \(field)"
        }
    }
}

// MARK: - Fetch Request

extension Profile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile")
    }
}
