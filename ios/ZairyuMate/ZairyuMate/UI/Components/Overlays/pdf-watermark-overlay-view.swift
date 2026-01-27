//
//  pdf-watermark-overlay-view.swift
//  ZairyuMate
//
//  Watermark overlay component for free tier PDF exports
//  Displays "Created with Zairyu Mate Free" text at bottom of pages
//

import SwiftUI
import PDFKit

// MARK: - PDF Watermark Overlay

struct PDFWatermarkOverlay {

    // MARK: - Properties

    /// Watermark text to display
    let text: String

    /// Font size for watermark
    let fontSize: CGFloat

    /// Text opacity (0.0 - 1.0)
    let opacity: Double

    // MARK: - Initialization

    init(
        text: String = IAPConstants.watermarkText,
        fontSize: CGFloat = 10,
        opacity: Double = 0.5
    ) {
        self.text = text
        self.fontSize = fontSize
        self.opacity = opacity
    }

    // MARK: - Watermark Application

    /// Add watermark to all pages of PDF document
    /// - Parameter document: PDF document to add watermark to
    func apply(to document: PDFDocument) {
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            addWatermark(to: page)
        }

        #if DEBUG
        print("💧 PDFWatermark: Applied watermark to \(document.pageCount) pages")
        #endif
    }

    /// Add watermark to a single PDF page
    /// - Parameter page: PDF page to add watermark to
    private func addWatermark(to page: PDFPage) {
        let bounds = page.bounds(for: .mediaBox)

        // Calculate watermark position (bottom center)
        let watermarkWidth: CGFloat = 250
        let watermarkHeight: CGFloat = 20
        let xPosition = (bounds.width - watermarkWidth) / 2
        let yPosition: CGFloat = 20 // 20pt from bottom

        let watermarkBounds = CGRect(
            x: xPosition,
            y: yPosition,
            width: watermarkWidth,
            height: watermarkHeight
        )

        // Create free text annotation
        let annotation = PDFAnnotation(
            bounds: watermarkBounds,
            forType: .freeText,
            withProperties: nil
        )

        // Configure annotation appearance
        annotation.contents = text
        annotation.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        annotation.fontColor = UIColor.gray.withAlphaComponent(opacity)
        annotation.alignment = .center
        annotation.color = .clear // No background
        annotation.border = nil

        // Make annotation non-interactive
        annotation.shouldDisplay = true
        annotation.shouldPrint = true

        // Add annotation to page
        page.addAnnotation(annotation)
    }

    // MARK: - Watermark Rendering (Alternative Method)

    /// Render watermark directly to PDF page graphics context
    /// This method draws watermark into page content (not as annotation)
    /// - Parameter page: PDF page to render watermark on
    func renderToPage(_ page: PDFPage) {
        let bounds = page.bounds(for: .mediaBox)

        // Calculate text size
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: UIColor.gray.withAlphaComponent(opacity)
        ]
        let textSize = (text as NSString).size(withAttributes: attributes)

        // Calculate position (bottom center)
        let xPosition = (bounds.width - textSize.width) / 2
        let yPosition: CGFloat = 20

        // Render watermark
        UIGraphicsBeginPDFPageWithInfo(bounds, nil)
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()

            // Draw original page
            context.translateBy(x: 0, y: bounds.height)
            context.scaleBy(x: 1.0, y: -1.0)
            page.draw(with: .mediaBox, to: context)

            context.restoreGState()

            // Draw watermark text
            (text as NSString).draw(
                at: CGPoint(x: xPosition, y: yPosition),
                withAttributes: attributes
            )
        }
        UIGraphicsEndPDFContext()
    }
}

// MARK: - Preview

#if DEBUG
struct PDFWatermarkOverlay_Preview: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Visual representation of watermark
            ZStack(alignment: .bottom) {
                // Simulate PDF page
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white)
                    .frame(width: 200, height: 280)
                    .shadow(radius: 4)
                    .overlay(
                        VStack {
                            Text("PDF Content")
                                .font(.zmBody)
                                .foregroundColor(.zmTextSecondary)
                        }
                    )

                // Watermark overlay
                Text(IAPConstants.watermarkText)
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.bottom, Spacing.sm)
            }

            Text("Free tier PDF exports include this watermark")
                .font(.zmCaption)
                .foregroundColor(.zmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .screenPadding()
        .background(Color.zmBackground)
    }
}

#Preview {
    PDFWatermarkOverlay_Preview()
}
#endif
