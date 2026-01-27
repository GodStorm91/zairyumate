//
//  dropdown-picker-field.swift
//  ZairyuMate
//
//  Dropdown picker field with label for selecting from list of options
//  Styled presentation with required indicator support
//

import SwiftUI

struct DropdownPickerField<T: Hashable & Identifiable>: View {
    let title: String
    let options: [T]
    @Binding var selection: T?
    let displayText: (T) -> String
    var isRequired: Bool = false

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

            // Picker
            Menu {
                ForEach(options) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(displayText(option))
                            if selection?.id == option.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection.map(displayText) ?? "選択してください")
                        .font(.zmBody)
                        .foregroundColor(selection == nil ? .zmTextSecondary : .zmTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.zmCaption)
                        .foregroundColor(.zmTextSecondary)
                }
                .padding(Spacing.md)
                .background(Color.zmBackground)
                .cornerRadius(CornerRadius.textField)
            }
            .accessibilityLabel(title)
            .accessibilityValue(selection.map(displayText) ?? "Not selected")
            .accessibilityHint(isRequired ? "Required field, tap to select" : "Tap to select")
        }
    }
}

// MARK: - Preview Models

#if DEBUG
struct VisaType: Identifiable, Hashable {
    let id: String
    let name: String
}

#Preview("Visa Type Picker") {
    struct PreviewWrapper: View {
        @State private var selectedVisa: VisaType? = nil

        let visaTypes = [
            VisaType(id: "work", name: "就労"),
            VisaType(id: "study", name: "留学"),
            VisaType(id: "dependent", name: "家族滞在"),
            VisaType(id: "permanent", name: "永住者"),
            VisaType(id: "spouse", name: "配偶者")
        ]

        var body: some View {
            VStack(spacing: Spacing.lg) {
                DropdownPickerField(
                    title: "在留資格",
                    options: visaTypes,
                    selection: $selectedVisa,
                    displayText: { $0.name },
                    isRequired: true
                )

                if let selectedVisa = selectedVisa {
                    Text("Selected: \(selectedVisa.name)")
                        .font(.zmCaption)
                        .foregroundColor(.zmTextSecondary)
                }
            }
            .screenPadding()
            .background(Color.zmBackground)
        }
    }

    return PreviewWrapper()
}

#Preview("With Selection") {
    struct PreviewWrapper: View {
        @State private var selectedVisa: VisaType? = VisaType(id: "work", name: "就労")

        let visaTypes = [
            VisaType(id: "work", name: "就労"),
            VisaType(id: "study", name: "留学"),
            VisaType(id: "dependent", name: "家族滞在")
        ]

        var body: some View {
            VStack(spacing: Spacing.lg) {
                DropdownPickerField(
                    title: "Visa Type",
                    options: visaTypes,
                    selection: $selectedVisa,
                    displayText: { $0.name },
                    isRequired: true
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
        @State private var selectedVisa: VisaType? = nil

        let visaTypes = [
            VisaType(id: "work", name: "就労"),
            VisaType(id: "study", name: "留学"),
            VisaType(id: "dependent", name: "家族滞在")
        ]

        var body: some View {
            VStack(spacing: Spacing.lg) {
                DropdownPickerField(
                    title: "在留資格",
                    options: visaTypes,
                    selection: $selectedVisa,
                    displayText: { $0.name },
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
