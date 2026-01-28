//
//  ColorTheme.swift
//  ZairyuMate
//
//  Color theme with light and dark mode support
//  All colors are loaded from Assets.xcassets
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors

    /// Primary brand color - iOS blue (#007AFF light, #0A84FF dark)
    static let zmPrimary = Color("Primary")

    // MARK: - Background Colors

    /// Main background color (#F2F2F7 light, #1C1C1E dark)
    static let zmBackground = Color("Background")

    // MARK: - Card Gradient Colors

    /// Card gradient start color - Green (#34C759 light, #32D74B dark)
    static let zmCardGradientStart = Color("CardGradientStart")

    /// Card gradient end color - Teal (#30B0C7 light, #64D2FF dark)
    static let zmCardGradientEnd = Color("CardGradientEnd")

    // MARK: - Text Colors

    /// Primary text color (#000000 light, #FFFFFF dark)
    static let zmTextPrimary = Color("TextPrimary")

    /// Secondary text color (#8E8E93 light and dark)
    static let zmTextSecondary = Color("TextSecondary")

    /// Tertiary text color for subtle/disabled text
    static let zmTextTertiary = Color("TextSecondary").opacity(0.6)

    // MARK: - Surface Colors

    /// Surface color for cards and input fields
    static let zmSurface = Color(uiColor: .secondarySystemBackground)

    /// Border color for separators and outlines
    static let zmBorder = Color(uiColor: .separator)

    // MARK: - Status Colors

    /// Error/destructive color (Red)
    static let zmError = Color.red

    /// Success color (Green)
    static let zmSuccess = Color.green

    /// Warning color (Orange)
    static let zmWarning = Color.orange
}

// MARK: - Color Palette Preview Helper

#if DEBUG
struct ColorThemePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ColorRow(name: "Primary", color: .zmPrimary)
                ColorRow(name: "Background", color: .zmBackground)
                ColorRow(name: "Card Gradient Start", color: .zmCardGradientStart)
                ColorRow(name: "Card Gradient End", color: .zmCardGradientEnd)
                ColorRow(name: "Text Primary", color: .zmTextPrimary)
                ColorRow(name: "Text Secondary", color: .zmTextSecondary)

                // Gradient preview
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.zmCardGradientStart, .zmCardGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                    .overlay(
                        Text("Card Gradient")
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                    .padding()
            }
            .padding()
        }
        .background(Color.zmBackground)
    }
}

struct ColorRow: View {
    let name: String
    let color: Color

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.zmTextPrimary)

                Text("zm\(name.replacingOccurrences(of: " ", with: ""))")
                    .font(.caption)
                    .foregroundColor(.zmTextSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.zmBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

#Preview {
    ColorThemePreview()
}
#endif
