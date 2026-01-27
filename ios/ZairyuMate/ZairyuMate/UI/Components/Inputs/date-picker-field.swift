//
//  date-picker-field.swift
//  ZairyuMate
//
//  Date picker input field with label and styled presentation
//  Supports required indicator and accessible date selection
//

import SwiftUI

struct DatePickerField: View {
    let title: String
    @Binding var date: Date
    var isRequired: Bool = false
    var displayedComponents: DatePickerComponents = .date

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

            // Date picker
            DatePicker(
                "",
                selection: $date,
                displayedComponents: displayedComponents
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding(Spacing.sm)
            .background(Color.zmBackground)
            .cornerRadius(CornerRadius.textField)
            .accessibilityLabel(title)
            .accessibilityValue(date.formatted(date: .long, time: displayedComponents == .hourAndMinute ? .shortened : .omitted))
            .accessibilityHint(isRequired ? "Required field" : "")
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Date Only") {
    struct PreviewWrapper: View {
        @State private var expiryDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
        @State private var birthDate = Date().addingTimeInterval(-25 * 365 * 24 * 60 * 60)

        var body: some View {
            VStack(spacing: Spacing.lg) {
                DatePickerField(
                    title: "有効期限",
                    date: $expiryDate,
                    isRequired: true
                )

                DatePickerField(
                    title: "生年月日",
                    date: $birthDate,
                    isRequired: true
                )
            }
            .screenPadding()
            .background(Color.zmBackground)
        }
    }

    return PreviewWrapper()
}

#Preview("Date and Time") {
    struct PreviewWrapper: View {
        @State private var appointmentDate = Date()

        var body: some View {
            VStack(spacing: Spacing.lg) {
                DatePickerField(
                    title: "Appointment Date & Time",
                    date: $appointmentDate,
                    isRequired: true,
                    displayedComponents: [.date, .hourAndMinute]
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
        @State private var date = Date()

        var body: some View {
            VStack(spacing: Spacing.lg) {
                DatePickerField(
                    title: "在留カード有効期限",
                    date: $date,
                    isRequired: true
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
