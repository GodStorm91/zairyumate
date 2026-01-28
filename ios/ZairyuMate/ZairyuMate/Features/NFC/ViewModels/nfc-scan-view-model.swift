//
//  nfc-scan-view-model.swift
//  ZairyuMate
//
//  NFC card scan view model with state management
//  Manages scan lifecycle and Pro feature gating
//

import Foundation
import Observation

@MainActor
@Observable
class NFCScanViewModel {

    // MARK: - State

    enum ScanState: Equatable {
        case idle
        case inputCardNumber
        case scanning
        case success(ZairyuCardData)
        case error(String)
    }

    var scanState: ScanState = .idle
    var cardNumberInput: String = ""
    var isLoading: Bool = false
    var showProUpgrade: Bool = false

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

    // MARK: - Initialization

    init(
        nfcReader: NFCReaderService,
        profileService: ProfileService,
        entitlementManager: EntitlementManager
    ) {
        self.nfcReader = nfcReader
        self.profileService = profileService
        self.entitlementManager = entitlementManager
    }

    // MARK: - Actions

    func checkProAccess() -> Bool {
        let hasAccess = entitlementManager.canUseNFC()
        if !hasAccess {
            showProUpgrade = true
        }
        return hasAccess
    }

    func startScan() async {
        guard isCardNumberValid else { return }
        guard checkProAccess() else { return }

        scanState = .scanning
        isLoading = true

        do {
            #if targetEnvironment(simulator)
            // Use mock data in simulator
            try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 second delay
            let mockData = ZairyuCardDataParser.createMockData()
            scanState = .success(mockData)
            #else
            let rawData = try await nfcReader.beginScan(cardNumber: cardNumberInput)
            let parsedData = try ZairyuCardDataParser.parse(data: rawData)
            scanState = .success(parsedData)
            #endif
        } catch let error as NFCReaderError {
            scanState = .error(error.localizedDescription)
        } catch {
            scanState = .error("An unexpected error occurred: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func cancelScan() {
        nfcReader.invalidateSession()
        scanState = .inputCardNumber
        isLoading = false
    }

    func reset() {
        cardNumberInput = ""
        scanState = .inputCardNumber
        isLoading = false
    }

    func saveToProfile(_ cardData: ZairyuCardData) async throws {
        isLoading = true
        defer { isLoading = false }

        // Check if there's an active profile to update
        if let existingProfile = try await profileService.fetchActive() {
            try await profileService.update(existingProfile, with: cardData.toProfileUpdates())
        } else {
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
        }
    }
}
