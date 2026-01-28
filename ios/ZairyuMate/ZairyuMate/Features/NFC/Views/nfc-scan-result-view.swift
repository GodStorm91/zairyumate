//
//  nfc-scan-result-view.swift
//  ZairyuMate
//
//  Result view showing scanned card data
//  Allows user to review and save to profile
//

import SwiftUI

struct NFCScanResultView: View {
    let cardData: ZairyuCardData
    let onSave: () async -> Void
    let onScanAgain: () -> Void

    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Success header
                VStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.zmSuccess.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.zmSuccess)
                    }

                    Text("Card Read Successfully")
                        .font(.zmTitle2)
                        .foregroundColor(.zmTextPrimary)
                }
                .padding(.top, Spacing.lg)

                // Card type badge
                Text(cardData.cardType.displayName)
                    .font(.zmCaption)
                    .foregroundColor(.zmTextSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.zmSurface)
                    .cornerRadius(CornerRadius.sm)

                // Data preview
                VStack(spacing: 0) {
                    DataRow(label: "Name", value: cardData.name)
                    Divider()

                    if let katakana = cardData.nameKatakana {
                        DataRow(label: "Name (Katakana)", value: katakana)
                        Divider()
                    }

                    if let dob = cardData.dateOfBirth {
                        DataRow(label: "Date of Birth", value: formatDate(dob))
                        Divider()
                    }

                    if let nationality = cardData.nationality {
                        DataRow(label: "Nationality", value: nationalityDisplay(nationality))
                        Divider()
                    }

                    if let address = cardData.address {
                        DataRow(label: "Address", value: address)
                        Divider()
                    }

                    DataRow(label: "Card Number", value: formatCardNumber(cardData.cardNumber))
                    Divider()

                    if let expiry = cardData.cardExpiry {
                        DataRow(label: "Card Expiry", value: formatDate(expiry))
                        Divider()
                    }

                    if let visa = cardData.visaType {
                        DataRow(label: "Status of Residence", value: visa)
                    }
                }
                .background(Color.zmSurface)
                .cornerRadius(CornerRadius.md)
                .padding(.horizontal, Spacing.screenHorizontal)

                // Action buttons
                VStack(spacing: Spacing.md) {
                    Button {
                        Task {
                            isSaving = true
                            await onSave()
                            isSaving = false
                        }
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "person.badge.plus")
                            }
                            Text("Save to Profile")
                        }
                        .font(.zmHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.zmPrimary)
                        .cornerRadius(CornerRadius.button)
                    }
                    .disabled(isSaving)

                    Button {
                        onScanAgain()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "arrow.clockwise")
                            Text("Scan Again")
                        }
                        .font(.zmBody)
                        .foregroundColor(.zmPrimary)
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
        .background(Color.zmBackground)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func formatCardNumber(_ number: String) -> String {
        var result = ""
        for (index, char) in number.enumerated() {
            if index > 0 && index % 4 == 0 {
                result += " "
            }
            result += String(char)
        }
        return result
    }

    private func nationalityDisplay(_ code: String) -> String {
        Country.allCountries.first { $0.code == code }?.displayName ?? code
    }
}

// MARK: - Data Row Component

struct DataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.zmCaption)
                .foregroundColor(.zmTextSecondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.zmBody)
                .foregroundColor(.zmTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}
