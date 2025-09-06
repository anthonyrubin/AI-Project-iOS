import Foundation
import StoreKit

typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionGroupStatus: RenewalState?
    
    var monthlyMembershipProduct: Product? {
        subscriptions.first { $0.id == "subscription.monthly" }
    }
    
    private let productIDs = ["subscription.monthly"]
    
    private var updateListenerTask: Task<Void, Error>?
    
    init () {
        
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                
                    print("Transaction failed verification")
                }

            }
        }
    }

    @MainActor
    func requestProducts() async {
        do {
            subscriptions = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Check whether the transaction is verified. If it isn't,
            // this function re-throws the verification error
            let transaction = try checkVerified(verification)
            
            // The transaction is verified.
            //
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
        

    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    @MainActor
    private func updateCustomerProductStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                // Check whether the transaction is verified.
                // If it isn't, catch `failedVerification` error.
                
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: {$0.id == transaction.productID}) {
                        purchasedSubscriptions.append(subscription)
                    }
                default:
                    break
                }
                
                // Always finish a transaction
                await transaction.finish()
            } catch {
                print("Failed updating products")
            }
        }
        
//        for await result in Transaction.currentEntitlements {
//            guard let transaction = try? checkVerified(result) else {
//                continue
//            }
//
//            if transaction.revocationDate == nil {
//                purchasedProductIDs.insert(transaction.productID)
//            } else {
//                purchasedProductIDs.remove(transaction.productID)
//            }
//        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}

//@MainActor
//class StoreKitManager: NSObject, ObservableObject {
//    static let shared = StoreKitManager()
//    
//    @Published var products: [Product] = []
//    @Published var purchasedProductIDs = Set<String>()
//    @Published var isPurchasing = false
//    @Published var errorMessage: String?
//    
//    private var productIDs = ["subscription.monthly"]
//    private var updateListenerTask: Task<Void, Error>?
//    
//    override init() {
//        super.init()
//        updateListenerTask = listenForTransactions()
//        
//        Task {
//            await requestProducts()
//            await updatePurchasedProducts()
//        }
//    }
//    
//    deinit {
//        updateListenerTask?.cancel()
//    }
//    
//    func requestProducts() async {
//        do {
//            products = try await Product.products(for: productIDs)
//        } catch {
//            print("Failed to load products: \(error)")
//            errorMessage = "Failed to load products"
//        }
//    }
//    
//    func purchase(_ product: Product) async throws -> Transaction? {
//        isPurchasing = true
//        defer { isPurchasing = false }
//        
//        do {
//            let result = try await product.purchase()
//            
//            switch result {
//            case .success(let verification):
//                let transaction = try checkVerified(verification)
//                await updatePurchasedProducts()
//                await transaction.finish()
//                return transaction
//            case .userCancelled:
//                return nil
//            case .pending:
//                return nil
//            @unknown default:
//                return nil
//            }
//        } catch {
//            errorMessage = error.localizedDescription
//            throw error
//        }
//    }
//    
//    func restorePurchases() async throws {
//        try await AppStore.sync()
//        await updatePurchasedProducts()
//    }
//    
//    private func updatePurchasedProducts() async {
//        for await result in Transaction.currentEntitlements {
//            guard let transaction = try? checkVerified(result) else {
//                continue
//            }
//            
//            if transaction.revocationDate == nil {
//                purchasedProductIDs.insert(transaction.productID)
//            } else {
//                purchasedProductIDs.remove(transaction.productID)
//            }
//        }
//    }
//    
//    private func listenForTransactions() -> Task<Void, Error> {
//        let manager = self
//        return Task.detached {
//            for await result in Transaction.updates {
//                guard let transaction = try? await manager.checkVerified(result) else {
//                    continue
//                }
//                
//                await manager.updatePurchasedProducts()
//                await transaction.finish()
//            }
//        }
//    }
//    
//    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
//        switch result {
//        case .unverified:
//            throw StoreError.failedVerification
//        case .verified(let safe):
//            return safe
//        }
//    }
//    
//    var monthlyMembershipProduct: Product? {
//        products.first { $0.id == "subscription.monthly" }
//    }
//    
//    var hasActiveMembership: Bool {
//        !purchasedProductIDs.isEmpty
//    }
//}
//
//enum StoreError: LocalizedError {
//    case failedVerification
//    
//    var errorDescription: String? {
//        switch self {
//        case .failedVerification:
//            return "Transaction verification failed"
//        }
//    }
//}
