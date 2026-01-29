//
//  card-type-selection-view.swift
//  ZairyuMate
//
//  UI for selecting card type (Zairyu/My Number/Driver's License)
//

import SwiftUI

struct CardTypeSelectionView: View {

    @Binding var selectedCardType: CardType?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection

                    ForEach(CardType.allCases, id: \.self) { cardType in
                        CardTypeCard(
                            cardType: cardType,
                            isSelected: selectedCardType == cardType
                        ) {
                            selectedCardType = cardType
                            dismiss()
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.zmBackground)
            .navigationTitle("Select Card Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.zmPrimary)

            Text("Which card would you like to scan?")
                .zmHeadlineStyle()
                .multilineTextAlignment(.center)

            Text("Select the type of ID card you want to add to your profile")
                .zmSecondaryBodyStyle()
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - Card Type Card Component

struct CardTypeCard: View {
    let cardType: CardType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Icon
                Image(systemName: cardType.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.zmPrimary)
                    .frame(width: 60)

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(cardType.displayName)
                        .zmHeadlineStyle()

                    Text(cardType.englishName)
                        .zmSecondaryBodyStyle()
                        .font(.caption)

                    Text(cardType.description)
                        .zmSecondaryBodyStyle()
                        .font(.caption2)
                        .lineLimit(2)

                    // Supported methods
                    HStack(spacing: Spacing.xs) {
                        ForEach(cardType.supportedMethods, id: \.self) { method in
                            methodBadge(for: method)
                        }
                    }
                    .padding(.top, Spacing.xs)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.zmSuccess)
                        .font(.title2)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(isSelected ? Color.zmPrimary.opacity(0.1) : Color.zmCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isSelected ? Color.zmPrimary : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Method Badge

    private func methodBadge(for method: ReadMethod) -> some View {
        HStack(spacing: 4) {
            Image(systemName: method.icon)
                .font(.caption2)

            Text(method.rawValue)
                .font(.caption2)

            if method.requiresPro {
                Text("PRO")
                    .font(.caption2.bold())
                    .foregroundColor(.zmAccent)
            }
        }
        .foregroundColor(.zmSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.zmPrimary.opacity(0.1))
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Card Selection") {
    CardTypeSelectionView(selectedCardType: .constant(nil))
}

#Preview("With Selection") {
    CardTypeSelectionView(selectedCardType: .constant(.zairyuCard))
}

#Preview("Dark Mode") {
    CardTypeSelectionView(selectedCardType: .constant(nil))
        .preferredColorScheme(.dark)
}
#endif
