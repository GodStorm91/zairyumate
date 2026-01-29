//
//  ml-kit-text-recognizer-service.swift
//  ZairyuMate
//
//  Google ML Kit Text Recognition service for Japanese text
//  Provides higher accuracy than Vision Framework for Japanese characters
//

import UIKit
import MLKitTextRecognition
import MLKitTextRecognitionJapanese
import MLKitVision

/// Google ML Kit text recognition service with Japanese language support
class MLKitTextRecognizerService {

    private let textRecognizer: TextRecognizer

    init() {
        // Initialize with Japanese text recognizer options
        let options = JapaneseTextRecognizerOptions()
        self.textRecognizer = TextRecognizer.textRecognizer(options: options)
    }

    /// Recognize text from image using ML Kit
    func recognize(_ image: UIImage) async throws -> [OCRField] {
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation

        // Process image with ML Kit
        let text = try await processImage(visionImage)

        // Convert ML Kit results to OCRField array
        return extractFields(from: text, imageSize: image.size)
    }

    // MARK: - Private Methods

    private func processImage(_ visionImage: VisionImage) async throws -> Text {
        try await withCheckedThrowingContinuation { continuation in
            textRecognizer.process(visionImage) { result, error in
                if let error = error {
                    continuation.resume(throwing: MLKitError.recognitionFailed(error))
                    return
                }

                guard let text = result else {
                    continuation.resume(throwing: MLKitError.noTextFound)
                    return
                }

                continuation.resume(returning: text)
            }
        }
    }

    private func extractFields(from text: Text, imageSize: CGSize) -> [OCRField] {
        var fields: [OCRField] = []

        for block in text.blocks {
            for line in block.lines {
                let normalizedBox = normalizeBox(line.frame, imageSize: imageSize)

                let field = OCRField(
                    fieldName: "raw_line",
                    value: line.text,
                    confidence: line.confidence,
                    boundingBox: normalizedBox,
                    source: .mlkit
                )

                fields.append(field)

                #if DEBUG
                if DebugConstants.verboseLogging {
                    print("📱 [ML Kit] Line: \(line.text) | Confidence: \(String(format: "%.2f", line.confidence))")
                }
                #endif
            }
        }

        return fields
    }

    /// Normalize bounding box coordinates to 0-1 range
    private func normalizeBox(_ frame: CGRect, imageSize: CGSize) -> CGRect {
        CGRect(
            x: frame.origin.x / imageSize.width,
            y: frame.origin.y / imageSize.height,
            width: frame.width / imageSize.width,
            height: frame.height / imageSize.height
        )
    }
}

// MARK: - Error Types

enum MLKitError: LocalizedError {
    case recognitionFailed(Error)
    case noTextFound
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .recognitionFailed(let error):
            return "ML Kit recognition failed: \(error.localizedDescription)"
        case .noTextFound:
            return "No text found in image"
        case .invalidImage:
            return "Invalid image format"
        }
    }
}
