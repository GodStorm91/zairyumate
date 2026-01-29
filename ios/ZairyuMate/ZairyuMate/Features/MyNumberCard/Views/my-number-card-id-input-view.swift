//
//  my-number-card-id-input-view.swift
//  ZairyuMate
//
//  UI for entering 12-digit My Number Card ID for NFC authentication
//

import SwiftUI

struct MyNumberCardIdInputView: View {

    @Binding var cardId: String
    @State private var isValid = false
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            headerSection

            cardIdInputSection

            validationMessage

            Spacer()

            confirmButton
        }
        .padding(Spacing.md)
        .navigationTitle("Card ID")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "creditcard")
                .font(.system(size: 48))
                .foregroundColor(.zmPrimary)

            Text("Enter 12-Digit Card ID")
                .zmLargeTitleStyle()

            Text("The card ID is printed on the back of your My Number Card")
                .zmSecondaryBodyStyle()
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Input Section

    private var cardIdInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Card ID")
                .zmCaptionStyle()
                .foregroundColor(.zmSecondary)

            TextField("0000 0000 0000", text: $cardId)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .font(.title2.monospacedDigit())
                .multilineTextAlignment(.center)
                .onChange(of: cardId) { _, newValue in
                    cardId = formatCardId(newValue)
                    isValid = validateCardId(cardId)
                }
                .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - Validation Message

    @ViewBuilder
    private var validationMessage: some View {
        if !cardId.isEmpty && !isValid {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "exclamationmark.circle.fill")
                Text("Card ID must be 12 digits")
            }
            .font(.caption)
            .foregroundColor(.zmError)
        } else if isValid {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                Text("Card ID valid")
            }
            .font(.caption)
            .foregroundColor(.zmSuccess)
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button(action: onConfirm) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text("Start NFC Scan")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValid ? Color.zmPrimary : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.medium)
        }
        .disabled(!isValid)
    }

    // MARK: - Helpers

    /// Format card ID as #### #### ####
    private func formatCardId(_ input: String) -> String {
        // Remove non-digits
        let digits = input.filter { $0.isNumber }

        // Limit to 12 digits
        let limited = String(digits.prefix(12))

        // Format as #### #### ####
        var formatted = ""
        for (index, char) in limited.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }

        return formatted
    }

    /// Validate card ID (12 digits)
    private func validateCardId(_ input: String) -> Bool {
        let digits = input.filter { $0.isNumber }
        return digits.count == 12
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Empty") {
    NavigationStack {
        MyNumberCardIdInputView(cardId: .constant(""), onConfirm: {})
    }
}

#Preview("Partial") {
    NavigationStack {
        MyNumberCardIdInputView(cardId: .constant("1234 5678"), onConfirm: {})
    }
}

#Preview("Valid") {
    NavigationStack {
        MyNumberCardIdInputView(cardId: .constant("1234 5678 9012"), onConfirm: {})
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        MyNumberCardIdInputView(cardId: .constant("1234 5678 9012"), onConfirm: {})
    }
    .preferredColorScheme(.dark)
}
#endif
