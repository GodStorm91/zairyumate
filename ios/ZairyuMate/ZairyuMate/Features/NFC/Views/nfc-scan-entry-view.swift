//
//  nfc-scan-entry-view.swift
//  ZairyuMate
//
//  NFC card number entry and scan coordinator view
//  Manages state transitions between entry, scanning, and result
//

import SwiftUI

struct NFCScanEntryView: View {
    @State private var viewModel: NFCScanViewModel
    @State private var showProUpgrade = false
    @State private var cardNumberText = ""
    @Environment(\.dismiss) private var dismiss

    init(entitlementManager: EntitlementManager) {
        let nfcReader = NFCReaderService()
        let profileService = ProfileService(persistenceController: .shared)
        let vm = NFCScanViewModel(
            nfcReader: nfcReader,
            profileService: profileService,
            entitlementManager: entitlementManager
        )
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.scanState {
                case .idle, .inputCardNumber:
                    cardNumberInputView

                case .scanning:
                    NFCScanningAnimationView(onCancel: viewModel.cancelScan)

                case .success(let cardData):
                    NFCScanResultView(
                        cardData: cardData,
                        onSave: { await saveAndDismiss(cardData) },
                        onScanAgain: { viewModel.reset() }
                    )

                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("Scan Zairyu Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showProUpgrade) {
                ProFeatureLockedView(
                    feature: "NFC Card Scan",
                    icon: "wave.3.right",
                    description: "Scan your Zairyu Card using NFC technology to automatically import your information."
                )
            }
            .onChange(of: viewModel.showProUpgrade) { _, newValue in
                showProUpgrade = newValue
            }
        }
        .onAppear {
            viewModel.scanState = .inputCardNumber
        }
    }

    // MARK: - Card Number Input View

    private var cardNumberInputView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // NFC Icon
            ZStack {
                Circle()
                    .fill(Color.zmPrimary.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "wave.3.right")
                    .font(.system(size: 50))
                    .foregroundColor(.zmPrimary)
            }

            // Instructions
            VStack(spacing: Spacing.sm) {
                Text("Enter Card Number")
                    .font(.zmTitle2)
                    .foregroundColor(.zmTextPrimary)

                Text("Find the 12-character code on the top-right corner of your Zairyu Card")
                    .font(.zmBody)
                    .foregroundColor(.zmTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            
            // Scanning tip
            HStack(spacing: Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.zmPrimary)
                    .font(.zmCaption)
                VStack(alignment: .leading, spacing: 2) {
                    Text("After tapping 'Start Scan':")
                        .font(.zmCaption)
                        .foregroundColor(.zmTextSecondary)
                        .fontWeight(.semibold)
                    Text("A system dialog will appear at the bottom. Hold the TOP of your iPhone against the card's IC chip (back of card).")
                        .font(.zmCaption)
                        .foregroundColor(.zmTextSecondary)
                }
            }
            .padding(Spacing.md)
            .background(Color.zmPrimary.opacity(0.1))
            .cornerRadius(CornerRadius.md)
            .padding(.horizontal, Spacing.screenHorizontal)

            // Card number input
            VStack(spacing: Spacing.sm) {
                TextField("AB12 3456 78CD", text: $cardNumberText)
                    .font(.system(.title2, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .padding()
                    .background(Color.zmSurface)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(
                                viewModel.isCardNumberValid ? Color.zmPrimary : Color.zmBorder,
                                lineWidth: 1
                            )
                    )
                    .onChange(of: cardNumberText) { _, newValue in
                        // Limit to 12 characters (excluding spaces)
                        let cleaned = newValue.replacingOccurrences(of: " ", with: "")
                        if cleaned.count > 12 {
                            cardNumberText = String(cleaned.prefix(12))
                        } else {
                            viewModel.cardNumberInput = newValue
                        }
                    }

                if !cardNumberText.isEmpty && !viewModel.isCardNumberValid {
                    Text("Card number must be 12 alphanumeric characters")
                        .font(.zmCaption)
                        .foregroundColor(.zmError)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            // Scan button
            Button {
                Task { await viewModel.startScan() }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "wave.3.right")
                    Text("Start Scan")
                }
                .font(.zmHeadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.isCardNumberValid ? Color.zmPrimary : Color.zmPrimary.opacity(0.5))
                .cornerRadius(CornerRadius.button)
            }
            .disabled(!viewModel.isCardNumberValid)
            .padding(.horizontal, Spacing.screenHorizontal)

            // Device compatibility note
            if !NFCReaderService.isAvailable {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.zmWarning)
                    Text("NFC not available on this device")
                        .font(.zmCaption)
                        .foregroundColor(.zmWarning)
                }
            }

            Spacer()

            // Help link
            Button {
                // Show help sheet
            } label: {
                Text("Where do I find my card number?")
                    .font(.zmCaption)
                    .foregroundColor(.zmPrimary)
            }
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.zmBackground)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.zmError.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.zmError)
            }

            Text("Scan Failed")
                .font(.zmTitle2)
                .foregroundColor(.zmTextPrimary)

            Text(message)
                .font(.zmBody)
                .foregroundColor(.zmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            VStack(spacing: Spacing.md) {
                Button {
                    Task { await viewModel.startScan() }
                } label: {
                    Text("Try Again")
                        .font(.zmHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.zmPrimary)
                        .cornerRadius(CornerRadius.button)
                }

                Button {
                    viewModel.reset()
                } label: {
                    Text("Enter Different Card Number")
                        .font(.zmBody)
                        .foregroundColor(.zmPrimary)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            Spacer()
        }
        .background(Color.zmBackground)
    }

    // MARK: - Actions

    private func saveAndDismiss(_ cardData: ZairyuCardData) async {
        do {
            try await viewModel.saveToProfile(cardData)
            dismiss()
        } catch {
            viewModel.scanState = .error("Failed to save: \(error.localizedDescription)")
        }
    }
}
