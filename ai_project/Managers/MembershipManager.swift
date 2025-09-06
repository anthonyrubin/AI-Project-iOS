import Foundation
import Combine

@MainActor
class MembershipManager: ObservableObject {
    @Published var isMember = false
    @Published var membershipStatus: String?
    @Published var daysRemaining: Int = 0
    @Published var minutesUsed: Double = 0
    @Published var minutesAllowed: Double = 0
    @Published var minutesRemaining: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func checkMembershipStatus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: MembershipStatusResponse = try await networkManager.request(
                endpoint: "/membership/status/",
                method: .get,
                responseType: MembershipStatusResponse.self
            )
            
            isMember = response.isMember
            membershipStatus = response.membership?.status
            daysRemaining = response.membership?.daysRemaining ?? 0
            minutesUsed = response.monthlyUsage.minutesUsed
            minutesAllowed = response.monthlyUsage.minutesAllowed
            minutesRemaining = response.monthlyUsage.minutesRemaining
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error checking membership status: \(error)")
        }
        
        isLoading = false
    }
    
    func verifyReceipt(receiptData: String, transactionId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = VerifyReceiptRequest(
                receiptData: receiptData,
                transactionId: transactionId
            )
            
            let response: VerifyReceiptResponse = try await networkManager.request(
                endpoint: "/membership/verify-receipt/",
                method: .post,
                body: request,
                responseType: VerifyReceiptResponse.self
            )
            
            // Update local membership status
            await checkMembershipStatus()
            
            isLoading = false
            return response.success
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error verifying receipt: \(error)")
            isLoading = false
            return false
        }
    }
    
    func restorePurchase() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: RestorePurchaseResponse = try await networkManager.request(
                endpoint: "/membership/restore-purchase/",
                method: .post,
                responseType: RestorePurchaseResponse.self
            )
            
            // Update local membership status
            await checkMembershipStatus()
            
            isLoading = false
            return response.success
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error restoring purchase: \(error)")
            isLoading = false
            return false
        }
    }
    
    func checkAnalysisAllowance() async -> AnalysisAllowanceResponse? {
        do {
            let response: AnalysisAllowanceResponse = try await networkManager.request(
                endpoint: "/membership/analysis-allowance/",
                method: .get,
                responseType: AnalysisAllowanceResponse.self
            )
            
            return response
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error checking analysis allowance: \(error)")
            return nil
        }
    }
}

// MARK: - Response Models

struct MembershipStatusResponse: Codable {
    let isMember: Bool
    let membership: MembershipInfo?
    let monthlyUsage: MonthlyUsageInfo
    
    enum CodingKeys: String, CodingKey {
        case isMember = "is_member"
        case membership
        case monthlyUsage = "monthly_usage"
    }
}

struct MembershipInfo: Codable {
    let status: String?
    let daysRemaining: Int
    let subscriptionEndDate: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case daysRemaining = "days_remaining"
        case subscriptionEndDate = "subscription_end_date"
    }
}

struct MonthlyUsageInfo: Codable {
    let minutesUsed: Double
    let minutesAllowed: Double
    let minutesRemaining: Double
    
    enum CodingKeys: String, CodingKey {
        case minutesUsed = "minutes_used"
        case minutesAllowed = "minutes_allowed"
        case minutesRemaining = "minutes_remaining"
    }
}

struct VerifyReceiptRequest: Codable {
    let receiptData: String
    let transactionId: String
    
    enum CodingKeys: String, CodingKey {
        case receiptData = "receipt_data"
        case transactionId = "transaction_id"
    }
}

struct VerifyReceiptResponse: Codable {
    let success: Bool
    let message: String
    let membership: MembershipDetails?
}

struct MembershipDetails: Codable {
    let status: String
    let daysRemaining: Int
    let monthlyAllowance: Double
    let minutesRemaining: Double
    
    enum CodingKeys: String, CodingKey {
        case status
        case daysRemaining = "days_remaining"
        case monthlyAllowance = "monthly_allowance"
        case minutesRemaining = "minutes_remaining"
    }
}

struct RestorePurchaseResponse: Codable {
    let success: Bool
    let message: String
    let membership: MembershipDetails?
}

struct AnalysisAllowanceResponse: Codable {
    let canAnalyze: Bool
    let reason: String?
    let upgradeRequired: Bool?
    let minutesRemaining: Double?
    let resetDate: String?
    
    enum CodingKeys: String, CodingKey {
        case canAnalyze = "can_analyze"
        case reason
        case upgradeRequired = "upgrade_required"
        case minutesRemaining = "minutes_remaining"
        case resetDate = "reset_date"
    }
}
