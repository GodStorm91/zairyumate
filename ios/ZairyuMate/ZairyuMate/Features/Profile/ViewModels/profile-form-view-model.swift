//
//  profile-form-view-model.swift
//  ZairyuMate
//
//  ViewModel for profile creation and editing form
//  Handles validation, data binding, and save operations
//

import Foundation
import Observation

@MainActor
@Observable
class ProfileFormViewModel {

    // MARK: - Form Fields

    var name: String = ""
    var nameKatakana: String = ""
    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var nationality: String = "VNM"
    var relationship: String = "self"
    var address: String = ""
    var cardNumber: String = ""
    var cardExpiry: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    var visaType: VisaType = .engineer
    var passportNumber: String = ""
    var passportExpiry: Date = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()

    // MARK: - State

    var isLoading: Bool = false
    var validationErrors: [String: String] = [:]
    var showingError: Bool = false
    var errorMessage: String = ""

    // MARK: - Dependencies

    private let profileService: ProfileService
    private var existingProfile: Profile?

    // MARK: - Computed Properties

    var isEditing: Bool {
        existingProfile != nil
    }

    var formTitle: String {
        isEditing ? "Edit Profile" : "Add Profile"
    }

    var saveButtonTitle: String {
        isEditing ? "Update" : "Save"
    }

    // MARK: - Initialization

    init(profileService: ProfileService = ProfileService()) {
        self.profileService = profileService
    }

    // MARK: - Load Profile for Editing

    func loadProfile(_ profile: Profile) {
        existingProfile = profile
        name = profile.name
        nameKatakana = profile.nameKatakana ?? ""
        dateOfBirth = profile.dateOfBirth ?? Date()
        nationality = profile.nationality ?? "VNM"
        relationship = profile.relationship ?? "self"
        address = profile.address ?? ""
        cardExpiry = profile.cardExpiry ?? Date()
        passportExpiry = profile.passportExpiry ?? Date()

        // Load encrypted fields
        cardNumber = profile.decryptedCardNumber ?? ""
        passportNumber = profile.decryptedPassportNumber ?? ""

        // Load visa type
        if let visaTypeStr = profile.visaType,
           let visa = VisaType.allCases.first(where: { $0.rawValue == visaTypeStr }) {
            visaType = visa
        }
    }

    // MARK: - Validation

    func validate() -> Bool {
        validationErrors.removeAll()

        // Required: Name
        if let error = FormValidators.requiredFieldError(name, fieldName: "Name") {
            validationErrors["name"] = error
        }

        // Optional: Katakana validation
        if !nameKatakana.isEmpty, let error = FormValidators.katakanaError(nameKatakana) {
            validationErrors["nameKatakana"] = error
        }

        // Required: Date of Birth
        if let error = FormValidators.dateOfBirthError(dateOfBirth) {
            validationErrors["dateOfBirth"] = error
        }

        // Required: Address
        if let error = FormValidators.addressError(address) {
            validationErrors["address"] = error
        }

        // Required: Card Number
        if let error = FormValidators.cardNumberError(cardNumber) {
            validationErrors["cardNumber"] = error
        }

        // Required: Card Expiry
        if let error = FormValidators.expiryDateError(cardExpiry, fieldName: "Card expiry date") {
            validationErrors["cardExpiry"] = error
        }

        // Optional: Passport Number
        if !passportNumber.isEmpty, let error = FormValidators.passportNumberError(passportNumber) {
            validationErrors["passportNumber"] = error
        }

        // Optional: Passport Expiry (only if passport number exists)
        if !passportNumber.isEmpty, let error = FormValidators.expiryDateError(passportExpiry, fieldName: "Passport expiry date") {
            validationErrors["passportExpiry"] = error
        }

        return validationErrors.isEmpty
    }

    /// Get error for specific field
    func error(for field: String) -> String? {
        return validationErrors[field]
    }

    // MARK: - Save

    func save() async throws {
        guard validate() else {
            errorMessage = "Please fix validation errors"
            showingError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if let existing = existingProfile {
                // Update existing profile
                existing.name = name
                existing.nameKatakana = nameKatakana.isEmpty ? nil : nameKatakana
                existing.dateOfBirth = dateOfBirth
                existing.nationality = nationality
                existing.relationship = relationship
                existing.address = address
                existing.cardExpiry = cardExpiry
                existing.visaType = visaType.rawValue
                existing.passportExpiry = passportExpiry

                // Update encrypted fields
                existing.decryptedCardNumber = cardNumber
                existing.decryptedPassportNumber = passportNumber.isEmpty ? nil : passportNumber

                try await profileService.update(existing)

                #if DEBUG
                print("✅ Updated profile: \(name)")
                #endif
            } else {
                // Create new profile
                _ = try await profileService.create(
                    name: name,
                    nameKatakana: nameKatakana.isEmpty ? nil : nameKatakana,
                    dateOfBirth: dateOfBirth,
                    nationality: nationality,
                    address: address,
                    cardNumber: cardNumber,
                    cardExpiry: cardExpiry,
                    visaType: visaType.rawValue,
                    passportNumber: passportNumber.isEmpty ? nil : passportNumber,
                    passportExpiry: passportExpiry,
                    relationship: relationship
                )

                #if DEBUG
                print("✅ Created profile: \(name)")
                #endif
            }
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            showingError = true
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Clear all form fields
    func clearForm() {
        name = ""
        nameKatakana = ""
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        nationality = "VNM"
        relationship = "self"
        address = ""
        cardNumber = ""
        cardExpiry = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        visaType = .engineer
        passportNumber = ""
        passportExpiry = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        validationErrors.removeAll()
        existingProfile = nil
    }

    /// Convert card number to uppercase automatically
    func formatCardNumber() {
        cardNumber = cardNumber.uppercased()
    }

    /// Convert passport number to uppercase automatically
    func formatPassportNumber() {
        passportNumber = passportNumber.uppercased()
    }
}
