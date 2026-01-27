//
//  form-fill-view-model.swift
//  ZairyuMate
//
//  ViewModel for PDF form filling and preview
//  Handles form generation, export, and sharing
//

import Foundation
import PDFKit
import Observation

@MainActor
@Observable
class FormFillViewModel {

    // MARK: - State

    var filledDocument: PDFDocument?
    var exportedURL: URL?
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let profile: Profile
    private let formType: FormType
    private let templateManager = FormTemplateManager.shared
    private let formFiller = PDFFormFiller()
    private let exporter = PDFExporter()

    // MARK: - Computed Properties

    var hasError: Bool {
        errorMessage != nil
    }

    // MARK: - Initialization

    init(profile: Profile, formType: FormType) {
        self.profile = profile
        self.formType = formType
    }

    // MARK: - PDF Generation

    /// Generate filled PDF from template
    func generatePDF() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Load template
            let templateURL = try templateManager.loadTemplate(formType)

            // Get field mappings
            let mappings = templateManager.getFieldMappings(for: formType)

            // Fill form
            let document = try await formFiller.fillForm(
                templateURL: templateURL,
                profile: profile,
                mappings: mappings
            )

            filledDocument = document

            #if DEBUG
            print("✅ Generated PDF for \(formType.shortName)")
            #endif
        } catch {
            errorMessage = "Failed to generate PDF: \(error.localizedDescription)"
            #if DEBUG
            print("❌ PDF generation failed: \(error)")
            #endif
        }
    }

    // MARK: - Export Actions

    /// Export PDF to temp directory (for sharing)
    func exportForSharing() async {
        guard let document = filledDocument else {
            errorMessage = "No document to export"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let filename = generateFilename()
            let url = try await exporter.export(document, filename: filename, flatten: true)
            exportedURL = url

            #if DEBUG
            print("✅ Exported for sharing: \(url.lastPathComponent)")
            #endif
        } catch {
            errorMessage = "Failed to export PDF: \(error.localizedDescription)"
            #if DEBUG
            print("❌ Export failed: \(error)")
            #endif
        }
    }

    /// Save PDF to Files app
    func saveToFiles() async {
        await exportForSharing()
    }

    /// Open netprint app for 7-Eleven printing
    func openNetprint() {
        guard let url = URL(string: "netprint://") else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            #if DEBUG
            print("✅ Opened netprint app")
            #endif
        } else {
            // Fallback to App Store
            if let appStoreURL = URL(string: "https://apps.apple.com/jp/app/netprint/id858452676") {
                UIApplication.shared.open(appStoreURL)
                #if DEBUG
                print("📱 Opening App Store for netprint")
                #endif
            }
        }
    }

    // MARK: - Helper Methods

    /// Generate filename for export
    private func generateFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())

        let nameComponent = profile.name
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()

        return "\(formType.filename)-\(nameComponent)-\(dateString)"
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Cleanup

    deinit {
        // Clean up exported file
        if let url = exportedURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
