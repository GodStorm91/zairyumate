//
//  pdf-form-integration-helper.swift
//  ZairyuMate
//
//  Helper for integrating PDF form functionality
//  Provides convenience methods for common operations
//

import Foundation
import PDFKit

// MARK: - PDF Form Integration Helper

@MainActor
class PDFFormIntegrationHelper {

    // MARK: - Singleton

    static let shared = PDFFormIntegrationHelper()

    // MARK: - Dependencies

    private let templateManager = FormTemplateManager.shared
    private let formFiller = PDFFormFiller()
    private let exporter = PDFExporter()

    // MARK: - Initialization

    private init() {}

    // MARK: - One-Stop Operations

    /// Generate, fill, and export PDF in one call
    func generateAndExportPDF(
        profile: Profile,
        formType: FormType,
        flatten: Bool = true
    ) async throws -> URL {
        // Load template
        let templateURL = try templateManager.loadTemplate(formType)

        // Get mappings
        let mappings = templateManager.getFieldMappings(for: formType)

        // Fill form
        let document = try await formFiller.fillForm(
            templateURL: templateURL,
            profile: profile,
            mappings: mappings
        )

        // Generate filename
        let filename = generateFilename(profile: profile, formType: formType)

        // Export
        let url = try await exporter.export(document, filename: filename, flatten: flatten)

        return url
    }

    /// Validate form template availability
    func validateFormAvailability(_ formType: FormType) -> Bool {
        do {
            _ = try templateManager.loadTemplate(formType)
            return true
        } catch {
            return false
        }
    }

    /// Get list of available forms
    func availableFormTypes() -> [FormType] {
        return FormType.allCases.filter { validateFormAvailability($0) }
    }

    // MARK: - Debug Helpers

    #if DEBUG
    /// List all form fields in a template (for debugging)
    func debugListFields(formType: FormType) throws -> [String] {
        let templateURL = try templateManager.loadTemplate(formType)
        guard let document = PDFDocument(url: templateURL) else {
            throw FormError.pdfLoadFailed
        }
        return formFiller.listFormFields(in: document)
    }

    /// Validate field mappings against actual PDF
    func debugValidateMappings(formType: FormType) throws -> [String] {
        let templateURL = try templateManager.loadTemplate(formType)
        guard let document = PDFDocument(url: templateURL) else {
            throw FormError.pdfLoadFailed
        }
        let mappings = templateManager.getFieldMappings(for: formType)
        return formFiller.validateMappings(document: document, mappings: mappings)
    }
    #endif

    // MARK: - Helper Methods

    private func generateFilename(profile: Profile, formType: FormType) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())

        let nameComponent = profile.name
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()

        return "\(formType.filename)-\(nameComponent)-\(dateString)"
    }

    /// Cleanup all temporary files
    func cleanupTempFiles() {
        exporter.cleanupTempFiles()
    }
}
