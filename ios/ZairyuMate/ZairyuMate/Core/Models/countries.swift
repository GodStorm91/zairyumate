//
//  countries.swift
//  ZairyuMate
//
//  Country list for nationality selection
//  ISO 3166-1 alpha-3 codes with English and Japanese names
//

import Foundation

struct Country: Identifiable, Hashable {
    let code: String // ISO 3166-1 alpha-3
    let nameEnglish: String
    let nameJapanese: String

    var id: String { code }

    /// Display name (English)
    var displayName: String {
        return nameEnglish
    }
}

extension Country {
    /// Common countries for foreign residents in Japan
    static let commonCountries: [Country] = [
        Country(code: "CHN", nameEnglish: "China", nameJapanese: "中国"),
        Country(code: "VNM", nameEnglish: "Vietnam", nameJapanese: "ベトナム"),
        Country(code: "PHL", nameEnglish: "Philippines", nameJapanese: "フィリピン"),
        Country(code: "KOR", nameEnglish: "South Korea", nameJapanese: "韓国"),
        Country(code: "IDN", nameEnglish: "Indonesia", nameJapanese: "インドネシア"),
        Country(code: "THA", nameEnglish: "Thailand", nameJapanese: "タイ"),
        Country(code: "NPL", nameEnglish: "Nepal", nameJapanese: "ネパール"),
        Country(code: "USA", nameEnglish: "United States", nameJapanese: "アメリカ"),
        Country(code: "IND", nameEnglish: "India", nameJapanese: "インド"),
        Country(code: "BRA", nameEnglish: "Brazil", nameJapanese: "ブラジル"),
    ]

    /// All countries (comprehensive list)
    static let allCountries: [Country] = [
        // Asia
        Country(code: "AFG", nameEnglish: "Afghanistan", nameJapanese: "アフガニスタン"),
        Country(code: "BGD", nameEnglish: "Bangladesh", nameJapanese: "バングラデシュ"),
        Country(code: "BTN", nameEnglish: "Bhutan", nameJapanese: "ブータン"),
        Country(code: "KHM", nameEnglish: "Cambodia", nameJapanese: "カンボジア"),
        Country(code: "CHN", nameEnglish: "China", nameJapanese: "中国"),
        Country(code: "IND", nameEnglish: "India", nameJapanese: "インド"),
        Country(code: "IDN", nameEnglish: "Indonesia", nameJapanese: "インドネシア"),
        Country(code: "KOR", nameEnglish: "South Korea", nameJapanese: "韓国"),
        Country(code: "LAO", nameEnglish: "Laos", nameJapanese: "ラオス"),
        Country(code: "MYS", nameEnglish: "Malaysia", nameJapanese: "マレーシア"),
        Country(code: "MNG", nameEnglish: "Mongolia", nameJapanese: "モンゴル"),
        Country(code: "MMR", nameEnglish: "Myanmar", nameJapanese: "ミャンマー"),
        Country(code: "NPL", nameEnglish: "Nepal", nameJapanese: "ネパール"),
        Country(code: "PAK", nameEnglish: "Pakistan", nameJapanese: "パキスタン"),
        Country(code: "PHL", nameEnglish: "Philippines", nameJapanese: "フィリピン"),
        Country(code: "SGP", nameEnglish: "Singapore", nameJapanese: "シンガポール"),
        Country(code: "LKA", nameEnglish: "Sri Lanka", nameJapanese: "スリランカ"),
        Country(code: "THA", nameEnglish: "Thailand", nameJapanese: "タイ"),
        Country(code: "VNM", nameEnglish: "Vietnam", nameJapanese: "ベトナム"),

        // Americas
        Country(code: "ARG", nameEnglish: "Argentina", nameJapanese: "アルゼンチン"),
        Country(code: "BRA", nameEnglish: "Brazil", nameJapanese: "ブラジル"),
        Country(code: "CAN", nameEnglish: "Canada", nameJapanese: "カナダ"),
        Country(code: "CHL", nameEnglish: "Chile", nameJapanese: "チリ"),
        Country(code: "COL", nameEnglish: "Colombia", nameJapanese: "コロンビア"),
        Country(code: "MEX", nameEnglish: "Mexico", nameJapanese: "メキシコ"),
        Country(code: "PER", nameEnglish: "Peru", nameJapanese: "ペルー"),
        Country(code: "USA", nameEnglish: "United States", nameJapanese: "アメリカ"),

        // Europe
        Country(code: "AUT", nameEnglish: "Austria", nameJapanese: "オーストリア"),
        Country(code: "BEL", nameEnglish: "Belgium", nameJapanese: "ベルギー"),
        Country(code: "BGR", nameEnglish: "Bulgaria", nameJapanese: "ブルガリア"),
        Country(code: "CZE", nameEnglish: "Czech Republic", nameJapanese: "チェコ"),
        Country(code: "DNK", nameEnglish: "Denmark", nameJapanese: "デンマーク"),
        Country(code: "FIN", nameEnglish: "Finland", nameJapanese: "フィンランド"),
        Country(code: "FRA", nameEnglish: "France", nameJapanese: "フランス"),
        Country(code: "DEU", nameEnglish: "Germany", nameJapanese: "ドイツ"),
        Country(code: "GRC", nameEnglish: "Greece", nameJapanese: "ギリシャ"),
        Country(code: "HUN", nameEnglish: "Hungary", nameJapanese: "ハンガリー"),
        Country(code: "IRL", nameEnglish: "Ireland", nameJapanese: "アイルランド"),
        Country(code: "ITA", nameEnglish: "Italy", nameJapanese: "イタリア"),
        Country(code: "NLD", nameEnglish: "Netherlands", nameJapanese: "オランダ"),
        Country(code: "NOR", nameEnglish: "Norway", nameJapanese: "ノルウェー"),
        Country(code: "POL", nameEnglish: "Poland", nameJapanese: "ポーランド"),
        Country(code: "PRT", nameEnglish: "Portugal", nameJapanese: "ポルトガル"),
        Country(code: "ROU", nameEnglish: "Romania", nameJapanese: "ルーマニア"),
        Country(code: "RUS", nameEnglish: "Russia", nameJapanese: "ロシア"),
        Country(code: "ESP", nameEnglish: "Spain", nameJapanese: "スペイン"),
        Country(code: "SWE", nameEnglish: "Sweden", nameJapanese: "スウェーデン"),
        Country(code: "CHE", nameEnglish: "Switzerland", nameJapanese: "スイス"),
        Country(code: "UKR", nameEnglish: "Ukraine", nameJapanese: "ウクライナ"),
        Country(code: "GBR", nameEnglish: "United Kingdom", nameJapanese: "イギリス"),

        // Middle East
        Country(code: "ARE", nameEnglish: "United Arab Emirates", nameJapanese: "アラブ首長国連邦"),
        Country(code: "EGY", nameEnglish: "Egypt", nameJapanese: "エジプト"),
        Country(code: "IRN", nameEnglish: "Iran", nameJapanese: "イラン"),
        Country(code: "ISR", nameEnglish: "Israel", nameJapanese: "イスラエル"),
        Country(code: "SAU", nameEnglish: "Saudi Arabia", nameJapanese: "サウジアラビア"),
        Country(code: "TUR", nameEnglish: "Turkey", nameJapanese: "トルコ"),

        // Africa
        Country(code: "GHA", nameEnglish: "Ghana", nameJapanese: "ガーナ"),
        Country(code: "KEN", nameEnglish: "Kenya", nameJapanese: "ケニア"),
        Country(code: "NGA", nameEnglish: "Nigeria", nameJapanese: "ナイジェリア"),
        Country(code: "ZAF", nameEnglish: "South Africa", nameJapanese: "南アフリカ"),

        // Oceania
        Country(code: "AUS", nameEnglish: "Australia", nameJapanese: "オーストラリア"),
        Country(code: "NZL", nameEnglish: "New Zealand", nameJapanese: "ニュージーランド"),
    ].sorted { $0.nameEnglish < $1.nameEnglish }
}
