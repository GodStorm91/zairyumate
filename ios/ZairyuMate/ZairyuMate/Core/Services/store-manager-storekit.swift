//
//  store-manager-storekit.swift
//  ZairyuMate
//
//  StoreKit 2 manager for In-App Purchases
//  Handles product loading, purchases, restore, and transaction monitoring
//

import Foundation
import StoreKit
import Observation

// MARK: - Store Manager

@Observable
@MainActor
class StoreManager {

    // MARK: - Published State

    /// Available products from App Store
    var products: [Product] = []

    /// Set of purchased product IDs
    var purchasedProductIDs: Set<String> = []

    /// Loading state for products
    var isLoadingProducts = false

    /// Loading state for purchase
    var isPurchasing = false

    /// Last error message
    var lastError: String?

    // MARK: - Private Properties

    /// Transaction update listener task
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products and restore purchases
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Load available products from App Store
    func loadProducts() async {
        isLoadingProducts = true
        lastError = nil

        #if DEBUG
        print("🛒 StoreManager: Loading products...")
        #endif

        do {
            let loadedProducts = try await Product.products(for: IAPConstants.productIDs)
            products = loadedProducts

            #if DEBUG
            print("✅ StoreManager: Loaded \(products.count) products")
            for product in products {
                print("   - \(product.id): \(product.displayName) - \(product.displayPrice)")
            }
            #endif
        } catch {
            lastError = "Failed to load products: \(error.localizedDescription)"

            #if DEBUG
            print("❌ StoreManager: Failed to load products - \(error)")
            #endif
        }

        isLoadingProducts = false
    }

    // MARK: - Purchase

    /// Purchase a product
    /// - Parameter product: Product to purchase
    /// - Returns: True if purchase succeeded
    func purchase(_ product: Product) async throws -> Bool {
        isPurchasing = true
        lastError = nil

        #if DEBUG
        print("🛒 StoreManager: Initiating purchase for \(product.id)")
        #endif

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify transaction
                let transaction = try checkVerified(verification)

                // Update purchased products
                await updatePurchasedProducts()

                // Finish transaction
                await transaction.finish()

                // Cache Pro status locally
                UserDefaults.app.set(true, forKey: IAPConstants.Keys.isPro)
                UserDefaults.app.set(Date(), forKey: IAPConstants.Keys.lastVerificationDate)

                #if DEBUG
                print("✅ StoreManager: Purchase successful - \(product.id)")
                #endif

                isPurchasing = false
                return true

            case .userCancelled:
                #if DEBUG
                print("⚠️ StoreManager: Purchase cancelled by user")
                #endif

                isPurchasing = false
                return false

            case .pending:
                lastError = "Purchase is pending approval"

                #if DEBUG
                print("⏳ StoreManager: Purchase pending approval")
                #endif

                isPurchasing = false
                return false

            @unknown default:
                lastError = "Unknown purchase result"

                #if DEBUG
                print("❓ StoreManager: Unknown purchase result")
                #endif

                isPurchasing = false
                return false
            }
        } catch {
            lastError = error.localizedDescription

            #if DEBUG
            print("❌ StoreManager: Purchase failed - \(error)")
            #endif

            isPurchasing = false
            throw StoreError.purchaseFailed(error.localizedDescription)
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async {
        #if DEBUG
        print("🔄 StoreManager: Restoring purchases...")
        #endif

        await updatePurchasedProducts()

        if isPro {
            // Cache Pro status locally
            UserDefaults.app.set(true, forKey: IAPConstants.Keys.isPro)
            UserDefaults.app.set(Date(), forKey: IAPConstants.Keys.lastVerificationDate)

            #if DEBUG
            print("✅ StoreManager: Restore complete - Pro status active")
            #endif
        } else {
            // Clear cached Pro status
            UserDefaults.app.set(false, forKey: IAPConstants.Keys.isPro)

            #if DEBUG
            print("⚠️ StoreManager: Restore complete - No purchases found")
            #endif
        }
    }

    // MARK: - Transaction Monitoring

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { @MainActor in
            for await result in Transaction.updates {
                #if DEBUG
                print("🔔 StoreManager: Transaction update received")
                #endif

                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()

                    // Cache Pro status
                    UserDefaults.app.set(self.isPro, forKey: IAPConstants.Keys.isPro)
                    UserDefaults.app.set(Date(), forKey: IAPConstants.Keys.lastVerificationDate)
                } catch {
                    #if DEBUG
                    print("⚠️ StoreManager: Transaction verification failed - \(error)")
                    #endif
                }
            }
        }
    }

    /// Update set of purchased products from current entitlements
    private func updatePurchasedProducts() async {
        var purchasedIDs = Set<String>()

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedIDs.insert(transaction.productID)

                #if DEBUG
                print("✓ StoreManager: Found entitlement - \(transaction.productID)")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ StoreManager: Entitlement verification failed - \(error)")
                #endif
            }
        }

        purchasedProductIDs = purchasedIDs
    }

    // MARK: - Verification

    /// Verify transaction cryptographic signature
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw StoreError.verificationFailed(error.localizedDescription)
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Computed Properties

    /// Check if user has Pro access
    var isPro: Bool {
        // Check StoreKit entitlements first
        let hasEntitlement = purchasedProductIDs.contains(IAPConstants.proProductID)

        // Fallback to cached value for offline access
        if !hasEntitlement {
            return UserDefaults.app.bool(forKey: IAPConstants.Keys.isPro)
        }

        return hasEntitlement
    }

    /// Get Pro product
    var proProduct: Product? {
        products.first { $0.id == IAPConstants.proProductID }
    }
}

// MARK: - Store Errors

enum StoreError: LocalizedError {
    case verificationFailed(String)
    case purchaseFailed(String)
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .verificationFailed(let message):
            return "Verification failed: \(message)"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .productNotFound:
            return "Product not found"
        }
    }
}
