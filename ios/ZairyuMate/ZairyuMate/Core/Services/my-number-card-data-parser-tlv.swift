//
//  my-number-card-data-parser-tlv.swift
//  ZairyuMate
//
//  Parser for My Number Card TLV (Tag-Length-Value) data from NFC
//  Handles Shift-JIS encoding and My Number masking for privacy
//

import Foundation

/// Parser for My Number Card TLV data format
final class MyNumberCardDataParserTLV {

    /// Parse TLV response from My Number Card NFC
    func parse(_ tlvData: Data) throws -> MyNumberCardData {
        let tags = parseTLV(tlvData)

        #if DEBUG
        print("📊 [TLV Parser] Found \(tags.count) tags")
        #endif

        // Extract fields from TLV tags
        // Note: Tag values are examples - actual My Number Card tags differ
        let name = extractString(from: tags, tag: 0x01) ?? ""
        let nameKana = extractString(from: tags, tag: 0x02) ?? ""
        let address = extractString(from: tags, tag: 0x03) ?? ""
        let dateOfBirth = extractDate(from: tags, tag: 0x04)
        let gender = extractGender(from: tags, tag: 0x05) ?? .other
        let myNumber = extractMyNumber(from: tags, tag: 0x06)
        let cardNumber = extractString(from: tags, tag: 0x07) ?? ""
        let expiryDate = extractDate(from: tags, tag: 0x08)
        let issueDate = extractDate(from: tags, tag: 0x09)

        #if DEBUG
        print("✅ [TLV Parser] Extraction complete")
        if !name.isEmpty {
            print("   Name: \(name)")
        }
        if let myNum = myNumber {
            print("   My Number: ****-****-\(myNum)")
        }
        #endif

        return MyNumberCardData(
            name: name,
            nameKana: nameKana,
            address: address,
            dateOfBirth: dateOfBirth,
            gender: gender,
            myNumber: myNumber, // Already masked (last 4 digits)
            cardNumber: cardNumber,
            expiryDate: expiryDate,
            facePhoto: nil, // NFC doesn't extract photo
            issueDate: issueDate
        )
    }

    // MARK: - TLV Parsing

    /// Parse TLV-encoded data into tag-value dictionary
    private func parseTLV(_ data: Data) -> [UInt8: Data] {
        var result: [UInt8: Data] = [:]
        var index = 0

        while index < data.count {
            // Read tag
            guard index < data.count else { break }
            let tag = data[index]
            index += 1

            // Read length
            guard index < data.count else { break }
            let length = Int(data[index])
            index += 1

            // Read value
            guard index + length <= data.count else { break }
            let value = data.subdata(in: index..<(index + length))
            index += length

            result[tag] = value

            #if DEBUG
            print("📋 [TLV] Tag: 0x\(String(format: "%02X", tag)), Length: \(length)")
            #endif
        }

        return result
    }

    // MARK: - Field Extraction

    /// Extract string from TLV tags (Shift-JIS encoding)
    private func extractString(from tags: [UInt8: Data], tag: UInt8) -> String? {
        guard let data = tags[tag] else { return nil }

        // My Number Card uses Shift-JIS encoding for Japanese text
        let encoding = String.Encoding.shiftJIS
        return String(data: data, encoding: encoding)
    }

    /// Extract date from TLV tags (format: YYYYMMDD)
    private func extractDate(from tags: [UInt8: Data], tag: UInt8) -> Date? {
        guard let dateString = extractString(from: tags, tag: tag) else {
            return nil
        }

        // Try multiple date formats
        let formatters = [
            "yyyyMMdd",
            "yyyy年MM月dd日",
            "yyyy.MM.dd"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "ja_JP")

            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    /// Extract gender from TLV tags
    private func extractGender(from tags: [UInt8: Data], tag: UInt8) -> MyNumberCardData.Gender? {
        guard let genderString = extractString(from: tags, tag: tag) else {
            return nil
        }

        // Gender codes: 1 or "男" = male, 2 or "女" = female
        switch genderString {
        case "1", "男":
            return .male
        case "2", "女":
            return .female
        default:
            return .other
        }
    }

    /// Extract My Number with privacy masking
    /// CRITICAL: Only returns last 4 digits for privacy compliance
    private func extractMyNumber(from tags: [UInt8: Data], tag: UInt8) -> String? {
        guard let numberString = extractString(from: tags, tag: tag) else {
            return nil
        }

        // Remove any formatting (spaces, dashes)
        let cleaned = numberString.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        // Validate 12 digits
        guard cleaned.count == 12, cleaned.allSatisfy({ $0.isNumber }) else {
            #if DEBUG
            print("⚠️ [TLV] Invalid My Number format: \(numberString)")
            #endif
            return nil
        }

        // PRIVACY: Only store last 4 digits
        let last4 = String(cleaned.suffix(4))

        #if DEBUG
        print("🔒 [TLV] My Number masked: ****-****-\(last4)")
        #endif

        return last4
    }
}
