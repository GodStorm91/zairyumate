//
//  hybrid-ocr-engine-service.swift
//  ZairyuMate
//
//  Hybrid OCR engine that combines Vision Framework and ML Kit
//  Runs both engines in parallel and selects best results by confidence
//

import UIKit
import Vision

/// Hybrid OCR engine combining Vision Framework and Google ML Kit
class HybridOCREngineService {

    private let visionService = OCRCardScannerService()
    private let mlKitService = MLKitTextRecognizerService()
    private let preprocessor = AdvancedImagePreprocessorService()

    /// Scan card image using hybrid OCR approach
    func scanCard(_ image: UIImage) async throws -> [OCRField] {
        let startTime = Date()

        // Preprocess image with advanced filters
        let preprocessed = preprocessor.preprocess(image)

        // Quality check
        let (isGood, issues) = preprocessor.assessQuality(preprocessed)
        if !isGood {
            #if DEBUG
            print("⚠️ [Hybrid OCR] Image quality issues: \(issues.joined(separator: ", "))")
            #endif
        }

        // Run both engines in parallel
        async let visionResults = runVision(preprocessed)
        async let mlKitResults = runMLKit(preprocessed)

        let (vision, mlKit) = await (visionResults, mlKitResults)

        // Merge results by confidence
        let merged = mergeResults(vision: vision, mlKit: mlKit)

        let processingTime = Date().timeIntervalSince(startTime)

        #if DEBUG
        print("✅ [Hybrid OCR] Processed in \(String(format: "%.2f", processingTime))s | Fields: \(merged.count)")
        print("   Vision: \(vision.count) fields | ML Kit: \(mlKit.count) fields")
        #endif

        return merged
    }

    // MARK: - Private Methods

    /// Run Vision Framework OCR
    private func runVision(_ image: UIImage) async -> [OCRField] {
        do {
            let observations = try await visionService.scanFrontCard(image)
            return convertVisionResults(observations, imageSize: image.size)
        } catch {
            #if DEBUG
            print("⚠️ [Hybrid OCR] Vision failed: \(error.localizedDescription)")
            #endif
            return []
        }
    }

    /// Run ML Kit OCR
    private func runMLKit(_ image: UIImage) async -> [OCRField] {
        do {
            return try await mlKitService.recognize(image)
        } catch {
            #if DEBUG
            print("⚠️ [Hybrid OCR] ML Kit failed: \(error.localizedDescription)")
            #endif
            return []
        }
    }

    /// Convert Vision observations to OCRField array
    private func convertVisionResults(_ observations: [VNRecognizedTextObservation], imageSize: CGSize) -> [OCRField] {
        observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }

            return OCRField(
                fieldName: "raw_line",
                value: candidate.string,
                confidence: candidate.confidence,
                boundingBox: observation.boundingBox,
                source: .vision
            )
        }
    }

    /// Merge Vision and ML Kit results by confidence
    private func mergeResults(vision: [OCRField], mlKit: [OCRField]) -> [OCRField] {
        // If one engine failed, return results from the other
        if vision.isEmpty { return mlKit }
        if mlKit.isEmpty { return vision }

        // Combine all fields and deduplicate by position and text similarity
        var merged: [OCRField] = []
        var processedPositions: Set<String> = []

        // First pass: Add all unique fields from both sources
        for field in vision + mlKit {
            let positionKey = positionKey(for: field.boundingBox)

            if !processedPositions.contains(positionKey) {
                // Find matching field from other source
                let otherSource = field.source == .vision ? mlKit : vision
                if let match = findMatch(for: field, in: otherSource) {
                    // Both engines found this field - pick higher confidence
                    let best = field.confidence > match.confidence ? field : match
                    merged.append(best.tagged(source: .hybrid))
                } else {
                    // Only one engine found this field
                    merged.append(field)
                }

                processedPositions.insert(positionKey)
            }
        }

        // Sort by vertical position (top to bottom)
        merged.sort { $0.boundingBox.minY > $1.boundingBox.minY }

        return merged
    }

    /// Find matching field in other source by position and text similarity
    private func findMatch(for field: OCRField, in fields: [OCRField]) -> OCRField? {
        fields.first { other in
            // Check if bounding boxes overlap significantly
            let intersection = field.boundingBox.intersection(other.boundingBox)
            let unionArea = field.boundingBox.union(other.boundingBox).area
            let overlapRatio = intersection.area / unionArea

            // Check text similarity
            let textSimilar = field.value.lowercased() == other.value.lowercased() ||
                              field.value.contains(other.value) ||
                              other.value.contains(field.value)

            return overlapRatio > 0.5 && textSimilar
        }
    }

    /// Generate position key for deduplication
    private func positionKey(for box: CGRect) -> String {
        let x = Int(box.minX * 100)
        let y = Int(box.minY * 100)
        return "\(x),\(y)"
    }
}

// MARK: - CGRect Extensions

private extension CGRect {
    var area: CGFloat {
        width * height
    }
}
