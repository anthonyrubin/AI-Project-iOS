import Foundation
import Combine

@MainActor
class CreateAccountViewModel: ObservableObject {
    
    private let authRepository: AuthRepository
    private let socialLoginManager: SocialLoginManager
    @Published var checkpoint: Checkpoint?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    init(
        authRepository: AuthRepository,
        socialLoginManager: SocialLoginManager
    ) {
        self.authRepository = authRepository
        self.socialLoginManager = socialLoginManager
    }
    
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        
        socialLoginManager.signInWithGoogle { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let socialResult):
                    self?.handleSocialLogin(socialResult)
                case .failure(let error):
                    self?.isLoading = false
                    if case .cancelled = error {
                        // User cancelled, don't show error
                        return
                    }
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        socialLoginManager.signInWithApple { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let socialResult):
                    self?.handleSocialLogin(socialResult)
                case .failure(let error):
                    self?.isLoading = false
                    if case .cancelled = error {
                        // User cancelled, don't show error
                        return
                    }
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleSocialLogin(_ socialResult: SocialLoginResult) {
        // Check if this is a new user (has signup data) or existing user
        let signupData = UserDefaultsManager.shared.getSignupData()
        let hasSignupData = signupData.birthday != nil || signupData.gender != nil || 
                           signupData.height != nil || signupData.weight != nil ||
                           signupData.selectedGoals != nil || signupData.sportDisplay != nil
        
        if hasSignupData {
            // New user with signup data - use enhanced endpoint
            sendSignupDataToBackend(socialResult: socialResult)
        } else {
            // Existing user - use simple social login
            sendSimpleSocialLogin(socialResult: socialResult)
        }
    }
    
    private func sendSimpleSocialLogin(socialResult: SocialLoginResult) {
        // Simple request without signup data for existing users
        var requestData: [String: Any] = [
            "provider": socialResult.provider.rawValue,
            "id_token": socialResult.idToken
        ]
        
        // Add access token if available
        if let accessToken = socialResult.accessToken {
            requestData["access_token"] = accessToken
        }
        
        print("📝 CreateAccountViewModel: Sending simple social login request for existing user")
        
        authRepository.socialSignInWithData(
            provider: socialResult.provider,
            data: requestData
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                self?.handleSocialLoginResponse(result, socialResult: socialResult)
            }
        }
    }
    
    private func handleSocialLoginResponse(_ result: Result<SocialSignInResponse, NetworkError>, socialResult: SocialLoginResult) {
        switch result {
        case .success(let response):
            if response.isNewUser {
                // New user - send collected signup data to backend
                sendSignupDataToBackend(socialResult: socialResult)
            } else if let _ = response.tokens {
                // Existing user - complete signup and go home
                UserDefaultsManager.shared.completeSignupSession()
                checkpoint = .home
            } else if let checkpoint = response.checkpoint {
                // Handle checkpoint-based navigation
                handleCheckpoint(checkpoint)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func sendSignupDataToBackend(socialResult: SocialLoginResult) {
        let signupData = UserDefaultsManager.shared.getSignupData()
        
        // Create enhanced request with signup data
        let requestData = createEnhancedSocialLoginRequest(
            socialResult: socialResult,
            signupData: signupData
        )
        
        print("📝 CreateAccountViewModel: Sending enhanced social login request:")
        print("  - Request Data: \(requestData)")
        
        // Use unified social login endpoint
        authRepository.socialSignInWithData(
            provider: socialResult.provider,
            data: requestData
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                switch result {
                case .success(let response):
                    // Successfully completed signup
                    
                    self?.checkpoint = Checkpoint(rawValue: response.checkpoint!)
                    print("Checkpoint be")
                    print(self?.checkpoint)
                    print(response.checkpoint)
//
//                    // Check if user uploaded video for analysis
//                    let signupData = UserDefaultsManager.shared.getSignupData()
//                    if signupData.didUploadVideoForAnalysis {
//                        self?.checkpoint = .videoAnalysis
//                    } else {
//                        self?.checkpoint = .home
//                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func createEnhancedSocialLoginRequest(
        socialResult: SocialLoginResult,
        signupData: SignupUserData
    ) -> [String: Any] {
        var requestData: [String: Any] = [
            "provider": socialResult.provider.rawValue,
            "id_token": socialResult.idToken
        ]
        
        // Add access token if available
        if let accessToken = socialResult.accessToken {
            requestData["access_token"] = accessToken
        }
        
        // Add signup data for new users
        var signupDataDict: [String: Any] = [:]
        signupDataDict["birthday"] = signupData.birthday?.timeIntervalSince1970 ?? 0
        signupDataDict["gender"] = signupData.gender ?? ""
        signupDataDict["height"] = signupData.height ?? 0
        signupDataDict["weight"] = signupData.weight ?? 0
        signupDataDict["is_metric"] = signupData.isMetric ?? false
        signupDataDict["selected_goals"] = signupData.selectedGoals ?? []
        signupDataDict["sport_display"] = signupData.sportDisplay ?? ""
        signupDataDict["did_upload_video"] = signupData.didUploadVideoForAnalysis
        
        requestData["signup_data"] = signupDataDict
        
        return requestData
    }
    
    private func handleCheckpoint(_ checkpoint: String) {
        let _checkpoint = Checkpoint(rawValue: checkpoint)
        switch _checkpoint {
        case .name, .birthday, .home:
            self.checkpoint = _checkpoint
        default:
            errorMessage = "Unknown checkpoint: \(checkpoint)"
        }
    }
    
    func resetNavigationFlags() {
        checkpoint = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
}

