//
//  pro-upgrade-purchase-screen-view.swift
//  ZairyuMate
//
//  Pro upgrade purchase screen with pricing, features, and purchase flow
//  Handles product loading, purchase, restore, and error states
//

import SwiftUI
import StoreKit

// MARK: - Pro Upgrade View

struct ProUpgradeView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    @Environment(EntitlementManager.self) private var entitlements

    // MARK: - State

    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var errorMessage = ""

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Header
                headerSection

                // Feature comparison
                TierComparisonView()
                    .padding(.horizontal, Spacing.screenHorizontal)

                // Pro features list
                proFeaturesSection

                // Purchase section
                if !storeManager.isPro {
                    purchaseSection
                } else {
                    proActiveSection
                }

                // Legal text
                legalSection
            }
            .padding(.vertical, Spacing.xl)
        }
        .background(Color.zmBackground)
        .navigationTitle("Upgrade to Pro")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Welcome to Pro!", isPresented: $showingSuccess) {
            Button("Continue") {
                dismiss()
            }
        } message: {
            Text("All Pro features are now unlocked. Enjoy!")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Pro badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.8),
                                Color.orange.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "star.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.yellow.opacity(0.3), radius: 10, x: 0, y: 4)

            Text("Zairyu Mate Pro")
                .font(.zmTitle)
                .foregroundColor(.zmTextPrimary)

            Text("Unlock all premium features")
                .font(.zmBody)
                .foregroundColor(.zmTextSecondary)
        }
    }

    // MARK: - Pro Features Section

    private var proFeaturesSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(entitlements.proFeatures) { feature in
                HStack(spacing: Spacing.md) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.zmPrimary)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(feature.name)
                            .font(.zmHeadline)
                            .foregroundColor(.zmTextPrimary)

                        Text(feature.description)
                            .font(.zmCaption)
                            .foregroundColor(.zmTextSecondary)
                    }

                    Spacer()
                }
                .padding(Spacing.md)
                .background(Color.white)
                .cornerRadius(CornerRadius.md)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: Spacing.md) {
            if storeManager.isLoadingProducts {
                ProgressView("Loading products...")
                    .padding()
            } else if let product = storeManager.proProduct {
                // Purchase button
                PrimaryButton(
                    title: "Upgrade for \(product.displayPrice)",
                    action: { purchaseProduct(product) },
                    isLoading: storeManager.isPurchasing
                )
                .padding(.horizontal, Spacing.screenHorizontal)

                // Restore purchases button
                Button {
                    restorePurchases()
                } label: {
                    Text("Restore Purchases")
                        .font(.zmBody)
                        .foregroundColor(.zmPrimary)
                }
            } else {
                // Product not available
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)

                    Text("Unable to load products")
                        .font(.zmBody)
                        .foregroundColor(.zmTextSecondary)

                    Button("Try Again") {
                        Task {
                            await storeManager.loadProducts()
                        }
                    }
                    .font(.zmBody)
                    .foregroundColor(.zmPrimary)
                }
                .padding()
            }
        }
    }

    // MARK: - Pro Active Section

    private var proActiveSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Pro Active")
                .font(.zmTitle2)
                .foregroundColor(.zmTextPrimary)

            Text("You have access to all Pro features")
                .font(.zmBody)
                .foregroundColor(.zmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .background(Color.green.opacity(0.1))
        .cornerRadius(CornerRadius.card)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("One-time purchase. No subscription.")
                .font(.zmCaption)
                .foregroundColor(.zmTextSecondary)

            Text("Payment charged to Apple ID at purchase confirmation.")
                .font(.zmCaption2)
                .foregroundColor(.zmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Actions

    private func purchaseProduct(_ product: Product) {
        Task {
            do {
                let success = try await storeManager.purchase(product)
                if success {
                    showingSuccess = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func restorePurchases() {
        Task {
            await storeManager.restorePurchases()

            if storeManager.isPro {
                showingSuccess = true
            } else {
                errorMessage = "No previous purchases found. If you already purchased Pro, please contact support."
                showingError = true
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Not Pro") {
    NavigationStack {
        ProUpgradeView()
            .environment(StoreManager())
            .environment(EntitlementManager(storeManager: StoreManager()))
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        ProUpgradeView()
            .environment(StoreManager())
            .environment(EntitlementManager(storeManager: StoreManager()))
    }
    .preferredColorScheme(.dark)
}
#endif
