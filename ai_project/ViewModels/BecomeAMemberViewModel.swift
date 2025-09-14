import Foundation
import Combine

class BecomeAMemberViewModel {
    
    private var repository: VideoAnalysisRepository
    private var membershipAPI: MembershipAPI
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isMember = false
    @Published var membershipStatus: String?
    
    init(repository: VideoAnalysisRepository, membershipAPI: MembershipAPI) {
        self.repository = repository
        self.membershipAPI = membershipAPI
    }
    
    func attachSubscription(_ payload: AttachPayload, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        membershipAPI.attachSubscription(payload: payload) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    completion(response.success)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Error attaching subscription: \(error)")
                    completion(false)
                }
                self?.isLoading = false
            }
        }
    }
    
    func getLastUpload() -> VideoAnalysisObject? {
        return repository.getLastAnalysis()
    }
}
