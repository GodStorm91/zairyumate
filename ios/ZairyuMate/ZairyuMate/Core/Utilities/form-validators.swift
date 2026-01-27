//
//  form-validators.swift
//  ZairyuMate
//
//  Form validation helpers for profile and form data
//  Validates card numbers, passport numbers, katakana text, etc.
//

import Foundation

struct FormValidators {

    // MARK: - Card Number Validation

    /// Validates Zairyu card number format: 2 letters + 8 digits + 2 letters
    /// Example: AB12345678CD
    static func isValidCardNumber(_ number: String) -> Bool {
        let pattern = "^[A-Z]{2}\\d{8}[A-Z]{2}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: number.utf16.count)
        return regex?.firstMatch(in: number, range: range) != nil
    }

    /// Returns card number validation error message if invalid
    static func cardNumberError(_ number: String) -> String? {
        guard !number.isEmpty else {
            return "Card number is required"
        }

        if number.count != 12 {
            return "Card number must be 12 characters (XX00000000XX)"
        }

        if !isValidCardNumber(number) {
            return "Invalid format. Use: 2 letters + 8 digits + 2 letters"
        }

        return nil
    }

    // MARK: - Passport Number Validation

    /// Validates passport number (alphanumeric, 6-9 characters)
    static func isValidPassportNumber(_ number: String) -> Bool {
        guard !number.isEmpty else { return true } // Optional field

        let pattern = "^[A-Z0-9]{6,9}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: number.utf16.count)
        return regex?.firstMatch(in: number, range: range) != nil
    }

    /// Returns passport number validation error message if invalid
    static func passportNumberError(_ number: String) -> String? {
        guard !number.isEmpty else { return nil } // Optional field

        if number.count < 6 || number.count > 9 {
            return "Passport number must be 6-9 characters"
        }

        if !isValidPassportNumber(number) {
            return "Passport number must be alphanumeric"
        }

        return nil
    }

    // MARK: - Katakana Validation

    /// Validates if text contains only Katakana characters
    static func isKatakanaOnly(_ text: String) -> Bool {
        guard !text.isEmpty else { return true } // Optional field

        // Katakana unicode range: \u{30A0}-\u{30FF}
        // Also allow space, middle dot (・), and long vowel mark (ー)
        let pattern = "^[\\u{30A0}-\\u{30FF}\\s・ー]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex?.firstMatch(in: text, range: range) != nil
    }

    /// Returns katakana validation error message if invalid
    static func katakanaError(_ text: String) -> String? {
        guard !text.isEmpty else { return nil } // Optional field

        if !isKatakanaOnly(text) {
            return "Must be Katakana characters only"
        }

        return nil
    }

    // MARK: - Date Validation

    /// Validates date of birth (must be in the past)
    static func isValidDateOfBirth(_ date: Date) -> Bool {
        return date < Date()
    }

    /// Returns date of birth validation error message if invalid
    static func dateOfBirthError(_ date: Date) -> String? {
        if !isValidDateOfBirth(date) {
            return "Date of birth must be in the past"
        }

        return nil
    }

    /// Validates expiry date (must be in the future)
    static func isValidExpiryDate(_ date: Date) -> Bool {
        return date > Date()
    }

    /// Returns expiry date validation error message if invalid
    static func expiryDateError(_ date: Date, fieldName: String = "Expiry date") -> String? {
        if !isValidExpiryDate(date) {
            return "\(fieldName) must be in the future"
        }

        return nil
    }

    // MARK: - Required Field Validation

    /// Validates required string field
    static func isRequiredFieldValid(_ text: String) -> Bool {
        return !text.trimmed.isEmpty
    }

    /// Returns required field validation error message if invalid
    static func requiredFieldError(_ text: String, fieldName: String) -> String? {
        if !isRequiredFieldValid(text) {
            return "\(fieldName) is required"
        }

        return nil
    }

    // MARK: - Japanese Address Validation

    /// Basic validation for Japanese address (non-empty)
    static func isValidJapaneseAddress(_ address: String) -> Bool {
        return !address.trimmed.isEmpty
    }

    /// Returns address validation error message if invalid
    static func addressError(_ address: String) -> String? {
        if !isValidJapaneseAddress(address) {
            return "Address is required"
        }

        return nil
    }
}
