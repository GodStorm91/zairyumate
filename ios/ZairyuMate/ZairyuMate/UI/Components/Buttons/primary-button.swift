//
//  primary-button.swift
//  ZairyuMate
//
//  Primary call-to-action button with loading and disabled states
//  Full width, rounded corners, primary color background
//

import SwiftUI

struct PrimaryButton: View {
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }

                Text(title)
                    .font(.zmHeadline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(effectiveDisabled ? Color.zmTextSecondary : Color.zmPrimary)
            .cornerRadius(CornerRadius.button)
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
        PrimaryButton(title: "保存", action: {})
        PrimaryButton(title: "Submit", action: {})
        PrimaryButton(title: "Continue", action: {})
    }
    .screenPadding()
    .background(Color.zmBackground)
}

#Preview("Loading State") {
    VStack(spacing: Spacing.lg) {
        PrimaryButton(title: "保存中...", action: {}, isLoading: true)
        PrimaryButton(title: "Submitting...", action: {}, isLoading: true)
    }
    .screenPadding()
    .background(Color.zmBackground)
}

#Preview("Disabled State") {
    VStack(spacing: Spacing.lg) {
        PrimaryButton(title: "保存", action: {}, isDisabled: true)
        PrimaryButton(title: "Submit", action: {}, isDisabled: true)
    }
    .screenPadding()
    .background(Color.zmBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.lg) {
        PrimaryButton(title: "保存", action: {})
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .screenPadding()
    .background(Color.zmBackground)
    .preferredColorScheme(.dark)
}
#endif
