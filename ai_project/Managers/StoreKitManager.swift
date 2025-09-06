import Foundation
import StoreKit

typealias RenewalState = StoreKit.Product.SubscriptionInfo.Status

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionGroupStatus: RenewalState?

    private let productIDs = ["subscription.monthly"]

    var monthlyMembershipProduct: Product? {
        subscriptions.first { $0.id == "subscription.monthly" }
    }

    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }

    deinit { updateListenerTask?.cancel() }

    func requestProducts() async {
        do { subscriptions = try await Product.products(for: productIDs) }
        catch { print("⚠️ Failed to load products: \(error)") }
    }

    struct PurchaseOutcome {
        let transaction: Transaction
        let jws: String?        // signed JWS from Apple’s VerificationResult
    }

    /// Purchase wrapper. If you have an appAccountToken for this user, pass it.
    /// Apple will store it and return it in all server webhooks and API responses.
    func purchase(_ product: Product, appAccountToken: UUID? = nil) async throws -> PurchaseOutcome? {
        let options: Set<Product.PurchaseOption> = appAccountToken.map { [.appAccountToken($0)] } ?? []

        let result = try await product.purchase(options: options)

        switch result {
        case .success(let verification):
            // This is Apple’s signed payload – keep it and send to your server.
            let jws = verification.jwsRepresentation

            // Verify locally to get a Transaction object
            let tx: Transaction = try checkVerified(verification)

            await updateCustomerProductStatus()
            await tx.finish()

            return PurchaseOutcome(transaction: tx, jws: jws)

        case .userCancelled, .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            for await update in Transaction.updates {
                do {
                    let tx: Transaction = try await self.checkVerified(update)
                    await self.updateCustomerProductStatus()
                    await tx.finish()
                } catch {
                    print("⚠️ Transaction failed verification: \(error)")
                }
            }
        }
    }

    func updateCustomerProductStatus() async {
        var owned = Set<String>()
        for await r in Transaction.currentEntitlements {
            guard case .verified(let tx) = r else { continue }
            if tx.productType == .autoRenewable { owned.insert(tx.productID) }
        }
        purchasedSubscriptions = subscriptions.filter { owned.contains($0.id) }

        if let sub = subscriptions.first(where: { $0.type == .autoRenewable }),
           let statuses = try? await sub.subscription?.status,
           let first = statuses.first {
            subscriptionGroupStatus = first
        } else {
            subscriptionGroupStatus = nil
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified: throw StoreError.failedVerification
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification
    case purchaseNotCompleted
    var errorDescription: String? {
        switch self {
        case .failedVerification: return "Transaction verification failed."
        case .purchaseNotCompleted: return "Purchase not completed."
        }
    }
}
