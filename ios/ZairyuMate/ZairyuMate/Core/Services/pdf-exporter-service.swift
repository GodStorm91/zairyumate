//
//  pdf-exporter-service.swift
//  ZairyuMate
//
//  Service for exporting and sharing PDF documents
//  Supports flattening (rendering forms to static content)
//

import Foundation
import PDFKit
import UIKit

// MARK: - PDF Exporter

@MainActor
class PDFExporter {

    // MARK: - Export

    /// Export PDF document to temporary file
    func export(
        _ document: PDFDocument,
        filename: String,
        flatten: Bool = true
    ) async throws -> URL {
        #if DEBUG
        let startTime = Date()
        print("📤 Exporting PDF (flatten: \(flatten))")
        #endif

        // Create temporary file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension("pdf")

        // Remove existing file if present
        try? FileManager.default.removeItem(at: tempURL)

        if flatten {
            // Flatten: render to new PDF (makes fields non-editable)
            let flattenedDocument = try await renderFlattened(document)
            guard flattenedDocument.write(to: tempURL) else {
                throw FormError.exportFailed
            }
        } else {
            // Direct write (keeps fields editable)
            guard document.write(to: tempURL) else {
                throw FormError.exportFailed
            }
        }

        #if DEBUG
        let duration = Date().timeIntervalSince(startTime)
        let fileSize = try? FileManager.default.attributesOfItem(atPath: tempURL.path)[.size] as? Int64 ?? 0
        let fileSizeKB = Double(fileSize ?? 0) / 1024.0
        print("✅ Exported PDF in \(String(format: "%.2f", duration))s (\(String(format: "%.1f", fileSizeKB)) KB)")
        #endif

        return tempURL
    }

    // MARK: - Flattening

    /// Render PDF to flattened version (non-editable)
    private func renderFlattened(_ document: PDFDocument) async throws -> PDFDocument {
        guard let firstPage = document.page(at: 0) else {
            throw FormError.flattenFailed
        }

        // Get page size from first page
        let pageRect = firstPage.bounds(for: .mediaBox)

        // Create new PDF document
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)

        // Render each page
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            let bounds = page.bounds(for: .mediaBox)

            // Start new page
            UIGraphicsBeginPDFPageWithInfo(bounds, nil)

            guard let context = UIGraphicsGetCurrentContext() else { continue }

            // Save context state
            context.saveGState()

            // Set up coordinate system (PDF uses bottom-left origin)
            context.translateBy(x: 0, y: bounds.height)
            context.scaleBy(x: 1.0, y: -1.0)

            // Draw page content
            page.draw(with: .mediaBox, to: context)

            // Restore context state
            context.restoreGState()
        }

        UIGraphicsEndPDFContext()

        // Create PDFDocument from rendered data
        guard let flattenedDocument = PDFDocument(data: pdfData as Data) else {
            throw FormError.flattenFailed
        }

        return flattenedDocument
    }

    // MARK: - Cleanup

    /// Clean up temporary PDF files
    func cleanupTempFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: nil
            )

            let pdfFiles = files.filter { $0.pathExtension == "pdf" }

            for file in pdfFiles {
                try? FileManager.default.removeItem(at: file)
            }

            #if DEBUG
            print("🗑️ Cleaned up \(pdfFiles.count) temporary PDF files")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to cleanup temp files: \(error)")
            #endif
        }
    }
}
