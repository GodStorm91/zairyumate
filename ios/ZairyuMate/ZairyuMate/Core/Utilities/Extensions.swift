//
//  Extensions.swift
//  ZairyuMate
//
//  Swift extensions for common functionality
//

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    /// Returns the number of days between this date and another date
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: date)
        return components.day ?? 0
    }

    /// Returns true if the date is in the past
    var isPast: Bool {
        return self < Date()
    }

    /// Returns true if the date is in the future
    var isFuture: Bool {
        return self > Date()
    }

    /// Returns true if the date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    /// Formats date to Japanese style (yyyy年MM月dd日)
    var japaneseFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }

    /// Formats date to standard format (yyyy-MM-dd)
    var standardFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    /// Formats date to display format (MMM d, yyyy)
    var displayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    /// Returns date with time set to start of day (00:00:00)
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    /// Returns date with time set to end of day (23:59:59)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
}

// MARK: - String Extensions

extension String {
    /// Removes whitespace and newlines from both ends
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns true if string is empty after trimming whitespace
    var isBlankOrEmpty: Bool {
        return self.trimmed.isEmpty
    }

    /// Validates if string is a valid email format
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }

    /// Converts string to Date using standard format (yyyy-MM-dd)
    var toDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self)
    }

    /// Localizes string using NSLocalizedString
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

// MARK: - Optional Extensions

extension Optional where Wrapped == String {
    /// Returns true if optional string is nil or empty
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }

    /// Returns the string value or empty string if nil
    var orEmpty: String {
        return self ?? ""
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safely accesses element at index, returns nil if out of bounds
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - View Extensions

extension View {
    /// Hides keyboard when tapped outside text fields
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Custom Shapes

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    /// Returns app version string
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// Returns app build number
    var appBuild: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    /// Returns app name
    var appName: String {
        return infoDictionary?["CFBundleName"] as? String ?? "Zairyu Mate"
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    /// Custom suite for app
    static let app = UserDefaults(suiteName: StorageConstants.userDefaultsSuite) ?? .standard

    /// Saves codable object to UserDefaults
    func setCodable<T: Codable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            set(encoded, forKey: key)
        }
    }

    /// Retrieves codable object from UserDefaults
    func getCodable<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Color Extensions (Hex Support)

extension Color {
    /// Initializes Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Returns hex string representation of color
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}
