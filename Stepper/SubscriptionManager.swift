//
//  SubscriptionManager.swift
//  Stepper
//
//  StoreKit 2 wrapper. Owns the auto-renewable subscription products,
//  drives the paywall, and exposes a single source of truth (`isPremium`)
//  for premium-gating across the app.
//
//  Why StoreKit 2 (not the legacy SKPaymentQueue): the modern API is
//  async/await native, type-safe, and — critically for App Review —
//  surfaces fully verified `Transaction` objects so we never need our own
//  receipt-validation server. The trade-off is iOS 15+ only, which is
//  fine for our deployment target (iOS 17+).
//

import Foundation
import StoreKit

@MainActor
@Observable
final class SubscriptionManager {

    // MARK: - Product identifiers
    //
    // These are *placeholders*. Before submitting to App Store Connect:
    //   1. Create matching auto-renewable subscriptions inside ASC under
    //      the "Stepper Premium" group (Subscriptions → Create).
    //   2. Set the price tier per region — see docs/storekit-setup.md.
    //   3. Localise display names and descriptions in EN+RU.
    //
    // The IDs match the local `Stepper.storekit` configuration so the same
    // codepath drives both Xcode previews and the real App Store.
    enum ProductID: String, CaseIterable {
        case monthly  = "com.borisdev.Stepper.premium.monthly"
        case yearly   = "com.borisdev.Stepper.premium.yearly"
        case lifetime = "com.borisdev.Stepper.premium.lifetime"

        var isSubscription: Bool { self != .lifetime }
    }

    // MARK: - Public state

    /// All loaded products, sorted by price ascending. Empty until
    /// `loadProducts()` resolves.
    private(set) var products: [Product] = []

    /// True iff the current user has an active premium entitlement (any
    /// subscription period or the lifetime product). Drives every premium
    /// gate in the app.
    private(set) var isPremium: Bool = false

    /// True while a purchase / restore is in flight; the paywall CTA
    /// reflects this so the user doesn't fire two purchases.
    private(set) var isProcessing: Bool = false

    /// Last error surfaced to the UI. Cleared on the next successful op.
    var lastError: String?

    // MARK: - Lifecycle

    private var transactionListener: Task<Void, Never>?

    init() {
        // Apple recommends installing the listener immediately (before the
        // first call to `Product.products(for:)`) so any out-of-band
        // transactions (e.g. pending family-share authorizations resolving
        // while we're cold-starting) don't get dropped.
        transactionListener = Self.listenForTransactions(target: self)
    }

    // No `deinit { transactionListener?.cancel() }` — `deinit` runs on a
    // nonisolated context and can't touch our main-actor stored property.
    // The listener task captures `self` weakly, so when the manager is
    // deallocated the loop exits on its next iteration.

    // MARK: - Public API

    /// Loads products from the App Store. Safe to call repeatedly; each
    /// call replaces the cached list.
    func loadProducts() async {
        do {
            let identifiers = ProductID.allCases.map(\.rawValue)
            let loaded = try await Product.products(for: identifiers)
            products = loaded.sorted { $0.price < $1.price }
            await refreshEntitlement()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Initiates a purchase. Returns the verified transaction on success,
    /// or nil for user cancel / pending (Ask-to-Buy / SCA).
    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        isProcessing = true
        defer { isProcessing = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlement()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            // Apple finishes this asynchronously and our
            // `transactionListener` will pick it up.
            return nil

        @unknown default:
            return nil
        }
    }

    /// Forces App Store to re-deliver every entitlement the user has
    /// previously bought. Required by Apple Guideline 3.1.1 (any paywall
    /// must offer Restore Purchases).
    func restore() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await AppStore.sync()
            await refreshEntitlement()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Recomputes `isPremium` from the current entitlements. Call after
    /// any operation that may change them.
    func refreshEntitlement() async {
        var hasPremium = false
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if Self.isPremiumProduct(transaction.productID) {
                    hasPremium = true
                }
            } catch {
                // Verification failure ≠ premium.
                continue
            }
        }
        isPremium = hasPremium
    }

    // MARK: - Convenience

    /// Returns the product matching the given ID, if loaded.
    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    /// Localised price string ("$9.99", "990 ₽") for the given product.
    func displayPrice(for product: Product) -> String {
        product.displayPrice
    }

    // MARK: - Private

    private static func listenForTransactions(target: SubscriptionManager) -> Task<Void, Never> {
        Task { [weak target] in
            for await result in Transaction.updates {
                guard let target else { return }
                do {
                    let transaction = try await target.handleVerified(result)
                    await transaction.finish()
                    await target.refreshEntitlement()
                } catch {
                    continue
                }
            }
        }
    }

    private func handleVerified(_ result: VerificationResult<Transaction>) async throws -> Transaction {
        try checkVerified(result)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified(_, let error):
            throw error
        }
    }

    private static func isPremiumProduct(_ identifier: String) -> Bool {
        ProductID.allCases.contains { $0.rawValue == identifier }
    }
}
