//
//  nfc-reader-service-iso7816.swift
//  ZairyuMate
//
//  Service for reading Zairyu Card IC chips via NFC
//  Uses ISO 7816 (Type B) protocol
//

import Foundation
import CoreNFC
import Combine

/// Service for reading Zairyu Card IC chips via NFC
@MainActor
class NFCReaderService: NSObject {

    // MARK: - Properties

    private var session: NFCTagReaderSession?
    private var continuation: CheckedContinuation<Data, Error>?
    private var cardNumber: String = ""

    /// Check if NFC is available on this device
    static var isAvailable: Bool {
        NFCTagReaderSession.readingAvailable
    }

    // MARK: - Public Methods

    /// Begin NFC scan session
    /// - Parameter cardNumber: 12-character card number from top-right of card
    /// - Returns: Raw IC chip data
    func beginScan(cardNumber: String) async throws -> Data {
        guard Self.isAvailable else {
            throw NFCReaderError.notAvailable
        }

        // Validate card number format (12 alphanumeric characters)
        let cleanCardNumber = cardNumber.uppercased().replacingOccurrences(of: " ", with: "")
        guard cleanCardNumber.count == 12,
              cleanCardNumber.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            throw NFCReaderError.invalidCardNumber
        }

        self.cardNumber = cleanCardNumber

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            // Create session with ISO 14443 polling (for ISO 7816 cards)
            session = NFCTagReaderSession(
                pollingOption: .iso14443,
                delegate: self,
                queue: .main
            )
            session?.alertMessage = NFCConstants.AlertMessage.ready
            session?.begin()
        }
    }

    /// Invalidate current session
    func invalidateSession() {
        session?.invalidate()
        session = nil
        continuation = nil
    }
}

// MARK: - NFCTagReaderSessionDelegate

extension NFCReaderService: NFCTagReaderSessionDelegate {

    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        #if DEBUG
        print("📶 NFC Session became active")
        #endif
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            defer {
                self.session = nil
            }

            guard let continuation = self.continuation else { return }
            self.continuation = nil

            // Check error type (handle CoreNFC errors)
            let nsError = error as NSError
            if nsError.domain == "NFCError" {
                // User cancelled (code 200)
                if nsError.code == 200 {
                    continuation.resume(throwing: NFCReaderError.userCancelled)
                    return
                }
                // Session timeout (code 201)
                if nsError.code == 201 {
                    continuation.resume(throwing: NFCReaderError.sessionTimeout)
                    return
                }
            }

            continuation.resume(throwing: NFCReaderError.readFailed(underlying: error))
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Task { @MainActor in
            // Handle multiple tags
            guard tags.count == 1 else {
                session.alertMessage = NFCConstants.AlertMessage.multipleCards
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    session.restartPolling()
                }
                return
            }

            guard case let NFCTag.iso7816(tag) = tags.first! else {
                session.invalidate(errorMessage: "Unsupported card type")
                continuation?.resume(throwing: NFCReaderError.invalidResponse)
                continuation = nil
                return
            }

            do {
                try await session.connect(to: tags.first!)
                let data = try await readCardData(tag: tag, session: session)

                session.alertMessage = NFCConstants.AlertMessage.success
                session.invalidate()

                continuation?.resume(returning: data)
                continuation = nil

            } catch {
                session.invalidate(errorMessage: error.localizedDescription)
                continuation?.resume(throwing: NFCReaderError.readFailed(underlying: error))
                continuation = nil
            }
        }
    }

    // MARK: - Card Reading

    private func readCardData(tag: NFCISO7816Tag, session: NFCTagReaderSession) async throws -> Data {
        // Step 1: SELECT application (DF)
        let selectDF = try await sendAPDU(
            tag: tag,
            cla: 0x00,
            ins: 0xA4,  // SELECT
            p1: 0x04,   // Select by DF name
            p2: 0x0C,   // First occurrence
            data: Data(hexString: NFCConstants.zairyuCardAID)!
        )

        guard selectDF.sw1 == 0x90 && selectDF.sw2 == 0x00 else {
            throw NFCReaderError.invalidResponse
        }

        // Step 2: Verify card number (PIN)
        // The card number acts as a PIN to unlock the IC chip
        let verifyResult = try await sendAPDU(
            tag: tag,
            cla: 0x00,
            ins: 0x20,  // VERIFY
            p1: 0x00,
            p2: 0x80,   // PIN reference
            data: cardNumber.data(using: .ascii)!
        )

        guard verifyResult.sw1 == 0x90 && verifyResult.sw2 == 0x00 else {
            if verifyResult.sw1 == 0x63 {
                // Wrong PIN / card number
                throw NFCReaderError.invalidCardNumber
            }
            throw NFCReaderError.securityViolation
        }

        // Step 3: Read EF01 (Common data - spec version)
        let ef01 = try await readEF(tag: tag, efId: 0x01)

        // Step 4: Read EF02 (Card type)
        let ef02 = try await readEF(tag: tag, efId: 0x02)

        // Step 5: SELECT DF1 and read face data
        _ = try await sendAPDU(
            tag: tag,
            cla: 0x00,
            ins: 0xA4,
            p1: 0x01,  // Select child DF
            p2: 0x0C,
            data: Data([0x00, 0x01])  // DF1
        )

        // Step 6: Read DF1/EF01 (Card surface image - contains text data)
        let df1ef01 = try await readEF(tag: tag, efId: 0x01)

        // Combine all data
        var result = Data()
        result.append(contentsOf: [0x01])  // Marker for EF01
        result.append(ef01)
        result.append(contentsOf: [0x02])  // Marker for EF02
        result.append(ef02)
        result.append(contentsOf: [0x11])  // Marker for DF1/EF01
        result.append(df1ef01)

        return result
    }

    private func readEF(tag: NFCISO7816Tag, efId: UInt8) async throws -> Data {
        // SELECT EF
        _ = try await sendAPDU(
            tag: tag,
            cla: 0x00,
            ins: 0xA4,
            p1: 0x02,  // Select EF under current DF
            p2: 0x0C,
            data: Data([0x00, efId])
        )

        // READ BINARY
        var allData = Data()
        var offset: UInt16 = 0
        let chunkSize: UInt8 = 0xFF

        while true {
            let response = try await sendAPDU(
                tag: tag,
                cla: 0x00,
                ins: 0xB0,  // READ BINARY
                p1: UInt8((offset >> 8) & 0xFF),
                p2: UInt8(offset & 0xFF),
                le: chunkSize
            )

            if response.sw1 == 0x6C {
                // Wrong Le, retry with correct length
                let correctLe = response.sw2
                let retryResponse = try await sendAPDU(
                    tag: tag,
                    cla: 0x00,
                    ins: 0xB0,
                    p1: UInt8((offset >> 8) & 0xFF),
                    p2: UInt8(offset & 0xFF),
                    le: correctLe
                )
                allData.append(retryResponse.data)
                break
            }

            allData.append(response.data)

            if response.sw1 == 0x90 && response.sw2 == 0x00 {
                if response.data.count < Int(chunkSize) {
                    break
                }
                offset += UInt16(response.data.count)
            } else if response.sw1 == 0x62 || response.sw1 == 0x6B {
                // End of file or wrong offset
                break
            } else {
                throw NFCReaderError.readFailed(underlying: nil)
            }
        }

        return allData
    }

    private func sendAPDU(
        tag: NFCISO7816Tag,
        cla: UInt8,
        ins: UInt8,
        p1: UInt8,
        p2: UInt8,
        data: Data? = nil,
        le: UInt8? = nil
    ) async throws -> (data: Data, sw1: UInt8, sw2: UInt8) {
        let apdu = NFCISO7816APDU(
            instructionClass: cla,
            instructionCode: ins,
            p1Parameter: p1,
            p2Parameter: p2,
            data: data ?? Data(),
            expectedResponseLength: le.map { Int($0) } ?? -1
        )

        let (responseData, sw1, sw2) = try await tag.sendCommand(apdu: apdu)
        return (responseData, sw1, sw2)
    }
}

// MARK: - Data Extension

extension Data {
    init?(hexString: String) {
        let hex = hexString.replacingOccurrences(of: " ", with: "")
        guard hex.count % 2 == 0 else { return nil }

        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex

        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = nextIndex
        }

        self = data
    }
}
