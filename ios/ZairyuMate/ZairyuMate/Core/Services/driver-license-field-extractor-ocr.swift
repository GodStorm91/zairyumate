//
//  driver-license-field-extractor-ocr.swift
//  ZairyuMate
//
//  Extract structured fields from Japanese Driver's License OCR results
//  Handles 47 prefecture variations and multiple license types
//

import Foundation
import UIKit

/// Extracts Driver's License fields from OCR results
final class DriverLicenseFieldExtractorOCR {

    /// Extract fields from Driver's License OCR
    func extractFields(from ocrFields: [OCRField]) -> DriverLicenseData? {
        var name: String?
        var nameKana: String?
        var dateOfBirth: Date?
        var address: String?
        var licenseNumber: String?
        var issueDate: Date?
        var expiryDate: Date?
        var licenseTypes: [DriverLicenseData.LicenseType] = []
        var conditions: String?
        var prefecture: DriverLicenseData.Prefecture?

        #if DEBUG
        print("🚗 [License OCR] Processing \(ocrFields.count) OCR fields")
        #endif

        for field in ocrFields {
            let text = field.value

            // License number extraction (12 digits)
            if let number = extractLicenseNumber(text) {
                licenseNumber = number
                #if DEBUG
                print("✅ [License OCR] Found license number: \(number)")
                #endif
            }

            // Prefecture extraction (from license number or text)
            if let detectedPrefecture = extractPrefecture(text) {
                prefecture = detectedPrefecture
                #if DEBUG
                print("✅ [License OCR] Found prefecture: \(detectedPrefecture.displayName)")
                #endif
            }

            // Name extraction (Kanji, upper area)
            if let extractedName = extractName(field) {
                name = extractedName
                #if DEBUG
                print("✅ [License OCR] Found name: \(extractedName)")
                #endif
            }

            // Name Kana extraction (カナ/Kana prefix)
            if let extractedKana = extractNameKana(text) {
                nameKana = extractedKana
                #if DEBUG
                print("✅ [License OCR] Found name kana: \(extractedKana)")
                #endif
            }

            // Date of birth
            if let dob = extractDateOfBirth(text) {
                dateOfBirth = dob
                #if DEBUG
                print("✅ [License OCR] Found DOB: \(dob)")
                #endif
            }

            // Address
            if text.contains("住所") || isAddressLike(text) {
                address = text.replacingOccurrences(of: "住所", with: "")
                    .trimmingCharacters(in: .whitespaces)
                #if DEBUG
                print("✅ [License OCR] Found address")
                #endif
            }

            // Issue date (交付)
            if text.contains("交付") {
                if let date = extractDate(text) {
                    issueDate = date
                    #if DEBUG
                    print("✅ [License OCR] Found issue date: \(date)")
                    #endif
                }
            }

            // Expiry date (有効期限)
            if text.contains("有効期限") || text.contains("まで") {
                if let date = extractDate(text) {
                    expiryDate = date
                    #if DEBUG
                    print("✅ [License OCR] Found expiry date: \(date)")
                    #endif
                }
            }

            // License types
            let extractedTypes = extractLicenseTypes(text)
            if !extractedTypes.isEmpty {
                licenseTypes.append(contentsOf: extractedTypes)
                #if DEBUG
                print("✅ [License OCR] Found license types: \(extractedTypes.map { $0.displayName })")
                #endif
            }

            // Conditions (眼鏡等)
            if let extractedConditions = extractConditions(text) {
                conditions = extractedConditions
                #if DEBUG
                print("✅ [License OCR] Found conditions: \(extractedConditions)")
                #endif
            }
        }

        // Require at least name and license number
        guard let name = name, let licenseNumber = licenseNumber else {
            #if DEBUG
            print("❌ [License OCR] Failed to extract required fields (name or license number)")
            #endif
            return nil
        }

        // Default prefecture if not detected
        let finalPrefecture = prefecture ?? .tokyo

        // Remove duplicate license types
        let uniqueLicenseTypes = Array(Set(licenseTypes))

        return DriverLicenseData(
            name: name,
            nameKana: nameKana ?? "",
            dateOfBirth: dateOfBirth,
            address: address ?? "",
            licenseNumber: licenseNumber,
            issueDate: issueDate,
            expiryDate: expiryDate,
            licenseTypes: uniqueLicenseTypes.isEmpty ? [.regular] : uniqueLicenseTypes,
            conditions: conditions,
            facePhoto: nil,
            prefecture: finalPrefecture
        )
    }

    // MARK: - Field Extraction Methods

    /// Extract 12-digit license number
    private func extractLicenseNumber(_ text: String) -> String? {
        // Pattern: 12 digits (may have spaces)
        let pattern = #"(\d{4})\s?(\d{4})\s?(\d{4})"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }

        // Extract all 3 groups
        let groups = (1...3).compactMap { index -> String? in
            guard let range = Range(match.range(at: index), in: text) else { return nil }
            return String(text[range])
        }

        guard groups.count == 3 else { return nil }
        let fullNumber = groups.joined()

        // Validate 12 digits
        guard fullNumber.count == 12, fullNumber.allSatisfy({ $0.isNumber }) else {
            return nil
        }

        return fullNumber
    }

    /// Extract prefecture from text or license number
    private func extractPrefecture(_ text: String) -> DriverLicenseData.Prefecture? {
        // Check if text contains prefecture name
        for prefecture in DriverLicenseData.Prefecture.allCases {
            if text.contains(prefecture.displayName) {
                return prefecture
            }
        }

        // TODO: Extract from license number first 2 digits (prefecture code)
        // This requires more complex logic based on license number format

        return nil
    }

    /// Extract name (Kanji, top area of license)
    private func extractName(_ field: OCRField) -> String? {
        // Name is usually in top 30% of card (y > 0.7 in normalized coords)
        guard field.boundingBox.minY > 0.7 else { return nil }

        let text = field.value.trimmingCharacters(in: .whitespaces)

        // Filter out numbers and short text
        guard text.count > 1, !text.contains(where: { $0.isNumber }) else {
            return nil
        }

        // Avoid common labels
        let excludedWords = ["氏名", "住所", "生年月日", "交付", "有効期限", "免許証", "運転"]
        guard !excludedWords.contains(where: { text.contains($0) }) else {
            return nil
        }

        return text
    }

    /// Extract name kana (カナ/Kana prefix)
    private func extractNameKana(_ text: String) -> String? {
        // Pattern: カナ or かな followed by katakana/hiragana
        let pattern = #"(?:カナ|かな|氏名カナ)[\s:：]*([ァ-ヴー\s]+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let kana = String(text[range]).trimmingCharacters(in: .whitespaces)
        return kana.isEmpty ? nil : kana
    }

    /// Extract date of birth
    private func extractDateOfBirth(_ text: String) -> Date? {
        // Try Western format (YYYY.MM.DD or YYYY/MM/DD)
        let westernPattern = #"(\d{4})[\.\/年](0?[1-9]|1[0-2])[\.\/月](0?[1-9]|[12][0-9]|3[01])"#

        if let regex = try? NSRegularExpression(pattern: westernPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            let dateString = String(text[range])
                .replacingOccurrences(of: "年", with: ".")
                .replacingOccurrences(of: "月", with: ".")
                .replacingOccurrences(of: "日", with: "")

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd"
            formatter.locale = Locale(identifier: "ja_JP")

            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        // Try Japanese era format (平成/令和)
        return extractJapaneseEraDate(text)
    }

    /// Extract date from text (generic)
    private func extractDate(_ text: String) -> Date? {
        return extractDateOfBirth(text) ?? extractJapaneseEraDate(text)
    }

    /// Extract Japanese era date
    private func extractJapaneseEraDate(_ text: String) -> Date? {
        // Example: 平成5年12月25日
        let eraPattern = #"(平成|令和|昭和)(元|[1-9]|[1-5][0-9]|6[0-4])年(0?[1-9]|1[0-2])月(0?[1-9]|[12][0-9]|3[01])日"#

        guard let regex = try? NSRegularExpression(pattern: eraPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }

        guard let eraRange = Range(match.range(at: 1), in: text),
              let yearRange = Range(match.range(at: 2), in: text),
              let monthRange = Range(match.range(at: 3), in: text),
              let dayRange = Range(match.range(at: 4), in: text) else {
            return nil
        }

        let era = String(text[eraRange])
        let yearStr = String(text[yearRange])
        let year = yearStr == "元" ? 1 : (Int(yearStr) ?? 0)
        let month = Int(String(text[monthRange])) ?? 0
        let day = Int(String(text[dayRange])) ?? 0

        // Convert era year to Western year
        let westernYear: Int
        switch era {
        case "令和": westernYear = 2018 + year
        case "平成": westernYear = 1988 + year
        case "昭和": westernYear = 1925 + year
        default: return nil
        }

        var components = DateComponents()
        components.year = westernYear
        components.month = month
        components.day = day
        components.calendar = Calendar(identifier: .gregorian)

        return components.date
    }

    /// Extract license types
    private func extractLicenseTypes(_ text: String) -> [DriverLicenseData.LicenseType] {
        var types: [DriverLicenseData.LicenseType] = []

        for licenseType in DriverLicenseData.LicenseType.allCases {
            if text.contains(licenseType.rawValue) {
                types.append(licenseType)
            }
        }

        return types
    }

    /// Extract conditions (眼鏡等)
    private func extractConditions(_ text: String) -> String? {
        // Common conditions: 眼鏡等, AT限定, etc.
        let conditionPatterns = ["眼鏡等", "AT限定", "補聴器", "義手", "義足"]

        for pattern in conditionPatterns {
            if text.contains(pattern) {
                return pattern
            }
        }

        return nil
    }

    /// Check if text looks like an address
    private func isAddressLike(_ text: String) -> Bool {
        // Address usually contains: 都道府県 + 市区町村 + 番地
        let addressKeywords = ["都", "道", "府", "県", "市", "区", "町", "村", "番地", "丁目", "号"]
        let matchCount = addressKeywords.filter { text.contains($0) }.count

        return matchCount >= 2 && text.count > 10
    }
}
