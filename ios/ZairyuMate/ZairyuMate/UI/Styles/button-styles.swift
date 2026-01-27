//
//  button-styles.swift
//  ZairyuMate
//
//  Reusable button styles for consistent button appearance
//  Includes primary, secondary, destructive, and ghost styles
//

import SwiftUI

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zmHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(configuration.isPressed ? Color.zmPrimary.opacity(0.8) : Color.zmPrimary)
            .cornerRadius(CornerRadius.button)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zmHeadline)
            .foregroundColor(configuration.isPressed ? Color.zmPrimary.opacity(0.7) : Color.zmPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(configuration.isPressed ? Color.zmPrimary.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(Color.zmPrimary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zmHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(configuration.isPressed ? Color.red.opacity(0.8) : Color.red)
            .cornerRadius(CornerRadius.button)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zmBody)
            .foregroundColor(configuration.isPressed ? Color.zmTextSecondary : Color.zmTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(configuration.isPressed ? Color.zmBackground : Color.clear)
            .cornerRadius(CornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Button Style

struct CompactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zmCallout)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(configuration.isPressed ? Color.zmPrimary.opacity(0.8) : Color.zmPrimary)
            .cornerRadius(CornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }

    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }

    func destructiveButtonStyle() -> some View {
        self.buttonStyle(DestructiveButtonStyle())
    }

    func ghostButtonStyle() -> some View {
        self.buttonStyle(GhostButtonStyle())
    }

    func compactButtonStyle() -> some View {
        self.buttonStyle(CompactButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Button Styles") {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.lg) {
                Text("Primary Style")
                    .zmHeadlineStyle()

                Button("Primary Button") {}
                    .primaryButtonStyle()

                Button("Disabled") {}
                    .primaryButtonStyle()
                    .disabled(true)
            }

            Divider()

            VStack(spacing: Spacing.lg) {
                Text("Secondary Style")
                    .zmHeadlineStyle()

                Button("Secondary Button") {}
                    .secondaryButtonStyle()

                Button("Disabled") {}
                    .secondaryButtonStyle()
                    .disabled(true)
            }

            Divider()

            VStack(spacing: Spacing.lg) {
                Text("Destructive Style")
                    .zmHeadlineStyle()

                Button("Delete Account") {}
                    .destructiveButtonStyle()

                Button("Disabled") {}
                    .destructiveButtonStyle()
                    .disabled(true)
            }

            Divider()

            VStack(spacing: Spacing.lg) {
                Text("Ghost Style")
                    .zmHeadlineStyle()

                Button("Ghost Button") {}
                    .ghostButtonStyle()
            }

            Divider()

            VStack(spacing: Spacing.lg) {
                Text("Compact Style")
                    .zmHeadlineStyle()

                HStack {
                    Button("保存") {}
                        .compactButtonStyle()

                    Button("キャンセル") {}
                        .compactButtonStyle()
                }
            }
        }
        .screenPadding()
    }
    .background(Color.zmBackground)
}

#Preview("Dark Mode") {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            Button("Primary") {}
                .primaryButtonStyle()

            Button("Secondary") {}
                .secondaryButtonStyle()

            Button("Destructive") {}
                .destructiveButtonStyle()

            Button("Ghost") {}
                .ghostButtonStyle()
        }
        .screenPadding()
    }
    .background(Color.zmBackground)
    .preferredColorScheme(.dark)
}
#endif
