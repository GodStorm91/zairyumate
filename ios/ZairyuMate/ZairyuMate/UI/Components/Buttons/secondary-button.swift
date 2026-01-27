//
//  secondary-button.swift
//  ZairyuMate
//
//  Secondary button with outlined variant style
//  Border with primary color, transparent background
//

import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    private var effectiveDisabled: Bool {
        isLoading || isDisabled
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .zmPrimary))
                        .scaleEffect(0.9)
                }

                Text(title)
                    .font(.zmHeadline)
                    .foregroundColor(effectiveDisabled ? .zmTextSecondary : .zmPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(effectiveDisabled ? Color.zmTextSecondary : Color.zmPrimary, lineWidth: 2)
            )
        }
        .disabled(effectiveDisabled)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : "")
        .accessibilityAddTraits(effectiveDisabled ? .isButton : [.isButton])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Normal State") {
    VStack(spacing: Spacing.lg) {
        SecondaryButton(title: "キャンセル", action: {})
        SecondaryButton(title: "Cancel", action: {})
        SecondaryButton(title: "Go Back", action: {})
    }
    .screenPadding()
    .background(Color.zmBackground)
}

#Preview("Loading State") {
    VStack(spacing: Spacing.lg) {
        SecondaryButton(title: "処理中...", action: {}, isLoading: true)
        SecondaryButton(title: "Processing...", action: {}, isLoading: true)
    }
    .screenPadding()
    .background(Color.zmBackground)
}

#Preview("Disabled State") {
    VStack(spacing: Spacing.lg) {
        SecondaryButton(title: "キャンセル", action: {}, isDisabled: true)
        SecondaryButton(title: "Cancel", action: {}, isDisabled: true)
    }
    .screenPadding()
    .background(Color.zmBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.lg) {
        SecondaryButton(title: "キャンセル", action: {})
        SecondaryButton(title: "Loading...", action: {}, isLoading: true)
        SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .screenPadding()
    .background(Color.zmBackground)
    .preferredColorScheme(.dark)
}

#Preview("Primary + Secondary Together") {
    VStack(spacing: Spacing.lg) {
        PrimaryButton(title: "保存", action: {})
        SecondaryButton(title: "キャンセル", action: {})
    }
    .screenPadding()
    .background(Color.zmBackground)
}
#endif
