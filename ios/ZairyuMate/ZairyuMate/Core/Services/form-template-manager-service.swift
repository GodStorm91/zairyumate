//
//  form-template-manager-service.swift
//  ZairyuMate
//
//  Service for managing PDF form templates
//  Loads bundled templates and caches field mappings
//

import Foundation

// MARK: - Form Template Manager

@MainActor
class FormTemplateManager {

    // MARK: - Singleton

    static let shared = FormTemplateManager()

    // MARK: - Properties

    private var cachedMappings: [String: [FormFieldMapping]] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Template Loading

    /// Load PDF template from bundle
    func loadTemplate(_ type: FormType) throws -> URL {
        guard let url = Bundle.main.url(forResource: type.filename, withExtension: "pdf", subdirectory: "Forms") else {
            throw FormError.templateNotFound(type.shortName)
        }

        // Verify file exists and is readable
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FormError.templateNotFound(type.shortName)
        }

        #if DEBUG
        print("✅ Loaded template: \(type.filename).pdf")
        #endif

        return url
    }

    // MARK: - Field Mappings

    /// Get field mappings for form type (cached)
    func getFieldMappings(for type: FormType) -> [FormFieldMapping] {
        // Check cache first
        if let cached = cachedMappings[type.rawValue] {
            return cached
        }

        // Load mappings based on type
        let mappings: [FormFieldMapping]
        switch type {
        case .extensionForm:
            mappings = ExtensionFormMapping.mappings
        case .changeForm:
            mappings = ChangeFormMapping.mappings
        }

        // Cache for next time
        cachedMappings[type.rawValue] = mappings

        #if DEBUG
        print("✅ Cached \(mappings.count) field mappings for \(type.shortName)")
        #endif

        return mappings
    }

    /// Clear cached mappings (useful for testing or updates)
    func clearCache() {
        cachedMappings.removeAll()
        #if DEBUG
        print("🗑️ Cleared field mapping cache")
        #endif
    }
}

// MARK: - Form Errors

enum FormError: LocalizedError {
    case templateNotFound(String)
    case pdfLoadFailed
    case fieldNotFound(String)
    case exportFailed
    case flattenFailed

    var errorDescription: String? {
        switch self {
        case .templateNotFound(let name):
            return "Form template not found: \(name)"
        case .pdfLoadFailed:
            return "Failed to load PDF document"
        case .fieldNotFound(let fieldName):
            return "PDF field not found: \(fieldName)"
        case .exportFailed:
            return "Failed to export PDF"
        case .flattenFailed:
            return "Failed to flatten PDF"
        }
    }
}
