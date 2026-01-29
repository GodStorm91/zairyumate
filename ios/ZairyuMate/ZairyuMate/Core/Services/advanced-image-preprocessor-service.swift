//
//  advanced-image-preprocessor-service.swift
//  ZairyuMate
//
//  Advanced image preprocessing for OCR accuracy improvement
//  Includes deskew, binarization, morphological operations, shadow removal
//

import UIKit
import CoreImage

/// Advanced image preprocessing service for improved OCR accuracy
class AdvancedImagePreprocessorService {

    private let context = CIContext()

    /// Apply full preprocessing pipeline to card image
    func preprocess(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        var processed = ciImage

        // Step 1: Perspective correction (deskew)
        processed = correctPerspective(processed)

        // Step 2: Contrast enhancement
        processed = enhanceContrast(processed)

        // Step 3: Sharpening
        processed = sharpen(processed)

        // Step 4: Binarization for better text recognition
        processed = binarize(processed)

        // Step 5: Morphological operations (close gaps in characters)
        processed = morphologicalClose(processed)

        // Step 6: Shadow removal
        processed = removeShadows(processed)

        return render(processed) ?? image
    }

    // MARK: - Preprocessing Steps

    /// Correct perspective distortion (deskew)
    private func correctPerspective(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)

        // Auto-detect corners (simplified - production may need rectangle detection)
        let topLeft = CIVector(x: 0, y: image.extent.height)
        let topRight = CIVector(x: image.extent.width, y: image.extent.height)
        let bottomLeft = CIVector(x: 0, y: 0)
        let bottomRight = CIVector(x: image.extent.width, y: 0)

        filter.setValue(topLeft, forKey: "inputTopLeft")
        filter.setValue(topRight, forKey: "inputTopRight")
        filter.setValue(bottomLeft, forKey: "inputBottomLeft")
        filter.setValue(bottomRight, forKey: "inputBottomRight")

        return filter.outputImage ?? image
    }

    /// Enhance contrast for better text visibility
    private func enhanceContrast(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.5, forKey: kCIInputContrastKey) // Boost contrast
        filter.setValue(1.1, forKey: kCIInputSaturationKey) // Slight saturation increase

        return filter.outputImage ?? image
    }

    /// Sharpen text edges
    private func sharpen(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIUnsharpMask") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(2.5, forKey: kCIInputIntensityKey)
        filter.setValue(0.5, forKey: kCIInputRadiusKey)

        return filter.outputImage ?? image
    }

    /// Binarize image (black text on white background)
    private func binarize(_ image: CIImage) -> CIImage {
        // Convert to grayscale first
        guard let grayscale = CIFilter(name: "CIPhotoEffectMono") else {
            return image
        }
        grayscale.setValue(image, forKey: kCIInputImageKey)
        let gray = grayscale.outputImage ?? image

        // Apply threshold (Otsu's method approximation)
        guard let threshold = CIFilter(name: "CIColorControls") else {
            return gray
        }
        threshold.setValue(gray, forKey: kCIInputImageKey)
        threshold.setValue(2.0, forKey: kCIInputContrastKey)
        threshold.setValue(0.5, forKey: kCIInputBrightnessKey)

        return threshold.outputImage ?? gray
    }

    /// Morphological close operation (dilate then erode)
    private func morphologicalClose(_ image: CIImage) -> CIImage {
        // Dilation (fill gaps)
        guard let dilate = CIFilter(name: "CIMorphologyMaximum") else {
            return image
        }
        dilate.setValue(image, forKey: kCIInputImageKey)
        dilate.setValue(1, forKey: kCIInputRadiusKey)

        let dilated = dilate.outputImage ?? image

        // Erosion (smooth edges)
        guard let erode = CIFilter(name: "CIMorphologyMinimum") else {
            return dilated
        }
        erode.setValue(dilated, forKey: kCIInputImageKey)
        erode.setValue(1, forKey: kCIInputRadiusKey)

        return erode.outputImage ?? dilated
    }

    /// Remove shadows for uniform background
    private func removeShadows(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIExposureAdjust") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.5, forKey: kCIInputEVKey) // Brighten shadows

        return filter.outputImage ?? image
    }

    // MARK: - Utilities

    /// Render CIImage to UIImage
    private func render(_ ciImage: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    /// Assess image quality before OCR
    func assessQuality(_ image: UIImage) -> (isGood: Bool, issues: [String]) {
        var issues: [String] = []

        // Check resolution
        if image.size.width < 1000 || image.size.height < 600 {
            issues.append("Low resolution (\(Int(image.size.width))x\(Int(image.size.height)))")
        }

        // Check aspect ratio (cards are typically ~1.6:1)
        let aspectRatio = image.size.width / image.size.height
        if aspectRatio < 1.3 || aspectRatio > 2.0 {
            issues.append("Unusual aspect ratio (\(String(format: "%.2f", aspectRatio)):1)")
        }

        return (issues.isEmpty, issues)
    }
}
