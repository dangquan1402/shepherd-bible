import XCTest
import StoreKit
import StoreKitTest
import SwiftData
@testable import Shepherd

@MainActor
final class StoreKitTests: XCTestCase {
    var session: SKTestSession!

    override func setUp() async throws {
        try await super.setUp()
        session = try SKTestSession(configurationFileNamed: "Shepherd")
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDown() async throws {
        session?.clearTransactions()
        session = nil
        try await super.tearDown()
    }

    func testStoreKitConfigurationAndPurchaseLifecycle() async throws {
        let session = try XCTUnwrap(session)

        // 1. Assert: 2 products loaded from configuration (monthly and yearly)
        let manager = StoreKitManager.shared
        await manager.loadProducts()
        if manager.products.isEmpty {
            throw XCTSkip("storekitd: app not installed for development (StoreKit Testing requires Xcode's Run/Test registration)")
        }
        XCTAssertEqual(manager.products.count, 2, "Must load 2 auto-renewing subscription products")

        let yearly = try XCTUnwrap(manager.yearlyProduct)
        let monthly = try XCTUnwrap(manager.monthlyProduct)
        XCTAssertEqual(yearly.id, ShepherdConstants.yearlySubscriptionID)
        XCTAssertEqual(monthly.id, ShepherdConstants.monthlySubscriptionID)

        // 2. Assert: free trial intro offer of 1 week (7 days)
        let introOffer = try XCTUnwrap(yearly.subscription?.introductoryOffer)
        XCTAssertEqual(introOffer.paymentMode, .freeTrial)
        XCTAssertEqual(introOffer.period.unit, .week)
        XCTAssertEqual(introOffer.period.value, 1)

        // 3. Purchase gives isPremium == true
        let purchaseResult = try await yearly.purchase()
        guard case .success(let verification) = purchaseResult,
              case .verified(let transaction) = verification else {
            XCTFail("Purchase failed or unverified")
            return
        }
        await transaction.finish()
        await manager.updateCustomerProductStatus()
        XCTAssertTrue(manager.isPremium, "Purchasing yearly plan must set isPremium to true")

        // 4. Persistence to EntitlementState
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: EntitlementState.self, configurations: config)
        let context = ModelContext(container)
        let ent = EntitlementState(isPremium: false)
        context.insert(ent)
        try context.save()

        await manager.updateCustomerProductStatus(context: context)
        XCTAssertTrue(ent.isPremium, "updateCustomerProductStatus(context:) must persist isPremium")
        XCTAssertEqual(ent.productId, yearly.id)

        // 5. Expiring subscription sets isPremium == false
        try session.expireSubscription(productIdentifier: yearly.id)
        await manager.updateCustomerProductStatus(context: context)
        XCTAssertFalse(manager.isPremium, "Expired subscription must set isPremium to false")

        // 6. Ask to Buy enabled gives .pending
        session.clearTransactions()
        session.askToBuyEnabled = true
        let askToBuyResult = try await monthly.purchase()
        if case .pending = askToBuyResult {
            XCTAssertTrue(true)
        } else {
            XCTFail("Ask to Buy must yield .pending")
        }
        session.askToBuyEnabled = false

        // 7. Simulated purchase failure keeps isPremium == false
        session.clearTransactions()
        try await session.setSimulatedError(.generic(.unknown), forAPI: .purchase)
        do {
            _ = try await monthly.purchase()
            XCTFail("Purchase should have failed with simulated error")
        } catch {
            XCTAssertFalse(manager.isPremium, "Failed purchase keeps isPremium false")
        }

        // 8. Restore with no transactions does not set .restored
        session.clearTransactions()
        try await session.setSimulatedError(nil, forAPI: .purchase)
        await manager.updateCustomerProductStatus()
        _ = await manager.restorePurchases()
        XCTAssertNotEqual(manager.purchaseState, .restored, "Restore with 0 transactions must not set .restored")
    }
}
