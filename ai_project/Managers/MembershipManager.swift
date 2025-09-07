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
    
    func checkMembershipStatus() {
        isLoading = true
        errorMessage = nil
        
        networkManager.checkMembershipStatus { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.isMember = response.isMember
                    self?.membershipStatus = response.membership?.status
                    self?.daysRemaining = response.membership?.daysRemaining ?? 0
                    self?.minutesUsed = response.monthlyUsage.minutesUsed
                    self?.minutesAllowed = response.monthlyUsage.minutesAllowed
                    self?.minutesRemaining = response.monthlyUsage.minutesRemaining
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Error checking membership status: \(error)")
                }
                self?.isLoading = false
            }
        }
    }

    
    func restorePurchase(completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        networkManager.restorePurchase { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Update local membership status
                    self?.checkMembershipStatus()
                    completion(response.success)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Error restoring purchase: \(error)")
                    completion(false)
                }
                self?.isLoading = false
            }
        }
    }
    
    func checkAnalysisAllowance(completion: @escaping (AnalysisAllowanceResponse?) -> Void) {
        networkManager.checkAnalysisAllowance { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    completion(response)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Error checking analysis allowance: \(error)")
                    completion(nil)
                }
            }
        }
    }
    
//    func attachSubscription(_ payload: AttachPayload, completion: @escaping (Bool) -> Void) {
//        isLoading = true
//        errorMessage = nil
//
//        networkManager.attachSubscription(payload: payload) { [weak self] result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let response):
//                    // Pull latest state
//                    self?.checkMembershipStatus()
//                    completion(response.success)
//                case .failure(let error):
//                    self?.errorMessage = error.localizedDescription
//                    print("Error attaching subscription: \(error)")
//                    completion(false)
//                }
//                self?.isLoading = false
//            }
//        }
//    }
}
