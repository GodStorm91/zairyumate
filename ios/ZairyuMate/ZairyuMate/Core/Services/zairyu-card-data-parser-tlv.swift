//
//  zairyu-card-data-parser-tlv.swift
//  ZairyuMate
//
//  Parser for Zairyu Card IC chip TLV (Tag-Length-Value) data
//  Based on MOJ Residence Card Specification

import Foundation

// MARK: - TLV Tag Definitions

/// TLV Tag definitions per MOJ Residence Card Specification
enum ZairyuCardTag: UInt8 {
    // MF/EF01 - Common Data
    case specVersion = 0xC0

    // MF/EF02 - Card Type
    case cardType = 0xC1

    // DF1/EF01 - Card Surface Data
    case name = 0xC2
    case nameKatakana = 0xC3
    case dateOfBirth = 0xC4
    case gender = 0xC5
    case nationality = 0xC6
    case address = 0xC7
    case statusOfResidence = 0xC8
    case periodOfStay = 0xC9
    case cardNumber = 0xCA
    case validityPeriod = 0xCB
    case workPermission = 0xCC

    // DF1/EF02 - Photo (JPEG2000)
    case photoData = 0xD0

    // DF2 - Back side data
    case addressUpdate = 0xD1
    case workPermissionBlanket = 0xD2
    case workPermissionIndividual = 0xD3
    case extensionApplication = 0xD4
}

// MARK: - Parser

/// Parser for Zairyu Card IC chip TLV data
struct ZairyuCardDataParser {

    // MARK: - TLV Parsing

    /// Parse raw IC chip data into ZairyuCardData
    /// - Parameter data: Raw data from NFCReaderService
    /// - Returns: Parsed card data
    /// - Throws: ParsingError if parsing fails
    static func parse(data: Data) throws -> ZairyuCardData {
        var ef01Data = Data()
        var ef02Data = Data()
        var df1ef01Data = Data()

        // Split combined data by markers (set by NFCReaderService)
        var index = 0
        while index < data.count {
            let marker = data[index]
            index += 1

            // Find next marker or end
            var endIndex = index
            while endIndex < data.count {
                let byte = data[endIndex]
                if byte == 0x01 || byte == 0x02 || byte == 0x11 {
                    break
                }
                endIndex += 1
            }

            let segmentData = data[index..<endIndex]

            switch marker {
            case 0x01:
                ef01Data = Data(segmentData)
            case 0x02:
                ef02Data = Data(segmentData)
            case 0x11:
                df1ef01Data = Data(segmentData)
            default:
                break
            }

            index = endIndex
        }

        // Parse TLV from each segment
        let ef01TLV = parseTLVs(from: ef01Data)
        let ef02TLV = parseTLVs(from: ef02Data)
        let df1TLV = parseTLVs(from: df1ef01Data)

        // Extract fields
        let specVersion = extractString(tag: .specVersion, from: ef01TLV)
        let cardTypeValue = extractByte(tag: .cardType, from: ef02TLV) ?? 1
        let cardType = ZairyuCardData.CardType(rawValue: Int(cardTypeValue)) ?? .residenceCard

        let name = extractString(tag: .name, from: df1TLV) ?? ""
        let nameKatakana = extractString(tag: .nameKatakana, from: df1TLV)
        let dateOfBirth = extractDate(tag: .dateOfBirth, from: df1TLV)
        let nationality = extractNationality(tag: .nationality, from: df1TLV)
        let address = extractString(tag: .address, from: df1TLV)
        let cardNumber = extractString(tag: .cardNumber, from: df1TLV) ?? ""
        let cardExpiry = extractDate(tag: .validityPeriod, from: df1TLV)
        let visaType = extractVisaType(tag: .statusOfResidence, from: df1TLV)

        // Validate required fields
        guard !name.isEmpty else {
            throw ParsingError.missingRequiredField("name")
        }

        return ZairyuCardData(
            name: name,
            nameKatakana: nameKatakana,
            dateOfBirth: dateOfBirth,
            nationality: nationality,
            address: address,
            cardNumber: cardNumber,
            cardExpiry: cardExpiry,
            visaType: visaType,
            cardType: cardType,
            specVersion: specVersion
        )
    }

    // MARK: - TLV Structure Parsing

    /// Parse TLV structures from binary data
    private static func parseTLVs(from data: Data) -> [(tag: UInt8, value: Data)] {
        var results: [(tag: UInt8, value: Data)] = []
        var index = 0

        while index < data.count {
            // Read Tag (1 byte, range 0xC0-0xDB)
            let tag = data[index]
            index += 1

            guard index < data.count else { break }

            // Read Length (1-3 bytes BER encoding)
            let (length, bytesConsumed) = parseLength(data: data, startIndex: index)
            index += bytesConsumed

            guard index + length <= data.count else { break }

            // Read Value
            let value = data[index..<(index + length)]
            results.append((tag: tag, value: Data(value)))

            index += length
        }

        return results
    }

    /// Parse BER-TLV length encoding
    /// - Returns: (length, bytesConsumed)
    private static func parseLength(data: Data, startIndex: Int) -> (Int, Int) {
        guard startIndex < data.count else { return (0, 0) }

        let firstByte = data[startIndex]

        // Short form: 0x00-0x7F
        if firstByte <= 0x7F {
            return (Int(firstByte), 1)
        }

        // Long form: 0x81 or 0x82
        if firstByte == 0x81 {
            guard startIndex + 1 < data.count else { return (0, 1) }
            return (Int(data[startIndex + 1]), 2)
        }

        if firstByte == 0x82 {
            guard startIndex + 2 < data.count else { return (0, 1) }
            let highByte = UInt16(data[startIndex + 1])
            let lowByte = UInt16(data[startIndex + 2])
            return (Int((highByte << 8) | lowByte), 3)
        }

        // Unsupported length encoding
        return (0, 1)
    }

    // MARK: - Field Extraction Helpers

    private static func extractData(tag: ZairyuCardTag, from tlvs: [(tag: UInt8, value: Data)]) -> Data? {
        return tlvs.first { $0.tag == tag.rawValue }?.value
    }

    private static func extractString(tag: ZairyuCardTag, from tlvs: [(tag: UInt8, value: Data)]) -> String? {
        guard let data = extractData(tag: tag, from: tlvs) else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespaces)
    }

    private static func extractByte(tag: ZairyuCardTag, from tlvs: [(tag: UInt8, value: Data)]) -> UInt8? {
        guard let data = extractData(tag: tag, from: tlvs), !data.isEmpty else { return nil }
        return data[0]
    }

    /// Parse date in YYYYMMDD format
    private static func extractDate(tag: ZairyuCardTag, from tlvs: [(tag: UInt8, value: Data)]) -> Date? {
        guard let dateString = extractString(tag: tag, from: tlvs) else { return nil }

        // Format: YYYYMMDD or YYYY/MM/DD or YYYY-MM-DD
        let cleanDate = dateString.replacingOccurrences(of: "/", with: "")
                                   .replacingOccurrences(of: "-", with: "")

        guard cleanDate.count == 8 else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        return formatter.date(from: cleanDate)
    }

    /// Parse nationality code and map to Country
    private static func extractNationality(tag: ZairyuCardTag, from tlvs: [(tag: UInt8, value: Data)]) -> String? {
        guard let rawValue = extractString(tag: tag, from: tlvs) else { return nil }

        // The IC chip may store full country name or ISO code
        // Try to match against known countries
        let normalizedValue = rawValue.uppercased().trimmingCharacters(in: .whitespaces)

        // Check if it's already a valid ISO 3166-1 alpha-3 code
        if normalizedValue.count == 3, Country.allCountries.contains(where: { $0.code == normalizedValue }) {
            return normalizedValue
        }

        // Try to find by name match
        if let country = Country.allCountries.first(where: {
            $0.displayName.uppercased().contains(normalizedValue) ||
            normalizedValue.contains($0.displayName.uppercased())
        }) {
            return country.code
        }

        // Common mappings for Japanese IC chip format
        let nationalityMap: [String: String] = [
            "VIET NAM": "VNM",
            "VIETNAM": "VNM",
            "CHINA": "CHN",
            "KOREA": "KOR",
            "PHILIPPINES": "PHL",
            "BRAZIL": "BRA",
            "NEPAL": "NPL",
            "INDONESIA": "IDN",
            "TAIWAN": "TWN",
            "UNITED STATES": "USA",
            "USA": "USA"
        ]

        return nationalityMap[normalizedValue] ?? normalizedValue
    }

    /// Parse status of residence and map to VisaType
    private static func extractVisaType(tag: ZairyuCardTag, from tlvs: [(tag: UInt8, value: Data)]) -> String? {
        guard let rawValue = extractString(tag: tag, from: tlvs) else { return nil }

        let normalizedValue = rawValue.lowercased().trimmingCharacters(in: .whitespaces)

        // Map common residence statuses to VisaType raw values
        let visaTypeMap: [String: String] = [
            "技術・人文知識・国際業務": VisaType.engineer.rawValue,
            "engineer": VisaType.engineer.rawValue,
            "技術": VisaType.engineer.rawValue,
            "経営・管理": VisaType.businessManager.rawValue,
            "business manager": VisaType.businessManager.rawValue,
            "家族滞在": VisaType.dependant.rawValue,
            "dependent": VisaType.dependant.rawValue,
            "永住者": VisaType.permanentResident.rawValue,
            "permanent resident": VisaType.permanentResident.rawValue,
            "日本人の配偶者等": VisaType.spouseOfJapanese.rawValue,
            "永住者の配偶者等": VisaType.spouseOfPR.rawValue,
            "留学": VisaType.student.rawValue,
            "student": VisaType.student.rawValue,
            "特定技能1号": VisaType.specifiedSkilled1.rawValue,
            "特定技能2号": VisaType.specifiedSkilled2.rawValue,
            "企業内転勤": VisaType.intraCompanyTransfer.rawValue,
            "高度専門職": VisaType.highlySkilled.rawValue,
            "技能実習": VisaType.technicalIntern.rawValue,
            "特定活動": VisaType.designatedActivities.rawValue
        ]

        // Try exact match first
        if let mapped = visaTypeMap[normalizedValue] {
            return mapped
        }

        // Try partial match
        for (key, value) in visaTypeMap {
            if normalizedValue.contains(key) || key.contains(normalizedValue) {
                return value
            }
        }

        // Return raw value if no mapping found
        return rawValue
    }
}

// MARK: - Parsing Errors

enum ParsingError: LocalizedError {
    case invalidFormat
    case missingRequiredField(String)
    case invalidTLVStructure
    case unsupportedEncoding

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid card data format"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidTLVStructure:
            return "Invalid TLV structure in card data"
        case .unsupportedEncoding:
            return "Unsupported data encoding"
        }
    }
}

// MARK: - Debug Mock Support

#if DEBUG
extension ZairyuCardDataParser {
    /// Create mock data for simulator testing
    static func createMockData() -> ZairyuCardData {
        let calendar = Calendar.current

        return ZairyuCardData(
            name: "NGUYEN VAN ANH",
            nameKatakana: "グエン バン アン",
            dateOfBirth: calendar.date(from: DateComponents(year: 1990, month: 5, day: 15)),
            nationality: "VNM",
            address: "東京都渋谷区渋谷1-2-3",
            cardNumber: "AB12345678CD",
            cardExpiry: calendar.date(byAdding: .year, value: 1, to: Date()),
            visaType: VisaType.engineer.rawValue,
            cardType: .residenceCard,
            specVersion: "1.5"
        )
    }

    /// Create mock raw data for testing parser
    static func createMockRawData() -> Data {
        var data = Data()

        // Marker for EF01
        data.append(0x01)
        // Spec version TLV: Tag=0xC0, Length=0x03, Value="1.5"
        data.append(contentsOf: [0xC0, 0x03])
        data.append("1.5".data(using: .utf8)!)

        // Marker for EF02
        data.append(0x02)
        // Card type TLV: Tag=0xC1, Length=0x01, Value=0x01 (Residence Card)
        data.append(contentsOf: [0xC1, 0x01, 0x01])

        // Marker for DF1/EF01
        data.append(0x11)

        // Name TLV
        let name = "NGUYEN VAN ANH"
        data.append(contentsOf: [0xC2, UInt8(name.count)])
        data.append(name.data(using: .utf8)!)

        // Name Katakana TLV
        let katakana = "グエン バン アン"
        let katakanaData = katakana.data(using: .utf8)!
        data.append(0xC3)
        data.append(contentsOf: [0x81, UInt8(katakanaData.count)])
        data.append(katakanaData)

        // Date of birth TLV: 19900515
        let dob = "19900515"
        data.append(contentsOf: [0xC4, UInt8(dob.count)])
        data.append(dob.data(using: .utf8)!)

        // Nationality TLV
        let nationality = "VNM"
        data.append(contentsOf: [0xC6, UInt8(nationality.count)])
        data.append(nationality.data(using: .utf8)!)

        // Address TLV
        let address = "東京都渋谷区渋谷1-2-3"
        let addressData = address.data(using: .utf8)!
        data.append(0xC7)
        data.append(contentsOf: [0x81, UInt8(addressData.count)])
        data.append(addressData)

        // Card number TLV
        let cardNum = "AB12345678CD"
        data.append(contentsOf: [0xCA, UInt8(cardNum.count)])
        data.append(cardNum.data(using: .utf8)!)

        // Expiry date TLV
        let expiry = "20271028"
        data.append(contentsOf: [0xCB, UInt8(expiry.count)])
        data.append(expiry.data(using: .utf8)!)

        // Visa type TLV
        let visa = "技術・人文知識・国際業務"
        let visaData = visa.data(using: .utf8)!
        data.append(0xC8)
        data.append(contentsOf: [0x81, UInt8(visaData.count)])
        data.append(visaData)

        return data
    }
}
#endif
