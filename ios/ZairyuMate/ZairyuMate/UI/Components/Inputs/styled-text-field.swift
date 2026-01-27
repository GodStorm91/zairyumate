//
//  styled-text-field.swift
//  ZairyuMate
//
//  Form input text field with title label, required indicator, error state
//  Consistent styling with background and rounded corners
//

import SwiftUI

struct StyledTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isRequired: Bool = false
    var errorMessage: String? = nil
    var keyboardType: UIKeyboardType = .default

    private var hasError: Bool {
        errorMessage != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Title label with required indicator
            HStack(spacing: 2) {
                Text(title)
                    .font(.zmSubheadline)
                    .foregroundColor(.zmTextSecondary)

                if isRequired {
                    Text("*")
                        .font(.zmSubheadline)
                        .foregroundColor(.red)
                }
            }

            // Text field
            TextField(placeholder, text: $text)
                .font(.zmBody)
                .foregroundColor(.zmTextPrimary)
                .padding(Spacing.md)
                .background(Color.zmBackground)
                .cornerRadius(CornerRadius.textField)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.textField)
                        .stroke(hasError ? Color.red : Color.clear, lineWidth: 1)
                )
                .keyboardType(keyboardType)
                .accessibilityLabel(title)
                .accessibilityValue(text.isEmpty ? placeholder : text)
                .accessibilityHint(isRequired ? "Required field" : "")

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.zmCaption)
                    .foregroundColor(.red)
                    .accessibilityLabel("Error: \(errorMessage)")
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Normal State") {
    struct PreviewWrapper: View {
        @State private var text = ""

        var body: some View {
            VStack(spacing: Spacing.lg) {
                StyledTextField(
                    title: "Full Name",
                    text: $text,
                    placeholder: "Enter your name",
                    isRequired: true
                )

                StyledTextField(
                    title: "Email Address",
                    text: $text,
                    placeholder: "your@email.com",
                    keyboardType: .emailAddress
                )
            }
            .screenPadding()
            .background(Color.zmBackground)
        }
    }

    return PreviewWrapper()
}

#Preview("Error State") {
    struct PreviewWrapper: View {
        @State private var text = "invalid"

        var body: some View {
            VStack(spacing: Spacing.lg) {
                StyledTextField(
                    title: "Card Number",
                    text: $text,
                    placeholder: "1234567890123456",
                    isRequired: true,
                    errorMessage: "Card number must be 16 digits",
                    keyboardType: .numberPad
                )
            }
            .screenPadding()
            .background(Color.zmBackground)
        }
    }

    return PreviewWrapper()
}

#Preview("Dark Mode") {
    struct PreviewWrapper: View {
        @State private var name = "山田太郎"
        @State private var email = ""

        var body: some View {
            VStack(spacing: Spacing.lg) {
                StyledTextField(
                    title: "氏名",
                    text: $name,
                    placeholder: "名前を入力",
                    isRequired: true
                )

                StyledTextField(
                    title: "メールアドレス",
                    text: $email,
                    placeholder: "your@email.com",
                    isRequired: true,
                    errorMessage: "メールアドレスが必要です"
                )
            }
            .screenPadding()
            .background(Color.zmBackground)
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}
#endif
