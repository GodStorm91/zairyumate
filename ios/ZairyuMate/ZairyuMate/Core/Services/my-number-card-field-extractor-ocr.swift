//
//  my-number-card-field-extractor-ocr.swift
//  ZairyuMate
//
//  Extract structured fields from My Number Card OCR results
//  Handles My Number masking and Japanese text recognition
//

import Foundation
import UIKit

/// Extracts My Number Card fields from OCR results
final class MyNumberCardFieldExtractorOCR {

    /// Extract fields from My Number Card OCR
    func extractFields(from ocrFields: [OCRField]) -> MyNumberCardData? {
        var name: String?
        var dateOfBirth: Date?
        var address: String?
        var myNumber: String?
        var gender: MyNumberCardData.Gender?

        #if DEBUG
        print("📄 [My Number OCR] Processing \(ocrFields.count) OCR fields")
        #endif

        for field in ocrFields {
            // My Number extraction (12 digits, format: #### #### ####)
            if let number = extractMyNumber(field.value) {
                myNumber = number // Already masked to last 4
                #if DEBUG
                print("✅ [My Number OCR] Found My Number: ****-****-\(number)")
                #endif
            }

            // Name extraction (Kanji, top area, y > 0.7)
            if let extractedName = extractName(field) {
                name = extractedName
                #if DEBUG
                print("✅ [My Number OCR] Found name: \(extractedName)")
                #endif
            }

            // Date of birth
            if let dob = extractDateOfBirth(field.value) {
                dateOfBirth = dob
                #if DEBUG
                print("✅ [My Number OCR] Found DOB: \(dob)")
                #endif
            }

            // Address (contains "住所" prefix)
            if field.value.contains("住所") {
                address = field.value.replacingOccurrences(of: "住所", with: "")
                    .trimmingCharacters(in: .whitespaces)
                #if DEBUG
                print("✅ [My Number OCR] Found address")
                #endif
            }

            // Gender
            if let extractedGender = extractGender(field.value) {
                gender = extractedGender
                #if DEBUG
                print("✅ [My Number OCR] Found gender: \(extractedGender.rawValue)")
                #endif
            }
        }

        // Require at least name
        guard let name = name else {
            #if DEBUG
            print("❌ [My Number OCR] Failed to extract name")
            #endif
            return nil
        }

        return MyNumberCardData(
            name: name,
            nameKana: "", // OCR can't reliably extract furigana
            address: address ?? "",
            dateOfBirth: dateOfBirth,
            gender: gender ?? .other,
            myNumber: myNumber,
            cardNumber: "",
            expiryDate: nil,
            facePhoto: nil,
            issueDate: nil
        )
    }

    // MARK: - Field Extraction Methods

    /// Extract My Number with privacy masking
    /// Returns only last 4 digits for privacy compliance
    private func extractMyNumber(_ text: String) -> String? {
        // Regex: 12 digits with optional spaces/dashes (#### #### ####)
        let pattern = #"(\d{4})[\s\-]?(\d{4})[\s\-]?(\d{4})"#

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
        guard fullNumber.count == 12 else { return nil }

        // PRIVACY: Only return last 4 digits
        let last4 = String(fullNumber.suffix(4))

        return last4
    }

    /// Extract name (Kanji, top area of card)
    private func extractName(_ field: OCRField) -> String? {
        // Name is usually in top 30% of card (y > 0.7 in normalized coords)
        guard field.boundingBox.minY > 0.7 else { return nil }

        let text = field.value.trimmingCharacters(in: .whitespaces)

        // Filter out numbers and short text
        guard text.count > 1, !text.contains(where: { $0.isNumber }) else {
            return nil
        }

        // Avoid common labels
        let excludedWords = ["氏名", "住所", "生年月日", "性別", "マイナンバー"]
        guard !excludedWords.contains(where: { text.contains($0) }) else {
            return nil
        }

        return text
    }

    /// Extract date of birth
    private func extractDateOfBirth(_ text: String) -> Date? {
        // Try Western format (YYYY.MM.DD or YYYY/MM/DD)
        let westernPattern = #"(\d{4})[\.\/](\d{1,2})[\.\/](\d{1,2})"#

        if let regex = try? NSRegularExpression(pattern: westernPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            let dateString = String(text[range])
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd"
            formatter.locale = Locale(identifier: "ja_JP")

            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        // Try Japanese era format (平成/令和)
        // Example: 平成5年12月25日
        let eraPattern = #"(平成|令和|昭和)(\d{1,2})年(\d{1,2})月(\d{1,2})日"#

        if let regex = try? NSRegularExpression(pattern: eraPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {

            guard let eraRange = Range(match.range(at: 1), in: text),
                  let yearRange = Range(match.range(at: 2), in: text),
                  let monthRange = Range(match.range(at: 3), in: text),
                  let dayRange = Range(match.range(at: 4), in: text) else {
                return nil
            }

            let era = String(text[eraRange])
            let year = Int(String(text[yearRange])) ?? 0
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

        return nil
    }

    /// Extract gender
    private func extractGender(_ text: String) -> MyNumberCardData.Gender? {
        if text.contains("男") && !text.contains("女") {
            return .male
        } else if text.contains("女") {
            return .female
        }
        return nil
    }
}
