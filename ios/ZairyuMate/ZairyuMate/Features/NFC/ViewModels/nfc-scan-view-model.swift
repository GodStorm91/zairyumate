//
//  nfc-scan-view-model.swift
//  ZairyuMate
//
//  NFC card scan view model with state management
//  Manages scan lifecycle and Pro feature gating
//

import Foundation
import Observation
import UIKit
import Vision

@MainActor
@Observable
class NFCScanViewModel {

    // MARK: - State

    enum ScanState: Equatable {
        case idle
        case selectCardType
        case selectMethod
        case awaitingConsent  // My Number consent screen
        case enteringCardId   // My Number card ID input
        case inputCardNumber  // Zairyu card number
        case scanning
        case cameraCapturingFront
        case cameraCapturingBack
        case ocrProcessing
        case reviewOCRResults([OCRField])
        case success(ZairyuCardData)
        case error(String)

        var isBackCardPending: Bool {
            switch self {
            case .reviewOCRResults(let fields):
                return !fields.contains { $0.fieldName == "address" }
            default:
                return false
            }
        }
    }

    var scanState: ScanState = .idle
    var cardNumberInput: String = ""
    var myNumberCardId: String = "" // For My Number Card NFC
    var isLoading: Bool = false
    var showProUpgrade: Bool = false
    var selectedMethod: CardScanMethod? = nil
    var selectedCardType: CardType? = nil

    // MARK: - Validation

    var isCardNumberValid: Bool {
        let cleaned = cardNumberInput.uppercased().replacingOccurrences(of: " ", with: "")
        return cleaned.count == 12 && cleaned.allSatisfy { $0.isLetter || $0.isNumber }
    }

    var formattedCardNumber: String {
        let cleaned = cardNumberInput.uppercased().replacingOccurrences(of: " ", with: "")
        // Format as XXXX XXXX XXXX
        var result = ""
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                result += " "
            }
            result += String(char)
        }
        return result
    }

    // MARK: - Dependencies

    private let nfcReader: NFCReaderService
    private let profileService: ProfileService
    private let entitlementManager: EntitlementManager
    private let hybridOCREngine: HybridOCREngineService
    private let fieldExtractor: ZairyuCardFieldExtractorService
    private let myNumberNFCReader: MyNumberCardNFCReaderService
    private let myNumberOCRExtractor: MyNumberCardFieldExtractorOCR
    private let driverLicenseOCRExtractor: DriverLicenseFieldExtractorOCR

    // MARK: - OCR State

    private var frontCardOCRFields: [OCRField] = []
    private var backCardOCRFields: [OCRField] = []
    private var currentCardSide: CardSide = .front

    // MARK: - Initialization

    init(
        nfcReader: NFCReaderService,
        profileService: ProfileService,
        entitlementManager: EntitlementManager,
        hybridOCREngine: HybridOCREngineService = HybridOCREngineService(),
        fieldExtractor: ZairyuCardFieldExtractorService = ZairyuCardFieldExtractorService(),
        myNumberNFCReader: MyNumberCardNFCReaderService? = nil,
        myNumberOCRExtractor: MyNumberCardFieldExtractorOCR = MyNumberCardFieldExtractorOCR(),
        driverLicenseOCRExtractor: DriverLicenseFieldExtractorOCR = DriverLicenseFieldExtractorOCR()
    ) {
        self.nfcReader = nfcReader
        self.profileService = profileService
        self.entitlementManager = entitlementManager
        self.hybridOCREngine = hybridOCREngine
        self.fieldExtractor = fieldExtractor
        self.myNumberNFCReader = myNumberNFCReader ?? MyNumberCardNFCReaderService(nfcReader: nfcReader)
        self.myNumberOCRExtractor = myNumberOCRExtractor
        self.driverLicenseOCRExtractor = driverLicenseOCRExtractor
    }

    // MARK: - Actions

    func showCardTypeSelection() {
        scanState = .selectCardType
    }

    func selectCardType(_ type: CardType) {
        selectedCardType = type

        #if DEBUG
        print("🎯 [NFCScanVM] Selected card type: \(type.displayName)")
        #endif

        // Proceed to method selection
        scanState = .selectMethod
    }

    func showMethodSelection() {
        scanState = .selectMethod
    }

    func selectScanMethod(_ method: CardScanMethod) {
        selectedMethod = method

        #if DEBUG
        print("🎯 [NFCScanVM] Selected scan method: \(method.displayName)")
        #endif

        // Route based on card type
        switch selectedCardType {
        case .zairyuCard:
            handleZairyuCardMethod(method)
        case .myNumberCard:
            handleMyNumberCardMethod(method)
        case .driverLicense:
            handleDriverLicenseMethod(method)
        case .none:
            #if DEBUG
            print("⚠️ [NFCScanVM] No card type selected")
            #endif
            scanState = .selectCardType
        }
    }

    // MARK: - Card-Specific Method Handlers

    private func handleZairyuCardMethod(_ method: CardScanMethod) {
        switch method {
        case .nfc:
            // Existing Zairyu NFC flow
            guard checkProAccess() else {
                #if DEBUG
                print("❌ [NFCScanVM] Pro access check failed")
                #endif
                return
            }

            #if DEBUG
            print("✅ [NFCScanVM] Pro access granted, starting Zairyu NFC scan")
            #endif

            // Automatically start NFC scan if card number is valid
            if isCardNumberValid {
                Task {
                    await startScan()
                }
            } else {
                // Go back to input if card number is not valid
                scanState = .inputCardNumber
            }

        case .camera:
            // Zairyu OCR flow (free tier)
            #if DEBUG
            print("📷 [NFCScanVM] Setting state to cameraCapturingFront for Zairyu")
            #endif
            scanState = .cameraCapturingFront
        }
    }

    private func handleMyNumberCardMethod(_ method: CardScanMethod) {
        switch method {
        case .nfc:
            // My Number NFC flow requires consent first
            guard checkProAccess() else {
                #if DEBUG
                print("❌ [NFCScanVM] Pro access check failed")
                #endif
                return
            }

            #if DEBUG
            print("🎴 [NFCScanVM] Starting My Number consent flow for NFC")
            #endif
            scanState = .awaitingConsent

        case .camera:
            // My Number OCR flow (free tier, but requires consent)
            #if DEBUG
            print("📷 [NFCScanVM] Starting My Number consent flow for OCR")
            #endif
            scanState = .awaitingConsent
        }
    }

    private func handleDriverLicenseMethod(_ method: CardScanMethod) {
        switch method {
        case .nfc:
            // Driver's License doesn't support NFC yet
            #if DEBUG
            print("⚠️ [NFCScanVM] Driver's License NFC not supported")
            #endif
            scanState = .error("NFC is not supported for Driver's License cards")

        case .camera:
            // Driver's License OCR flow (free tier)
            #if DEBUG
            print("📷 [NFCScanVM] Setting state to cameraCapturingFront for License")
            #endif
            scanState = .cameraCapturingFront
        }
    }

    func checkProAccess() -> Bool {
        let hasAccess = entitlementManager.canUseNFC()
        if !hasAccess {
            showProUpgrade = true
        }
        return hasAccess
    }

    func startScan() async {
        guard isCardNumberValid else { 
            #if DEBUG
            print("❌ [ViewModel] Card number invalid: '\(cardNumberInput)'")
            #endif
            return 
        }
        guard checkProAccess() else { 
            #if DEBUG
            print("❌ [ViewModel] Pro access denied")
            #endif
            return 
        }

        #if DEBUG
        print("🚀 [ViewModel] Starting scan with card number: \(cardNumberInput)")
        #endif
        
        scanState = .scanning
        isLoading = true

        do {
            #if targetEnvironment(simulator)
            // Use mock data in simulator
            #if DEBUG
            print("🧪 [ViewModel] Using simulator mock data")
            #endif
            try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 second delay
            let mockData = ZairyuCardDataParser.createMockData()
            scanState = .success(mockData)
            #if DEBUG
            print("✅ [ViewModel] Mock data created successfully")
            #endif
            #else
            #if DEBUG
            print("📡 [ViewModel] Initiating NFC scan...")
            #endif
            let rawData = try await nfcReader.beginScan(cardNumber: cardNumberInput)
            #if DEBUG
            print("✅ [ViewModel] NFC scan complete - received \(rawData.count) bytes")
            print("📊 [ViewModel] Raw data (hex): \(rawData.prefix(50).map { String(format: "%02x", $0) }.joined(separator: " "))...")
            print("🔍 [ViewModel] Parsing card data...")
            #endif
            let parsedData = try ZairyuCardDataParser.parse(data: rawData)
            #if DEBUG
            print("✅ [ViewModel] Parsing complete")
            print("👤 [ViewModel] Name: \(parsedData.name)")
            print("🎴 [ViewModel] Card Number: \(parsedData.cardNumber)")
            print("📅 [ViewModel] Expiry: \(parsedData.cardExpiry)")
            #endif
            scanState = .success(parsedData)
            #endif
        } catch let error as NFCReaderError {
            #if DEBUG
            print("❌ [ViewModel] NFC error: \(error.localizedDescription)")
            if let suggestion = error.recoverySuggestion {
                print("💡 [ViewModel] Suggestion: \(suggestion)")
            }
            #endif
            scanState = .error(error.localizedDescription)
        } catch {
            #if DEBUG
            print("❌ [ViewModel] Unexpected error: \(error)")
            #endif
            scanState = .error("An unexpected error occurred: \(error.localizedDescription)")
        }

        isLoading = false
        #if DEBUG
        print("🏁 [ViewModel] Scan process finished - state: \(scanState)")
        #endif
    }

    func cancelScan() {
        #if DEBUG
        print("🛑 [ViewModel] User cancelled scan")
        #endif
        nfcReader.invalidateSession()
        scanState = .inputCardNumber
        isLoading = false
    }

    func reset() {
        cardNumberInput = ""
        myNumberCardId = ""
        scanState = .inputCardNumber
        isLoading = false
    }

    // MARK: - My Number Card Actions

    /// User confirmed My Number consent - proceed to next step
    func confirmMyNumberConsent() {
        #if DEBUG
        print("✅ [My Number] User confirmed consent")
        #endif

        guard let method = selectedMethod else {
            #if DEBUG
            print("⚠️ [My Number] No scan method selected")
            #endif
            return
        }

        switch method {
        case .nfc:
            // NFC requires card ID input
            scanState = .enteringCardId
        case .camera:
            // OCR goes directly to camera
            scanState = .cameraCapturingFront
        }
    }

    /// User entered valid card ID - start My Number NFC scan
    func confirmMyNumberCardId() async {
        guard !myNumberCardId.isEmpty else {
            #if DEBUG
            print("⚠️ [My Number] Card ID is empty")
            #endif
            return
        }

        #if DEBUG
        print("🚀 [My Number] Starting NFC scan with card ID")
        #endif

        await scanMyNumberCard()
    }

    /// Perform My Number Card NFC scan
    private func scanMyNumberCard() async {
        scanState = .scanning
        isLoading = true

        do {
            #if targetEnvironment(simulator)
            // Use mock data in simulator
            #if DEBUG
            print("🧪 [My Number] Using simulator mock data")
            #endif
            try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 second delay

            // Mock My Number data
            let mockData = MyNumberCardData(
                name: "山田 太郎",
                nameKana: "ヤマダ タロウ",
                address: "東京都渋谷区代々木1-2-3",
                dateOfBirth: Calendar.current.date(from: DateComponents(year: 1990, month: 5, day: 15)),
                gender: .male,
                myNumber: "1234", // Last 4 digits only
                cardNumber: "AB1234567890",
                expiryDate: Calendar.current.date(from: DateComponents(year: 2030, month: 12, day: 31)),
                facePhoto: nil,
                issueDate: Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))
            )

            scanState = .success(mockData)
            #if DEBUG
            print("✅ [My Number] Mock data created successfully")
            #endif
            #else
            #if DEBUG
            print("📡 [My Number] Initiating NFC scan with card ID: \(myNumberCardId)")
            #endif

            let myNumberData = try await myNumberNFCReader.readMyNumberCard(cardId: myNumberCardId)

            #if DEBUG
            print("✅ [My Number] NFC scan complete")
            print("👤 [My Number] Name: \(myNumberData.name)")
            print("🔒 [My Number] My Number: ****-****-\(myNumberData.myNumber ?? "****")")
            #endif

            scanState = .success(myNumberData)
            #endif
        } catch let error as NFCReaderError {
            #if DEBUG
            print("❌ [My Number] NFC error: \(error.localizedDescription)")
            if let suggestion = error.recoverySuggestion {
                print("💡 [My Number] Suggestion: \(suggestion)")
            }
            #endif
            scanState = .error(error.localizedDescription)
        } catch {
            #if DEBUG
            print("❌ [My Number] Unexpected error: \(error)")
            #endif
            scanState = .error("An unexpected error occurred: \(error.localizedDescription)")
        }

        isLoading = false
        #if DEBUG
        print("🏁 [My Number] Scan process finished - state: \(scanState)")
        #endif
    }

    func saveToProfile(_ cardData: ZairyuCardData) async throws {
        #if DEBUG
        print("💾 [ViewModel] Saving card data to profile...")
        print("   Name: \(cardData.name)")
        print("   Card Number: \(cardData.cardNumber)")
        #endif
        
        isLoading = true
        defer { isLoading = false }

        // Check if there's an active profile to update
        if let existingProfile = try await profileService.fetchActive() {
            #if DEBUG
            print("✏️ [ViewModel] Updating existing profile ID: \(existingProfile.id)")
            #endif
            try await profileService.update(existingProfile, with: cardData.toProfileUpdates())
            #if DEBUG
            print("✅ [ViewModel] Profile updated successfully")
            #endif
        } else {
            #if DEBUG
            print("➕ [ViewModel] Creating new profile")
            #endif
            // Create new profile
            _ = try await profileService.create(
                name: cardData.name,
                nameKatakana: cardData.nameKatakana,
                dateOfBirth: cardData.dateOfBirth,
                nationality: cardData.nationality,
                address: cardData.address,
                cardNumber: cardData.cardNumber,
                cardExpiry: cardData.cardExpiry,
                visaType: cardData.visaType
            )
            #if DEBUG
            print("✅ [ViewModel] New profile created successfully")
            #endif
        }
    }

    // MARK: - OCR Actions

    /// Process captured camera image with hybrid OCR engine
    func processCameraImage(_ image: UIImage, cardSide: CardSide) async {
        scanState = .ocrProcessing
        isLoading = true

        do {
            // Use hybrid OCR engine (Vision + ML Kit)
            let rawFields = try await hybridOCREngine.scanCard(image)

            // Route based on card type
            switch selectedCardType {
            case .zairyuCard:
                await processZairyuCardOCR(rawFields: rawFields, cardSide: cardSide)

            case .myNumberCard:
                await processMyNumberCardOCR(rawFields: rawFields)

            case .driverLicense:
                await processDriverLicenseOCR(rawFields: rawFields)

            case .none:
                #if DEBUG
                print("⚠️ [OCR] No card type selected")
                #endif
                scanState = .error("Please select a card type first")
            }

        } catch {
            #if DEBUG
            print("❌ [OCR] Processing failed: \(error.localizedDescription)")
            #endif

            scanState = .error("OCR processing failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Card-Specific OCR Processing

    private func processZairyuCardOCR(rawFields: [OCRField], cardSide: CardSide) async {
        let fields: [OCRField]

        switch cardSide {
        case .front:
            fields = fieldExtractor.extractFrontCardFields(from: rawFields)
            frontCardOCRFields = fields

        case .back:
            fields = fieldExtractor.extractBackCardFields(from: rawFields)
            backCardOCRFields = fields
        }

        #if DEBUG
        print("✅ [OCR] Extracted \(fields.count) Zairyu fields from \(cardSide) card")
        fields.forEach { field in
            print("  - \(field.fieldName): \(field.value) (confidence: \(field.confidence))")
        }
        #endif

        guard fields.count >= 1 else {
            throw OCRError.lowConfidence
        }

        // For back card, merge with front fields
        let allFields = cardSide == .back
            ? frontCardOCRFields + fields
            : fields

        scanState = .reviewOCRResults(allFields)
    }

    private func processMyNumberCardOCR(rawFields: [OCRField]) async {
        #if DEBUG
        print("🎴 [My Number OCR] Processing \(rawFields.count) raw fields")
        #endif

        // Extract My Number Card fields
        guard let myNumberData = myNumberOCRExtractor.extractFields(from: rawFields) else {
            #if DEBUG
            print("❌ [My Number OCR] Failed to extract required fields")
            #endif
            scanState = .error("Could not extract My Number Card information. Please try again.")
            return
        }

        #if DEBUG
        print("✅ [My Number OCR] Successfully extracted My Number Card data")
        print("   Name: \(myNumberData.name)")
        if let myNumber = myNumberData.myNumber {
            print("   My Number: ****-****-\(myNumber)")
        }
        #endif

        // My Number cards don't have reviewable fields in the current flow
        // Go directly to success since extraction succeeded
        scanState = .success(myNumberData)
    }

    private func processDriverLicenseOCR(rawFields: [OCRField]) async {
        #if DEBUG
        print("🚗 [License OCR] Processing \(rawFields.count) raw fields")
        #endif

        // Extract Driver's License fields
        guard let licenseData = driverLicenseOCRExtractor.extractFields(from: rawFields) else {
            #if DEBUG
            print("❌ [License OCR] Failed to extract required fields")
            #endif
            scanState = .error("Could not extract Driver's License information. Please try again with better lighting.")
            return
        }

        #if DEBUG
        print("✅ [License OCR] Successfully extracted Driver's License data")
        print("   Name: \(licenseData.name)")
        print("   License Number: \(licenseData.licenseNumber)")
        print("   Prefecture: \(licenseData.prefecture.displayName)")
        print("   License Types: \(licenseData.formattedLicenseTypes)")
        #endif

        // Driver's License goes directly to success (no review screen for now)
        scanState = .success(licenseData)
    }

    /// Prompt for back card scan after front review
    func promptBackCardScan() {
        currentCardSide = .back
        scanState = .cameraCapturingBack
    }

    /// Skip back card scan (save with front data only)
    func skipBackCardScan() async {
        let fields = frontCardOCRFields.reduce(into: [String: String]()) { result, field in
            result[field.fieldName] = field.value
        }
        await confirmOCRResults(editedFields: fields)
    }

    /// Confirm and save OCR results
    func confirmOCRResults(editedFields: [String: String]) async {
        isLoading = true

        do {
            // Build ZairyuCardData from edited fields
            let cardData = try buildCardData(from: editedFields)

            // Save to Core Data via ProfileService
            try await saveToProfile(cardData)

            #if DEBUG
            print("✅ [OCR] Card data saved successfully")
            #endif

            // Success state
            scanState = .success(cardData)

        } catch {
            #if DEBUG
            print("❌ [OCR] Save failed: \(error.localizedDescription)")
            #endif

            scanState = .error("Failed to save card data: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Private Helpers

    private func buildCardData(from fields: [String: String]) throws -> ZairyuCardData {
        // Validate required fields
        guard let name = fields["name"], !name.isEmpty else {
            throw ValidationError.missingRequiredField("name")
        }
        guard let cardNumber = fields["cardNumber"], cardNumber.count == 12 else {
            throw ValidationError.invalidValue("cardNumber", fields["cardNumber"] ?? "")
        }

        // Parse dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"

        let dateOfBirth = fields["dateOfBirth"].flatMap { dateFormatter.date(from: $0) }
        let cardExpiry = fields["cardExpiry"].flatMap { dateFormatter.date(from: $0) }

        // Build data model
        return ZairyuCardData(
            name: name,
            nameKatakana: nil, // OCR doesn't extract katakana reliably
            dateOfBirth: dateOfBirth,
            nationality: fields["nationality"],
            address: fields["address"],
            cardNumber: cardNumber,
            cardExpiry: cardExpiry,
            visaType: fields["visaType"],
            cardType: .residenceCard, // Default assumption
            specVersion: nil
        )
    }
}

// MARK: - Supporting Types

enum CardSide {
    case front
    case back
}
