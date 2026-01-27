//
//  Spacing.swift
//  ZairyuMate
//
//  Consistent spacing system following 8pt grid
//

import SwiftUI

// MARK: - Spacing Constants

enum Spacing {
    /// Extra small spacing - 4pt
    static let xs: CGFloat = 4

    /// Small spacing - 8pt
    static let sm: CGFloat = 8

    /// Medium spacing - 16pt (base unit)
    static let md: CGFloat = 16

    /// Large spacing - 24pt
    static let lg: CGFloat = 24

    /// Extra large spacing - 32pt
    static let xl: CGFloat = 32

    /// Extra extra large spacing - 48pt
    static let xxl: CGFloat = 48

    // MARK: - Semantic Spacing

    /// Spacing between items in a list
    static let listItem: CGFloat = 12

    /// Spacing between sections
    static let section: CGFloat = 24

    /// Horizontal padding for screen edges
    static let screenHorizontal: CGFloat = 20

    /// Vertical padding for screen edges
    static let screenVertical: CGFloat = 16

    /// Padding inside cards
    static let cardInner: CGFloat = 16

    /// Spacing between cards
    static let cardOuter: CGFloat = 12
}

// MARK: - Corner Radius Constants

enum CornerRadius {
    /// Extra small radius - 4pt
    static let xs: CGFloat = 4

    /// Small radius - 8pt
    static let sm: CGFloat = 8

    /// Medium radius - 12pt (default for cards)
    static let md: CGFloat = 12

    /// Large radius - 16pt
    static let lg: CGFloat = 16

    /// Extra large radius - 20pt
    static let xl: CGFloat = 20

    /// Extra extra large radius - 24pt
    static let xxl: CGFloat = 24

    // MARK: - Semantic Radius

    /// Radius for buttons
    static let button: CGFloat = 12

    /// Radius for cards
    static let card: CGFloat = 16

    /// Radius for text fields
    static let textField: CGFloat = 10
}

// MARK: - View Extensions

extension View {
    /// Applies standard horizontal screen padding
    func screenHorizontalPadding() -> some View {
        self.padding(.horizontal, Spacing.screenHorizontal)
    }

    /// Applies standard vertical screen padding
    func screenVerticalPadding() -> some View {
        self.padding(.vertical, Spacing.screenVertical)
    }

    /// Applies standard screen padding (horizontal and vertical)
    func screenPadding() -> some View {
        self
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.screenVertical)
    }

    /// Applies standard card padding
    func cardPadding() -> some View {
        self.padding(Spacing.cardInner)
    }

    /// Applies standard card style with background and shadow
    func cardStyle() -> some View {
        self
            .background(Color.white)
            .cornerRadius(CornerRadius.card)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Spacing Preview

#if DEBUG
struct SpacingPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                // Spacing examples
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Spacing System")
                        .zmTitleStyle()

                    SpacingRow(name: "XS", value: Spacing.xs)
                    SpacingRow(name: "SM", value: Spacing.sm)
                    SpacingRow(name: "MD", value: Spacing.md)
                    SpacingRow(name: "LG", value: Spacing.lg)
                    SpacingRow(name: "XL", value: Spacing.xl)
                    SpacingRow(name: "XXL", value: Spacing.xxl)
                }

                Divider()

                // Corner radius examples
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Corner Radius")
                        .zmTitleStyle()

                    RadiusBox(name: "XS", radius: CornerRadius.xs)
                    RadiusBox(name: "SM", radius: CornerRadius.sm)
                    RadiusBox(name: "MD", radius: CornerRadius.md)
                    RadiusBox(name: "LG", radius: CornerRadius.lg)
                    RadiusBox(name: "XL", radius: CornerRadius.xl)
                    RadiusBox(name: "XXL", radius: CornerRadius.xxl)
                }

                Divider()

                // Card example
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Card Example")
                        .zmTitleStyle()

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Card Title")
                            .zmHeadlineStyle()
                        Text("Card content with standard padding")
                            .zmBodyStyle()
                    }
                    .cardPadding()
                    .cardStyle()
                }
            }
            .screenPadding()
        }
        .background(Color.zmBackground)
    }
}

struct SpacingRow: View {
    let name: String
    let value: CGFloat

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(name)
                .frame(width: 40, alignment: .leading)
                .zmBodyStyle()

            Rectangle()
                .fill(Color.zmPrimary)
                .frame(width: value, height: 20)

            Text("\(Int(value))pt")
                .zmCaptionStyle()

            Spacer()
        }
    }
}

struct RadiusBox: View {
    let name: String
    let radius: CGFloat

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(name)
                .frame(width: 40, alignment: .leading)
                .zmBodyStyle()

            RoundedRectangle(cornerRadius: radius)
                .fill(Color.zmPrimary)
                .frame(width: 80, height: 50)

            Text("\(Int(radius))pt")
                .zmCaptionStyle()

            Spacer()
        }
    }
}

#Preview {
    SpacingPreview()
}
#endif
