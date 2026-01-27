//
//  pdf-kit-view-wrapper.swift
//  ZairyuMate
//
//  UIViewRepresentable wrapper for PDFKit's PDFView
//  Displays PDF documents in SwiftUI
//

import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {

    // MARK: - Properties

    let document: PDFDocument
    var autoScales: Bool = true
    var displayMode: PDFDisplayMode = .singlePageContinuous
    var displayDirection: PDFDisplayDirection = .vertical

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()

        // Configure display settings
        pdfView.autoScales = autoScales
        pdfView.displayMode = displayMode
        pdfView.displayDirection = displayDirection

        // Enable user interaction
        pdfView.isUserInteractionEnabled = true
        pdfView.usePageViewController(true, withViewOptions: nil)

        // Set background
        pdfView.backgroundColor = UIColor.systemBackground

        // Set document
        pdfView.document = document

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update document if changed
        if pdfView.document != document {
            pdfView.document = document
        }

        // Update display settings
        pdfView.autoScales = autoScales
        pdfView.displayMode = displayMode
        pdfView.displayDirection = displayDirection
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    if let url = Bundle.main.url(forResource: "sample", withExtension: "pdf"),
       let document = PDFDocument(url: url) {
        PDFKitView(document: document)
    } else {
        Text("No PDF available for preview")
            .foregroundColor(.zmTextSecondary)
    }
}
#endif
