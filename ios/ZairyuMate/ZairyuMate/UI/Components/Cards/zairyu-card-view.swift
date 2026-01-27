//
//  zairyu-card-view.swift
//  ZairyuMate
//
//  Virtual Zairyu card with Apple Wallet-inspired design
//  Shows masked card number, name, visa type, expiry date
//

import SwiftUI

struct ZairyuCardView: View {
    let name: String
    let cardNumber: String
    let visaType: String
    let expiryDate: Date

    private var maskedCardNumber: String {
        // Show last 4 digits only
        let last4 = String(cardNumber.suffix(4))
        return "●●●● ●●●● ●●●● \(last4)"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [.zmCardGradientStart, .zmCardGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("在留カード")
                    .font(.zmCaption)
                    .fontWeight(.medium)
                    .accessibilityLabel("Zairyu Card")

                Text(name)
                    .font(.zmTitle2)
                    .fontWeight(.bold)
                    .accessibilityLabel("Name: \(name)")

                Spacer()

                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(maskedCardNumber)
                            .font(.system(.footnote, design: .monospaced))
                            .accessibilityLabel("Card number ending in \(String(cardNumber.suffix(4)))")

                        Text("有効期限: \(expiryDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.zmCaption)
                            .accessibilityLabel("Expiry date: \(expiryDate.formatted(date: .long, time: .omitted))")
                    }

                    Spacer()

                    Text(visaType)
                        .font(.zmCaption)
                        .fontWeight(.bold)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(.ultraThinMaterial)
                        .cornerRadius(CornerRadius.xs)
                        .accessibilityLabel("Visa type: \(visaType)")
                }
            }
            .padding(Spacing.md)
            .foregroundColor(.white)
        }
        .frame(height: 200)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Light Mode") {
    ZairyuCardView(
        name: "山田太郎",
        cardNumber: "1234567890123456",
        visaType: "就労",
        expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year from now
    )
    .screenPadding()
    .background(Color.zmBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ZairyuCardView(
        name: "山田太郎",
        cardNumber: "1234567890123456",
        visaType: "就労",
        expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60)
    )
    .screenPadding()
    .background(Color.zmBackground)
    .preferredColorScheme(.dark)
}

#Preview("Long Name") {
    ZairyuCardView(
        name: "マイケル・アンソニー・ウィリアムソン",
        cardNumber: "9876543210987654",
        visaType: "留学",
        expiryDate: Date().addingTimeInterval(180 * 24 * 60 * 60) // 6 months
    )
    .screenPadding()
    .background(Color.zmBackground)
}
#endif
