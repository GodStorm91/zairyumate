//
//  app-settings-core-data-properties.swift
//  ZairyuMate
//
//  Core Data generated properties for AppSettings entity
//

import Foundation
import CoreData

extension AppSettings {

    @NSManaged public var id: UUID?
    @NSManaged public var biometricEnabled: Bool
    @NSManaged public var selectedLanguage: String?
    @NSManaged public var isPro: Bool
    @NSManaged public var lastSyncDate: Date?

}

extension AppSettings: Identifiable {}
