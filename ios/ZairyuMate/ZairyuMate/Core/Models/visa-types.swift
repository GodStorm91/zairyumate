//
//  visa-types.swift
//  ZairyuMate
//
//  Visa/residence status types for Japan
//  Complete list of common residence statuses
//

import Foundation

enum VisaType: String, CaseIterable, Identifiable {
    case engineer = "Engineer/Specialist in Humanities/International Services"
    case businessManager = "Business Manager"
    case dependant = "Dependent"
    case permanentResident = "Permanent Resident"
    case spouseOfJapanese = "Spouse or Child of Japanese National"
    case spouseOfPR = "Spouse or Child of Permanent Resident"
    case student = "Student"
    case specifiedSkilled1 = "Specified Skilled Worker (i)"
    case specifiedSkilled2 = "Specified Skilled Worker (ii)"
    case intraCompanyTransfer = "Intra-Company Transferee"
    case highlySkilled = "Highly Skilled Professional"
    case technicalIntern = "Technical Intern Training"
    case culturalActivities = "Cultural Activities"
    case temporaryVisitor = "Temporary Visitor"
    case designatedActivities = "Designated Activities"
    case other = "Other"

    var id: String { rawValue }

    /// Localized display name
    var localizedName: String {
        // For MVP, return raw value
        // In future, implement proper localization
        return rawValue
    }

    /// Short display name for compact UI
    var shortName: String {
        switch self {
        case .engineer:
            return "Engineer/SSM"
        case .businessManager:
            return "Business Manager"
        case .dependant:
            return "Dependent"
        case .permanentResident:
            return "PR"
        case .spouseOfJapanese:
            return "Spouse (Japanese)"
        case .spouseOfPR:
            return "Spouse (PR)"
        case .student:
            return "Student"
        case .specifiedSkilled1:
            return "SSW (i)"
        case .specifiedSkilled2:
            return "SSW (ii)"
        case .intraCompanyTransfer:
            return "Intra-Company"
        case .highlySkilled:
            return "HSP"
        case .technicalIntern:
            return "Technical Intern"
        case .culturalActivities:
            return "Cultural Activities"
        case .temporaryVisitor:
            return "Temporary Visitor"
        case .designatedActivities:
            return "Designated Activities"
        case .other:
            return "Other"
        }
    }

    /// Whether this visa type allows work
    var allowsWork: Bool {
        switch self {
        case .engineer, .businessManager, .permanentResident, .spouseOfJapanese,
             .specifiedSkilled1, .specifiedSkilled2, .intraCompanyTransfer,
             .highlySkilled, .spouseOfPR:
            return true
        case .dependant, .student, .technicalIntern, .culturalActivities,
             .temporaryVisitor, .designatedActivities, .other:
            return false
        }
    }
}
