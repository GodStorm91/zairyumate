//
//  card-scan-errors.swift
//  ZairyuMate
//
//  Enhanced error handling for card scanning with user-friendly messages
//  Provides specific error types and recovery suggestions
//

import Foundation

/// Errors that can occur during card scanning (NFC or OCR)
enum CardScanError: LocalizedError {

    // MARK: - OCR Errors

    case ocrProcessingFailed
    case ocrLowConfidence
    case ocrImageQualityPoor
    case ocrNoTextDetected
    case ocrTimeout
    case ocrMissingRequiredFields(fields: [String])

    // MARK: - NFC Errors

    case nfcNotSupported
    case nfcSessionTimeout
    case nfcCardNotDetected
    case nfcAuthenticationFailed
    case nfcInvalidCardNumber
    case nfcInvalidCardId
    case nfcReadError

    // MARK: - Card Type Errors

    case wrongCardType(expected: CardType, detected: CardType?)
    case cardTypeNotSelected
    case unsupportedReadMethod(cardType: CardType, method: CardScanMethod)

    // MARK: - General Errors

    case cameraPermissionDenied
    case nfcPermissionDenied
    case processingCancelled
    case unknown(Error)

    // MARK: - LocalizedError Protocol

    var errorDescription: String? {
        switch self {
        // OCR Errors
        case .ocrProcessingFailed:
            return "Failed to process card image"
        case .ocrLowConfidence:
            return "Could not read card information clearly"
        case .ocrImageQualityPoor:
            return "Image quality is too poor to read"
        case .ocrNoTextDetected:
            return "No text detected on card"
        case .ocrTimeout:
            return "Processing took too long"
        case .ocrMissingRequiredFields(let fields):
            return "Could not detect: \(fields.joined(separator: ", "))"

        // NFC Errors
        case .nfcNotSupported:
            return "NFC is not supported on this device"
        case .nfcSessionTimeout:
            return "NFC scan timed out"
        case .nfcCardNotDetected:
            return "Card not detected - please hold card steady"
        case .nfcAuthenticationFailed:
            return "Card authentication failed"
        case .nfcInvalidCardNumber:
            return "Invalid card number - please check and try again"
        case .nfcInvalidCardId:
            return "Invalid card ID - must be 12 digits"
        case .nfcReadError:
            return "Failed to read card data"

        // Card Type Errors
        case .wrongCardType(let expected, let detected):
            if let detected = detected {
                return "Wrong card type - expected \(expected.displayName), detected \(detected.displayName)"
            } else {
                return "Wrong card type - expected \(expected.displayName)"
            }
        case .cardTypeNotSelected:
            return "Please select a card type first"
        case .unsupportedReadMethod(let cardType, let method):
            return "\(method.displayName) is not supported for \(cardType.displayName)"

        // General Errors
        case .cameraPermissionDenied:
            return "Camera permission is required"
        case .nfcPermissionDenied:
            return "NFC permission is required"
        case .processingCancelled:
            return "Scan cancelled"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        // OCR Errors
        case .ocrProcessingFailed:
            return "Please try again with better lighting and a clear view of the card."
        case .ocrLowConfidence:
            return "Try improving lighting, removing glare, and keeping the card flat."
        case .ocrImageQualityPoor:
            return "Ensure good lighting, no shadows or glare, and hold the camera steady."
        case .ocrNoTextDetected:
            return "Make sure the entire card is visible in the frame."
        case .ocrTimeout:
            return "Please try again. Close other apps if the problem persists."
        case .ocrMissingRequiredFields:
            return "Try scanning both sides of the card or entering information manually."

        // NFC Errors
        case .nfcNotSupported:
            return "Use camera scanning instead, or upgrade to a device with NFC support."
        case .nfcSessionTimeout:
            return "Hold the card against the top of your iPhone for at least 3 seconds."
        case .nfcCardNotDetected:
            return "Position the card against the top edge of your iPhone and hold still."
        case .nfcAuthenticationFailed:
            return "Verify the card number is correct and try again."
        case .nfcInvalidCardNumber:
            return "The card number should be 12 characters (letters and numbers)."
        case .nfcInvalidCardId:
            return "The card ID should be 12 digits, found on the back of your card."
        case .nfcReadError:
            return "Remove the card and try scanning again. Ensure the card is valid."

        // Card Type Errors
        case .wrongCardType:
            return "Please select the correct card type before scanning."
        case .cardTypeNotSelected:
            return "Go back and select which type of card you want to scan."
        case .unsupportedReadMethod:
            return "Please use the supported scanning method for this card type."

        // General Errors
        case .cameraPermissionDenied:
            return "Go to Settings > Privacy > Camera and enable access for ZairyuMate."
        case .nfcPermissionDenied:
            return "Go to Settings and enable NFC for ZairyuMate."
        case .processingCancelled:
            return nil
        case .unknown:
            return "Please try again. Contact support if the problem continues."
        }
    }

    var failureReason: String? {
        switch self {
        case .ocrLowConfidence:
            return "The OCR engine could not confidently read the text on the card."
        case .ocrImageQualityPoor:
            return "The image is blurry, too dark, or has too much glare."
        case .nfcAuthenticationFailed:
            return "The card number provided does not match the card's data."
        case .wrongCardType:
            return "The detected card type does not match the selected type."
        default:
            return nil
        }
    }
}

// MARK: - Error Helpers

extension CardScanError {

    /// Check if error is recoverable by retrying
    var isRecoverable: Bool {
        switch self {
        case .ocrProcessingFailed, .ocrLowConfidence, .ocrImageQualityPoor,
             .ocrNoTextDetected, .ocrTimeout,
             .nfcSessionTimeout, .nfcCardNotDetected, .nfcReadError:
            return true
        case .nfcNotSupported, .cameraPermissionDenied, .nfcPermissionDenied:
            return false
        default:
            return true
        }
    }

    /// Suggested action for user
    var suggestedAction: String {
        switch self {
        case .cameraPermissionDenied, .nfcPermissionDenied:
            return "Open Settings"
        case .nfcNotSupported:
            return "Use Camera"
        case .processingCancelled:
            return "Try Again"
        default:
            return "Retry Scan"
        }
    }

    /// Icon to display with error
    var icon: String {
        switch self {
        case .ocrProcessingFailed, .ocrLowConfidence, .ocrImageQualityPoor,
             .ocrNoTextDetected, .ocrTimeout, .ocrMissingRequiredFields:
            return "camera.fill"
        case .nfcNotSupported, .nfcSessionTimeout, .nfcCardNotDetected,
             .nfcAuthenticationFailed, .nfcInvalidCardNumber, .nfcInvalidCardId,
             .nfcReadError:
            return "antenna.radiowaves.left.and.right"
        case .wrongCardType, .cardTypeNotSelected, .unsupportedReadMethod:
            return "creditcard.fill"
        case .cameraPermissionDenied:
            return "lock.camera"
        case .nfcPermissionDenied:
            return "lock.shield"
        case .processingCancelled:
            return "xmark.circle"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Error Creation Helpers

extension CardScanError {

    /// Create error from OCR failure
    static func fromOCRFailure(confidence: Float? = nil) -> CardScanError {
        if let conf = confidence, conf < 0.5 {
            return .ocrLowConfidence
        } else if let conf = confidence, conf < 0.7 {
            return .ocrImageQualityPoor
        } else {
            return .ocrProcessingFailed
        }
    }

    /// Create error from NFC failure
    static func fromNFCError(_ nfcError: NFCReaderError) -> CardScanError {
        switch nfcError {
        case .sessionTimeout:
            return .nfcSessionTimeout
        case .tagConnectionLost, .invalidResponse:
            return .nfcCardNotDetected
        case .unsupportedTag:
            return .wrongCardType(expected: .zairyuCard, detected: nil)
        case .userCancelled:
            return .processingCancelled
        default:
            return .nfcReadError
        }
    }
}
