//
//  form-field-mapping.swift
//  ZairyuMate
//
//  PDF form field mapping definitions
//  Maps Profile properties to PDF form fields with transformations
//

import Foundation

// MARK: - Form Field Mapping

struct FormFieldMapping {
    let pdfFieldName: String
    let valueExtractor: (Profile) -> String?
    let transformer: ((String) -> String)?

    init(
        pdfFieldName: String,
        valueExtractor: @escaping (Profile) -> String?,
        transformer: ((String) -> String)? = nil
    ) {
        self.pdfFieldName = pdfFieldName
        self.valueExtractor = valueExtractor
        self.transformer = transformer
    }

    /// Extract and transform value from profile
    func extractValue(from profile: Profile) -> String {
        guard let value = valueExtractor(profile) else { return "" }
        return transformer?(value) ?? value
    }
}

// MARK: - Extension Form Mapping

struct ExtensionFormMapping {
    static let mappings: [FormFieldMapping] = [
        // Name fields
        FormFieldMapping(pdfFieldName: "name_romaji") { $0.name },
        FormFieldMapping(pdfFieldName: "name_katakana") { $0.nameKatakana },

        // Date of birth fields
        FormFieldMapping(pdfFieldName: "dob_year") { profile in
            guard let dob = profile.dateOfBirth else { return nil }
            return DateFormatters.year(from: dob)
        },
        FormFieldMapping(pdfFieldName: "dob_month") { profile in
            guard let dob = profile.dateOfBirth else { return nil }
            return DateFormatters.month(from: dob)
        },
        FormFieldMapping(pdfFieldName: "dob_day") { profile in
            guard let dob = profile.dateOfBirth else { return nil }
            return DateFormatters.day(from: dob)
        },

        // Nationality
        FormFieldMapping(pdfFieldName: "nationality") { profile in
            guard let code = profile.nationality else { return nil }
            return CountryCodeHelper.countryName(from: code)
        },

        // Address
        FormFieldMapping(pdfFieldName: "address") { $0.address },

        // Card information
        FormFieldMapping(pdfFieldName: "card_number") { $0.decryptedCardNumber },
        FormFieldMapping(pdfFieldName: "card_expiry_year") { profile in
            guard let expiry = profile.cardExpiry else { return nil }
            return DateFormatters.year(from: expiry)
        },
        FormFieldMapping(pdfFieldName: "card_expiry_month") { profile in
            guard let expiry = profile.cardExpiry else { return nil }
            return DateFormatters.month(from: expiry)
        },
        FormFieldMapping(pdfFieldName: "card_expiry_day") { profile in
            guard let expiry = profile.cardExpiry else { return nil }
            return DateFormatters.day(from: expiry)
        },

        // Visa type
        FormFieldMapping(pdfFieldName: "visa_type") { $0.visaType },

        // Passport information
        FormFieldMapping(pdfFieldName: "passport_number") { $0.decryptedPassportNumber },
        FormFieldMapping(pdfFieldName: "passport_expiry_year") { profile in
            guard let expiry = profile.passportExpiry else { return nil }
            return DateFormatters.year(from: expiry)
        },
        FormFieldMapping(pdfFieldName: "passport_expiry_month") { profile in
            guard let expiry = profile.passportExpiry else { return nil }
            return DateFormatters.month(from: expiry)
        },
        FormFieldMapping(pdfFieldName: "passport_expiry_day") { profile in
            guard let expiry = profile.passportExpiry else { return nil }
            return DateFormatters.day(from: expiry)
        }
    ]
}

// MARK: - Change Form Mapping

struct ChangeFormMapping {
    static let mappings: [FormFieldMapping] = [
        // Reuse most fields from extension form
        // Name fields
        FormFieldMapping(pdfFieldName: "name_romaji") { $0.name },
        FormFieldMapping(pdfFieldName: "name_katakana") { $0.nameKatakana },

        // Date of birth fields
        FormFieldMapping(pdfFieldName: "dob_year") { profile in
            guard let dob = profile.dateOfBirth else { return nil }
            return DateFormatters.year(from: dob)
        },
        FormFieldMapping(pdfFieldName: "dob_month") { profile in
            guard let dob = profile.dateOfBirth else { return nil }
            return DateFormatters.month(from: dob)
        },
        FormFieldMapping(pdfFieldName: "dob_day") { profile in
            guard let dob = profile.dateOfBirth else { return nil }
            return DateFormatters.day(from: dob)
        },

        // Nationality
        FormFieldMapping(pdfFieldName: "nationality") { profile in
            guard let code = profile.nationality else { return nil }
            return CountryCodeHelper.countryName(from: code)
        },

        // Address
        FormFieldMapping(pdfFieldName: "address") { $0.address },

        // Card information
        FormFieldMapping(pdfFieldName: "card_number") { $0.decryptedCardNumber },

        // Current visa type
        FormFieldMapping(pdfFieldName: "current_visa_type") { $0.visaType },

        // Passport information
        FormFieldMapping(pdfFieldName: "passport_number") { $0.decryptedPassportNumber }
    ]
}

// MARK: - Helper: Date Formatters

private enum DateFormatters {
    static func year(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    static func month(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        return formatter.string(from: date)
    }

    static func day(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
}

// MARK: - Helper: Country Code

private enum CountryCodeHelper {
    /// Convert ISO 3166-1 alpha-3 country code to country name
    static func countryName(from code: String) -> String {
        // Common countries for visa application context
        let countryMap: [String: String] = [
            "VNM": "Vietnam",
            "CHN": "China",
            "KOR": "Korea",
            "PHL": "Philippines",
            "THA": "Thailand",
            "IDN": "Indonesia",
            "IND": "India",
            "USA": "United States",
            "GBR": "United Kingdom",
            "FRA": "France",
            "DEU": "Germany",
            "AUS": "Australia",
            "CAN": "Canada",
            "BRA": "Brazil",
            "MEX": "Mexico",
            "NZL": "New Zealand",
            "SGP": "Singapore",
            "MYS": "Malaysia",
            "TWN": "Taiwan",
            "HKG": "Hong Kong"
        ]

        return countryMap[code] ?? code
    }
}
