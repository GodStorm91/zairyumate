//
//  driver-license-data-model.swift
//  ZairyuMate
//
//  Japanese Driver's License (運転免許証) data model
//  Supports 47 prefectures and multiple license types
//

import Foundation
import UIKit

/// Driver's License data model
struct DriverLicenseData: IDCard, Codable {
    // MARK: - IDCard Protocol

    let cardType: CardType = .driverLicense

    // MARK: - Personal Information

    let name: String
    let nameKana: String
    let dateOfBirth: Date?
    let address: String

    // MARK: - License Information

    let licenseNumber: String // 12 digits
    let issueDate: Date?
    let expiryDate: Date?
    let licenseTypes: [LicenseType]
    let conditions: String? // e.g., "眼鏡等"
    let prefecture: Prefecture

    // MARK: - Optional

    let facePhoto: UIImage?

    // MARK: - Computed Properties

    var cardNumber: String { licenseNumber }
    var supportedReadMethods: [ReadMethod] { [.ocr] }

    // MARK: - License Types

    enum LicenseType: String, Codable, CaseIterable {
        case regular = "普通"
        case regularAutomatic = "普通AT"
        case medium = "中型"
        case mediumLimited = "中型(限定)"
        case large = "大型"
        case motorcycle = "普通二輪"
        case largeMotorcycle = "大型二輪"
        case moped = "原付"
        case special = "特殊"
        case towing = "牽引"
        case secondClass = "大型特殊二種"

        var displayName: String { rawValue }

        var englishName: String {
            switch self {
            case .regular: return "Regular"
            case .regularAutomatic: return "Regular (AT)"
            case .medium: return "Medium"
            case .mediumLimited: return "Medium (Limited)"
            case .large: return "Large"
            case .motorcycle: return "Motorcycle"
            case .largeMotorcycle: return "Large Motorcycle"
            case .moped: return "Moped"
            case .special: return "Special"
            case .towing: return "Towing"
            case .secondClass: return "Large Special 2nd Class"
            }
        }
    }

    // MARK: - Prefecture

    enum Prefecture: String, Codable, CaseIterable {
        case hokkaido = "北海道"
        case aomori = "青森"
        case iwate = "岩手"
        case miyagi = "宮城"
        case akita = "秋田"
        case yamagata = "山形"
        case fukushima = "福島"
        case ibaraki = "茨城"
        case tochigi = "栃木"
        case gunma = "群馬"
        case saitama = "埼玉"
        case chiba = "千葉"
        case tokyo = "東京"
        case kanagawa = "神奈川"
        case niigata = "新潟"
        case toyama = "富山"
        case ishikawa = "石川"
        case fukui = "福井"
        case yamanashi = "山梨"
        case nagano = "長野"
        case gifu = "岐阜"
        case shizuoka = "静岡"
        case aichi = "愛知"
        case mie = "三重"
        case shiga = "滋賀"
        case kyoto = "京都"
        case osaka = "大阪"
        case hyogo = "兵庫"
        case nara = "奈良"
        case wakayama = "和歌山"
        case tottori = "鳥取"
        case shimane = "島根"
        case okayama = "岡山"
        case hiroshima = "広島"
        case yamaguchi = "山口"
        case tokushima = "徳島"
        case kagawa = "香川"
        case ehime = "愛媛"
        case kochi = "高知"
        case fukuoka = "福岡"
        case saga = "佐賀"
        case nagasaki = "長崎"
        case kumamoto = "熊本"
        case oita = "大分"
        case miyazaki = "宮崎"
        case kagoshima = "鹿児島"
        case okinawa = "沖縄"

        var displayName: String { rawValue }

        /// Prefecture code (01-47)
        var code: Int {
            switch self {
            case .hokkaido: return 1
            case .aomori: return 2
            case .iwate: return 3
            case .miyagi: return 4
            case .akita: return 5
            case .yamagata: return 6
            case .fukushima: return 7
            case .ibaraki: return 8
            case .tochigi: return 9
            case .gunma: return 10
            case .saitama: return 11
            case .chiba: return 12
            case .tokyo: return 13
            case .kanagawa: return 14
            case .niigata: return 15
            case .toyama: return 16
            case .ishikawa: return 17
            case .fukui: return 18
            case .yamanashi: return 19
            case .nagano: return 20
            case .gifu: return 21
            case .shizuoka: return 22
            case .aichi: return 23
            case .mie: return 24
            case .shiga: return 25
            case .kyoto: return 26
            case .osaka: return 27
            case .hyogo: return 28
            case .nara: return 29
            case .wakayama: return 30
            case .tottori: return 31
            case .shimane: return 32
            case .okayama: return 33
            case .hiroshima: return 34
            case .yamaguchi: return 35
            case .tokushima: return 36
            case .kagawa: return 37
            case .ehime: return 38
            case .kochi: return 39
            case .fukuoka: return 40
            case .saga: return 41
            case .nagasaki: return 42
            case .kumamoto: return 43
            case .oita: return 44
            case .miyazaki: return 45
            case .kagoshima: return 46
            case .okinawa: return 47
            }
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case name, nameKana, dateOfBirth, address
        case licenseNumber, issueDate, expiryDate
        case licenseTypes, conditions, prefecture
        // facePhoto excluded from Codable
    }

    // MARK: - Initialization

    init(
        name: String,
        nameKana: String,
        dateOfBirth: Date?,
        address: String,
        licenseNumber: String,
        issueDate: Date?,
        expiryDate: Date?,
        licenseTypes: [LicenseType],
        conditions: String?,
        facePhoto: UIImage?,
        prefecture: Prefecture
    ) {
        self.name = name
        self.nameKana = nameKana
        self.dateOfBirth = dateOfBirth
        self.address = address
        self.licenseNumber = licenseNumber
        self.issueDate = issueDate
        self.expiryDate = expiryDate
        self.licenseTypes = licenseTypes
        self.conditions = conditions
        self.facePhoto = facePhoto
        self.prefecture = prefecture
    }
}

// MARK: - Display Utilities

extension DriverLicenseData {
    /// Formatted license types display
    var formattedLicenseTypes: String {
        licenseTypes.map { $0.displayName }.joined(separator: ", ")
    }

    /// Check if has specific license type
    func hasLicenseType(_ type: LicenseType) -> Bool {
        licenseTypes.contains(type)
    }
}
