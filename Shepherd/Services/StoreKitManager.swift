import Foundation
import StoreKit
import SwiftData

public enum PaywallPurchaseState: Equatable, Sendable {
    case idle
    case purchasing
    case pending // Ask to Buy
    case failed(String)
    case restored
}

@MainActor
public final class StoreKitManager: ObservableObject {
    public static let shared = StoreKitManager()

    @Published public private(set) var products: [Product] = []
    @Published public private(set) var isPremium: Bool = false
    @Published public var purchaseState: PaywallPurchaseState = .idle
    @Published public var lastErrorMessage: String?

    public var yearlyProduct: Product? {
        products.first { $0.id == ShepherdConstants.yearlySubscriptionID }
    }

    public var monthlyProduct: Product? {
        products.first { $0.id == ShepherdConstants.monthlySubscriptionID }
    }

    private var updatesTask: Task<Void, Never>?

    public init() {
        startTransactionListener()
    }

    deinit {
        updatesTask?.cancel()
    }

    public func startTransactionListener() {
        guard updatesTask == nil else { return }
        updatesTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await self?.updateCustomerProductStatus()
                }
            }
        }
    }

    public func loadProducts() async {
        do {
            let productIDs = [
                ShepherdConstants.monthlySubscriptionID,
                ShepherdConstants.yearlySubscriptionID
            ]
            let loaded = try await Product.products(for: productIDs)
            self.products = loaded.sorted { $0.price > $1.price } // Yearly first
            await updateCustomerProductStatus()
        } catch {
            self.lastErrorMessage = error.localizedDescription
        }
    }

    public func updateCustomerProductStatus() async {
        var hasActiveEntitlement = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                if transaction.revocationDate == nil,
                   (transaction.expirationDate == nil || transaction.expirationDate! > Date()) {
                    hasActiveEntitlement = true
                }
            }
        }
        self.isPremium = hasActiveEntitlement
    }

    public func purchase(_ product: Product) async -> Bool {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updateCustomerProductStatus()
                    purchaseState = .idle
                    return true
                case .unverified(_, let error):
                    purchaseState = .failed(error.localizedDescription)
                    return false
                }
            case .userCancelled:
                purchaseState = .idle
                return false
            case .pending:
                purchaseState = .pending
                return false
            @unknown default:
                purchaseState = .idle
                return false
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            return false
        }
    }

    public func restorePurchases() async -> Bool {
        purchaseState = .purchasing
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
            purchaseState = .restored
            return isPremium
        } catch {
            purchaseState = .failed(error.localizedDescription)
            return false
        }
    }
}
