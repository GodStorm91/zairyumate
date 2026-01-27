//
//  form-template.swift
//  ZairyuMate
//
//  Form template metadata and types
//  Defines available MOJ visa forms
//

import Foundation

// MARK: - Form Type

enum FormType: String, CaseIterable, Identifiable {
    case extensionForm = "extension"
    case changeForm = "change"

    var id: String { rawValue }

    /// Display name in Japanese and English
    var displayName: String {
        switch self {
        case .extensionForm:
            return "在留期間更新許可申請書\nVisa Extension"
        case .changeForm:
            return "在留資格変更許可申請書\nStatus Change"
        }
    }

    /// Short display name for UI
    var shortName: String {
        switch self {
        case .extensionForm:
            return "Visa Extension"
        case .changeForm:
            return "Status Change"
        }
    }

    /// Description of when to use this form
    var description: String {
        switch self {
        case .extensionForm:
            return "Use this form to extend your current visa status"
        case .changeForm:
            return "Use this form to change your visa status"
        }
    }

    /// PDF filename in bundle Resources/Forms/
    var filename: String {
        switch self {
        case .extensionForm:
            return "extension-form"
        case .changeForm:
            return "change-form"
        }
    }

    /// Icon name for form selection
    var iconName: String {
        switch self {
        case .extensionForm:
            return "arrow.clockwise.circle.fill"
        case .changeForm:
            return "arrow.left.arrow.right.circle.fill"
        }
    }
}

// MARK: - Form Template

struct FormTemplate {
    let type: FormType
    let version: String
    let lastUpdated: Date
    let fieldMappings: [FormFieldMapping]

    init(type: FormType, version: String = "1.0", lastUpdated: Date = Date(), fieldMappings: [FormFieldMapping]) {
        self.type = type
        self.version = version
        self.lastUpdated = lastUpdated
        self.fieldMappings = fieldMappings
    }
}
