//
//  pdf-form-filler-service.swift
//  ZairyuMate
//
//  Service for filling PDF form fields with profile data
//  Uses PDFKit to populate AcroForm fields
//

import Foundation
import PDFKit

// MARK: - PDF Form Filler

@MainActor
class PDFFormFiller {

    // MARK: - Fill Form

    /// Fill PDF form with profile data using field mappings
    func fillForm(
        templateURL: URL,
        profile: Profile,
        mappings: [FormFieldMapping]
    ) async throws -> PDFDocument {
        // Load PDF document
        guard let document = PDFDocument(url: templateURL) else {
            throw FormError.pdfLoadFailed
        }

        #if DEBUG
        print("📄 Filling PDF with \(document.pageCount) pages")
        let startTime = Date()
        #endif

        var filledFieldsCount = 0

        // Iterate through all pages
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            // Get all annotations on this page
            let annotations = page.annotations

            // Fill each field based on mappings
            for mapping in mappings {
                // Find annotation by field name
                if let annotation = annotations.first(where: { $0.fieldName == mapping.pdfFieldName }) {
                    let value = mapping.extractValue(from: profile)

                    // Set value based on annotation type
                    if let widgetAnnotation = annotation as? PDFAnnotation {
                        // Text field
                        if widgetAnnotation.widgetFieldType == .text {
                            widgetAnnotation.widgetStringValue = value
                            filledFieldsCount += 1
                        }
                        // Checkbox
                        else if widgetAnnotation.widgetFieldType == .button {
                            // Set checkbox state based on value
                            if !value.isEmpty && value != "0" && value.lowercased() != "false" {
                                widgetAnnotation.buttonWidgetState = .onState
                                filledFieldsCount += 1
                            }
                        }
                    }

                    #if DEBUG
                    if !value.isEmpty {
                        print("  ✓ \(mapping.pdfFieldName): \(value)")
                    }
                    #endif
                }
            }
        }

        #if DEBUG
        let duration = Date().timeIntervalSince(startTime)
        print("✅ Filled \(filledFieldsCount) fields in \(String(format: "%.2f", duration))s")
        #endif

        return document
    }

    // MARK: - Field Discovery

    /// List all form fields in PDF (useful for debugging)
    func listFormFields(in document: PDFDocument) -> [String] {
        var fieldNames: [String] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            for annotation in page.annotations {
                if let fieldName = annotation.fieldName, !fieldName.isEmpty {
                    fieldNames.append(fieldName)
                }
            }
        }

        return fieldNames
    }

    /// Validate that all mapped fields exist in PDF
    func validateMappings(
        document: PDFDocument,
        mappings: [FormFieldMapping]
    ) -> [String] {
        let availableFields = Set(listFormFields(in: document))
        let mappedFields = Set(mappings.map { $0.pdfFieldName })

        // Return fields that are mapped but don't exist in PDF
        let missingFields = mappedFields.subtracting(availableFields)

        #if DEBUG
        if !missingFields.isEmpty {
            print("⚠️ Missing PDF fields: \(missingFields.joined(separator: ", "))")
        }
        #endif

        return Array(missingFields)
    }
}
