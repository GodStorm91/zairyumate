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
    
    /// Progress callback for real-time updates
    var progressHandler: ((String) -> Void)?

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
                session.invalidate(errorMessage: "Unsupported card type. Please use a valid Zairyu Card.")
                continuation?.resume(throwing: NFCReaderError.invalidResponse)
                continuation = nil
                return
            }

            do {
                // Update alert message to show connection
                session.alertMessage = NFCConstants.AlertMessage.connecting
                try await session.connect(to: tags.first!)
                
                // Update alert message to show reading
                session.alertMessage = NFCConstants.AlertMessage.reading
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
        let startTime = Date()
        
        #if DEBUG
        print("🔵 [NFC] Starting card read at \(startTime)")
        print("🔵 [NFC] Card identifier: \(tag.identifier.map { String(format: "%02x", $0) }.joined())")
        print("🔵 [NFC] Card number: \(cardNumber)")
        #endif
        
        // Step 1: SELECT application (DF)
        let step1Start = Date()
        session.alertMessage = "Selecting card application..."
        #if DEBUG
        print("🔵 [NFC] Step 1: Selecting application...")
        #endif
        
        let selectDF = try await sendAPDU(
            tag: tag,
            cla: 0x00,
            ins: 0xA4,  // SELECT
            p1: 0x04,   // Select by DF name
            p2: 0x0C,   // First occurrence
            data: Data(hexString: NFCConstants.zairyuCardAID)!
        )

        guard selectDF.sw1 == 0x90 && selectDF.sw2 == 0x00 else {
            #if DEBUG
            print("🔴 [NFC] Step 1 FAILED: SW1=\(String(format: "%02x", selectDF.sw1)), SW2=\(String(format: "%02x", selectDF.sw2))")
            #endif
            throw NFCReaderError.invalidResponse
        }
        
        #if DEBUG
        print("🟢 [NFC] Step 1 completed in \(Date().timeIntervalSince(step1Start))s")
        #endif

        // Step 2: Verify card number (PIN)
        let step2Start = Date()
        session.alertMessage = "Verifying card number..."
        #if DEBUG
        print("🔵 [NFC] Step 2: Verifying card number...")
        #endif
        
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
            #if DEBUG
            print("🔴 [NFC] Step 2 FAILED: SW1=\(String(format: "%02x", verifyResult.sw1)), SW2=\(String(format: "%02x", verifyResult.sw2))")
            #endif
            if verifyResult.sw1 == 0x63 {
                // Wrong PIN / card number
                throw NFCReaderError.invalidCardNumber
            }
            throw NFCReaderError.securityViolation
        }
        
        #if DEBUG
        print("🟢 [NFC] Step 2 completed in \(Date().timeIntervalSince(step2Start))s")
        #endif

        // Step 3: Read EF01 (Common data - spec version)
        let step3Start = Date()
        session.alertMessage = "Reading card data (1/3)..."
        #if DEBUG
        print("🔵 [NFC] Step 3: Reading EF01...")
        #endif
        
        let ef01 = try await readEF(tag: tag, efId: 0x01, session: session, label: "EF01")
        
        #if DEBUG
        print("🟢 [NFC] Step 3 completed in \(Date().timeIntervalSince(step3Start))s - EF01 size: \(ef01.count) bytes")
        #endif

        // Step 4: Read EF02 (Card type)
        let step4Start = Date()
        session.alertMessage = "Reading card data (2/3)..."
        #if DEBUG
        print("🔵 [NFC] Step 4: Reading EF02...")
        #endif
        
        let ef02 = try await readEF(tag: tag, efId: 0x02, session: session, label: "EF02")
        
        #if DEBUG
        print("🟢 [NFC] Step 4 completed in \(Date().timeIntervalSince(step4Start))s - EF02 size: \(ef02.count) bytes")
        #endif

        // Step 5: SELECT DF1 and read face data
        let step5Start = Date()
        session.alertMessage = "Accessing personal data..."
        #if DEBUG
        print("🔵 [NFC] Step 5: Selecting DF1...")
        #endif
        
        _ = try await sendAPDU(
            tag: tag,
            cla: 0x00,
            ins: 0xA4,
            p1: 0x01,  // Select child DF
            p2: 0x0C,
            data: Data([0x00, 0x01])  // DF1
        )
        
        #if DEBUG
        print("🟢 [NFC] Step 5 completed in \(Date().timeIntervalSince(step5Start))s")
        #endif

        // Step 6: Read DF1/EF01 (Card surface image - contains text data)
        let step6Start = Date()
        session.alertMessage = "Reading card data (3/3)..."
        #if DEBUG
        print("🔵 [NFC] Step 6: Reading DF1/EF01...")
        #endif
        
        let df1ef01 = try await readEF(tag: tag, efId: 0x01, session: session, label: "DF1/EF01")
        
        #if DEBUG
        print("🟢 [NFC] Step 6 completed in \(Date().timeIntervalSince(step6Start))s - DF1/EF01 size: \(df1ef01.count) bytes")
        #endif

        // Combine all data
        var result = Data()
        result.append(contentsOf: [0x01])  // Marker for EF01
        result.append(ef01)
        result.append(contentsOf: [0x02])  // Marker for EF02
        result.append(ef02)
        result.append(contentsOf: [0x11])  // Marker for DF1/EF01
        result.append(df1ef01)

        let totalTime = Date().timeIntervalSince(startTime)
        #if DEBUG
        print("🟢 [NFC] ✅ TOTAL READ TIME: \(totalTime)s - Total data: \(result.count) bytes")
        #endif

        return result
    }

    private func readEF(tag: NFCISO7816Tag, efId: UInt8, session: NFCTagReaderSession, label: String) async throws -> Data {
        let efStartTime = Date()
        
        // SELECT EF
        #if DEBUG
        print("  📁 [NFC] Selecting \(label) (0x\(String(format: "%02x", efId)))...")
        #endif
        
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
        var chunkCount = 0

        while true {
            let chunkStartTime = Date()
            
            let response = try await sendAPDU(
                tag: tag,
                cla: 0x00,
                ins: 0xB0,  // READ BINARY
                p1: UInt8((offset >> 8) & 0xFF),
                p2: UInt8(offset & 0xFF),
                le: chunkSize
            )

            chunkCount += 1
            
            #if DEBUG
            let chunkTime = Date().timeIntervalSince(chunkStartTime)
            print("  📦 [NFC] Chunk \(chunkCount) read in \(chunkTime)s - \(response.data.count) bytes - SW: \(String(format: "%02x%02x", response.sw1, response.sw2))")
            #endif

            if response.sw1 == 0x6C {
                // Wrong Le, retry with correct length
                let correctLe = response.sw2
                #if DEBUG
                print("  ⚠️ [NFC] Wrong Le, retrying with Le=\(correctLe)")
                #endif
                
                let retryResponse = try await sendAPDU(
                    tag: tag,
                    cla: 0x00,
                    ins: 0xB0,
                    p1: UInt8((offset >> 8) & 0xFF),
                    p2: UInt8(offset & 0xFF),
                    le: correctLe
                )
                allData.append(retryResponse.data)
                
                #if DEBUG
                print("  ✅ [NFC] Retry successful - \(retryResponse.data.count) bytes")
                #endif
                break
            }

            allData.append(response.data)

            if response.sw1 == 0x90 && response.sw2 == 0x00 {
                if response.data.count < Int(chunkSize) {
                    #if DEBUG
                    print("  ✅ [NFC] Last chunk received (partial: \(response.data.count) < \(chunkSize))")
                    #endif
                    break
                }
                offset += UInt16(response.data.count)
            } else if response.sw1 == 0x62 || response.sw1 == 0x6B {
                // End of file or wrong offset
                #if DEBUG
                print("  ✅ [NFC] EOF or wrong offset - SW: \(String(format: "%02x%02x", response.sw1, response.sw2))")
                #endif
                break
            } else {
                #if DEBUG
                print("  ❌ [NFC] Unexpected status - SW: \(String(format: "%02x%02x", response.sw1, response.sw2))")
                #endif
                throw NFCReaderError.readFailed(underlying: nil)
            }
        }

        let efTotalTime = Date().timeIntervalSince(efStartTime)
        #if DEBUG
        print("  ✅ [NFC] \(label) complete: \(allData.count) bytes in \(efTotalTime)s (\(chunkCount) chunks)")
        #endif

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
        #if DEBUG
        let apduStart = Date()
        #endif
        
        let apdu = NFCISO7816APDU(
            instructionClass: cla,
            instructionCode: ins,
            p1Parameter: p1,
            p2Parameter: p2,
            data: data ?? Data(),
            expectedResponseLength: le.map { Int($0) } ?? -1
        )

        let (responseData, sw1, sw2) = try await tag.sendCommand(apdu: apdu)
        
        #if DEBUG
        let apduTime = Date().timeIntervalSince(apduStart)
        if apduTime > 0.1 {  // Only log slow APDUs
            print("    ⏱️ [NFC] SLOW APDU: INS=\(String(format: "%02x", ins)) took \(apduTime)s")
        }
        #endif
        
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
