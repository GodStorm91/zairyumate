//
//  Typography.swift
//  ZairyuMate
//
//  Typography system with consistent font styles
//

import SwiftUI

// MARK: - Font Extensions

extension Font {
    // MARK: - Title Styles

    /// Large title for main headings (34pt, bold)
    static let zmLargeTitle = Font.system(size: 34, weight: .bold)

    /// Title for section headings (28pt, bold)
    static let zmTitle = Font.system(size: 28, weight: .bold)

    /// Title 2 for subsection headings (22pt, bold)
    static let zmTitle2 = Font.system(size: 22, weight: .bold)

    /// Title 3 for card titles (20pt, semibold)
    static let zmTitle3 = Font.system(size: 20, weight: .semibold)

    // MARK: - Body Styles

    /// Headline for important text (17pt, semibold)
    static let zmHeadline = Font.system(size: 17, weight: .semibold)

    /// Body text for main content (17pt, regular)
    static let zmBody = Font.system(size: 17, weight: .regular)

    /// Callout for secondary content (16pt, regular)
    static let zmCallout = Font.system(size: 16, weight: .regular)

    /// Subheadline for labels (15pt, regular)
    static let zmSubheadline = Font.system(size: 15, weight: .regular)

    /// Footnote for small text (13pt, regular)
    static let zmFootnote = Font.system(size: 13, weight: .regular)

    /// Caption for tiny text (12pt, regular)
    static let zmCaption = Font.system(size: 12, weight: .regular)

    /// Caption 2 for even tinier text (11pt, regular)
    static let zmCaption2 = Font.system(size: 11, weight: .regular)
}

// MARK: - Text Style Modifiers

extension View {
    /// Applies large title style with primary color
    func zmLargeTitleStyle() -> some View {
        self
            .font(.zmLargeTitle)
            .foregroundColor(.zmTextPrimary)
    }

    /// Applies title style with primary color
    func zmTitleStyle() -> some View {
        self
            .font(.zmTitle)
            .foregroundColor(.zmTextPrimary)
    }

    /// Applies headline style with primary color
    func zmHeadlineStyle() -> some View {
        self
            .font(.zmHeadline)
            .foregroundColor(.zmTextPrimary)
    }

    /// Applies body style with primary color
    func zmBodyStyle() -> some View {
        self
            .font(.zmBody)
            .foregroundColor(.zmTextPrimary)
    }

    /// Applies body style with secondary color
    func zmSecondaryBodyStyle() -> some View {
        self
            .font(.zmBody)
            .foregroundColor(.zmTextSecondary)
    }

    /// Applies caption style with secondary color
    func zmCaptionStyle() -> some View {
        self
            .font(.zmCaption)
            .foregroundColor(.zmTextSecondary)
    }
}

// MARK: - Typography Preview

#if DEBUG
struct TypographyPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Group {
                    Text("Large Title")
                        .font(.zmLargeTitle)

                    Text("Title")
                        .font(.zmTitle)

                    Text("Title 2")
                        .font(.zmTitle2)

                    Text("Title 3")
                        .font(.zmTitle3)

                    Text("Headline")
                        .font(.zmHeadline)

                    Text("Body")
                        .font(.zmBody)

                    Text("Callout")
                        .font(.zmCallout)

                    Text("Subheadline")
                        .font(.zmSubheadline)

                    Text("Footnote")
                        .font(.zmFootnote)

                    Text("Caption")
                        .font(.zmCaption)

                    Text("Caption 2")
                        .font(.zmCaption2)
                }
                .foregroundColor(.zmTextPrimary)

                Divider()

                Text("With Style Modifiers")
                    .zmHeadlineStyle()

                Text("Large Title Style")
                    .zmLargeTitleStyle()

                Text("Body Style")
                    .zmBodyStyle()

                Text("Secondary Body Style")
                    .zmSecondaryBodyStyle()

                Text("Caption Style")
                    .zmCaptionStyle()
            }
            .padding()
        }
        .background(Color.zmBackground)
    }
}

#Preview {
    TypographyPreview()
}
#endif
