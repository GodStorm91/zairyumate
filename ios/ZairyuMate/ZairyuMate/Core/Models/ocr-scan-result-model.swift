//
//  ocr-scan-result-model.swift
//  ZairyuMate
//
//  Result from OCR scanning containing extracted fields with confidence scores
//

import Foundation
import CoreGraphics

/// OCR engine source identifier for hybrid results
enum OCRSource: String, Codable, Equatable {
    case vision = "Vision"
    case mlkit = "ML Kit"
    case hybrid = "Hybrid"
}

/// Confidence level classification for UI indicators
enum ConfidenceLevel {
    case high   // ≥0.85 - Green badge
    case medium // 0.75-0.85 - Orange badge
    case low    // <0.75 - Red badge
}

/// Result from OCR scanning containing extracted fields with confidence scores
struct OCRScanResult: Equatable {
    let frontCardFields: [OCRField]
    let backCardFields: [OCRField]?
    let rawText: String
    let processingTime: TimeInterval
    let ocrSource: OCRSource // Track which engine(s) used

    /// Get field value by name
    func field(_ name: String) -> OCRField? {
        frontCardFields.first { $0.fieldName == name }
            ?? backCardFields?.first { $0.fieldName == name }
    }
}

/// Individual OCR-extracted field with confidence score
struct OCRField: Equatable {
    let fieldName: String
    let value: String
    let confidence: Float
    let boundingBox: CGRect
    var source: OCRSource = .vision // Default to Vision for backward compatibility

    /// Field needs manual review if confidence below threshold
    var needsReview: Bool {
        confidence < OCRConstants.confidenceThreshold
    }

    /// Confidence level for UI display
    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0.85...: return .high
        case 0.75..<0.85: return .medium
        default: return .low
        }
    }

    /// Create a copy with updated source tag
    func tagged(source: OCRSource) -> OCRField {
        OCRField(
            fieldName: fieldName,
            value: value,
            confidence: confidence,
            boundingBox: boundingBox,
            source: source
        )
    }
}
