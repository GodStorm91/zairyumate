//
//  my-number-card-nfc-reader-service.swift
//  ZairyuMate
//
//  NFC reader service for My Number Card (マイナンバーカード)
//  Uses ISO 7816 Type B protocol (same as Zairyu Card)
//

import Foundation
import CoreNFC

/// My Number Card NFC reader service
class MyNumberCardNFCReaderService {

    private let nfcReader = NFCReaderService()

    /// Read My Number Card via NFC
    /// - Parameter cardId: 12-digit card ID for authentication
    /// - Returns: My Number Card data with masked My Number
    func readMyNumberCard(cardId: String) async throws -> MyNumberCardData {
        // Validate card ID (12 digits)
        let cleanCardId = cardId.replacingOccurrences(of: " ", with: "")
        guard cleanCardId.count == 12, cleanCardId.allSatisfy({ $0.isNumber }) else {
            throw MyNumberCardError.invalidCardId
        }

        #if DEBUG
        print("📱 [My Number NFC] Starting scan with card ID: \(cleanCardId)")
        #endif

        // Build APDU command for My Number Card
        let apdu = buildMyNumberAPDU(cardId: cleanCardId)

        // Use existing NFC infrastructure to send APDU
        // My Number cards use same ISO 7816 Type B as Zairyu
        let response = try await nfcReader.sendAPDU(apdu, cardNumber: cleanCardId)

        #if DEBUG
        print("✅ [My Number NFC] Received response: \(response.count) bytes")
        #endif

        // Parse TLV response
        let parser = MyNumberCardDataParserTLV()
        let cardData = try parser.parse(response)

        #if DEBUG
        print("✅ [My Number NFC] Parsed successfully")
        print("   Name: \(cardData.name)")
        print("   My Number: \(cardData.maskedMyNumber)")
        #endif

        return cardData
    }

    // MARK: - APDU Commands

    /// Build APDU command for My Number Card
    private func buildMyNumberAPDU(cardId: String) -> NFCISO7816APDU {
        // My Number Card APDU structure (simplified)
        // CLA: 0x00 (standard class)
        // INS: 0xA4 (SELECT command)
        // P1:  0x04 (select by name)
        // P2:  0x00
        // Data: AID (Application Identifier) for My Number Card

        // My Number Card AID (example - actual AID may vary)
        // Real implementation would use official My Number Card specification
        let aid = Data([0xA0, 0x00, 0x00, 0x02, 0x31, 0x01])

        guard let apdu = NFCISO7816APDU(
            instructionClass: 0x00,
            instructionCode: 0xA4,
            p1Parameter: 0x04,
            p2Parameter: 0x00,
            data: aid,
            expectedResponseLength: 256
        ) else {
            fatalError("Failed to construct My Number Card APDU")
        }

        return apdu
    }
}

// MARK: - Extensions

extension NFCReaderService {
    /// Send custom APDU to card (for My Number Card usage)
    func sendAPDU(_ apdu: NFCISO7816APDU, cardNumber: String) async throws -> Data {
        // Reuse existing beginScan infrastructure
        // This would need to be exposed in NFCReaderService
        // For now, this is a placeholder showing the architecture

        // Actual implementation would:
        // 1. Begin NFC session
        // 2. Connect to card
        // 3. Send APDU
        // 4. Return response

        return try await beginScan(cardNumber: cardNumber)
    }
}

// MARK: - Error Types

enum MyNumberCardError: LocalizedError {
    case invalidCardId
    case nfcReadFailed
    case parseError
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .invalidCardId:
            return "Card ID must be 12 digits"
        case .nfcReadFailed:
            return "Failed to read My Number Card via NFC"
        case .parseError:
            return "Failed to parse My Number Card data"
        case .authenticationFailed:
            return "Card ID authentication failed"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidCardId:
            return "Enter the 12-digit card ID printed on the back of your My Number Card"
        case .nfcReadFailed:
            return "Hold card flat against the top/back of iPhone and keep it still"
        case .parseError:
            return "Try scanning again or use camera OCR instead"
        case .authenticationFailed:
            return "Verify the card ID is correct"
        }
    }
}
