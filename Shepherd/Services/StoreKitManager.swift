import Foundation
import StoreKit

/// Wire real product IDs in App Store Connect, then replace stubs.
@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    static let monthlyID = "com.dangvietquan.shepherd.premium.monthly"
    static let yearlyID = "com.dangvietquan.shepherd.premium.yearly"

    @Published var products: [Product] = []
    @Published var purchaseError: String?

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.monthlyID, Self.yearlyID])
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(.verified):
                return true
            default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }
}
